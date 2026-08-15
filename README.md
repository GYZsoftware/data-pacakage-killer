# 流量消耗器 (DataPackageKiller)

> 一个 HarmonyOS NEXT（API 12）网络流量测试工具。
> 作者：kut — 一个略懂点信息技术的初中历史教师，AI 辅助编程（vibe coding）初体验。

## 功能特性

| 功能 | 说明 |
|------|------|
| **自定义下载链接** | 输入任意 HTTP/HTTPS 直链 |
| **流量限额** | 支持 KB/MB/GB 单位，超限自动停止 |
| **并发下载** | 默认 3 路并发 HTTP 流，可配置 1~10 路 |
| **实时计时** | 运行时计时，精确到秒 |
| **实时网速** | 每秒计算显示当前下载速度 |
| **累计流量** | 实时显示已消耗流量总量 |
| **自动重连** | 速度低于阈值时自动断开重建连接（5秒冷却，带单位选择） |
| **链接大全** | 内置预设测试链接，一键填入 |
| **屏幕常亮** | 运行时阻止设备休眠 |
| **深色模式** | 随系统自动切换，无需手动设置 |
| **首次引导** | 首次使用弹出欢迎浮层引导 |

## 截图
<img width="1260" height="2478" alt="2" src="https://github.com/user-attachments/assets/1ab4d91f-5998-4f46-ae3c-a0b5a690a6e2" />
<img width="1257" height="2510" alt="1" src="https://github.com/user-attachments/assets/8c0a1dd7-722f-467b-b9c5-05301bc7c56d" />

## 技术栈

- **语言：** ArkTS
- **框架：** ArkUI（Stage 模型）
- **SDK：** HarmonyOS NEXT 5.0.0 (API 12)
- **IDE：** DevEco Studio 6.1.1.300
- **网络：** `@ohos.net.http`（ARRAY_BUFFER 模式）
- **页面路由：** `@ohos.router`
- **屏幕控制：** `@kit.ArkUI`（window API）

## 项目结构

```
cmcc/
├── AppScope/
│   ├── app.json5                    # 应用配置（bundleName、版本）
│   └── resources/base/element/      # 应用级资源
│
├── entry/
│   └── src/main/
│       ├── module.json5             # 模块配置（权限声明）
│       ├── ets/
│       │   ├── entryability/        # Ability 入口
│       │   ├── pages/
│       │   │   ├── Index.ets        # 首页（核心功能 + 导航）
│       │   │   ├── LinksPage.ets    # 链接大全
│       │   │   └── AboutPage.ets    # 关于页面
│       │   └── model/
│       │       └── TrafficConsumer.ets  # 核心引擎
│       └── resources/
│           ├── base/element/        # 浅色模式颜色/字符串资源
│           ├── dark/element/        # 深色模式颜色资源
│           ├── en_US/               # 英文字符串
│           └── zh_CN/               # 中文字符串
│
├── build-profile.json5              # 顶层构建配置
├── package.json                     # 项目包声明
├── oh-package.json5                 # ohpm 包配置
├── hvigorfile.ts                    # hvigor 构建入口
└── README.md                        # 本文件
```

## 构建与安装

### 在 DevEco Studio 中

1. 打开 `File → Open` 选择项目根目录
2. 等待 Gradle 同步完成
3. 点击 `Build → Build HAP(s)`
4. 连接设备后点击 `Run`

### 命令行

```bash
# 设置环境
set NODE_HOME=%DEVECO_HOME%\tools\node
set JAVA_HOME=%DEVECO_HOME%\jbr
set DEVECO_SDK_HOME=%DEVECO_HOME%\sdk
set PATH=%NODE_HOME%;%JAVA_HOME%\bin;%PATH%

# 构建
cd D:\ohos\cmcc
hvigorw assembleApp --mode project -p product=default -p buildMode=debug --no-daemon

# 安装到设备
hdc install entry\build\default\outputs\default\entry-default-unsigned.hap

# 启动
hdc shell "aa start -a EntryAbility -b cn.kut.datapackagekiller"
```

> `%DEVECO_HOME%` 替换为你的 DevEco Studio 安装路径，例如 `E:\Program Files\Huawei\DevEco Studio`

## 使用说明

1. 输入下载链接（大文件直链效果最佳）
2. 设置流量限额与并发数
3. 可选：设置重连阈值（速度低于该值时自动重建连接）
4. 点击「开始消耗」运行
5. 实时查看计时、网速和累计流量
6. 达到限额自动停止，也可手动停止或重置

## 内置测试链接

主页面 → 链接大全：

- **哔哩哔哩** — B站静态资源包
- **腾讯 WeGame** — WeGame 图片资源
- **腾讯视频** — 播放器脚本
- **爱奇艺** — 播放器脚本
- **阿里云** — CDN 资源文件

## 开源许可

本项目仅供学习交流使用。

## 联系方式

- 邮箱：**kut@kut.hn.cn**
- GitHub：**[GYZsoftware](https://github.com/GYZsoftware)**
- Gitee：**[kut2005503](https://gitee.com/kut2005503)**
