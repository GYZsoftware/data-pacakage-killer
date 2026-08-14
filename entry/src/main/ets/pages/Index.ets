/**
 * 流量消耗器 - 主页面
 *
 * 功能：
 * 1. 自定义链接输入
 * 2. 流量限额配置（带单位选择）
 * 3. 并发下载数配置 + 重连阈值
 * 4. 实时计时、网速、累计流量显示
 * 5. 流量限额进度条
 * 6. 开始/停止/重置控制
 * 7. 链接大全 / 关于 导航
 */

import router from '@ohos.router';
import { window } from '@kit.ArkUI';
import { TrafficConsumer, TrafficCallbacks } from '../model/TrafficConsumer';

@Entry
@Component
struct Index {
  /********** UI 状态变量 **********/
  @State url: string = '';
  @State limitStr: string = '100';
  @State limitUnitIndex: number = 1;
  @State concurrentCount: string = '3';
  @State reconnectThreshold: string = '';
  @State reconnectUnitIndex: number = 0;    // 0=KB/s 1=MB/s
  @State elapsedText: string = '00:00:00';
  @State speedText: string = '0 KB/s';
  @State trafficText: string = '0 B';
  @State progressValue: number = 0;
  @State isActive: boolean = false;
  @State statusText: string = '就绪';
  @State errorMsg: string = '';
  @State showError: boolean = false;
  @State showWelcome: boolean = false;

  /********** 非状态成员 **********/
  private consumer: TrafficConsumer = new TrafficConsumer(3);
  private unitLabels: string[] = ['KB', 'MB', 'GB'];
  private unitMultipliers: number[] = [1024, 1024 * 1024, 1024 * 1024 * 1024];
  private reconnectLabels: string[] = ['KB/s', 'MB/s'];
  private reconnectMultipliers: number[] = [1, 1024];
  private startTimestamp: number = 0;
  private elapsedTimerId: number = -1;

  /********** 生命周期 **********/
  aboutToAppear(): void {
    // 首次使用欢迎浮层
    const hasSeen: boolean = AppStorage.Get<boolean>('hasSeenWelcome') === true;
    if (!hasSeen) {
      this.showWelcome = true;
    }

    this.consumer.setCallbacks({
      onSpeedUpdate: (speedKBps: number): void => {
        this.speedText = this.formatSpeed(speedKBps * 1024);
      },

      onTrafficUpdate: (totalMB: number, totalBytes: number): void => {
        this.trafficText = this.formatBytes(totalBytes);
        const limitBytes: number = this.getLimitBytes();
        if (limitBytes > 0) {
          this.progressValue = Math.min(totalBytes / limitBytes * 100, 100);
        }
      },

      onLimitReached: (): void => {
        this.isActive = false;
        this.statusText = '✅ 已达到流量限额，自动停止';
        this.showError = false;
        this.keepScreenOn(false);
        this.stopElapsedTimer();
      },

      onError: (msg: string): void => {
        this.isActive = false;
        this.errorMsg = msg;
        this.showError = true;
        this.statusText = '❌ 发生错误';
        this.keepScreenOn(false);
        this.stopElapsedTimer();
      },

      onStatusChange: (active: boolean): void => {
        this.isActive = active;
        this.statusText = active ? '🔄 正在消耗流量...' : '⏹ 已停止';
        if (active) {
          this.showError = false;
        }
        if (!active) {
          this.keepScreenOn(false);
          this.stopElapsedTimer();
        }
      }
    });
  }

  /********** 页面显示时调用（含从其他页面返回） **********/
  onPageShow(): void {
    const savedUrl: string | undefined = AppStorage.Get<string>('selectedLinkUrl');
    if (savedUrl) {
      this.url = savedUrl;
      AppStorage.SetOrCreate('selectedLinkUrl', '');
    }
  }

  /********** 计时器 **********/
  startElapsedTimer(): void {
    this.startTimestamp = Date.now();
    if (this.elapsedTimerId >= 0) {
      clearInterval(this.elapsedTimerId);
    }
    this.elapsedTimerId = setInterval((): void => {
      if (!this.isActive) {
        return;
      }
      const elapsed: number = Date.now() - this.startTimestamp;
      this.elapsedText = this.formatElapsed(elapsed);
    }, 1000);
  }

