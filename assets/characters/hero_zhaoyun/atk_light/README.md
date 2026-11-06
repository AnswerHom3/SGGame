# 赵云轻攻三连 v1

86 张 256×256 RGBA，未改像素。唯一接入图在本目录的 `mainline/` 与 `branches/`。时长以旁边的 `manifest.json` 为准。

## 帧

| 段 | 张数 | 文件 | 播放 | 冲击 | 取消帧 |
| --- | ---: | --- | --- | ---: | ---: |
| light1 | 11 | `mainline/hero_zhaoyun_atk_light1_000`–`010` | 目标 0.40s（约 27.5 fps，按时间取帧） | 007 | 010 |
| light2 | 20 | `mainline/hero_zhaoyun_atk_light2_000`–`019` | 目标 0.46s（约 43.48 fps） | 016 | 019 |
| light3 | 16 | `mainline/hero_zhaoyun_atk_light3_000`–`015` | 目标 0.62s（约 25.81 fps） | 011 | 015 |
| light1_recover | 13 | `branches/hero_zhaoyun_atk_light1_recover_000`–`012` | 源均值 12.48 fps | — | — |
| light2_recover | 11 | `branches/hero_zhaoyun_atk_light2_recover_000`–`010` | 源均值约 12.57 fps | — | — |
| light3_recover | 15 | `branches/hero_zhaoyun_atk_light3_recover_000`–`014` | 源均值约 12.41 fps | — | — |

light3 是通过的下劈，不是旧横扫。不要把六段合成一条 10 fps。

## 连段

正常：light1 → light2 → light3 → light3_recover → Idle。

light1_recover / light2_recover 只在这一击没有接上下一击时播，不烧进连续主线。light3 自己的收招只接一次。取消窗口在 `scripts/combat/tuning.lua`：0.34–0.40、0.40–0.46、0.52–0.62，靠近末帧。起手连打会等到窗口，而不是立刻切走。

挥击前冲是 0。命中窗口里的速度分支还在，0 表示脚锁定。贴图缩放和视口边界不在 `vx == 0` 时改角色 X。

`LIGHT_COMBO_RESET` 0.5 秒、`LIGHT_INPUT_BUFFER` 0.10 秒、`HIT_STOP` 0.10 秒仍按 main 的行为。

## 根点与比例

名义 root `(128, 248)`。不要用 Idle 的绘制偏移 `(−17, −1)`。六套共用一次缩放，相对 Idle 约 **79.7%**，相对 Run 约 **82.7%**。游戏里画布缩放保持 1，root 落在碰撞体脚底。体型差可能还在，这里不声称已经无缝对齐。逐帧脚底漂移保留，不逐帧贴脚。

## 枪尖

256 画布，手工标注，不是 hitbox。

- light1 007：`(243.178, 132.322)`
- light2 016：**null**（上边裁掉）。不要写成 `(0, 0)`。调试备用是 017：`(213.211, 28.644)`，只给调试标记
- light3 011：`(236.633, 238.067)`

## 已知限制

- 原片已裁枪：light2 的 015、016 顶边；light3 若干高举/急转/冲击帧右边；light3_recover 004–008 右边。没有补画
- 接点不是同一像素，不能说无缝
- 下劈冲击帧带紫白冲击图，留在图里
- 抽查未见嘴。遮挡处不保证
- 命中窗口仍是占位，没有改成冲击帧的时刻
