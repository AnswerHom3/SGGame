-- Presentation-only hit-stop. Listens for a successful hit and freezes time.
-- Damage, stagger, and the one-hit latch stay with the attacker.

local Tuning = require("combat.tuning")

local HitStop = {
    remaining = 0,
    _scene = nil,
    _lastMs = nil,
    _useSystemClock = false,
    _stall = 0,
}

local function systemMs()
    local clock = time
    if clock == nil then
        return nil
    end
    if clock.GetSystemTime ~= nil then
        local ok, value = pcall(function()
            return clock:GetSystemTime()
        end)
        if ok and type(value) == "number" then
            return value
        end
    end
    if type(clock.systemTime) == "number" then
        return clock.systemTime
    end
    return nil
end

local function writeScale(object, scale)
    if object == nil then
        return
    end
    if object.SetTimeScale ~= nil then
        local ok = pcall(function()
            object:SetTimeScale(scale)
        end)
        if ok then
            return
        end
    end
    pcall(function()
        object.timeScale = scale
    end)
end

-- Global time scale zeros Update's timestep, so it is only used when a
-- wall clock can expire the freeze. Scene scale freezes physics either way.
local function applyScale(frozen)
    writeScale(HitStop._scene, frozen and 0 or 1)
    if HitStop._useSystemClock then
        writeScale(time, frozen and 0 or 1)
    end
end

function HitStop.bind(scene)
    HitStop._scene = scene
end

function HitStop.active()
    return HitStop.remaining > 0
end

function HitStop.trigger(seconds)
    if seconds == nil then
        seconds = Tuning.HIT_STOP
    end
    if seconds == nil or seconds <= 0 then
        return
    end
    if seconds > HitStop.remaining then
        HitStop.remaining = seconds
    end
    HitStop._lastMs = systemMs()
    HitStop._useSystemClock = HitStop._lastMs ~= nil
    HitStop._stall = 0
    applyScale(true)
end

-- Returns 0 while this frame should stay frozen, 1 when gameplay time runs.
-- scaledDt is the engine Update timestep. It is 0 while global time scale is 0,
-- so a system clock advances the freeze in that case.
function HitStop.beginFrame(scaledDt)
    if HitStop.remaining <= 0 then
        return 1
    end

    local step = scaledDt or 0
    if step < 0 then
        step = 0
    end
    if HitStop._useSystemClock then
        local now = systemMs()
        if now ~= nil and HitStop._lastMs ~= nil then
            -- GetSystemTime is milliseconds on urhox / Urho.
            step = (now - HitStop._lastMs) / 1000
            if step < 0 then
                step = 0
            elseif step > 0.25 then
                step = 0.25
            end
        end
        if now ~= nil then
            HitStop._lastMs = now
        end
        -- A stuck clock plus a zeroed engine step would never expire.
        if step == 0 and (scaledDt or 0) == 0 then
            HitStop._stall = HitStop._stall + 1
            if HitStop._stall >= 8 then
                HitStop._useSystemClock = false
                writeScale(time, 1)
                HitStop._stall = 0
            end
        else
            HitStop._stall = 0
        end
    end

    HitStop.remaining = HitStop.remaining - step
    if HitStop.remaining > 0 then
        applyScale(true)
        return 0
    end

    HitStop.remaining = 0
    HitStop._lastMs = nil
    -- Restore while _useSystemClock is still set, so global scale goes back to 1.
    applyScale(false)
    HitStop._useSystemClock = false
    -- This frame already began frozen. Resume on the next one.
    return 0
end

function HitStop.reset()
    HitStop.remaining = 0
    HitStop._lastMs = nil
    HitStop._stall = 0
    applyScale(false)
    HitStop._useSystemClock = false
end

return HitStop
