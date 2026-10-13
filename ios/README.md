# BOXZY iOS 原生代码

2026-10-13 最终交付版本，包含 SwiftUI 工程、商品素材和测试代码。

## 打开与运行

1. 使用 Xcode 打开 `BoxzyApp-Prism/BoxzyApp.xcodeproj`。
2. 选择 `BoxzyApp` scheme 和 iPhone Simulator，运行。
3. 最低 iOS 17；独立 Bundle ID：`com.boxzy.mobile.prism.review20261013`。

## 本次交付

- 统一中性黑金、字体、按钮、间距与账户图标。
- 更新商品素材、奖池分组及寄送费用展示。
- 移除推荐码、邀请奖励入口及相关文章。
- 更新说明见 [README-UPDATED.md](README-UPDATED.md)，验证记录见 [verification.json](verification.json)。
- [最终 UI、对比图和产品说明](../ios-guide)。

## 实现范围

当前为本地业务演示。支付、税费、真实奖池、账号和物流仍需服务端接入。说明文档中的提现成功/失败最终设计已补充，但原生仍需接入 completed 结果分支与可靠状态路由，不能视为真实提现已完成。

仓库保留原交付结构；`native-changes.patch` 供核对相对原始版本的修改。直接克隆或通过 GitHub 的 Code → Download ZIP 下载完整工程。
