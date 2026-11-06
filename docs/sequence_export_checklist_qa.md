# 轻击脚底复验 checklist · 测试

可勾选；缺脚底表不接测。

## 准入

- [ ] 交付含 png + 脚底表 + QC 叠图 + README；缺脚底表拒测
- [ ] 正式预览码 / Maker hard-refresh（无 localDev 除非程序明确要求）
- [ ] HUD 可见：段名、`f=`、`ox=`

## 四项门禁（相对地面 planted，|Δ|<2px 才 PASS）

- [ ] 起手：Idle → 第一段轻击起手，脚底/根无横跳竖跳
- [ ] 段内：light1 / light2 / light3 播放中，ox 变化时脚仍钉地（只允许姿态前探，不允许整身跟 ox 滑）
- [ ] 切段：light1→2→3 切段瞬间 planted 对齐，hop <2px
- [ ] 回 Idle：收招结束回待机（含**单段**轻击1收招回 Idle、以及三连后回 Idle），hop <2px

## 记录 / 结论

- [ ] 每项记：段名、`f=`、`ox=`、目测/截图 hop
- [ ] AtkLightConfig / AtkLightFoot 无 Module not found；light1/2/3 可打
- [ ] 任一项 ≥2px → FAIL，写清哪一项；四项全过才记正式 PASS
- [ ] 感觉扫码 / 手感 smoke ≠ 正式通过
