-- 代号SG / Game004 combat prototype skeleton.
-- Side view. Move, jump, and a 3-hit light attack with provisional windows.
-- Visuals are colored blocks: the idle sheet is not on this branch, and Run
-- art is a tinted block on purpose. Root motion is the physics velocity.

local UI = require("urhox-libs/UI")
local Tuning = require("combat.tuning")
local Hero = require("combat.hero")

local CONFIG = {
    Title = "代号SG 战斗原型",
    CameraOrtho = 4.2,
    CameraLookY = 1.7,
}

---@type Scene
local scene_
---@type Node
local cameraNode_
---@type Camera
local camera_
---@type PhysicsWorld2D
local physicsWorld_
local nvg_ = nil
local uiRoot_ = nil

local hero_
local solids_ = {}
local dummy_ = { x = 2.55, y = 0.90, w = 0.70, h = 1.80, flash = 0, hits = 0 }
local debugDraw_ = false
local lightEdge_ = false
local jumpEdge_ = false

local STATE_LABEL = {
    idle = "待机",
    run = "跑（占位色块）",
    jump = "空中",
    light = "轻击",
}

local BLOCK_COLOR = {
    idle = { 212, 168, 72, 255 },
    run = { 64, 168, 176, 255 },
    jump = { 232, 206, 120, 255 },
    light = {
        { 214, 104, 48, 255 },
        { 224, 78, 64, 255 },
        { 186, 42, 42, 255 },
    },
}

local function aabbOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return math.abs(ax - bx) * 2 < (aw + bw)
        and math.abs(ay - by) * 2 < (ah + bh)
end

local function worldToScreen(x, y)
    local width = graphics:GetWidth()
    local height = graphics:GetHeight()
    if width < 1 or height < 1 or camera_ == nil or cameraNode_ == nil then
        return 0, 0
    end
    local cam = cameraNode_.position
    local halfH = camera_.orthoSize
    local halfW = halfH * (width / height)
    local sx = (x - cam.x) / (halfW * 2) * width + width * 0.5
    local sy = height * 0.5 - (y - cam.y) / (halfH * 2) * height
    return sx, sy
end

local function worldRect(cx, cy, w, h)
    local x0, y0 = worldToScreen(cx - w * 0.5, cy + h * 0.5)
    local x1, y1 = worldToScreen(cx + w * 0.5, cy - h * 0.5)
    return x0, y0, x1 - x0, y1 - y0
end

local function metersToPixels(meters)
    local height = graphics:GetHeight()
    if camera_ == nil or height < 1 then
        return 0
    end
    return meters / (camera_.orthoSize * 2) * height
end

