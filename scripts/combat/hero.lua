-- Side-view hero: program root motion, jump, and the 3-hit light attack.
-- Position comes from the physics body. A light-clip change also bakes the
-- previous planted-foot ox into X so the sprite does not pop.

local Tuning = require("combat.tuning")
local LightAttack = require("combat.light_attack")
local LightAnim = require("combat.light_anim")

local Hero = {}
Hero.__index = Hero

local CAT_GROUND = 1
local CAT_BODY = 2
local CAT_FOOT = 4

function Hero.create(scene, x, y)
    local self = setmetatable({}, Hero)

    self.attack = LightAttack.new()
    self.anim = LightAnim.new()
    self.facing = 1
    self.onGround = false
    self.groundContacts = 0
    self.airBuffer = 0
    self.pendingJump = false
    self.commandAxis = 0
    self.locomT = 0
    self.locomClip = "idle"
    self.plantClip = nil
    self.plantOx = 0

    self.node = scene:CreateChild("HeroZhaoYun")
    self.node:SetPosition2D(x, y)

    self.body = self.node:CreateComponent("RigidBody2D")
    self.body.bodyType = BT_DYNAMIC
    self.body.fixedRotation = true
    self.body.linearDamping = 0
    self.body.angularDamping = 0
    self.body.gravityScale = 1
    self.body.bullet = false

    local shape = self.node:CreateComponent("CollisionBox2D")
    shape:SetSize(Tuning.HERO_BODY_W, Tuning.HERO_BODY_H)
    shape.density = 1
    shape.friction = 0
    shape.restitution = 0
    shape.categoryBits = CAT_BODY
    shape.maskBits = CAT_GROUND

    -- Same body as the box. A child sensor would not ride this rigid body.
    local foot = self.node:CreateComponent("CollisionCircle2D")
    foot.radius = Tuning.FOOT_SENSOR_R
    foot.center = Vector2(0, -Tuning.HERO_BODY_H * 0.5)
    foot.trigger = true
    foot.categoryBits = CAT_FOOT
    foot.maskBits = CAT_GROUND

    return self
end

function Hero:notifyGroundContact(began)
    if began then
        self.groundContacts = self.groundContacts + 1
    else
        self.groundContacts = self.groundContacts - 1
        if self.groundContacts < 0 then
            self.groundContacts = 0
        end
    end
    self.onGround = self.groundContacts > 0
end

function Hero:position()
    return self.node.position2D
end

-- Grounded move uses MOVE_CLIP (Run). A stop plays Idle.
function Hero:locomotionClip()
    if math.abs(self.commandAxis or 0) > 0 then
        return Tuning.MOVE_CLIP
    end
    return "idle"
end

function Hero:visualState()
    if self.attack:isAttacking() then
        return "light"
    end
    if self.anim:isRecovering() and self.onGround then
        return "light_recover"
    end
    if not self.onGround then
        return "jump"
    end
    return self:locomotionClip()
end

-- Sheet to draw. Attack and recover use the nominal root, not Idle's offset.
-- Scale is visual only and must not be written back onto the body.
function Hero:presentation()
    if self.attack:isAttacking() or (self.anim:isRecovering() and self.onGround) then
        local pres = self.anim:presentation()
        if pres ~= nil then
            return pres
        end
    end
    if not self.onGround then
        return { kind = "jump", clip = "jump", frame = 0 }
    end
    local clip = self:locomotionClip()
    local frame = Tuning.loopFrameIndex(
        Tuning.clipFrameCount(clip),
        Tuning.clipFps(clip),
        self.locomT or 0
    )
    local ox, oy = Tuning.clipDrawOffsetPx(clip)
    local rootX = Tuning.FOOT_PIVOT_X
    local rootY = Tuning.FOOT_PIVOT_Y
    local resource = Tuning.idleFrameResource(frame)
    if clip == "run" then
        rootX = Tuning.RUN_ROOT_X
        rootY = Tuning.RUN_ROOT_Y
        resource = Tuning.runFrameResource(frame)
    end
    return {
        kind = clip,
        clip = clip,
        frame = frame,
        resource = resource,
        rootX = rootX,
        rootY = rootY,
        offsetX = ox,
        offsetY = oy,
        scale = 1,
    }
end

function Hero:gripWorld()
    local p = self:position()
    return Tuning.spearGrip(p.x, p.y, self.facing)
end

function Hero:tipWorld()
    local p = self:position()
    return Tuning.spearTip(p.x, p.y, self.facing)
end

-- Box while a swing is playing, plus whether the hit window is live.
function Hero:attackBoxWorld()
    if not self.attack:isAttacking() then
        return nil
    end
    local p = self:position()
    local cx, cy, w, h = Tuning.attackBox(p.x, p.y, self.facing, self.attack:hitIndex())
    return cx, cy, w, h, self.attack:hitboxActive()
