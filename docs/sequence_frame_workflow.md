# 代号SG · 序列帧工作流规范（制作人 · 2026-11-07）

老板验收通过后沉淀。本规范管**谁做什么、按什么顺序、卡什么门**；像素细则见 [sequence_self_check_standard.md](./sequence_self_check_standard.md)，美术勾选见 [sequence_export_checklist_art.md](./sequence_export_checklist_art.md)。

---

## 0. 一句话

**美术交钉脚固定格；测试叠帧签人物像素；程序只换图 + 同步脚点配置；攻击位移永远走程序，不靠画面平移。**

---

## 1. 角色分工

| 角色 | 负责 | 不负责 |
|---|---|---|
| **美术** | 出固定格 PNG；钉脚；统一 content_h；写 FOOT_REGISTRATION / README / QC | 改引擎 offset 救脚；用 renderScale 补尺度 |
| **程序** | 接入交付包；同步 `frames` / `plantedSole` / canvas / pivot；攻击位移与硬门禁1 | 擅自裁帧；只换图不改脚点族 |
| **测试** | 叠帧签脚点与 content_h；硬门禁1；青线；出码后眼测 | 感觉扫码当正式 PASS |
| **制作人** | 定基准（帧数 / content_h / 脚点族）；卡交接；推进门禁；沉淀规范 | 替职种改资产或写业务代码 |
| **老板** | 眼测定调；签发硬门禁；文档「合」 | — |

策划出设计文档另线；本规范只管序列帧交付链路。

---

## 2. 当前基准（赵云 · 可随角色表更新）

| 项 | 值 | 备注 |
|---|---|---|
| Idle 帧数 | **12**（`000–011`）@10fps | 禁止无说明缩到 5 帧；短循环须制作人书面批准 |
| Idle / Run 画布 | 256×256 | |
| 轻击画布 | 可 320×256 | 同套内统一 |
| 人物内容高基准 | **轻击静息 ≈190px**（sole→头，α≥8） | 夹间对齐靠此数，不靠画布边长 |
| 引擎 renderScale | **1.0** | 禁止用旧 1.255 等补尺 |
| Idle/Run drawOffset | **0** | 布局 reach 与脚点对齐，不靠 Idle 偏置 |
| 脚点门禁（夹内） | sole `|Δx/y| ≤ 1px`；content bottom span **= 0**（防 Idle 上下跳） | |
| 硬门禁1 | 攻击播放中**无位移**（程序 `LUNGE`/`Clamp` 按案） | 程序自测过再出码 |
| Join 参考 | **现行 Idle_000** 的 sole（cx/cy/bottom） | 换 Idle 包 = 换脚点族 |

现行 Idle 包：`hero_zhaoyun_idle_direct12_scale_atkrest190`  
Idle_000 join ≈ **(114.74, 244.54, bottom 247)**（以包内 `FOOT_REGISTRATION.md` 为准）。

---

## 3. 流水线（必须按序，不可跳）

```
① 任务单（制作人）
   → 写清：动作名、目标帧数、画布、content_h 基准、是否钉脚、是否动 Idle_000
② 美术出包
   → png + FOOT_REGISTRATION + foot_registration.csv/json + QC 叠图 + README + game_ready.zip
③ 美术自检（标准 §三 / §六）
   → 不过不交
④ 测试叠帧签
   → n 帧数、content_h、sole span、content bottom；对照现行 Idle_000
⑤ 程序接入（只换约定范围）
   → 同步 frames 列表 + plantedSole + canvas；其它动作默认不动
⑥ 程序硬门禁1 自测 → 出一版预览码
⑦ 测试青线 + 硬门禁1 + recover→Idle 接缝
⑧ 制作人 @老板 眼测（一码一次；测试未点头不出）
⑨ 老板点头 → 归档包路径与码号；失败则回 ②/⑤，禁止叠补丁糊弄
```

**原则：** 程序不接未叠帧 PASS 的包；测试不以「感觉可以」代正式 PASS；一版问题收敛后再出下一码。

---

## 4. 交付包最低集

每个动作包目录必须含：

1. `pngNNN/` 或约定画布目录：全帧 PNG，命名 `hero_xxx_动作_###.png`
2. `FOOT_REGISTRATION.md`：Idle_000（或本夹 frame0）join 参考；scale；gates
3. `foot_registration.csv` / `.json`（有则更好）
4. `qc/`：叠帧图 + `validation.json`（`all_pass`）
5. `README.md`：源包、帧数、content_h、已知限制
6. `*_game_ready.zip`