function Start()
    Tuning.validate()

    graphics.windowTitle = CONFIG.Title

    nvg_ = nvgCreate(1)
    if nvg_ == nil then
        print("ERROR: nvgCreate failed")
        return
    end
    nvgCreateFont(nvg_, "sans", "Fonts/MiSans-Regular.ttf")

    UI.Init({
        fonts = {
            { family = "sans", weights = { normal = "Fonts/MiSans-Regular.ttf" } },
        },
        scale = UI.Scale.DEFAULT,
    })

    scene_ = Scene()
    scene_:CreateComponent("Octree")
    scene_:CreateComponent("DebugRenderer")

    physicsWorld_ = scene_:CreateComponent("PhysicsWorld2D")
    physicsWorld_.gravity = Vector2(0, -Tuning.GRAVITY)
    physicsWorld_.autoClearForces = true

    cameraNode_ = scene_:CreateChild("Camera")
    camera_ = cameraNode_:CreateComponent("Camera")
    camera_.orthographic = true
    camera_.orthoSize = CONFIG.CameraOrtho
    cameraNode_.position = Vector3(0, CONFIG.CameraLookY, -10)
    renderer:SetViewport(0, Viewport:new(scene_, camera_))

    solids_ = {
        addStaticBox("Ground", 0, -0.5, 36, 1),
        addStaticBox("Platform", 6.2, 1.275, 2.6, 0.35),
    }

    hero_ = Hero.create(scene_, -0.4, 2.2)

    uiRoot_ = UI.Panel {
        id = "gameUI",
        width = "100%",
        height = "100%",
        pointerEvents = "box-none",
        children = {
            UI.Label {
                text = CONFIG.Title,
                fontSize = 16,
                fontColor = { 255, 255, 255, 230 },
                position = "absolute",
                top = 12,
                left = 16,
            },
            UI.Label {
                text = "A/D 或 ←/→ 移动    Space / W / ↑ 跳跃    J 轻击三连    Z 物理调试",
                fontSize = 13,
                fontColor = { 220, 220, 220, 210 },
                position = "absolute",
                top = 36,
                left = 16,
            },
            UI.Label {
                id = "stateLabel",
                text = "",
                fontSize = 13,
                fontColor = { 255, 214, 150, 230 },
                position = "absolute",
                top = 58,
                left = 16,
            },
            UI.Panel {
                position = "absolute",
                bottom = 20,
                left = 20,
                width = 96,
                pointerEvents = "auto",
                children = {
                    UI.Button {
                        text = "跳跃",
                        onClick = function()
                            jumpEdge_ = true
                        end,
                    },
                },
            },
            UI.Panel {
                position = "absolute",
                bottom = 20,
                right = 20,
                width = 96,
                pointerEvents = "auto",
                children = {
                    UI.Button {
                        text = "轻击",
                        variant = "primary",
                        onClick = function()
                            lightEdge_ = true
                        end,
                    },
                },
            },
        },
    }
    UI.SetRoot(uiRoot_)

    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("PostUpdate", "HandlePostUpdate")
    SubscribeToEvent(nvg_, "NanoVGRender", "HandleRender")
    SubscribeToEvent("PhysicsBeginContact2D", "HandlePhysicsBeginContact")
    SubscribeToEvent("PhysicsEndContact2D", "HandlePhysicsEndContact")

    local visual = Tuning.visualContract()
    print("=== " .. CONFIG.Title .. " ===")
    print("Move A/D, jump Space, light attack J. Numbers are provisional.")
    print(string.format(
        "Visual %s, run %s, spear %s, idle contract %s @ %.2f fps, foot (%d,%d), drawOffsetX %.1f px",
        visual.mode,
        visual.run,
        visual.spearHand,
        visual.idleFrame0,
        visual.idleFps,
        visual.footPivot[1],
        visual.footPivot[2],
        visual.drawOffsetPx[1]
    ))
end

function Stop()
    UI.Shutdown()
    if nvg_ ~= nil then
        nvgDelete(nvg_)
        nvg_ = nil
    end
end

function addStaticBox(name, x, y, w, h)
    local node = scene_:CreateChild(name)
    node:SetPosition2D(x, y)

    local body = node:CreateComponent("RigidBody2D")
    body.bodyType = BT_STATIC

    local shape = node:CreateComponent("CollisionBox2D")
    shape:SetSize(w, h)
    shape.friction = 0.4
    shape.restitution = 0
    shape.categoryBits = 1
    shape.maskBits = 65535

    return { name = name, x = x, y = y, w = w, h = h }
end

local function isGroundName(node)
    if node == nil or node.name == nil then
        return false
    end
    return node.name == "Ground" or node.name == "Platform"
end

local function otherBodyNode(nodeA, nodeB)
    if hero_ == nil then
        return nil
    end
    if nodeA == hero_.node then
        return nodeB
    end
    if nodeB == hero_.node then
        return nodeA
    end
    return nil
end

function HandlePhysicsBeginContact(eventType, eventData)
    local nodeA = eventData["NodeA"]:GetPtr("Node")
    local nodeB = eventData["NodeB"]:GetPtr("Node")
    local other = otherBodyNode(nodeA, nodeB)
    if isGroundName(other) then
        hero_:notifyGroundContact(true)
    end
end

function HandlePhysicsEndContact(eventType, eventData)
    local nodeA = eventData["NodeA"]:GetPtr("Node")
    local nodeB = eventData["NodeB"]:GetPtr("Node")
    local other = otherBodyNode(nodeA, nodeB)
    if isGroundName(other) then
        hero_:notifyGroundContact(false)
    end
end

local function moveAxis()
    local x = 0
    if input:GetKeyDown(KEY_A) or input:GetKeyDown(KEY_LEFT) then
        x = x - 1
    end
    if input:GetKeyDown(KEY_D) or input:GetKeyDown(KEY_RIGHT) then
        x = x + 1
    end
    return x
end

