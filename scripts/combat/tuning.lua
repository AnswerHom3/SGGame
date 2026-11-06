-- Provisional combat numbers for the 代号SG / Game004 prototype.
-- 策划 replaces this file from the combat one-pager. Nothing here is final.
-- Lengths are meters. Times are seconds. Sprite notes are pixels.
--
-- Root motion is code (MOVE_SPEED, LUNGE_SPEED). Do not bake it into sprites.
-- Spear stays in the right hand. Facing +1 is the authored facing-right pose;
-- local +X is "in front of the chest", which is the right-hand spear side.

local Tuning = {}

Tuning.SOURCE = "provisional-placeholder"

-- Program root motion. Horizontal stick only.
-- |deflection| <= MOVE_DEADZONE is a full stop the same frame (no inertia).
-- Outside the deadzone, deflection remaps to 0..1 so a full stick is MOVE_SPEED
-- and everything between is proportional. Keyboard debug passes ±1 and skips this.
Tuning.MOVE_SPEED = 5.0
Tuning.MOVE_DEADZONE = 0.15
Tuning.JUMP_SPEED = 10.0
Tuning.GRAVITY = 20.0

-- A press in the air is remembered this long and starts the combo on landing.
-- A press during a swing uses LIGHT_INPUT_BUFFER and is not cut by this air timer.
Tuning.INPUT_BUFFER_SEC = 0.12

Tuning.HERO_BODY_W = 0.55
Tuning.HERO_BODY_H = 1.75
Tuning.FOOT_SENSOR_R = 0.16

-- Right-hand spear, local meters, facing-right character space.
-- Grip is on the forward side of the torso. Tip is further forward, at hand height.
Tuning.SPEAR_HAND = "right"
Tuning.SPEAR_GRIP_LOCAL_X = 0.32
Tuning.SPEAR_GRIP_LOCAL_Y = 0.22
Tuning.SPEAR_TIP_LOCAL_X = 1.05
Tuning.SPEAR_TIP_LOCAL_Y = 0.42

-- Attack box centered on the spear tip, then pushed forward by tipBiasX
-- so the sweet spot sits on the point, not back on the shaft or the body.
-- w, h in meters. One entry per light-attack hit.
Tuning.HITBOX = {
    { w = 1.15, h = 0.38, tipBiasX = 0.15 },
    { w = 1.25, h = 0.42, tipBiasX = 0.20 },
    { w = 1.55, h = 0.55, tipBiasX = 0.35 },
}

-- Meters per second, forward, only while that hit's hit window is live.
-- Zero locks the foot. The hit-window branch stays so a later non-zero value
-- can lunge again. Do not bake this into sprites, and do not slide X from a
-- render-scale or viewport-bound change while the speed is 0.
Tuning.LUNGE_SPEED = { 0, 0, 0 }

-- Times are seconds from the start of that hit.
-- hitWindow: spear box can connect (half-open). Unchanged by the rhythm pass.
-- cancelWindow: jump, or the next light, can take over (half-open).
-- Windows sit near each clip's last frame so a mash during startup waits.
-- cancelInto "next" chains immediately. "end" waits out the swing, then
-- a press inside the cancel window starts light1 again. Jump still cancels now.
--
-- Light-string reset delay in seconds, counted from the end of recovery (收招结束).
-- After a swing finishes, the next press continues the string until this elapses.
Tuning.LIGHT_COMBO_RESET = 0.5

-- Light presses that land before the cancel window opens are kept, then consumed
-- when that window opens. The hold is at least this long (seconds), and always
-- long enough to reach the window so the press is not dropped.
Tuning.LIGHT_INPUT_BUFFER = 0.10

-- Presentation freeze on a successful hit. Time scale goes to 0 for this long.
-- Damage and the one-hit latch do not read this.
Tuning.HIT_STOP = 0.10

Tuning.LIGHT = {
    {
        name = "light1",
        duration = 0.40,
        hitWindow = { 0.10, 0.20 },
        cancelWindow = { 0.34, 0.40 },
        cancelInto = "next",
    },
    {
        name = "light2",
        duration = 0.46,
        hitWindow = { 0.12, 0.24 },
        cancelWindow = { 0.40, 0.46 },
        cancelInto = "next",
    },
    {
        name = "light3",
        duration = 0.62,
        hitWindow = { 0.16, 0.30 },
        cancelWindow = { 0.52, 0.62 },
        cancelInto = "end",
    },
}

