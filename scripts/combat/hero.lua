-- Side-view hero: program root motion, jump, and the 3-hit light attack.
-- Position comes from the physics body, never from a sprite.

local Tuning = require("combat.tuning")
local LightAttack = require("combat.light_attack")

local Hero = {}
Hero.__index = Hero

local CAT_GROUND = 1
local CAT_BODY = 2
local CAT_FOOT = 4

function Hero.create(scene, x, y)
    local self = setmetatable({}, Hero)

    self.attack = LightAttack.new()
    self.facing = 1
    self.onGround = false
    self.groundContacts = 0
    self.airBuffer = 0
    self.pendingJump = false
    self.commandAxis = 0

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
    if not self.onGround then
        return "jump"
    end
    return self:locomotionClip()
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

    local vx = 0
    if self.attack:isAttacking() then
        if self.attack:hitboxActive() then
            vx = self.facing * Tuning.LUNGE_SPEED[self.attack:hitIndex()]
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
end

function Hero:clampInside(bounds)
    if bounds == nil then
        return
    end
    local p = self:position()
    local oldX, oldY = p.x, p.y
    local x, y = Tuning.clampPosition(oldX, oldY, bounds)
    if x == oldX and y == oldY then
        return
    end
    self.node:SetPosition2D(x, y)
    local vel = self.body.linearVelocity
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