end

function Hero:commitHit(overlapping)
    return self.attack:tryCommitHit(overlapping)
end

function Hero:attackDebug()
    return self.attack:debug()
end

-- input.x is a horizontal axis in -1..1 (0 on release). Speed is axis * MOVE_SPEED,
-- written every frame, so letting go stops immediately.
-- input.bounds, when set, is the viewport in meters. Outward speed is cancelled there.
-- Same-frame jump and light: jump wins when the cancel window is open.
function Hero:update(dt, input)
    self.commandAxis = input.x or 0

    if self.airBuffer > 0 then
        self.airBuffer = self.airBuffer - dt
        if self.airBuffer < 0 then
            self.airBuffer = 0
        end
    end

    local attacking = self.attack:isAttacking()
    if self.commandAxis ~= 0 and not attacking then
        if self.commandAxis > 0 then
            self.facing = 1
        else
            self.facing = -1
        end
    end

    local canLeaveSwing = (not attacking) or self.attack:canCancel()
    if input.jump and self.onGround and canLeaveSwing then
        self.attack:cancel()
        self.anim:interrupt()
        self.pendingJump = true
        self.airBuffer = 0
    elseif input.light then
        if self.attack:isAttacking() or self.onGround then
            self.attack:request()
        else
            self.airBuffer = Tuning.INPUT_BUFFER_SEC
        end
    end

    if self.onGround and self.airBuffer > 0 and not self.attack:isAttacking() and not self.pendingJump then
        self.attack:request()
        self.airBuffer = 0
    end

    self.attack:update(dt)
    local groundedPose = self.onGround and not self.pendingJump
    self.anim:update(dt, self.attack, groundedPose)
    if not self.attack:isAttacking() and not self.anim:isRecovering() and groundedPose then
        local clip = self:locomotionClip()
        if clip ~= self.locomClip then
            self.locomClip = clip
            self.locomT = 0
        else
            self.locomT = self.locomT + dt
        end
    end

    local vx = 0
    if self.attack:isAttacking() then
        -- Hit-window lunge, same idea as a layout step. Speed 0 leaves vx at 0
        -- so the foot stays planted for the whole swing.
        if self.attack:hitboxActive() then
            local lunge = Tuning.attackLungeSpeed(self.attack:hitIndex())
            if lunge ~= 0 then
                vx = self.facing * lunge
            end
        end
    else
        vx = self.commandAxis * Tuning.MOVE_SPEED
    end

    local vy = self.body.linearVelocity.y
    if self.pendingJump then
        vy = Tuning.JUMP_SPEED
        self.pendingJump = false
        self.body.awake = true
    end

    if input.bounds ~= nil then
        local p = self:position()
        vx, vy = Tuning.clampVelocity(p.x, p.y, vx, vy, input.bounds)
    end

    self.body.linearVelocity = Vector2(vx, vy)
    self.body.awake = true
    self:_syncPlantedFoot()
end

-- Clip change: bake the previous plant ox into X (facing * actorScale),
-- then the new clip's draw offset applies. Idle clears the latch after the bake.
-- Frames inside one clip update ox only and do not move X.
function Hero:_syncPlantedFoot()
    local clip = nil
    local ox = 0
    if self.anim.mode == "mainline" or self.anim.mode == "recover" then
        local pres = self.anim:presentation()
        if pres ~= nil then
            clip = pres.clip
            ox = Tuning.lightFootSlideOffsetPx(clip, pres.frame or 0)
        end
    end
    local p = self:position()
    local x, nextClip, nextOx = Tuning.advancePlant(
        p.x, self.facing, self.plantClip, self.plantOx, clip, ox
    )
    self.plantClip = nextClip
    self.plantOx = nextOx
    if x ~= p.x then
        self.node:SetPosition2D(x, p.y)
    end
end

function Hero:clampInside(bounds)
    if bounds == nil then
        return
    end
    local p = self:position()
    local oldX, oldY = p.x, p.y
    local x, y = Tuning.clampPosition(oldX, oldY, bounds)
    local vel = self.body.linearVelocity
    -- Sheet scale and viewport bounds must not slide a planted attack foot.
    x = Tuning.keepLockedFootX(self.attack:isAttacking(), vel.x, oldX, x)
    if x == oldX and y == oldY then
        return
    end
    self.node:SetPosition2D(x, y)
    local vx = vel.x
    local vy = vel.y
    if x ~= oldX then
        vx = 0
    end
    if y ~= oldY then
        vy = 0
    end
    self.body.linearVelocity = Vector2(vx, vy)
    self.body.awake = true
end

return Hero
