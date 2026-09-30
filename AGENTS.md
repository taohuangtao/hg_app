# AGENTS.md

本文件适用于 `E:\workspace\ant\hg_app` 目录下的 Flutter App 项目。后续在本项目中进行开发、排查、重构、测试时，优先遵守本文件约定。

## 项目定位

- 本项目是海外短剧 App 的 Flutter 客户端。
- 目标平台为 iOS 和 Android。
- App 端要求优先保证播放流畅、滑动顺滑、首屏加载快、弱网体验稳定。
- 当前版本不接入广告 SDK，不实现广告展示、广告回调、广告收益相关逻辑。

## Flutter 环境

Flutter SDK 固定使用：

```powershell
D:\app\flutter
```

常用命令必须使用该 SDK：

```powershell
& "D:\app\flutter\bin\flutter.bat" --version
& "D:\app\flutter\bin\flutter.bat" pub get
& "D:\app\flutter\bin\flutter.bat" analyze
& "D:\app\flutter\bin\flutter.bat" test
& "D:\app\flutter\bin\flutter.bat" run
```

Android 打包命令：

```powershell
& "D:\app\flutter\bin\flutter.bat" build apk --release
```

iOS 构建需要 macOS 环境，不在 Windows 本机上直接执行 iOS 打包。

## 其他环境信息

```shell

export JAVA_HOME="/d/app/jdk-17.0.14+7"
export ANDROID_HOME="/d/app_data/android/sdk"
export PATH="$JAVA_HOME/bin:$PATH"

```





## 技术选型

App 端技术栈固定如下：

| 类型 | 技术方案 |
|---|---|
| 跨端框架 | Flutter + Dart |
| 状态管理 | Riverpod |
| 路由 | go_router |
| 网络请求 | Dio |
| 本地缓存 | Hive |
| 敏感数据存储 | flutter_secure_storage |
| 视频格式 | HLS 多码率 |
| Android 播放器 | Media3 / ExoPlayer |
| iOS 播放器 | AVPlayer |
| 推送 | Firebase Cloud Messaging |
| 崩溃监控 | Firebase Crashlytics |
| 埋点 | Firebase Analytics + 自建业务埋点 |

如需新增依赖，必须优先确认是否符合以上选型。不要在未说明原因的情况下引入同类替代库。

## 后端对接约定

后端技术栈为：

| 类型 | 技术方案 |
|---|---|
| 后端框架 | Node.js + NestJS |
| 数据库 | PostgreSQL |
| 缓存 | Redis |
| 视频存储 | AWS S3 |
| 视频分发 | AWS CloudFront |

App 端通过 REST API 对接后端。播放地址必须通过播放鉴权接口获取，不在客户端写死长期有效的视频地址。

## 目录组织

业务代码放在 `lib/` 下，推荐按模块拆分：

```text
lib/
  core/              网络、路由、缓存、主题、工具类
  features/
    auth/            登录、游客身份、Token 刷新
    home/            首页频道、推荐流
    player/          短剧播放、手势、弹幕、进度
    drama/           短剧详情、选集、继续观看
    theater/         剧场、分类、榜单、筛选
    search/          搜索和热门关键词
    profile/         个人中心、设置、多语言、账号注销
    share/           复制链接、系统分享、WhatsApp、SMS/iMessage
    analytics/       埋点事件
```

不要把接口请求、复杂业务逻辑、播放器状态直接堆在页面 Widget 中。页面层只负责展示和交互。

## 核心体验要求

短剧播放是本项目核心体验，开发时必须优先考虑：

- 上下滑切换视频时减少黑屏和等待。
- 当前视频播放时提前准备下一条数据和播放资源。
- 播放器实例数量要受控，避免内存持续上涨。
- 点赞、收藏、追剧等互动优先做即时反馈，再异步提交。
- 弱网下要有加载状态、失败重试和清晰提示。
- 列表封面、头像、海报必须使用缓存，避免重复请求。
- 观看进度要本地记录，并定时同步服务端。

## 登录与分享

登录方式：

- iOS：游客模式、Apple 登录、Google 登录、邮箱 + 密码登录。
- Android：游客模式、Google 登录、邮箱 + 密码登录。

分享方式：

- 复制链接。
- 系统分享面板。
- SMS / iMessage。
- WhatsApp。

分享链接由后端生成，包含短剧 ID、剧集 ID、渠道参数和归因参数。

## 代码规范

- 使用 Dart 官方格式化规则。
- 提交前运行 `flutter analyze`。
- 涉及业务逻辑、状态管理、数据解析的改动，需要补充或更新测试。
- 不要在业务代码中使用 `print` 输出调试信息，使用统一日志封装。
- 不要把 Token、邮箱、用户 ID 等敏感信息输出到日志。
- 不要在客户端硬编码生产环境密钥、长期 Token、私有地址。
- 不要随意修改 `android/`、`ios/`、`web/` 平台目录，除非任务明确需要。

## 文件修改边界

- 修改前先查看相关文件当前内容，避免覆盖已有改动。
- 不要回滚或删除用户已有修改，除非用户明确要求。
- 不要为了实现局部功能做大范围重构。
- 不要引入与当前任务无关的 UI、依赖、配置或平台能力。
- 生成文件、缓存文件、构建产物不应提交到项目源码中。

## 验证要求

完成代码改动后，至少执行：

```powershell
& "D:\app\flutter\bin\flutter.bat" analyze
```

涉及测试逻辑时执行：

```powershell
& "D:\app\flutter\bin\flutter.bat" test
```

涉及依赖变更时执行：

```powershell
& "D:\app\flutter\bin\flutter.bat" pub get
```

如因环境、网络或平台限制无法执行验证，需要在最终说明中明确原因。

## 当前版本不做

- 不接入广告 SDK。
- 不实现广告展示、激励广告、插屏广告。
- 不实现广告收益统计。
- 不在 Windows 本机执行 iOS 打包。

## 其他提醒

- 部分网络不可用的时候，可以尝试使用本地HTTP代理 http://127.0.0.1:7890
