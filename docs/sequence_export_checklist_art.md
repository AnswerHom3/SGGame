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
- [ ] 原片/源帧区间已写进 README

## 体型 / 连招
- [ ] Idle / Run / Atk 体型尺度一致；攻击偏小时先标目标缩放（程序只绕 root 放大）
- [ ] 连续技下一段起点对上一段结束枪位/姿势；收招单独序列

## 自检
- [ ] 本地过完上述门禁再出 zip
- [ ] 不把「靠 runtime offset 补脚」当作主交付理由

## 自检标准（老板定稿）

完整条文见 [序列帧自检标准](sequence_self_check_standard.md)。勾选对齐如下：

- [ ] 同套动作同一画布；四周透明边 ≥8–16px；不跨格、不贴边
- [ ] 锚点 = 脚底中心（非包围盒中心）
- [ ] 播放只换图；Trim 保留原画布与裁切偏移，否则交未裁固定格
- [ ] 攻击位移归程序，不靠画面整体平移；阴影/刀光/尘土不进主层
- [ ] 叠帧自检：脚点抖动 ≤1px，竖直不跳，末首无跳
- [ ] 交付含对照表 + 叠帧自检截图（脚底线可见）

## 参考交付根
`/workspace/sg-art/deliver/hero_zhaoyun_atk_light_v1/`

## 人物尺度 / 帧数（2026-11-07）
- [ ] 交付表含 `content_h`（min/avg/max）与相对基准的 scale；赵云基准 ≈190（sole→头，α≥8）
- [ ] 不靠程序 `renderScale` / 每帧 drawOffset 补尺
- [ ] 帧数与任务单一致；缩帧须制作人批准并写进 README
- [ ] 换 Idle 包时写明新 Idle_000 join sole；提醒程序改 plantedSole、recover 可能要重钉
