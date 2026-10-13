# BOXZY iOS — 已确认 UI 还原版

1. 用 Xcode 打开 `BoxzyApp.xcodeproj`。
2. 选择共享 Scheme `BoxzyApp` 和 iPhone Simulator，Run。
3. 运行原生回归测试：Product → Test（⌘U）。

最低部署目标保留 iOS 17，验证环境是 Xcode 中的 iOS 26.2 Simulator（Xcode 27）。模拟器构建不需要 Apple 登录或签名；真机需要选择自己的 Development Team。包内保留 `com.boxzy.mobile.prism` 标识，未绑定原作者团队。

应用从原有登录/首页入口运行，已移除截图专用的 `AuditRoute` 和常量绑定页面。最终资产、开盒视频和音效包含在工程中。

本包是原有离线演示工程的 UI 更新。Google 登录、Coinflow 支付/提现、交易和物流仍沿用原工程的演示数据/模拟响应，没有因此变成真实线上服务。正式法律正文仍需提供。

视觉评审：双击同包 `../UI-QA.html` 查看本轮原生截图和走查报告。完整产品说明另见离线说明包。
