# BOXZY Product Admin

BOXZY 英文后台交互原型及中文产品说明。2026-10-13 更新仓库，内容与已确认的库存告警离线版一致。

## 打开方式

通过 **Code → Download ZIP** 下载并完整解压，双击 `index.html`。无需安装依赖、编译或启动服务器。

| 文件 | 内容 |
| --- | --- |
| [index.html](index.html) | 离线入口 |
| [ui.html](ui.html) | 英文后台交互原型 |
| [product-guide.html](product-guide.html) | 中文产品说明、字段定义、计算规则和交互截图 |
| [src/](src/) | JavaScript 与 CSS 参考源码；运行代码已内嵌到 ui.html |
| [screens/](screens/) / [references/](references/) | 文档截图和设计参考，须保持相对路径 |
| [START-HERE.txt](START-HERE.txt) | 离线使用说明和运行边界 |

## 已包含

- 日期快捷筛选、四类 Box 筛选及明细。
- 销量、实付销售额、奖品回收、申请寄出、待处理奖品和未开盒数据。
- 已归属收入、成本与利润，以及未归属收入及其两类状态。
- Box 及奖池配置，Min Value / Max Value 输入和合并展示。
- 每个 Box/SKU 独立库存告警：默认关闭，无默认阈值；开启后填写非负整数，剩余库存 ≤ 阈值时显示 Low stock。

## 使用边界

这是本地交互原型，内置数据为演示数据。草稿和编辑记录保存在当前浏览器，不会自动写回仓库。真实支付、订单、库存及告警通知服务尚未接入。内置图片和页面支持离线运行；新输入的远程图片链接和外部资源仍需网络。

库存告警中 Apply changes 应用当前编辑，Save draft 保存草稿，Publish 更新演示中的已发布配置。详细口径以中文产品说明为准。

## 校验

[PACKAGE-VERIFICATION.json](PACKAGE-VERIFICATION.json) 保存已完成的离线浏览器验证记录；[SHA256-MANIFEST.json](SHA256-MANIFEST.json) 为后台交付文件的 SHA-256 清单，不包含仓库新增的 README、.gitignore 和 .nojekyll。

此次提交替换原有 iOS 资料；原内容可通过 Git 提交历史恢复。

## 文件保留规则

- `screens/` 保留中文说明的配图，以及桌面／窄屏、库存告警开关状态的验证截图。
- `references/` 只保留当前 SKU 提示设计和[库存告警确认图](references/stock-alert-approved.png)。
- 参数 JSON 供开发读取；验证记录供交付核验，不是临时运行缓存。
- `src/xlsx.js`、`src/segmented-xlsx.js` 是构建页面中仍存在的兼容代码，操作入口已移除；清除实现需要单独修改并验证，不能只删除源码文件。
- 已清理早期未引用效果图、生成提示词、废弃图片解析／超分方案及重复库存告警报告；旧文件仍可通过 Git 历史恢复。