local function consumePresses()
    local light = lightEdge_ or input:GetKeyPress(KEY_J)
    local jump = jumpEdge_
        or input:GetKeyPress(KEY_SPACE)
        or input:GetKeyPress(KEY_W)
        or input:GetKeyPress(KEY_UP)
    lightEdge_ = false
    jumpEdge_ = false
    return light, jump
end

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    if hero_ == nil then
        return
    end

    local dt = eventData["TimeStep"]:GetFloat()
    if input:GetKeyPress(KEY_Z) then
        debugDraw_ = not debugDraw_
    end

    local light, jump = consumePresses()
    hero_:update(dt, { x = moveAxis(), jump = jump, light = light })

    if dummy_.flash > 0 then
        dummy_.flash = dummy_.flash - dt
        if dummy_.flash < 0 then
            dummy_.flash = 0
        end
    end
end

function refreshHud()
    if uiRoot_ == nil or hero_ == nil then
        return
    end
    local label = uiRoot_:FindById("stateLabel") --[[@as Label?]]
    if label == nil then
        return
    end

    local atk = hero_:attackDebug()
    local state = STATE_LABEL[hero_:visualState()] or hero_:visualState()
    local facing = "右"
    if hero_.facing < 0 then
        facing = "左"
    end

    local text
    if atk.active then
        local cancel = "关"
        if atk.canCancel then
            cancel = "开"
        end
        local live = "无"
        if atk.hitbox then
            live = "生效"
        end
        text = string.format(
            "%s %s  朝向%s  t=%.2f  取消%s  判定%s  木桩%d  | 右手持枪  数值占位",
            state,
            atk.name or "",
            facing,
            atk.t,
            cancel,
            live,
            dummy_.hits
        )
    else
        text = string.format(
            "%s  朝向%s  木桩%d  | 右手持枪  数值占位",
            state,
            facing,
            dummy_.hits
        )
    end
    label:SetText(text)
end

---@param eventType string
---@param eventData PostUpdateEventData
function HandlePostUpdate(eventType, eventData)
    if hero_ == nil or cameraNode_ == nil then
        return
    end
    local pos = hero_:position()
    cameraNode_.position = Vector3(pos.x, CONFIG.CameraLookY, -10)

    -- Physics has stepped, so the spear box includes this frame's lunge.
    local cx, cy, w, h = hero_:attackBoxWorld()
    local overlapping = false
    if cx ~= nil then
        overlapping = aabbOverlap(cx, cy, w, h, dummy_.x, dummy_.y, dummy_.w, dummy_.h)
    end
    if hero_:commitHit(overlapping) then
        dummy_.hits = dummy_.hits + 1
        dummy_.flash = 0.12
        print(string.format("light hit %d -> dummy (%d)", hero_:attackDebug().index, dummy_.hits))
    end

    refreshHud()
end

local function fillWorldRect(vg, cx, cy, w, h, r, g, b, a)
    local x, y, rw, rh = worldRect(cx, cy, w, h)
    nvgBeginPath(vg)
    nvgRect(vg, x, y, rw, rh)
    nvgFillColor(vg, nvgRGBA(r, g, b, a))
    nvgFill(vg)
end

local function strokeWorldRect(vg, cx, cy, w, h, r, g, b, a, width)
    local x, y, rw, rh = worldRect(cx, cy, w, h)
    nvgBeginPath(vg)
    nvgRect(vg, x, y, rw, rh)
    nvgStrokeWidth(vg, width)
    nvgStrokeColor(vg, nvgRGBA(r, g, b, a))
    nvgStroke(vg)
end