缺脚底表 / 缺帧数说明 / 只报画布不报 content_h → **拒收**。

---

## 5. 尺度与帧数铁律

1. **量人物，不量画布。** `content_h` = 不透明包围盒鞋底→头顶；交付表必写 min/avg/max。
2. **夹间对齐基准动作**（赵云 = 轻击静息 ≈190）。Idle/Run/Atk frame0 脚底叠看，内容身高不可跳档。
3. **禁止**用程序 `renderScale` 或每帧 `drawOffset` 补美术尺度。
4. **帧数是产品规格。** 缩帧（如 12→5）必须制作人批准并写进 README「为何短循环」；磁盘上有多帧但 Config 未挂 = 视为缩帧，同样要说明。
5. 同源试验包与正式包尺度不一致时（例：`idle_direct_12` vs 旧 game-pkg 5 帧），**禁止混接**；要恢复帧数必须「源帧 → 缩到基准 content_h → 钉脚」整链重出。

---

## 6. 脚点族与 recover 接缝

1. 每个正式 Idle 包有唯一 **Idle_000 join sole**。换 Idle = 换脚点族。
2. 程序接入 Idle 时必须同时更新：
   - `IdleConfig.frames`（全帧）
   - `plantedSoleX/Y`（新 Idle_000）
   - 相关注释 / FOOT 引用
3. **禁止**只换 PNG、沿用旧 `plantedSole`。
4. 攻击 recover 尾帧必须钉向**现行** Idle_000。脚点族变更后：
   - 测试先验 recover→Idle hop
   - ≥2px 或老板喊「咔一下」→ 美术按新 Idle_000 重钉 recover 尾帧，再出码
5. 剪影接缝（XOR 观感）与脚点 hop 分开记；脚点 PASS 仍可因剪影单开重导，须制作人排期。

---

## 7. 程序接入检查单

- [ ] 只替换任务指定的动作目录
- [ ] `frames` 与交付 PNG 张数、编号一致（含前导零）
- [ ] `plantedSole` / pivot / canvasSize 与 `FOOT_REGISTRATION` 一致
- [ ] `renderScale = 1`；Idle/Run `drawOffset = 0`（除非制作人改基准）
- [ ] 攻击位移：无画面整体平移；硬门禁1 自测 PASS
- [ ] 出码号写入群；旧码标废
- [ ] 不接测试未叠帧 PASS 的包

---

## 8. 测试检查单（摘要）

- [ ] 准入：png + 脚底表 + QC + README
- [ ] 叠帧：帧数 n、content_h、sole span≤1、content bottom span=0（Idle）
- [ ] 夹间：与基准动作 content_h / 脚底线
- [ ] 硬门禁1：攻击无位移
- [ ] 起手 / 切段 / 回 Idle hop <2px
- [ ] 正式 PASS 才叫程序出码给老板；感觉扫码 ≠ PASS

细则可另维护轻击复验清单。

---

## 9. 群协作约定

1. 美术交包：贴**绝对路径** + 帧数 + content_h + join sole + `@程序` `@测试`。
2. 测试只回 **PASS/FAIL + 关键数**；FAIL 写回哪一环。
3. 程序出码：贴码号 + 改了什么（frames / plantedSole / 其它）+ 废码声明。
4. 制作人：同时只推一条主线；老板未点头不开下一视觉项。
5. 文档进仓库要老板说「合」；未合前以 `/workspace/sg-art/docs/` 本文件为准。

---

## 10. 文档地图

| 文档 | 用途 |
|---|---|
| **本文件** `sequence_frame_workflow.md` | 跨职种流程与铁律 |
| `sequence_self_check_standard.md` | 老板签发的像素/锚点自检标准 |
| `sequence_export_checklist_art.md` | 美术导出勾选 |
| 包内 `FOOT_REGISTRATION.md` | 该包唯一脚点真相源 |

---

## 11. 修订

| 日期 | 变更 |
|---|---|
| 2026-11-07 | 初版：12 帧 Idle 恢复、content_h≈190、脚点族、硬门禁1、流水线 |

制作人维护；基准表变更须老板或制作人在群内确认后改本文件。
