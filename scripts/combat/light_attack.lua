-- 3-hit light attack. Windows live in combat.tuning and are provisional.
--
-- A press before the cancel window is buffered and consumed when it opens:
--   cancelInto "next" -> start the next hit immediately
--   cancelInto "end"  -> remember a restart, fire it when the swing ends
-- Only one buffered input is kept per swing. A second press is ignored until
-- that swing ends or the open cancel window consumes a press immediately.
-- The buffer is LIGHT_INPUT_BUFFER and is kept at least until the window opens.
-- After recovery ends, the string stays open for LIGHT_COMBO_RESET seconds.
-- Jump cancel is owned by the hero: it calls cancel() when canCancel() is true.

local Tuning = require("combat.tuning")

local LightAttack = {}
LightAttack.__index = LightAttack

function LightAttack.new()
    local self = setmetatable({}, LightAttack)
    self:cancel()
    return self
end

function LightAttack:cancel()
    local interrupt = self.active == true
    self.active = false
    self.index = 0
    self.t = 0
    self.lastDt = 0
    self.buffered = false
    self.bufferLeft = 0
    self.restartQueued = false
    self.hitLatched = false
    self.phase = "none"
    -- Natural end is the only signal the sheet player uses to start a recover.
    -- Jump cancel and a chained next hit both leave this false.
    self.endedNaturally = false
    self.finishedIndex = 0
    if self.comboIndex == nil or interrupt then
        self.comboIndex = 0
        self.comboReset = 0
    end
end

function LightAttack:isAttacking()
    return self.active
end

function LightAttack:hitIndex()
    if not self.active then
        return 0
    end
    return self.index
end

function LightAttack:_def()
    if not self.active then
        return nil
    end
    return Tuning.LIGHT[self.index]
end

function LightAttack:_in(window)
    return self.t >= window[1] and self.t < window[2]
end

-- True when the timestep that just landed overlapped the window.
function LightAttack:_overlaps(window)
    local prev = self.t - self.lastDt
    return self.t >= window[1] and prev < window[2]
end

function LightAttack:_cancelReached(def)
    return self:_in(def.cancelWindow) or self:_overlaps(def.cancelWindow)
end

function LightAttack:hitboxActive()
    local def = self:_def()
    return def ~= nil and self:_in(def.hitWindow)
end

function LightAttack:canCancel()
    local def = self:_def()
    return def ~= nil and self:_in(def.cancelWindow)
end

function LightAttack:_begin(index)
    self.active = true
    self.index = index
    self.t = 0
    self.lastDt = 0
    self.buffered = false
    self.bufferLeft = 0
    self.restartQueued = false
    self.hitLatched = false
    self.phase = "startup"
    self.comboIndex = index
    self.comboReset = 0
    self.endedNaturally = false
    self.finishedIndex = 0
end

function LightAttack:_continuedIndex()
    local count = #Tuning.LIGHT
    if self.comboReset > 0 and self.comboIndex >= 1 and self.comboIndex <= count then
        local nextIndex = self.comboIndex + 1
        if nextIndex > count then
            return 1
        end
        return nextIndex
    end
    return 1
end

-- Returns true when this swing was replaced by the next hit.
function LightAttack:_takeCancel(def)
    self.buffered = false
    self.bufferLeft = 0
    if def.cancelInto == "next" then
        local nextIndex = self.index + 1
        if nextIndex > #Tuning.LIGHT then
            nextIndex = 1
        end
        self:_begin(nextIndex)
        return true
    end
    if def.cancelInto == "end" then
        self.restartQueued = true
    end
    return false
end

function LightAttack:_armBuffer(def)
    local untilOpen = def.cancelWindow[1] - self.t
    if untilOpen < 0 then
        untilOpen = 0
    end
    local hold = Tuning.LIGHT_INPUT_BUFFER
    if untilOpen > hold then
        hold = untilOpen
    end
    self.buffered = true
    if self.bufferLeft < hold then
        self.bufferLeft = hold
    end
end

function LightAttack:_finishSwing()
    local def = self:_def()
    local finished = self.index
    local restart = self.restartQueued
    local overshoot = 0
    if def ~= nil then
        overshoot = self.t - def.duration
        if overshoot < 0 then
            overshoot = 0
        end
    end

    self.active = false
    self.index = 0
    self.t = 0
    self.lastDt = 0
    self.buffered = false
    self.bufferLeft = 0
    self.restartQueued = false
    self.hitLatched = false
    self.phase = "none"
    self.finishedIndex = finished
    self.endedNaturally = true

    if restart then
        -- A queued extra press starts light1 now, so the sheet player must
        -- not treat this as a natural end (that would play light3_recover).
        self:_begin(1)
        return
    end

    local remain = Tuning.LIGHT_COMBO_RESET - overshoot
    if remain > 0 and finished >= 1 then
        self.comboIndex = finished
        self.comboReset = remain
    else
        self.comboIndex = 0
        self.comboReset = 0
    end
