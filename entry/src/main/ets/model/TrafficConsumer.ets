/**
 * TrafficConsumer - 流量消耗器核心引擎
 *
 * 功能：
 * - 通过并发HTTP下载持续消耗网络流量
 * - 实时计算网速（每秒更新）
 * - 支持流量限额自动停止
 * - 自定义下载链接
 */

import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';

/**
 * 流量消耗器回调接口
 */
export interface TrafficCallbacks {
  /** 网速更新 (KB/s) */
  onSpeedUpdate: (speedKBps: number) => void;
  /** 流量更新 (总MB, 总Bytes) */
  onTrafficUpdate: (totalMB: number, totalBytes: number) => void;
  /** 达到流量限额 */
  onLimitReached: () => void;
  /** 错误发生 */
  onError: (errorMsg: string) => void;
  /** 运行状态变化 */
  onStatusChange: (isActive: boolean) => void;
}

/**
 * 流量消耗器类
 */
export class TrafficConsumer {
  private url: string = '';
  private limitBytes: number = 0;    // 0 表示无限制
  private totalBytes: number = 0;    // 累计消耗流量
  private speedKBps: number = 0;     // 当前网速 KB/s
  private isActive: boolean = false; // 是否运行中
  private callbacks?: TrafficCallbacks;

  // 速度计算
  private lastCalcBytes: number = 0;
  private lastCalcTime: number = 0;
  private speedTimerId: number = -1;

  // 并发控制
  private activeRequests: http.HttpRequest[] = [];
  private stopFlag: boolean = false;
  private concurrentCount: number = 3;

  // 自动重连
  private reconnectThresholdKBps: number = 0;   // 0=禁用
  private reconnectCooldownMs: number = 5000;    // 重连冷却
  private lastReconnectTime: number = 0;         // 上次重连时间戳

  constructor(concurrent: number = 3) {
    this.concurrentCount = Math.max(1, Math.min(concurrent, 10));
  }

  /** 设置下载链接 */
  setUrl(url: string): void {
    this.url = url;
  }

  /** 设置流量限额（字节），0 为无限制 */
  setLimitBytes(bytes: number): void {
    this.limitBytes = bytes;
  }

  /** 设置重连阈值（KB/s），0 表示禁用 */
  setReconnectThreshold(kbps: number): void {
    this.reconnectThresholdKBps = kbps;
  }

  /** 设置并发下载数（1-10） */
  setConcurrentCount(count: number): void {
    if (!this.isActive && count >= 1 && count <= 10) {
      this.concurrentCount = count;
    }
  }

  /** 注册回调 */
  setCallbacks(cbs: TrafficCallbacks): void {
    this.callbacks = cbs;
  }

  /** 获取当前总消耗流量 */
  getTotalBytes(): number {
    return this.totalBytes;
  }

  /** 是否运行中 */
  isRunning(): boolean {
    return this.isActive;
  }

  /** 开始消耗流量 */
  start(): void {
    if (this.isActive) {
      return;
    }
    if (!this.url) {
      this.callbacks?.onError('请先设置下载链接');
      return;
    }

    this.isActive = true;
    this.stopFlag = false;
    this.lastCalcTime = Date.now();
    this.lastCalcBytes = this.totalBytes;

    // 启动速度监控定时器（每秒更新一次）
    this.speedTimerId = setInterval(() => {
      if (!this.isActive) {
        return;
      }
      const now: number = Date.now();
      const elapsed: number = (now - this.lastCalcTime) / 1000.0;
      if (elapsed >= 1.0) {
        const deltaBytes: number = this.totalBytes - this.lastCalcBytes;
        this.speedKBps = deltaBytes / 1024.0 / elapsed;
        this.lastCalcBytes = this.totalBytes;
        this.lastCalcTime = now;
        this.callbacks?.onSpeedUpdate(this.speedKBps);

        // 自动重连检测：速度低于阈值且非冷却中
        if (this.reconnectThresholdKBps > 0 && this.speedKBps < this.reconnectThresholdKBps) {
          const now2: number = Date.now();
          if (now2 - this.lastReconnectTime > this.reconnectCooldownMs) {
            this.reconnect();
          }
        }
      }
    }, 1000);

    this.callbacks?.onStatusChange(true);

    // 启动多个并发下载流
    for (let i = 0; i < this.concurrentCount; i++) {
      this.startStream();
    }
  }