function HandleRender(eventType, eventData)
    if nvg_ == nil or hero_ == nil then
        return
    end

    local width = graphics:GetWidth()
    local height = graphics:GetHeight()
    nvgBeginFrame(nvg_, width, height, 1.0)

    nvgBeginPath(nvg_)
    nvgRect(nvg_, 0, 0, width, height)
    local bg = nvgLinearGradient(
        nvg_, 0, 0, 0, height,
        nvgRGBA(18, 24, 38, 255),
        nvgRGBA(48, 36, 42, 255)
    )
    nvgFillPaint(nvg_, bg)
    nvgFill(nvg_)

    for _, solid in ipairs(solids_) do
        local r, g, b = 92, 74, 52
        if solid.name == "Platform" then
            r, g, b = 120, 108, 84
        end
        fillWorldRect(nvg_, solid.x, solid.y, solid.w, solid.h, r, g, b, 255)
        strokeWorldRect(nvg_, solid.x, solid.y, solid.w, solid.h, 40, 32, 24, 255, 2)
    end

    -- Meter ticks on the ground top (y = 0) so program motion is easy to see.
    for meter = -8, 12 do
        fillWorldRect(nvg_, meter, 0.04, 0.04, 0.12, 210, 196, 160, 180)
    end

    local dr, dg, db, da = 150, 48, 58, 255
    if dummy_.flash > 0 then
        dr, dg, db = 255, 236, 220
    end
    fillWorldRect(nvg_, dummy_.x, dummy_.y, dummy_.w, dummy_.h, dr, dg, db, da)
    strokeWorldRect(nvg_, dummy_.x, dummy_.y, dummy_.w, dummy_.h, 80, 20, 28, 255, 2)

    drawHero(nvg_)

    if debugDraw_ then
        drawDebugText(nvg_)
    end

    nvgEndFrame(nvg_)

    if debugDraw_ and physicsWorld_ ~= nil then
        physicsWorld_:DrawDebugGeometry()
    end
end

function drawHero(vg)
    local pos = hero_:position()
    local state = hero_:visualState()
    local color = BLOCK_COLOR[state]
    if state == "light" then
        local index = hero_:attackDebug().index
        color = BLOCK_COLOR.light[index] or BLOCK_COLOR.light[1]
    end

    local footY = pos.y - Tuning.HERO_BODY_H * 0.5
    fillWorldRect(vg, pos.x, footY, Tuning.HERO_BODY_W * 1.15, 0.08, 0, 0, 0, 70)
    fillWorldRect(vg, pos.x, pos.y, Tuning.HERO_BODY_W, Tuning.HERO_BODY_H, color[1], color[2], color[3], color[4])
    strokeWorldRect(vg, pos.x, pos.y, Tuning.HERO_BODY_W, Tuning.HERO_BODY_H, 30, 24, 18, 255, 2)

    -- Face notch on the forward side so facing reads without a sprite.
    local faceX = pos.x + hero_.facing * (Tuning.HERO_BODY_W * 0.5 + 0.04)
    local faceY = pos.y + Tuning.HERO_BODY_H * 0.28
    fillWorldRect(vg, faceX, faceY, 0.10, 0.16, 40, 32, 24, 255)

    local gx, gy = hero_:gripWorld()
    local tx, ty = hero_:tipWorld()
    -- Shaft is a row of blocks from the right-hand grip to the tip.
    -- nvgRect / nvgCircle are the sprite-free primitives this skeleton draws with.
    local steps = 5
    for i = 0, steps do
        local t = i / steps
        local x = gx + (tx - gx) * t
        local y = gy + (ty - gy) * t
        fillWorldRect(vg, x, y, 0.07, 0.07, 196, 176, 140, 255)
    end

    fillWorldRect(vg, gx, gy, 0.14, 0.14, 232, 196, 156, 255)
    local tsx, tsy = worldToScreen(tx, ty)
    nvgBeginPath(vg)
    nvgCircle(vg, tsx, tsy, metersToPixels(0.07))
    nvgFillColor(vg, nvgRGBA(210, 214, 220, 255))
    nvgFill(vg)

    local cx, cy, w, h, live = hero_:attackBoxWorld()
    if cx ~= nil then
        if live then
            fillWorldRect(vg, cx, cy, w, h, 255, 64, 48, 90)
            strokeWorldRect(vg, cx, cy, w, h, 255, 80, 64, 230, 2)
        else
            strokeWorldRect(vg, cx, cy, w, h, 255, 180, 120, 110, 1)
        end
    end
end

function drawDebugText(vg)
    local pos = hero_:position()
    local vel = hero_.body.linearVelocity
    local atk = hero_:attackDebug()
    nvgFontSize(vg, 16)
    nvgFontFace(vg, "sans")
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 255))
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgText(vg, 16, 88, string.format(
        "pos (%.2f, %.2f)  vel (%.2f, %.2f)\nground %s  facing %d  phase %s  held %s",
        pos.x, pos.y, vel.x, vel.y,
        tostring(hero_.onGround),
        hero_.facing,
        atk.phase,
        tostring(atk.held)
    ), nil)
end