end

function LightAttack:request()
    if not self.active then
        self:_begin(self:_continuedIndex())
        return
    end

    local def = self:_def()
    -- The open window consumes this press now. A restart already queued for
    -- this swing is the one input, so further presses do not stack another.
    if self:_in(def.cancelWindow) then
        if not self.restartQueued then
            self:_takeCancel(def)
        end
        return
    end

    if self.buffered or self.restartQueued then
        return
    end

    self:_armBuffer(def)
end

function LightAttack.check()
    local attack = LightAttack.new()
    attack:request()
    attack:update(0.05)
    attack:request()
    assert(attack.buffered == true and attack:hitIndex() == 1, "first early press is buffered")
    local left = attack.bufferLeft
    attack:request()
    attack:request()
    assert(attack.buffered == true and attack.bufferLeft == left, "extra presses during the swing are ignored")
    assert(attack:hitIndex() == 1, "an ignored press does not skip the swing")

    local light1 = Tuning.LIGHT[1]
    attack.t = light1.cancelWindow[1]
    attack:request()
    assert(attack:hitIndex() == 2 and attack.buffered == false, "cancel-window press consumes immediately")

    attack:request()
    assert(attack.buffered == true and attack:hitIndex() == 2, "the next swing can buffer one press")
    attack:request()
    assert(attack.buffered == true and attack:hitIndex() == 2, "light2 keeps a single buffer")

    local light2 = Tuning.LIGHT[2]
    attack.t = light2.cancelWindow[1]
    attack:request()
    assert(attack:hitIndex() == 3, "light2 cancel window chains to light3")

    local light3 = Tuning.LIGHT[3]
    attack.t = light3.cancelWindow[1]
    attack:request()
    assert(attack.restartQueued == true and attack:hitIndex() == 3, "light3 queues one restart")
    local queuedT = attack.t
    attack:request()
    attack:request()
    assert(
        attack.restartQueued == true and attack:hitIndex() == 3 and attack.t == queuedT,
        "further light3 presses do not queue another restart"
    )
    attack:update(light3.duration - attack.t + 0.001)
    assert(attack:hitIndex() == 1 and attack:isAttacking(), "the queued restart starts light1 once")
end

function LightAttack:_tickCombo(dt)
    if self.comboReset <= 0 then
        return
    end
    self.comboReset = self.comboReset - dt
    if self.comboReset <= 0 then
        self.comboReset = 0
        self.comboIndex = 0
    end
end

function LightAttack:_tickBuffer(dt, def)
    self.bufferLeft = self.bufferLeft - dt
    local untilOpen = def.cancelWindow[1] - self.t
    -- Still before the window: do not let the countdown eat the press.
    if untilOpen > 0 and self.bufferLeft < untilOpen then
        self.bufferLeft = untilOpen
    end
    if self.bufferLeft <= 0 then
        self.bufferLeft = 0
        self.buffered = false
    end
end

function LightAttack:update(dt)
    if dt < 0 then
        dt = 0
    end

    if not self.active then
        self.phase = "none"
        self:_tickCombo(dt)
        return
    end

    self.lastDt = dt
    self.t = self.t + dt

    local def = self:_def()
    if self.t < def.hitWindow[1] then
        self.phase = "startup"
    elseif self.t < def.hitWindow[2] then
        self.phase = "active"
    else
        self.phase = "recovery"
    end

    if self.buffered and self:_cancelReached(def) then
        if self:_takeCancel(def) then
            return
        end
    elseif self.buffered then
        self:_tickBuffer(dt, def)
    end

    if self.t >= def.duration then
        self:_finishSwing()
    end
end

-- One connection per swing, the first time the live box overlaps a target.
function LightAttack:tryCommitHit(overlapping)
    if not self:hitboxActive() then
        self.hitLatched = false
        return false
    end
    if overlapping and not self.hitLatched then
        self.hitLatched = true
        return true
    end
    return false
end

function LightAttack:debug()
    local name = nil
    if self.active then
        name = Tuning.LIGHT[self.index].name
    end
    return {
        active = self.active,
        index = self.active and self.index or 0,
        name = name,
        t = self.t,
        phase = self.phase,
        canCancel = self:canCancel(),
        hitbox = self:hitboxActive(),
        held = self.buffered == true,
        restartQueued = self.restartQueued,
        comboIndex = self.comboIndex or 0,
        comboReset = self.comboReset or 0,
        bufferLeft = self.bufferLeft or 0,
    }
end

return LightAttack
