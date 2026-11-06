# 代号SG · 一页纸玩法

三国 Q 版 2D 横版战斗。这一页定范围和美术约定。当前可玩骨架（移动、跳跃、轻击三连、占位数值）见 [战斗原型骨架](combat-proto-skeleton.md)。命中窗口、取消窗口和枪尖判定盒以 `scripts/combat/tuning.lua` 为准。轻攻击连段清零时长是同文件的 `LIGHT_COMBO_RESET`。

## 题材

三国 Q 版，2D 横版战斗。首个角色是赵云：银蓝甲、白缨、长枪，脸上不画嘴。

## 核心循环

进关 → 战斗 → 推进 → 结算。

## 手机操作

- **左下虚拟摇杆**只做左右移动。死区 `0.15`。推满是 `MOVE_SPEED = 5`（米/秒），死区外按推幅比例变速。松手即停，没有惯性。转向时翻转朝向。角色夹在屏幕左右两端，走不出画面。
- **按键**：跳、轻攻击、重攻击、闪避、技能。

原型里已经接上的是摇杆、跳跃和轻攻击。重攻击、闪避、技能列在操作里，还没做。键位和取消规则见 [战斗原型骨架](combat-proto-skeleton.md)。

## 轻攻击

连点攻击键，依次打出突刺、上挑、横扫。取消窗口内再按，就接下一段。

停手超过约 0.5 秒，连段清零，下一击从第一段重新开始。这 0.5 秒从收招结束算起，时长在 `scripts/combat/tuning.lua` 的 `LIGHT_COMBO_RESET` 里可调。

三段分开出图。每段包含起手、出手、收招，时长分别是 0.40 秒、0.46 秒、0.62 秒，默认 10 fps。命名为 `hero_zhaoyun_atk_light1_###.png`、`hero_zhaoyun_atk_light2_###.png`、`hero_zhaoyun_atk_light3_###.png`，目录为 `assets/characters/hero_zhaoyun/{atk_light1,atk_light2,atk_light3}/`。每段标出命中帧和枪尖位置。

命中窗口、取消窗口和判定盒见 `scripts/combat/tuning.lua`。

重攻击后做。

## 胜负

- **胜**：清关，或击败 Boss。
- **败**：HP 归零，或掉落。

## MVP

1 个英雄、1 关、2–3 种普通敌人、1 个小 Boss、基础 UI。

## 美术规范

赵云序列帧：

| 项 | 约定 |
| --- | --- |
| 画布 | 256×256，透明 |
| 朝向 | 角色朝右 |
| 脚底锚点 | `(128, 248)` |
| 命名 | Idle/Run：`hero_zhaoyun_<clip>_###.png`。轻攻击：`hero_zhaoyun_atk_light1_###.png`、`hero_zhaoyun_atk_light2_###.png`、`hero_zhaoyun_atk_light3_###.png` |
| 目录 | `assets/characters/hero_zhaoyun/{idle,run,atk_light1,atk_light2,atk_light3}/` |

- **Idle**：12 帧，10 fps，零漂移。
- **Run**：原地跑，画面里没有位移。验收以老板通过的 Run v5 原片节奏为准：8 帧、8 fps，1 秒一循环。身体起伏 4–6 px。每个循环最多 1–2 帧低腾空。支撑脚后移的速度与 `MOVE_SPEED` 一致。Run 帧注册点约 `(128, 248)`，不沿用 Idle 的 `(-17, -1)` 偏移，由引擎对齐 Idle/Run 根点。
- **持枪**：全部动画里，枪都在角色自己的右手。侧面朝右时，这只手是远离镜头的那一只。

## 待定

- 是否做二段跳
- 重攻击用长按，还是独立按键
- 技能用能量条，还是冷却
- 第一关的主题
