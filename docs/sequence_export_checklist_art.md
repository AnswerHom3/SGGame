# 序列帧导出门禁 · 美术 checklist

缺一不交。钉脚为主交付；运行时 `recommended_root_offset` 只作兜底。

## 画布 / 锚点
- [ ] 统一 256×256、透明底、面朝右
- [ ] README 同时写名义 root（默认 `(128,248)`）与实测 planted 基准
- [ ] 同支撑脚段内 `|Δplanted_x/y| < 2px`
- [ ] 切段：下一段首帧 planted 对齐上一段末帧（或 Idle）同脚；差 ≥2px 先重裁/重导

## 交付包（同包）
- [ ] `png256/` 全帧
- [ ] `manifest.json`（段名、帧数、fps、冲击帧、收招分支）
- [ ] 脚底表（每帧支撑脚、`recommended_root_offset`、`source_slide_flag`）
- [ ] QC 叠图（contact + 各段 inspect）
- [ ] README：名义 root、实测 planted、目标缩放（相对 Idle）、已知限制

## 体型 / 连招
- [ ] Idle / Run / Atk 体型尺度一致；攻击偏小时先标目标缩放（程序只绕 root 放大）
- [ ] 连续技下一段起点对上一段结束枪位/姿势；收招单独序列

## 自检
- [ ] 本地过完上述门禁再出 zip
- [ ] 不把「靠 runtime offset 补脚」当作主交付理由

## 参考交付根
`/workspace/sg-art/deliver/hero_zhaoyun_atk_light_v1/`
