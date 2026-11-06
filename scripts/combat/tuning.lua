-- Provisional combat numbers for the 代号SG / Game004 prototype.
-- 策划 replaces this file from the combat one-pager. Nothing here is final.
-- Lengths are meters. Times are seconds. Sprite notes are pixels.
--
-- Root motion is code (MOVE_SPEED, LUNGE_SPEED). Do not bake it into sprites.
-- Spear stays in the right hand. Facing +1 is the authored facing-right pose;
-- local +X is "in front of the chest", which is the right-hand spear side.

local Tuning = {}

Tuning.SOURCE = "provisional-placeholder"

-- Program root motion.
Tuning.MOVE_SPEED = 5.0
Tuning.JUMP_SPEED = 10.0
Tuning.GRAVITY = 20.0

-- A press in the air is remembered this long and starts the combo on landing.
-- A press during a swing is held until that swing's cancel window (not cut by this).
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
Tuning.LUNGE_SPEED = { 1.2, 1.6, 2.4 }

-- Times are seconds from the start of that hit.
-- hitWindow: spear box can connect (half-open).
-- cancelWindow: jump, or the next light, can take over (half-open).
-- cancelInto "next" chains immediately. "end" waits out the swing, then
-- a press inside the cancel window starts light1 again. Jump still cancels now.
Tuning.LIGHT = {
    {
        name = "light1",
        duration = 0.40,
        hitWindow = { 0.10, 0.20 },
        cancelWindow = { 0.18, 0.40 },
        cancelInto = "next",
    },
    {
        name = "light2",
        duration = 0.46,
        hitWindow = { 0.12, 0.24 },
        cancelWindow = { 0.22, 0.46 },
        cancelInto = "next",
    },
    {
        name = "light3",
        duration = 0.62,
        hitWindow = { 0.16, 0.30 },
        cancelWindow = { 0.36, 0.62 },
        cancelInto = "end",
    },
}

-- Idle sheet contract. Frames are not on this branch; the prototype draws blocks.
-- When the sheet lands, do not rewrite the PNGs.
-- Canvas 256x256, authored facing right.
-- Playback is 10 fps (策划). The earlier 2.38 extract pacing is retired.
-- Documented foot pivot is (128, 248). Tester measured the idle foot near x=145,
-- so the blit shifts by about -17 px (128 - 145) to put that foot on the pivot.
-- Vertical compensate used in the local preview is -1 px. Do not rewrite the PNGs.
Tuning.CANVAS = 256
Tuning.IDLE_FRAME_COUNT = 12
Tuning.IDLE_FPS = 10
Tuning.FOOT_PIVOT_X = 128
Tuning.FOOT_PIVOT_Y = 248
Tuning.IDLE_QC_FOOT_X = 145
Tuning.IDLE_DRAW_OFFSET_X_PX = Tuning.FOOT_PIVOT_X - Tuning.IDLE_QC_FOOT_X
Tuning.IDLE_DRAW_OFFSET_Y_PX = -1
Tuning.HERO_DRAW_H = 1.90

-- Run has no art in this prototype. Draw a tinted block (or, later, reuse Idle).
Tuning.RUN_VISUAL = "tinted_block"

function Tuning.idleFrameResource(index)
    return string.format(
        "characters/hero_zhaoyun/idle/hero_zhaoyun_idle_%03d.png",
        index
    )
end

-- Sprite-only. Colored blocks ignore this and stand on the collider feet.
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

function Tuning.visualContract()
    return {
        mode = "colored_blocks",
        run = Tuning.RUN_VISUAL,
        idleFps = Tuning.IDLE_FPS,
        canvas = Tuning.CANVAS,
        footPivot = { Tuning.FOOT_PIVOT_X, Tuning.FOOT_PIVOT_Y },
        idleQcFootX = Tuning.IDLE_QC_FOOT_X,
        drawOffsetPx = { Tuning.IDLE_DRAW_OFFSET_X_PX, Tuning.IDLE_DRAW_OFFSET_Y_PX },
        idleFrame0 = Tuning.idleFrameResource(0),
        idleFrameLast = Tuning.idleFrameResource(Tuning.IDLE_FRAME_COUNT - 1),
        spearHand = Tuning.SPEAR_HAND,
    }
end

function Tuning.validate()
    assert(Tuning.SPEAR_HAND == "right", "spear hand lock")
    assert(Tuning.SPEAR_TIP_LOCAL_X > Tuning.SPEAR_GRIP_LOCAL_X, "tip stays in front of the grip")
    assert(Tuning.RUN_VISUAL == "tinted_block", "run visual is a placeholder")
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
    assert(#Tuning.LIGHT == 3 and #Tuning.HITBOX == 3 and #Tuning.LUNGE_SPEED == 3, "3-hit")
    assert(Tuning.LIGHT[1].cancelInto == "next", "light1 chains")
    assert(Tuning.LIGHT[2].cancelInto == "next", "light2 chains")
    assert(Tuning.LIGHT[3].cancelInto == "end", "light3 ends the string")

    for i, hit in ipairs(Tuning.LIGHT) do
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
    return true
end

return Tuning
