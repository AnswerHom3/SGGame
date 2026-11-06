# 代号SG / Game004

玩法 Lua 在 `scripts/`。战斗原型的操作和占位数值见 [docs/combat-proto-skeleton.md](docs/combat-proto-skeleton.md)。

## 战斗原型

横版骨架：移动、跳跃、轻击三连。着地移动播 Run（8 帧、8 fps），停下播 Idle（12 帧、10 fps，Idle 自己的绘制偏移）。轻击播 `assets/characters/hero_zhaoyun/atk_light/` 的 86 张帧：主线按 0.40 / 0.46 / 0.62 秒取帧，收招按源均值帧率。挥击前冲为 0，脚锁定。时长和判定在 `scripts/combat/tuning.lua`。

- **左下摇杆**：左右移动（死区 0.15，推满 5 m/s，松开即停）
- **A / D** 或 **← / →**：桌面调试移动
- **Space / W / ↑**：跳跃
- **J**：轻击三连
- **Z**：物理调试
