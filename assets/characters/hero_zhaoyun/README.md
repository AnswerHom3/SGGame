# hero_zhaoyun asset root
Frames: idle/ run/ atk_light/
Canvas: 256x256, facing right
Foot pivot: (128,248)
Naming: hero_zhaoyun_<clip>_###.png

## idle
Status: 试用入仓、未过测 (trial check-in, not formally approved).
12 frames: `idle/hero_zhaoyun_idle_000.png`–`hero_zhaoyun_idle_011.png` (256×256 RGBA, facing right).
Playback: original extract pacing is about 2.38 fps (~0.420 s per frame, evenly sampled over 5.042 s, t = i × T/12). Do not play at 12 fps.
In-game playback stays 12 frames at 10 fps. Draw offset (−17, −1) is Idle only.
Documented foot pivot stays (128,248).

Known issues (QA, frames unchanged):
1. Foot/anchor bias about 17px to the right of the documented pivot (128,248). idle_direct_12 QC foot_x is ~132.5.
2. Loop seam / deformation is not cleared.

## run
Trial/approved: user-approved Run v5 from the pose video. 8 frames.
Frames: `run/hero_zhaoyun_run_000.png`–`hero_zhaoyun_run_007.png` (256×256 RGBA).
Playback: **8 fps** (125 ms/frame, 1.0 s loop). Do not play Run at 10 fps in game. A 10 fps preview is 25% faster than the source cycle.
Canvas register / root ≈ (128, 248). Do not reuse the Idle draw offset (−17, −1) for Run.
Source frames face right, have no mouth, and hold the spear in the right hand.
Moving uses Run. Idle plays when stopped (Idle remains 12 frames at 10 fps with its own offset).
