# 代号SG / Game004

玩法 Lua 在 `scripts/`。战斗原型的操作和占位数值见 [docs/combat-proto-skeleton.md](docs/combat-proto-skeleton.md)。

## 战斗原型

横版骨架：移动、跳跃、轻击三连。角色是色块。移动时仍播 Idle，不是 Run 动画。时长和判定在 `scripts/combat/tuning.lua`，等策划替换。

- **左下摇杆**：左右移动（死区 0.15，推满 5 m/s，松开即停）
- **A / D** 或 **← / →**：桌面调试移动
- **Space / W / ↑**：跳跃
- **J**：轻击三连
- **Z**：物理调试
