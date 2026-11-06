# 序列帧导出门禁

## 根因摘要

- 名义 root `(128, 248)` 与各帧实测 planted 不一致。
- 首包缺脚底表。
- 程序曾把 `recommended_root_offset` 叠在 `sprite.left` 上，导致约 47px 整段滑。
- 另有 `.meta` UUID 撞车，导致 `AtkLightConfig` 找不到。

## 门禁（三方）

### 美术

叠帧自检与出图硬约定以 [序列帧自检标准](sequence_self_check_standard.md) 为准（脚点抖动 ≤1px）。

- 导出先钉脚：同支撑脚段内 `|Δplanted_x/y| < 2px` 保留为接入/切段验收口径。美术导出前自检按老板标准，脚点抖动 ≤1px。
- 切段首帧 planted 对齐上一段末帧（或 Idle）；差 ≥ 2px 视为美术未过。
- 交付必带：`png256` + 脚底表（每帧支撑脚、`recommended_root_offset`、slide）+ QC 叠图 + README（名义 root 与实测 planted 都要写）。
- 缺一程序可不接。运行时 offset 只兜底，不作主交付。

### 程序

- `recommended_root_offset` 只进 `playerX`，禁止叠 `sprite.left`。
- 切段保留已钉 root。
- 接入验收：起手 / 段内 / 切段 / 回 Idle 四项脚底跳位均 `< 2px`。
- HUD 显示：段名 `f=` `ox=`。
- 进仓扫 `.meta` UUID 不重复、`require` 模块齐。

### 测试

- 上述四项必测；缺脚底表不接测。
- 全过程量，不只比起手收尾净位移。

## 正式验收参考

- 正式验收码：`m_ly1j_1793966882436`。
- 画布：256 透明；面朝右；脚锚 `(128, 248)`。
- 轻攻：刺 → 挑 → 下劈；收招独立。其余仍按 [一页纸玩法](gameplay-onepager.md)。

（赵云轻攻脚底跳位四项复验已 PASS；本文档是门禁固化，不是新开验收。）

## 可勾选 checklist

- [序列帧导出门禁 · 美术 checklist](sequence_export_checklist_art.md)
- [轻击脚底复验 checklist · 测试](sequence_export_checklist_qa.md)
- [序列帧自检标准](sequence_self_check_standard.md)
