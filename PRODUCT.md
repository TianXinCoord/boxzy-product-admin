BOXZY admin prototype: English operation UI and Chinese developer-facing product guide. Scope: dashboard, Box list and creation, basic information, SKU prize pool and stock adjustment, simulation, draft/publish flows, and optional per-SKU stock alerts. Current UI and product-guide screenshots are the implementation reference. Tailwind CSS runs offline with local demo persistence; no production API connection. Product names come from the supplied workbook; prices, inventory and images in demonstration are illustrative.

2026-10-12 refinement: outcome-attributed realized profit; remove sales trends and prior-period comparisons. Box Min Value / Max Value are required operator-entered customer-display USD values. Remove Box version management; retain draft and publish current configuration.

Unresolved boxes are explicitly shown as Unrealized revenue, split into opened/no choice and purchased/unopened at the end date; no estimated unrealized profit. Prize-pool Import/Export/template actions removed. Box list combines min/max into Value range after rarity probabilities; edit inputs remain separate.


## 2026-10-12 · SKU 库存告警
Stock alert 默认 Off，无默认阈值。开启必填非负整数；剩余库存 ≤ 阈值触发，仅当前 Box/SKU。Apply 应用当前编辑、Save draft 保存草稿、Publish 生效；取消不保存。列表 Low stock 为当前配置预览，不是服务端通知。关闭并应用清空阈值。不影响概率、收益、模拟或上线状态。真实通知渠道、接收人、重复频率尚未确定和接入。详见产品说明「SKU 库存告警」。
