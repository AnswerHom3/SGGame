-- 3-hit light attack. Windows live in combat.tuning and are provisional.
--
-- Press during a swing is held until that swing's cancel window:
--   cancelInto "next" -> start the next hit immediately
--   cancelInto "end"  -> remember a restart, fire it when the swing ends
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
    self.active = false
    self.index = 0
    self.t = 0
    self.lastDt = 0
    self.held = false
    self.restartQueued = false
    self.hitLatched = false
    self.phase = "none"
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
    self.held = false
    self.restartQueued = false
    self.hitLatched = false
    self.phase = "startup"
end

function LightAttack:request()
    if not self.active then
        self:_begin(1)
        return
    end

    local def = self:_def()
    if self:_in(def.cancelWindow) and def.cancelInto == "next" then
        self:_begin(self.index + 1)
        return
    end
    if self:_in(def.cancelWindow) and def.cancelInto == "end" then
        self.restartQueued = true
        self.held = false
        return
    end

    self.held = true
end

function LightAttack:update(dt)
    if not self.active then
        self.phase = "none"
        return
    end

    if dt < 0 then
        dt = 0
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

    if self.held and self:_overlaps(def.cancelWindow) then
        if def.cancelInto == "next" then
            self:_begin(self.index + 1)
            return
        end
        if def.cancelInto == "end" then
            self.restartQueued = true
            self.held = false
        end
    end

    if self.t >= def.duration then
        local restart = self.restartQueued
        self:cancel()
        if restart then
            self:_begin(1)
        end
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
        held = self.held,
        restartQueued = self.restartQueued,
    }
end

return LightAttack