-- Idle sheet contract. Do not rewrite the PNGs.
-- Canvas 256x256, authored facing right.
-- Playback is 10 fps (策划). The earlier 2.38 extract pacing is retired.
-- Documented foot pivot is (128, 248). Tester measured the idle foot near x=145,
-- so the blit shifts by about -17 px (128 - 145) to put that foot on the pivot.
-- Vertical compensate used in the local preview is -1 px. Do not rewrite the PNGs.
-- These draw offsets are Idle only. Run does not use them.
Tuning.CANVAS = 256
Tuning.IDLE_FRAME_COUNT = 12
Tuning.IDLE_FPS = 10
Tuning.FOOT_PIVOT_X = 128
Tuning.FOOT_PIVOT_Y = 248
Tuning.IDLE_QC_FOOT_X = 145
Tuning.IDLE_DRAW_OFFSET_X_PX = Tuning.FOOT_PIVOT_X - Tuning.IDLE_QC_FOOT_X
Tuning.IDLE_DRAW_OFFSET_Y_PX = -1
Tuning.HERO_DRAW_H = 1.90

-- Approved Run v5. Grounded move plays this clip. A stop plays Idle.
-- 8 frames at 8 fps is 125 ms/frame and a 1.0 s loop, matching the source cycle.
-- Do not play Run at 10 fps: that preview is 25% faster (1.25x) than the cycle.
-- Canvas register / root is (128, 248). Draw offset stays (0, 0).
-- Do not reuse Idle's (-17, -1).
Tuning.RUN_FRAME_COUNT = 8
Tuning.RUN_FPS = 8
Tuning.RUN_ROOT_X = 128
Tuning.RUN_ROOT_Y = 248
Tuning.RUN_DRAW_OFFSET_X_PX = 0
Tuning.RUN_DRAW_OFFSET_Y_PX = 0
Tuning.MOVE_CLIP = "run"

-- Zhao Yun light-attack v1. Mainline is duration-driven (time → frame).
-- Do not play these at 10 fps. Recover branches use source-mean fps, not the
-- attack target speeds. Nominal root is (128, 248). Do not reuse Idle's (-17, -1).
--
-- The six clips share one fit that is about 79.7% of Idle and 82.7% of Run
-- after that fit. Canvas scale stays 1 so the root stays on the collider foot.
-- A size step against Idle/Run can remain. Do not scale up to hide it.
Tuning.ATK_LIGHT_ROOT_X = 128
Tuning.ATK_LIGHT_ROOT_Y = 248
Tuning.ATK_LIGHT_DRAW_OFFSET_X_PX = 0
Tuning.ATK_LIGHT_DRAW_OFFSET_Y_PX = 0
Tuning.ATK_LIGHT_CANVAS_SCALE = 1
Tuning.ATK_LIGHT_RELATIVE_TO_IDLE = 0.7965875218419161
Tuning.ATK_LIGHT_RELATIVE_TO_RUN = 0.8266666666666667

Tuning.ATK_LIGHT_ORDER = {
    "light1",
    "light2",
    "light3",
    "light1_recover",
    "light2_recover",
    "light3_recover",
}

Tuning.ATK_LIGHT_CLIPS = {
    light1 = {
        group = "mainline",
        frames = 11,
        duration = 0.40,
        playback = "duration",
        suggestedFps = 11 / 0.40,
        impactFrame = 7,
        cancelFrame = 10,
        recover = "light1_recover",
    },
    light2 = {
        group = "mainline",
        frames = 20,
        duration = 0.46,
        playback = "duration",
        suggestedFps = 20 / 0.46,
        impactFrame = 16,
        cancelFrame = 19,
        recover = "light2_recover",
        -- Impact tip is cropped. Frame 17 is a debug-only backup, never (0, 0).
        debugBackupFrame = 17,
    },
    light3 = {
        group = "mainline",
        frames = 16,
        duration = 0.62,
        playback = "duration",
        suggestedFps = 16 / 0.62,
        impactFrame = 11,
        cancelFrame = 15,
        recover = "light3_recover",
    },
    light1_recover = {
        group = "branches",
        frames = 13,
        fps = 12.48,
        duration = 13 / 12.48,
        playback = "fps",
    },
    light2_recover = {
        group = "branches",
        frames = 11,
        fps = 11 / 0.875,
        duration = 0.875,
        playback = "fps",
    },
    light3_recover = {
        group = "branches",
        frames = 15,
        fps = 12.413793103448276,
        duration = 15 / 12.413793103448276,
        playback = "fps",
    },
}