  /** 停止消耗流量 */
  stop(): void {
    this.stopFlag = true;
    this.isActive = false;
    this.callbacks?.onStatusChange(false);

    // 停止速度计算定时器
    if (this.speedTimerId >= 0) {
      clearInterval(this.speedTimerId);
      this.speedTimerId = -1;
    }

    // 销毁所有正在进行的请求
    for (const req of this.activeRequests) {
      try {
        req.destroy();
      } catch (_) {
        // 忽略销毁时的错误
      }
    }
    this.activeRequests = [];
  }

  /** 重置计数器（停止并清零） */
  reset(): void {
    this.stop();
    this.totalBytes = 0;
    this.speedKBps = 0;
    this.lastCalcBytes = 0;
    this.lastCalcTime = Date.now();
  }

  /** 从活跃请求列表中移除 */
  private removeRequest(req: http.HttpRequest): void {
    const idx: number = this.activeRequests.indexOf(req);
    if (idx >= 0) {
      this.activeRequests.splice(idx, 1);
    }
  }

  /** 重连：销毁所有活跃请求，流会自动重建新连接 */
  private reconnect(): void {
    this.lastReconnectTime = Date.now();
    this.callbacks?.onStatusChange(true); // 刷新状态（触发UI更新）

    // 销毁所有正在进行的请求 → 各流的 catch 会捕获 Cancellation
    for (const req of this.activeRequests) {
      try {
        req.destroy();
      } catch (_) {
        // 忽略
      }
    }
    this.activeRequests = [];
  }

  /** 延迟工具函数 */
  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  /** 单个下载流 — 不断循环下载 */
  private async startStream(): Promise<void> {
    while (this.isActive && !this.stopFlag) {
      const request: http.HttpRequest = http.createHttp();
      let needsCleanup: boolean = true;

      try {
        this.activeRequests.push(request);

        const response: http.HttpResponse = await request.request(
          this.url,
          {
            method: http.RequestMethod.GET,
            expectDataType: http.HttpDataType.ARRAY_BUFFER,
            connectTimeout: 15000,
            readTimeout: 30000,
            usingProtocol: http.HttpProtocol.HTTP1_1,
          }
        );

        this.removeRequest(request);
        needsCleanup = false;
        request.destroy();

        if (response.responseCode === 200 && response.result) {
          const arrayBuf: ArrayBuffer = response.result as ArrayBuffer;
          const bytesDownloaded: number = arrayBuf.byteLength;
          this.totalBytes += bytesDownloaded;
          this.callbacks?.onTrafficUpdate(
            this.totalBytes / (1024.0 * 1024.0),
            this.totalBytes
          );

          // 检查是否达到流量限额
          if (this.limitBytes > 0 && this.totalBytes >= this.limitBytes) {
            this.stop();
            this.callbacks?.onLimitReached();
            break;
          }
        }
      } catch (e) {
        if (needsCleanup) {
          this.removeRequest(request);
          try {
            request.destroy();
          } catch (_) {
            // 忽略
          }
        }

        const err: BusinessError = e as BusinessError;

        // 主动停止 → 彻底退出循环
        if (this.stopFlag) {
          break;
        }

        // error code 2300036 = request cancelled（由重连导致）
        // 不 break，让 while 条件重新进入下一轮
        if (err.code === 2300036) {
          continue;
        }

        // 真正出错 → 等待2秒后重试
        await this.delay(2000);
      }
    }
  }
}