  stopElapsedTimer(): void {
    if (this.elapsedTimerId >= 0) {
      clearInterval(this.elapsedTimerId);
      this.elapsedTimerId = -1;
    }
  }

  formatElapsed(ms: number): string {
    const totalSec: number = Math.floor(ms / 1000);
    const hours: number = Math.floor(totalSec / 3600);
    const minutes: number = Math.floor((totalSec % 3600) / 60);
    const seconds: number = totalSec % 60;
    const pad = (n: number): string => n.toString().padStart(2, '0');
    return pad(hours) + ':' + pad(minutes) + ':' + pad(seconds);
  }

  /********** 计算流量限额（字节） **********/
  getLimitBytes(): number {
    const val: number = Number.parseInt(this.limitStr) || 0;
    return val * this.unitMultipliers[this.limitUnitIndex];
  }

  /********** 格式化显示 **********/
  formatBytes(bytes: number): string {
    if (bytes < 1024) {
      return bytes.toFixed(0) + ' B';
    }
    if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(1) + ' KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    }
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  }

  formatSpeed(bytesPerSec: number): string {
    if (bytesPerSec < 1024) {
      return bytesPerSec.toFixed(1) + ' B/s';
    }
    if (bytesPerSec < 1024 * 1024) {
      return (bytesPerSec / 1024).toFixed(1) + ' KB/s';
    }
    return (bytesPerSec / (1024 * 1024)).toFixed(2) + ' MB/s';
  }

  /********** 开始/停止切换 **********/
  onStartStop(): void {
    if (this.isActive) {
      this.consumer.stop();
      this.keepScreenOn(false);
      this.stopElapsedTimer();
      return;
    }
    if (!this.url || this.url.trim() === '') {
      this.errorMsg = '请先输入下载链接';
      this.showError = true;
      return;
    }
    if (!this.url.startsWith('http://') && !this.url.startsWith('https://')) {
      this.errorMsg = '链接必须以 http:// 或 https:// 开头';
      this.showError = true;
      return;
    }
    this.showError = false;
    this.consumer.setUrl(this.url.trim());
    this.consumer.setLimitBytes(this.getLimitBytes());
    const concurrency: number = Number.parseInt(this.concurrentCount) || 3;
    this.consumer.setConcurrentCount(Math.max(1, Math.min(concurrency, 10)));

    // 重连阈值（带单位换算）
    const reconnectVal: number = Number.parseFloat(this.reconnectThreshold) || 0;
    const reconnectKbps: number = reconnectVal * this.reconnectMultipliers[this.reconnectUnitIndex];
    this.consumer.setReconnectThreshold(Math.max(0, reconnectKbps));

    this.elapsedText = '00:00:00';
    this.keepScreenOn(true);
    this.startElapsedTimer();
    this.consumer.start();
  }

  /********** 重置 **********/
  onReset(): void {
    this.consumer.reset();
    this.keepScreenOn(false);
    this.stopElapsedTimer();
    this.elapsedText = '00:00:00';
    this.speedText = '0 KB/s';
    this.trafficText = '0 B';
    this.progressValue = 0;
    this.statusText = '🔄 已重置';
    this.showError = false;
  }

  /********** 屏幕常亮控制 **********/
  private keepScreenOn(keep: boolean): void {
    try {
      const ctx = getContext();
      window.getLastWindow(ctx).then((win: window.Window): void => {
        win.setKeepScreenOn(keep);
      });
    } catch (_) {}
  }

  /********** 关闭欢迎浮层 **********/
  dismissWelcome(): void {
    animateTo({ duration: 300, curve: Curve.EaseOut }, (): void => {
      this.showWelcome = false;
    });
    AppStorage.SetOrCreate('hasSeenWelcome', true);
  }