-- Spear tips in 256-canvas pixels. Missing entries are unknown.
-- light2 frame 16 is intentionally absent (cropped). Do not store (0, 0).
Tuning.ATK_LIGHT_TIPS = {
    light1 = {
        [7] = { 243.1778, 132.3222 },
    },
    light2 = {
        [17] = { 213.2111, 28.6444 },
    },
    light3 = {
        [11] = { 236.6333, 238.0667 },
    },
}

function Tuning.idleFrameResource(index)
    return string.format(
        "characters/hero_zhaoyun/idle/hero_zhaoyun_idle_%03d.png",
        index
    )
end

function Tuning.runFrameResource(index)
    return string.format(
        "characters/hero_zhaoyun/run/hero_zhaoyun_run_%03d.png",
        index
    )
end

function Tuning.lightFrameResource(clip, index)
    local spec = Tuning.ATK_LIGHT_CLIPS[clip]
    return string.format(
        "characters/hero_zhaoyun/atk_light/%s/hero_zhaoyun_atk_%s_%03d.png",
        spec.group,
        clip,
        index
    )
end

function Tuning.allHeroSheetResources()
    local list = {}
    for i = 0, Tuning.IDLE_FRAME_COUNT - 1 do
        list[#list + 1] = Tuning.idleFrameResource(i)
    end
    for i = 0, Tuning.RUN_FRAME_COUNT - 1 do
        list[#list + 1] = Tuning.runFrameResource(i)
    end
    for _, name in ipairs(Tuning.ATK_LIGHT_ORDER) do
        local spec = Tuning.ATK_LIGHT_CLIPS[name]
        for i = 0, spec.frames - 1 do
            list[#list + 1] = Tuning.lightFrameResource(name, i)
        end
    end
    return list
end

-- Uniform time → frame across a target duration. Last index holds until duration.
function Tuning.durationFrameIndex(frameCount, duration, t)
    if frameCount <= 1 or duration == nil or duration <= 0 then
        return 0
    end
    if t == nil or t <= 0 then
        return 0
    end
    if t >= duration then
        return frameCount - 1
    end
    local idx = math.floor((t / duration) * frameCount)
    if idx < 0 then
        return 0
    end
    if idx >= frameCount then
        return frameCount - 1
    end
    return idx
end

-- Source-mean playback. Clamps on the last frame; does not loop.
function Tuning.fpsFrameIndex(frameCount, fps, t)
    if frameCount <= 1 or fps == nil or fps <= 0 then
        return 0
    end
    if t == nil or t <= 0 then
        return 0
    end
    local idx = math.floor(t * fps)
    if idx < 0 then
        return 0
    end
    if idx >= frameCount then
        return frameCount - 1
    end
    return idx
end

function Tuning.loopFrameIndex(frameCount, fps, t)
    if frameCount <= 0 or fps == nil or fps <= 0 then
        return 0
    end
    if t == nil or t <= 0 then
        return 0
    end
    local idx = math.floor(t * fps) % frameCount
    if idx < 0 then
        return 0
    end
    return idx
end

function Tuning.playFrameIndex(clip, t)
    local spec = Tuning.ATK_LIGHT_CLIPS[clip]
    if spec.playback == "duration" then
        return Tuning.durationFrameIndex(spec.frames, spec.duration, t)
    end
    return Tuning.fpsFrameIndex(spec.frames, spec.fps, t)
end

function Tuning.lightArtTip(clip, frame)
    local row = Tuning.ATK_LIGHT_TIPS[clip]
    if row == nil then
        return nil
    end
    local tip = row[frame]
    if tip == nil then
        return nil
    end
    return tip[1], tip[2]
end

-- Debug only. A cropped light2 impact never becomes (0, 0).
-- Frame 17's visible tip may stand in while debugging that impact frame.
function Tuning.lightArtTipForDebug(clip, frame)
    local x, y = Tuning.lightArtTip(clip, frame)
    if x ~= nil and y ~= nil then
        return x, y, false
    end
    local spec = Tuning.ATK_LIGHT_CLIPS[clip]
    if spec ~= nil and frame == spec.impactFrame and spec.debugBackupFrame ~= nil then
        local bx, by = Tuning.lightArtTip(clip, spec.debugBackupFrame)
        if bx ~= nil and by ~= nil then
            return bx, by, true
        end
    end
    return nil
end

-- Canvas pixel → world meters. Root pixel lands on the foot point.
-- offX/offY shift the sheet (Idle only). Facing +1 is authored right.
function Tuning.sheetPointToWorld(footX, footY, facing, px, py, rootX, rootY, offX, offY, scale)
    local canvasScale = scale or 1
    local metersPerPx = (Tuning.HERO_DRAW_H / Tuning.CANVAS) * canvasScale
    local worldX = footX + ((px + offX) - rootX) * metersPerPx * facing
    local worldY = footY - ((py + offY) - rootY) * metersPerPx
    return worldX, worldY
end

-- Hit-window lunge. Zero means the foot stays where it is.
function Tuning.attackLungeSpeed(hitIndex)
    local speed = Tuning.LUNGE_SPEED[hitIndex]
    if speed == nil or speed == 0 then
        return 0
    end
    return speed
end

-- A locked foot (attacking, vx == 0) ignores X corrections that only exist
-- because a viewport bound or a sheet scale changed. Y is left to the caller.
function Tuning.keepLockedFootX(attacking, vx, oldX, clampedX)
    if attacking and vx == 0 then
        return oldX
    end
    return clampedX
end

function Tuning.clipFps(clip)
    if clip == "run" then
        return Tuning.RUN_FPS
    end
    return Tuning.IDLE_FPS
end

function Tuning.clipFrameCount(clip)
    if clip == "run" then
        return Tuning.RUN_FRAME_COUNT
    end
    return Tuning.IDLE_FRAME_COUNT
end

-- Sprite-only. Idle's measured-foot compensate must not be applied to Run.
function Tuning.clipDrawOffsetPx(clip)
    if clip == "run" then
        return Tuning.RUN_DRAW_OFFSET_X_PX, Tuning.RUN_DRAW_OFFSET_Y_PX
    end
    return Tuning.IDLE_DRAW_OFFSET_X_PX, Tuning.IDLE_DRAW_OFFSET_Y_PX
end

function Tuning.clipDrawOffsetMeters(clip)
    local metersPerPx = Tuning.HERO_DRAW_H / Tuning.CANVAS
    local ox, oy = Tuning.clipDrawOffsetPx(clip)
    return ox * metersPerPx, oy * metersPerPx
end

-- Idle only. Colored blocks ignore this and stand on the collider feet.
-- Run uses clipDrawOffsetPx("run"), which stays (0, 0).
function Tuning.idleDrawOffsetMeters()
    local metersPerPx = Tuning.HERO_DRAW_H / Tuning.CANVAS
    return Tuning.IDLE_DRAW_OFFSET_X_PX * metersPerPx,
           Tuning.IDLE_DRAW_OFFSET_Y_PX * metersPerPx
end

function Tuning.spearGrip(x, y, facing)
    return x + facing * Tuning.SPEAR_GRIP_LOCAL_X, y + Tuning.SPEAR_GRIP_LOCAL_Y
end

function Tuning.spearTip(x, y, facing)
    return x + facing * Tuning.SPEAR_TIP_LOCAL_X, y + Tuning.SPEAR_TIP_LOCAL_Y
end

function Tuning.attackBox(x, y, facing, hitIndex)
    local spec = Tuning.HITBOX[hitIndex]
    local tipX, tipY = Tuning.spearTip(x, y, facing)
    return tipX + facing * spec.tipBiasX, tipY, spec.w, spec.h
end

function Tuning.moveAxis(raw)
    if raw == nil then
        return 0
    end
    local ax = math.abs(raw)
    if ax <= Tuning.MOVE_DEADZONE then
        return 0
    end
    if ax > 1 then
        ax = 1
    end
    local scaled = (ax - Tuning.MOVE_DEADZONE) / (1 - Tuning.MOVE_DEADZONE)
    if raw < 0 then
        return -scaled
    end
    return scaled
end

function Tuning.moveSpeed(raw)
    return Tuning.moveAxis(raw) * Tuning.MOVE_SPEED
end

-- A live stick hides the keyboard. A released stick (axis 0) leaves desktop keys in charge.
function Tuning.combineMoveAxis(stickAxis, keyAxis)
    if stickAxis ~= nil and stickAxis ~= 0 then
        return stickAxis
    end
    if keyAxis == nil then
        return 0
    end
    return keyAxis
end

-- Outward speed becomes 0 on a viewport edge. Release already passes vx 0.
function Tuning.clampVelocity(x, y, vx, vy, bounds)
    if bounds == nil then
        return vx, vy
    end
    if x <= bounds.minX and vx < 0 then
        vx = 0
    end
    if x >= bounds.maxX and vx > 0 then
        vx = 0
    end
    if y <= bounds.minY and vy < 0 then
        vy = 0
    end
    if y >= bounds.maxY and vy > 0 then
        vy = 0
    end
    return vx, vy
end

function Tuning.clampPosition(x, y, bounds)
    if x < bounds.minX then
        x = bounds.minX
    end
    if x > bounds.maxX then
        x = bounds.maxX
    end
    if y < bounds.minY then
        y = bounds.minY
    end
    if y > bounds.maxY then
        y = bounds.maxY
    end
    return x, y
end

function Tuning.visualContract()
    return {
        mode = "hero_sheet",
        moveClip = Tuning.MOVE_CLIP,
        idleFps = Tuning.IDLE_FPS,
        canvas = Tuning.CANVAS,
        footPivot = { Tuning.FOOT_PIVOT_X, Tuning.FOOT_PIVOT_Y },
        idleQcFootX = Tuning.IDLE_QC_FOOT_X,
        drawOffsetPx = { Tuning.IDLE_DRAW_OFFSET_X_PX, Tuning.IDLE_DRAW_OFFSET_Y_PX },
        idleFrame0 = Tuning.idleFrameResource(0),
        idleFrameLast = Tuning.idleFrameResource(Tuning.IDLE_FRAME_COUNT - 1),
        runFps = Tuning.RUN_FPS,
        runFrameCount = Tuning.RUN_FRAME_COUNT,
        runRoot = { Tuning.RUN_ROOT_X, Tuning.RUN_ROOT_Y },
        runDrawOffsetPx = { Tuning.RUN_DRAW_OFFSET_X_PX, Tuning.RUN_DRAW_OFFSET_Y_PX },
        runFrame0 = Tuning.runFrameResource(0),
        runFrameLast = Tuning.runFrameResource(Tuning.RUN_FRAME_COUNT - 1),
        atkLightRoot = { Tuning.ATK_LIGHT_ROOT_X, Tuning.ATK_LIGHT_ROOT_Y },
        atkLightDrawOffsetPx = {
            Tuning.ATK_LIGHT_DRAW_OFFSET_X_PX,
            Tuning.ATK_LIGHT_DRAW_OFFSET_Y_PX,
        },
        atkLightCanvasScale = Tuning.ATK_LIGHT_CANVAS_SCALE,
        atkLightRelativeToIdle = Tuning.ATK_LIGHT_RELATIVE_TO_IDLE,
        atkLightRelativeToRun = Tuning.ATK_LIGHT_RELATIVE_TO_RUN,
        atkLightFrame0 = Tuning.lightFrameResource("light1", 0),
        atkLightFrameLast = Tuning.lightFrameResource("light3_recover", 14),
        spearHand = Tuning.SPEAR_HAND,
    }
end

function Tuning.validate()
    assert(Tuning.SPEAR_HAND == "right", "spear hand lock")
    assert(Tuning.SPEAR_TIP_LOCAL_X > Tuning.SPEAR_GRIP_LOCAL_X, "tip stays in front of the grip")
    assert(Tuning.MOVE_DEADZONE == 0.15, "move deadzone")
    assert(Tuning.MOVE_SPEED == 5, "move speed")
    assert(Tuning.MOVE_CLIP == "run", "grounded move plays run")
    assert(Tuning.moveAxis(0) == 0, "stick release is a stop")
    assert(Tuning.moveAxis(0.15) == 0 and Tuning.moveAxis(-0.15) == 0, "deadzone")
    assert(math.abs(Tuning.moveAxis(1) - 1) < 1e-9, "full stick right")
    assert(math.abs(Tuning.moveAxis(-1) + 1) < 1e-9, "full stick left")
    assert(math.abs(Tuning.moveSpeed(1) - 5) < 1e-9, "full stick speed")
    assert(Tuning.combineMoveAxis(0, -1) == -1, "keyboard when the stick is up")
    assert(Tuning.combineMoveAxis(0.4, 1) == 0.4, "stick overrides keyboard")
    local edgeVx = Tuning.clampVelocity(0, 1, -5, 0, {
        minX = 0, maxX = 10, minY = 0, maxY = 10,
    })
    assert(edgeVx == 0, "cannot walk out of the viewport")
    assert(Tuning.CANVAS == 256, "idle canvas")
    assert(Tuning.IDLE_FPS == 10, "idle playback")
    assert(Tuning.IDLE_FRAME_COUNT == 12, "idle frame count")
    assert(Tuning.FOOT_PIVOT_X == 128 and Tuning.FOOT_PIVOT_Y == 248, "documented foot pivot")
    assert(Tuning.IDLE_QC_FOOT_X == 145, "idle QC foot x")
    assert(Tuning.IDLE_DRAW_OFFSET_X_PX == -17, "idle horizontal compensate")
    assert(Tuning.IDLE_DRAW_OFFSET_Y_PX == -1, "idle vertical compensate")
    assert(
        math.abs(Tuning.IDLE_DRAW_OFFSET_X_PX - (Tuning.FOOT_PIVOT_X - Tuning.IDLE_QC_FOOT_X)) < 1e-6,
        "draw offset"
    )
    assert(Tuning.RUN_FPS == 8, "run playback is 8 fps")
    assert(Tuning.RUN_FRAME_COUNT == 8, "run frame count")
    assert(math.abs((Tuning.RUN_FRAME_COUNT / Tuning.RUN_FPS) - 1.0) < 1e-9, "run loop is 1 second")
    assert(Tuning.RUN_ROOT_X == 128 and Tuning.RUN_ROOT_Y == 248, "run canvas root")
    assert(
        Tuning.RUN_DRAW_OFFSET_X_PX == 0 and Tuning.RUN_DRAW_OFFSET_Y_PX == 0,
        "run does not reuse the idle draw offset"
    )
    local runOx, runOy = Tuning.clipDrawOffsetPx("run")
    assert(runOx == 0 and runOy == 0, "run clip offset")
    local idleOx, idleOy = Tuning.clipDrawOffsetPx("idle")
    assert(idleOx == -17 and idleOy == -1, "idle clip keeps its own offset")
    assert(Tuning.clipFps("run") == 8 and Tuning.clipFps("idle") == 10, "clip fps")
    assert(Tuning.clipFrameCount("run") == 8 and Tuning.clipFrameCount("idle") == 12, "clip frame counts")
    assert(
        Tuning.runFrameResource(0) == "characters/hero_zhaoyun/run/hero_zhaoyun_run_000.png",
        "run frame 0"
    )
    assert(
        Tuning.runFrameResource(7) == "characters/hero_zhaoyun/run/hero_zhaoyun_run_007.png",
        "run frame 7"
    )
    assert(#Tuning.LIGHT == 3 and #Tuning.HITBOX == 3 and #Tuning.LUNGE_SPEED == 3, "3-hit")
    assert(Tuning.LUNGE_SPEED[1] == 0 and Tuning.LUNGE_SPEED[2] == 0 and Tuning.LUNGE_SPEED[3] == 0, "lunge locked")
    assert(Tuning.attackLungeSpeed(1) == 0 and Tuning.attackLungeSpeed(2) == 0 and Tuning.attackLungeSpeed(3) == 0, "zero lunge is a locked foot")
    assert(Tuning.keepLockedFootX(true, 0, 1.25, 1.40) == 1.25, "locked foot ignores bound nudge")
    assert(Tuning.keepLockedFootX(true, 1, 1.25, 1.40) == 1.40, "moving attack can still clamp")
    assert(Tuning.keepLockedFootX(false, 0, 1.25, 1.40) == 1.40, "idle clamp still applies")
    assert(Tuning.LIGHT[1].duration == 0.40 and Tuning.LIGHT[2].duration == 0.46 and Tuning.LIGHT[3].duration == 0.62, "light durations")
    assert(Tuning.LIGHT[1].hitWindow[1] == 0.10 and Tuning.LIGHT[1].hitWindow[2] == 0.20, "light1 hit window")
    assert(Tuning.LIGHT[2].hitWindow[1] == 0.12 and Tuning.LIGHT[2].hitWindow[2] == 0.24, "light2 hit window")
    assert(Tuning.LIGHT[3].hitWindow[1] == 0.16 and Tuning.LIGHT[3].hitWindow[2] == 0.30, "light3 hit window")
    assert(Tuning.LIGHT[1].cancelWindow[1] == 0.34 and Tuning.LIGHT[1].cancelWindow[2] == 0.40, "light1 cancel")
    assert(Tuning.LIGHT[2].cancelWindow[1] == 0.40 and Tuning.LIGHT[2].cancelWindow[2] == 0.46, "light2 cancel")
    assert(Tuning.LIGHT[3].cancelWindow[1] == 0.52 and Tuning.LIGHT[3].cancelWindow[2] == 0.62, "light3 cancel")
    assert(Tuning.LIGHT_COMBO_RESET == 0.5, "light combo reset")
    assert(Tuning.LIGHT_INPUT_BUFFER == 0.10, "light input buffer")
    assert(Tuning.HIT_STOP == 0.10, "hit stop")
    assert(Tuning.LIGHT[1].cancelInto == "next", "light1 chains")
    assert(Tuning.LIGHT[2].cancelInto == "next", "light2 chains")
    assert(Tuning.LIGHT[3].cancelInto == "end", "light3 ends the string")
    assert(Tuning.ATK_LIGHT_ROOT_X == 128 and Tuning.ATK_LIGHT_ROOT_Y == 248, "light root")
    assert(
        Tuning.ATK_LIGHT_DRAW_OFFSET_X_PX == 0 and Tuning.ATK_LIGHT_DRAW_OFFSET_Y_PX == 0,
        "light attack does not reuse the idle draw offset"
    )
    assert(Tuning.ATK_LIGHT_CANVAS_SCALE == 1, "do not scale light sheets up to match idle")
    assert(math.abs(Tuning.ATK_LIGHT_RELATIVE_TO_IDLE - 0.7965875218419161) < 1e-12, "idle size ratio")
    assert(math.abs(Tuning.ATK_LIGHT_RELATIVE_TO_RUN - 0.8266666666666667) < 1e-12, "run size ratio")
    assert(math.abs(Tuning.ATK_LIGHT_CLIPS.light1.suggestedFps - 27.5) < 1e-9, "light1 fps")
    assert(math.abs(Tuning.ATK_LIGHT_CLIPS.light2.suggestedFps - (20 / 0.46)) < 1e-9, "light2 fps")
    assert(math.abs(Tuning.ATK_LIGHT_CLIPS.light3.suggestedFps - (16 / 0.62)) < 1e-9, "light3 fps")
    assert(Tuning.ATK_LIGHT_CLIPS.light1.suggestedFps ~= 10, "light1 is not 10 fps")
    assert(math.abs(Tuning.ATK_LIGHT_CLIPS.light1_recover.fps - 12.48) < 1e-9, "light1 recover fps")
    assert(math.abs(Tuning.ATK_LIGHT_CLIPS.light2_recover.fps - (11 / 0.875)) < 1e-9, "light2 recover fps")
    assert(math.abs(Tuning.ATK_LIGHT_CLIPS.light3_recover.fps - 12.413793103448276) < 1e-9, "light3 recover fps")
    assert(Tuning.ATK_LIGHT_CLIPS.light1_recover.duration > 1.0, "recover keeps source length")
    assert(Tuning.playFrameIndex("light1", 0) == 0, "light1 frame 0")
    assert(Tuning.playFrameIndex("light1", 0.40) == 10, "light1 last frame")
    assert(Tuning.playFrameIndex("light1", (7 / 11) * 0.40) == 7, "light1 impact frame")
    assert(Tuning.playFrameIndex("light2", 0) == 0 and Tuning.playFrameIndex("light2", 0.46) == 19, "light2 span")
    assert(Tuning.playFrameIndex("light3", (11 / 16) * 0.62) == 11, "light3 impact frame")
    assert(Tuning.playFrameIndex("light3", 0.62) == 15, "light3 last frame")
    assert(Tuning.playFrameIndex("light1_recover", 0) == 0, "recover starts at 0")
    assert(Tuning.playFrameIndex("light1_recover", 1 / 12.48) == 1, "recover steps at source fps")
    assert(Tuning.lightFrameResource("light3", 15)
        == "characters/hero_zhaoyun/atk_light/mainline/hero_zhaoyun_atk_light3_015.png",
        "downward slash frame")
    assert(Tuning.lightFrameResource("light1_recover", 12)
        == "characters/hero_zhaoyun/atk_light/branches/hero_zhaoyun_atk_light1_recover_012.png",
        "recover branch path")
    local sheetCount = 0
    for _, name in ipairs(Tuning.ATK_LIGHT_ORDER) do
        sheetCount = sheetCount + Tuning.ATK_LIGHT_CLIPS[name].frames
    end
    assert(sheetCount == 86, "86 light-attack frames")
    assert(#Tuning.allHeroSheetResources() == 12 + 8 + 86, "hero sheet list")
    assert(Tuning.lightArtTip("light2", 16) == nil, "cropped light2 impact tip stays unknown")
    local backupX, backupY, backup = Tuning.lightArtTipForDebug("light2", 16)
    assert(backup == true, "debug backup is explicit")
    assert(backupX ~= nil and not (backupX == 0 and backupY == 0), "backup is not the origin")
    assert(math.abs(backupX - 213.2111) < 1e-4 and math.abs(backupY - 28.6444) < 1e-4, "frame 17 backup tip")
    local realX, realY, realBackup = Tuning.lightArtTipForDebug("light1", 7)
    assert(realBackup == false and math.abs(realX - 243.1778) < 1e-4, "light1 impact tip")
    local rootX, rootY = Tuning.sheetPointToWorld(3, 1, 1, 128, 248, 128, 248, 0, 0, 1)
    assert(math.abs(rootX - 3) < 1e-9 and math.abs(rootY - 1) < 1e-9, "light root sits on the foot")
    local idleFootX = Tuning.sheetPointToWorld(0, 0, 1, 145, 248, 128, 248, -17, -1, 1)
    assert(math.abs(idleFootX) < 1e-9, "idle offset still parks its own foot")
    local lightFootX = Tuning.sheetPointToWorld(
        0, 0, 1, 145, 248,
        Tuning.ATK_LIGHT_ROOT_X, Tuning.ATK_LIGHT_ROOT_Y,
        Tuning.ATK_LIGHT_DRAW_OFFSET_X_PX, Tuning.ATK_LIGHT_DRAW_OFFSET_Y_PX,
        Tuning.ATK_LIGHT_CANVAS_SCALE
    )
    assert(math.abs(lightFootX - (17 * Tuning.HERO_DRAW_H / Tuning.CANVAS)) < 1e-9, "light sheet is not shifted by -17")

    for i, hit in ipairs(Tuning.LIGHT) do
        local spec = Tuning.ATK_LIGHT_CLIPS[hit.name]
        assert(spec.playback == "duration", hit.name .. " duration playback")
        assert(math.abs(spec.duration - hit.duration) < 1e-9, hit.name .. " sheet duration")
        assert(spec.cancelFrame == spec.frames - 1, hit.name .. " cancel frame is the last mainline frame")
        assert(hit.duration > 0, hit.name)
        assert(hit.hitWindow[1] >= 0 and hit.hitWindow[2] <= hit.duration, hit.name .. " hit window")
        assert(hit.hitWindow[1] < hit.hitWindow[2], hit.name .. " hit window order")
        assert(hit.cancelWindow[1] >= 0 and hit.cancelWindow[2] <= hit.duration, hit.name .. " cancel window")
        assert(hit.cancelWindow[1] < hit.cancelWindow[2], hit.name .. " cancel window order")
        local cx, _, w = Tuning.attackBox(0, 0, 1, i)
        local backEdge = cx - w * 0.5
        assert(backEdge > Tuning.SPEAR_GRIP_LOCAL_X, hit.name .. " box must stay in front of the right-hand grip")
        local leftCx = Tuning.attackBox(0, 0, -1, i)
        assert(leftCx < 0, hit.name .. " mirrors with facing")
    end

    local LightAnim = require("combat.light_anim")
    LightAnim.check()
    return true
end

return Tuning
