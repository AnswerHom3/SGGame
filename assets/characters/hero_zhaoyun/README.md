# hero_zhaoyun asset root
Frames: idle/ run/ atk_light/
Canvas: 256x256, facing right
Foot pivot: (128,248)
Naming: hero_zhaoyun_<clip>_###.png

## idle
Status: 试用入仓、未过测 (trial check-in, not formally approved).
12 frames: `idle/hero_zhaoyun_idle_000.png`–`hero_zhaoyun_idle_011.png` (256×256 RGBA, facing right).
Playback: original extract pacing is about 2.38 fps (~0.420 s per frame, evenly sampled over 5.042 s, t = i × T/12). Do not play at 12 fps.
Documented foot pivot stays (128,248).

Known issues (QA, frames unchanged):
1. Foot/anchor bias about 17px to the right of the documented pivot (128,248). idle_direct_12 QC foot_x is ~132.5.
2. Loop seam / deformation is not cleared.