  /********** UI 构建 **********/
  build() {
    Stack() {
      // ===== 主内容区 =====
      Scroll() {
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
          // 标题
          Text('流量消耗器')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 36, bottom: 24 })

          // 下载链接
          Column() {
            Text('下载链接')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .margin({ bottom: 6 })

            TextInput({ placeholder: '如 https://example.com/largefile.bin', text: this.url })
              .width('100%')
              .height(44)
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(10)
              .padding({ left: 14, right: 14 })
              .fontSize(15)
              .enabled(!this.isActive)
              .onChange((value: string): void => {
                this.url = value;
              })
          }
          .width('92%')
          .margin({ bottom: 14 })

          // 流量限额 + 单位 + 并发数
          Row() {
            Column() {
              Text('流量限额')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 6 })

              TextInput({ placeholder: '数值', text: this.limitStr })
                .width('100%')
                .height(44)
                .backgroundColor($r('app.color.card_background'))
                .borderRadius(10)
                .padding({ left: 14, right: 14 })
                .fontSize(15)
                .type(InputType.Number)
                .enabled(!this.isActive)
                .onChange((value: string): void => {
                  this.limitStr = value;
                })
            }
            .layoutWeight(1)
            .margin({ right: 8 })

            Column() {
              Text('单位')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 6 })

              Select([{ value: 'KB' }, { value: 'MB' }, { value: 'GB' }])
                .selected(this.limitUnitIndex)
                .value(this.unitLabels[this.limitUnitIndex])
                .height(44)
                .onSelect((index: number): void => {
                  this.limitUnitIndex = index;
                })
            }
            .width(90)
            .margin({ right: 8 })

            Column() {
              Text('并发数')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 6 })

              TextInput({ placeholder: '3', text: this.concurrentCount })
                .width('100%')
                .height(44)
                .backgroundColor($r('app.color.card_background'))
                .borderRadius(10)
                .padding({ left: 14, right: 14 })
                .fontSize(15)
                .type(InputType.Number)
                .enabled(!this.isActive)
                .onChange((value: string): void => {
                  this.concurrentCount = value;
                })
            }
            .width(76)
          }
          .width('92%')
          .margin({ bottom: 20 })

          // 重连阈值 + 单位
          Row() {
            Column() {
              Text('重连阈值')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 6 })

              TextInput({ placeholder: '0=禁用', text: this.reconnectThreshold })
                .width('100%')
                .height(44)
                .backgroundColor($r('app.color.card_background'))
                .borderRadius(10)
                .padding({ left: 14, right: 14 })
                .fontSize(15)
                .type(InputType.Number)
                .enabled(!this.isActive)
                .onChange((value: string): void => {
                  this.reconnectThreshold = value;
                })
            }
            .layoutWeight(1)
            .margin({ right: 8 })

            Column() {
              Text('单位')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ bottom: 6 })

              Select([{ value: 'KB/s' }, { value: 'MB/s' }])
                .selected(this.reconnectUnitIndex)
                .value(this.reconnectLabels[this.reconnectUnitIndex])
                .height(44)
                .onSelect((index: number): void => {
                  this.reconnectUnitIndex = index;
                })
            }
            .width(90)
          }
          .width('92%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })

          // 计时卡片
          Column() {
            Text('计时')
              .fontSize(15)
              .fontColor($r('app.color.text_tertiary'))

            Text(this.elapsedText)
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ top: 6 })
          }
          .width('92%')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(14)
          .padding(18)
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 12 })

          // 当前网速卡片
          Column() {
            Text('当前网速')
              .fontSize(15)
              .fontColor($r('app.color.text_tertiary'))

            Text(this.speedText)
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.accent_blue'))
              .margin({ top: 6 })
          }
          .width('92%')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(14)
          .padding(18)
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 12 })

          // 已消耗流量卡片
          Column() {
            Text('已消耗流量')
              .fontSize(15)
              .fontColor($r('app.color.text_tertiary'))

            Text(this.trafficText)
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor('#34C759')
              .margin({ top: 6 })
          }
          .width('92%')
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(14)
          .padding(18)
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 16 })

          // 进度条
          if (this.getLimitBytes() > 0) {
            Column() {
              Row() {
                Text('消耗进度')
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))

                Text(' ')

                Text(this.progressValue.toFixed(1) + '%')
                  .fontSize(14)
                  .fontColor($r('app.color.accent_blue'))
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .margin({ bottom: 6 })

              Progress({ value: this.progressValue, total: 100, type: ProgressType.Linear })
                .width('100%')
                .height(10)
                .color($r('app.color.accent_blue'))
                .backgroundColor('#E5E5EA')
                .borderRadius(5)
            }
            .width('92%')
            .margin({ bottom: 16 })
          }

          // 状态信息
          Text(this.statusText)
            .fontSize(15)
            .fontColor(this.isActive ? '#007AFF' : '#8E8E93')
            .margin({ bottom: 6 })

          // 错误信息
          if (this.showError) {
            Text(this.errorMsg)
              .fontSize(14)
              .fontColor($r('app.color.accent_red'))
              .width('92%')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 10 })
          }

          // 操作按钮（全部统一高度50）
          Row() {
            Button(this.isActive ? '停止' : '开始消耗')
              .width('46%')
              .height(50)
              .type(ButtonType.Capsule)
              .backgroundColor(this.isActive ? '#FF3B30' : '#007AFF')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .onClick((): void => {
                this.onStartStop();
              })

            Button('重置')
              .width('46%')
              .height(50)
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.button_gray_bg'))
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_on_primary'))
              .onClick((): void => {
                this.onReset();
              })
          }
          .width('92%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 8, bottom: 14 })

          // 导航按钮（统一高度50）
          Row() {
            Button('链接大全')
              .width('46%')
              .height(50)
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.button_nav_bg'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_on_primary'))
              .onClick((): void => {
                router.pushUrl({ url: 'pages/LinksPage' });
              })

            Button('关于')
              .width('46%')
              .height(50)
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.button_nav_bg'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_on_primary'))
              .onClick((): void => {
                router.pushUrl({ url: 'pages/AboutPage' });
              })
          }
          .width('92%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 32 })
        }
      }
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .height('100%')

      // ===== 首次使用欢迎浮层（位于Stack顶层） =====
      if (this.showWelcome) {
        Stack() {
          // 半透明遮罩（点击关闭）
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.overlay_mask'))

          // 浮层卡片
          Column() {
            Column() {
              Text('📡')
                .fontSize(56)
                .margin({ bottom: 12 })

              Text('流量消耗器')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_on_primary'))
                .margin({ bottom: 8 })

              Text('Traffic Consumer')
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 20 })

            Text('欢迎您使用本软件！')
              .fontSize(16)
              .fontColor($r('app.color.text_on_primary'))
              .margin({ bottom: 16 })

            Column() {
              Row() { Text('1️⃣  ').fontSize(14).fontColor($r('app.color.step_text')); Text('输入下载链接').fontSize(14).fontColor($r('app.color.step_text')) }
                .width('100%').margin({ bottom: 6 })
              Row() { Text('2️⃣  ').fontSize(14).fontColor($r('app.color.step_text')); Text('设置流量限额与并发数').fontSize(14).fontColor($r('app.color.step_text')) }
                .width('100%').margin({ bottom: 6 })
              Row() { Text('3️⃣  ').fontSize(14).fontColor($r('app.color.step_text')); Text('点击「开始消耗」运行').fontSize(14).fontColor($r('app.color.step_text')) }
                .width('100%').margin({ bottom: 6 })
              Row() { Text('4️⃣  ').fontSize(14).fontColor($r('app.color.step_text')); Text('实时查看网速与流量消耗').fontSize(14).fontColor($r('app.color.step_text')) }
                .width('100%').margin({ bottom: 6 })
              Row() { Text('5️⃣  ').fontSize(14).fontColor($r('app.color.step_text')); Text('从链接大全中选取测试链接').fontSize(14).fontColor($r('app.color.step_text')) }
                .width('100%').margin({ bottom: 6 })
            }
            .width('100%')
            .margin({ bottom: 24 })

            Button('开始使用')
              .width(200)
              .height(44)
              .type(ButtonType.Capsule)
              .backgroundColor($r('app.color.accent_blue'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .onClick((): void => {
                this.dismissWelcome();
              })
          }
          .width('85%')
          .padding({ top: 32, bottom: 28, left: 24, right: 24 })
          .backgroundColor($r('app.color.welcome_card_bg'))
          .borderRadius(20)
          .alignItems(HorizontalAlign.Center)
          .position({ x: '7.5%', y: '20%' })
        }
        .width('100%')
        .height('100%')
        .opacity(this.showWelcome ? 1.0 : 0.0)
        .onClick((): void => {
          this.dismissWelcome();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}