-- Sheet player for Zhao Yun light attacks.
-- Mainline frames follow the swing clock (target duration → frame).
-- light1_recover / light2_recover play only after a natural end (no next hit).
-- light3_recover plays once after light3 when nothing restarts the string.
-- A chain, a queued light3 restart, or a jump cancel does not bake those branches in.

local Tuning = require("combat.tuning")

local LightAnim = {}
LightAnim.__index = LightAnim

function LightAnim.new()
    local self = setmetatable({}, LightAnim)
    self:interrupt()
    return self
end

function LightAnim:interrupt()
    self.mode = "none"
    self.clip = nil
    self.frame = 0
    self.t = 0
    self.recoverFrom = 0
end

function LightAnim:isRecovering()
    return self.mode == "recover"
end

function LightAnim:_startRecover(name, fromIndex)
    self.mode = "recover"
    self.clip = name
    self.t = 0
    self.frame = 0
    self.recoverFrom = fromIndex or 0
end

function LightAnim:update(dt, attack, grounded)
    if dt < 0 then
        dt = 0
    end

    if attack:isAttacking() then
        attack.endedNaturally = false
        attack.finishedIndex = 0
        local index = attack:hitIndex()
        local name = Tuning.LIGHT[index].name
        self.mode = "mainline"
        self.clip = name
        self.t = attack.t
        self.frame = Tuning.playFrameIndex(name, attack.t)
        self.recoverFrom = 0
        return
    end

    local finished = 0
    if attack.endedNaturally then
        finished = attack.finishedIndex or 0
        attack.endedNaturally = false
        attack.finishedIndex = 0
    end

    if not grounded then
        self:interrupt()
        return
    end

    if finished >= 1 then
        local spec = Tuning.ATK_LIGHT_CLIPS[Tuning.LIGHT[finished].name]
        if spec.recover ~= nil then
            self:_startRecover(spec.recover, finished)
            return
        end
    end

    if self.mode == "recover" then
        self.t = self.t + dt
        local spec = Tuning.ATK_LIGHT_CLIPS[self.clip]
        if self.t >= spec.duration then
            self:interrupt()
            return
        end
        self.frame = Tuning.playFrameIndex(self.clip, self.t)
    end
end

function LightAnim:presentation()
    if self.mode ~= "mainline" and self.mode ~= "recover" then
        return nil
    end
    local kind = "light"
    if self.mode == "recover" then
        kind = "light_recover"
    end
    local spec = Tuning.ATK_LIGHT_CLIPS[self.clip]
    local scale = Tuning.ATK_LIGHT_RENDER_SCALE
    if spec ~= nil and spec.renderScale ~= nil then
        scale = spec.renderScale
    end
    return {
        kind = kind,
        clip = self.clip,
        frame = self.frame,
        resource = Tuning.lightFrameResource(self.clip, self.frame),
        rootX = Tuning.ATK_LIGHT_ROOT_X,
        rootY = Tuning.ATK_LIGHT_ROOT_Y,
        offsetX = Tuning.ATK_LIGHT_DRAW_OFFSET_X_PX,
        offsetY = Tuning.ATK_LIGHT_DRAW_OFFSET_Y_PX,
        scale = scale,
    }
end

local function step(attack, anim, dt)
    attack:update(dt)
    anim:update(dt, attack, true)
end

function LightAnim.check()
    local LightAttack = require("combat.light_attack")

    local attack = LightAttack.new()
    local anim = LightAnim.new()
    attack:request()
    step(attack, anim, 0)
    assert(anim.mode == "mainline" and anim.clip == "light1" and anim.frame == 0, "light1 opens on frame 0")
    local pres = anim:presentation()
    assert(
        pres ~= nil and math.abs(pres.scale - Tuning.ATK_LIGHT_RENDER_SCALE) < 1e-9,
        "light sheet draws at the idle-matching render scale"
    )

    step(attack, anim, 0.40)
    assert(anim.mode == "recover" and anim.clip == "light1_recover" and anim.frame == 0, "no press plays light1 recover")
    assert(attack.comboIndex == 1 and attack.comboReset > 0, "combo window still open during recover")
    assert(Tuning.LIGHT_COMBO_RESET == 0.5, "combo reset unchanged")
    assert(Tuning.LIGHT_INPUT_BUFFER == 0.10, "input buffer unchanged")
    assert(Tuning.HIT_STOP == 0.10, "hit stop unchanged")

    attack:request()
    step(attack, anim, 0)
    assert(attack:hitIndex() == 2 and anim.mode == "mainline" and anim.clip == "light2", "press during recover continues")

    attack = LightAttack.new()
    anim = LightAnim.new()
    attack:request()
    step(attack, anim, 0.20)
    attack:request()
    attack:request()
    step(attack, anim, 0)
    assert(anim.mode == "mainline" and anim.clip == "light1", "mash before the chain hold does not skip light1")
    assert(attack.buffered == true, "the mash keeps one buffer")
    step(attack, anim, 0.17)
    assert(anim.mode == "mainline" and anim.clip == "light2", "buffered press chains after impact plus chain hold")

    step(attack, anim, 0.545)
    attack:request()
    step(attack, anim, 0)
    assert(anim.clip == "light3" and anim.mode == "mainline", "light2 chains into the downward slash")
    step(attack, anim, 0.62)
    assert(anim.mode == "recover" and anim.clip == "light3_recover", "clean light3 plays its own recover once")
    assert(anim.clip ~= "light1_recover" and anim.clip ~= "light2_recover", "1/2 recover stays off the mainline")

    local recoverDur = Tuning.ATK_LIGHT_CLIPS.light3_recover.duration
    step(attack, anim, recoverDur - 0.0001)
    assert(anim.mode == "recover" and anim.frame == 14, "light3 recover holds the last source frame")
    step(attack, anim, 0.001)
    assert(anim.mode == "none", "recover returns to idle")

    attack = LightAttack.new()
    anim = LightAnim.new()
    attack:request()
    step(attack, anim, 0.36)
    attack:request()
    step(attack, anim, 0.545)
    attack:request()
    step(attack, anim, 0.53)
    attack:request()
    step(attack, anim, 0.10)
    assert(attack:hitIndex() == 1 and anim.mode == "mainline" and anim.clip == "light1", "queued light3 restart skips recover")

    attack = LightAttack.new()
    anim = LightAnim.new()
    attack:request()
    step(attack, anim, 0.05)
    attack:cancel()
    anim:interrupt()
    step(attack, anim, 0.50)
    assert(anim.mode == "none" and not attack:isAttacking(), "jump cancel does not start recover")

    attack = LightAttack.new()
    anim = LightAnim.new()
    attack:request()
    step(attack, anim, 0.40)
    step(attack, anim, 0.50)
    assert(anim.mode == "recover" and attack.comboReset == 0, "recover outlasts the combo window")
    attack:request()
    step(attack, anim, 0)
    assert(attack:hitIndex() == 1 and anim.clip == "light1", "expired combo restarts at light1")

    attack = LightAttack.new()
    anim = LightAnim.new()
    attack:request()
    step(attack, anim, 0.10)
    anim:update(0, attack, false)
    assert(anim.mode == "mainline", "airborne swing keeps the mainline sheet")
    attack:update(0.40)
    anim:update(0, attack, false)
    assert(anim.mode == "none", "an airborne ending does not play ground recover")
end

return LightAnim
