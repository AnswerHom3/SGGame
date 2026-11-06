-- 代号SG / Game004 combat prototype skeleton.
-- Side view. Move, jump, and a 3-hit light attack.
-- Grounded move plays Run at 8 fps. A stop plays Idle at 10 fps with Idle's offset.
-- Light mainline maps swing time onto the target duration. Recover branches play
-- at source-mean fps. Attack sheets use root (128, 248), not Idle's draw offset.
-- Lunge is 0. Per-frame foot offsets do not move the body. A clip change
-- bakes the previous plant ox into X before the new clip's offset.

local UI = require("urhox-libs/UI")
local Tuning = require("combat.tuning")
local Hero = require("combat.hero")
local MoveInput = require("combat.move_input")
local HitStop = require("combat.hit_stop")
local HeroSheet = require("combat.hero_sheet")
local AtkLightConfig = require("AtkLightConfig")

local CONFIG = {
    Title = "代号SG 战斗原型",
    CameraOrtho = 4.2,
    CameraLookX = 0,
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
local moveInput_
local solids_ = {}
local dummy_ = { x = 2.55, y = 0.90, w = 0.70, h = 1.80, flash = 0, hits = 0 }
local debugDraw_ = false
local lightEdge_ = false
local jumpEdge_ = false

local STATE_LABEL = {
    idle = "待机",
    run = "奔跑",
    jump = "空中",
    light = "轻击",
    light_recover = "收招",
}

local BLOCK_COLOR = {
    idle = { 212, 168, 72, 255 },
    run = { 92, 148, 196, 255 },
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
    -- Maker keeps these on resources preload_groups=default.
    -- Here the cache fetches every literal atk_light path before the first swing.
    if cache ~= nil then
        cache:DownloadResources(AtkLightConfig.allPaths())
    end
    HeroSheet.preload(nvg_, Tuning.allHeroSheetResources())

    UI.Init({
        fonts = {
            { family = "sans", weights = { normal = "Fonts/MiSans-Regular.ttf" } },
        },
        scale = UI.Scale.DEFAULT,
    })

    scene_ = Scene()
    HitStop.bind(scene_)
    HitStop.reset()
    scene_:CreateComponent("Octree")
    scene_:CreateComponent("DebugRenderer")

    physicsWorld_ = scene_:CreateComponent("PhysicsWorld2D")
    physicsWorld_.gravity = Vector2(0, -Tuning.GRAVITY)
    physicsWorld_.autoClearForces = true

    cameraNode_ = scene_:CreateChild("Camera")
    camera_ = cameraNode_:CreateComponent("Camera")
    camera_.orthographic = true
    camera_.orthoSize = CONFIG.CameraOrtho
    cameraNode_.position = Vector3(CONFIG.CameraLookX, CONFIG.CameraLookY, -10)
    moveInput_ = MoveInput.new()
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
                text = "左下摇杆左右移动    A/D 或 ←/→    Space / W / ↑ 跳跃    J 轻击    Z 调试",
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
                right = 124,
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
    print("Stick bottom-left, or A/D. Jump Space, light attack J. Numbers are provisional.")
    print(string.format(
        "Visual %s, grounded move %s %d @ %d fps root (%d,%d) drawOffset (%.0f,%.0f), stopped idle @ %d fps drawOffset (%.0f,%.0f), light root (%d,%d) renderScale %.3f (sheet fit %.1f%% of idle) lunge 0, spear %s",
        visual.mode,
        visual.moveClip,
        visual.runFrameCount,
        visual.runFps,
        visual.runRoot[1],
        visual.runRoot[2],
        visual.runDrawOffsetPx[1],
        visual.runDrawOffsetPx[2],
        visual.idleFps,
        visual.drawOffsetPx[1],
        visual.drawOffsetPx[2],
        visual.atkLightRoot[1],
        visual.atkLightRoot[2],
        visual.atkLightRenderScale,
        visual.atkLightRelativeToIdle * 100,
        visual.spearHand
    ))
end

function Stop()
    HitStop.reset()
    HeroSheet.release(nvg_)
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

local function keyboardAxis()
    local x = 0
    if input:GetKeyDown(KEY_A) or input:GetKeyDown(KEY_LEFT) then
        x = x - 1
    end
    if input:GetKeyDown(KEY_D) or input:GetKeyDown(KEY_RIGHT) then
        x = x + 1
    end
    return x
end

local function viewportBounds()
    local width = graphics:GetWidth()
    local height = graphics:GetHeight()
    if width < 1 or height < 1 or camera_ == nil or cameraNode_ == nil then
        return nil
    end
    local halfH = camera_.orthoSize
    local halfW = halfH * (width / height)
    local cam = cameraNode_.position
    local padX = Tuning.HERO_BODY_W * 0.5
    local padY = Tuning.HERO_BODY_H * 0.5
    return {
        minX = cam.x - halfW + padX,
        maxX = cam.x + halfW - padX,
        minY = cam.y - halfH + padY,
        maxY = cam.y + halfH - padY,
    }
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
    if HitStop.beginFrame(dt) == 0 then
        dt = 0
    end
    if input:GetKeyPress(KEY_Z) then
        debugDraw_ = not debugDraw_
    end

    local light, jump = consumePresses()
    if moveInput_ ~= nil then
        moveInput_:update(graphics:GetWidth(), graphics:GetHeight())
    end
    local stickAxis = 0
    if moveInput_ ~= nil then
        stickAxis = moveInput_.axis
    end
    local axis = Tuning.combineMoveAxis(stickAxis, keyboardAxis())
    hero_:update(dt, {
        x = axis,
        jump = jump,
        light = light,
        bounds = viewportBounds(),
    })

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
    local clip = hero_:visualState()
    local state = STATE_LABEL[clip] or clip
    local pres = hero_:presentation()
    if clip ~= "light" and clip ~= "light_recover" and not atk.active and hero_.onGround and math.abs(hero_.commandAxis) > 0 then
        state = string.format("移动 %d%% · Run", math.floor(math.abs(hero_.commandAxis) * 100 + 0.5))
    end
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
        local frameShown = 1
        if pres.frame ~= nil then
            frameShown = pres.frame + 1
        end
        text = string.format(
            "%s %s 帧%d  朝向%s  t=%.2f  取消%s  判定%s  木桩%d  | 右手持枪  脚锁定",
            state,
            pres.clip or atk.name or "",
            frameShown,
            facing,
            atk.t,
            cancel,
            live,
            dummy_.hits
        )
    elseif pres.kind == "light_recover" then
        local frameShown = 1
        if pres.frame ~= nil then
            frameShown = pres.frame + 1
        end
        text = string.format(
            "%s %s 帧%d  朝向%s  木桩%d  | 右手持枪",
            state,
            pres.clip or "",
            frameShown,
            facing,
            dummy_.hits
        )
        if atk.comboReset > 0 then
            text = string.format("%s  连段%.2f", text, atk.comboReset)
        end
    else
        text = string.format(
            "%s  朝向%s  木桩%d  | 右手持枪  数值占位",
            state,
            facing,
            dummy_.hits
        )
        if atk.comboReset > 0 then
            text = string.format("%s  连段%.2f", text, atk.comboReset)
        end
    end
    if HitStop.active() then
        text = text .. "  顿帧"
    end
    label:SetText(text)
end

---@param eventType string
---@param eventData PostUpdateEventData
function HandlePostUpdate(eventType, eventData)
    if hero_ == nil or cameraNode_ == nil then
        return
    end
    cameraNode_.position = Vector3(CONFIG.CameraLookX, CONFIG.CameraLookY, -10)
    hero_:clampInside(viewportBounds())

    -- Physics has stepped. Lunge is 0, so a live box does not drag the foot.
    local cx, cy, w, h = hero_:attackBoxWorld()
    local overlapping = false
    if cx ~= nil then
        overlapping = aabbOverlap(cx, cy, w, h, dummy_.x, dummy_.y, dummy_.w, dummy_.h)
    end
    -- Damage stays on the hit counter. Hit-stop only freezes presentation time.
    if hero_:commitHit(overlapping) then
        dummy_.hits = dummy_.hits + 1
        dummy_.flash = 0.12
        HitStop.trigger(Tuning.HIT_STOP)
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

    if moveInput_ ~= nil then
        moveInput_:draw(nvg_, width, height)
    end

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
    local pres = hero_:presentation()
    local footX = pos.x
    local footY = pos.y - Tuning.HERO_BODY_H * 0.5
    fillWorldRect(vg, footX, footY, Tuning.HERO_BODY_W * 1.15, 0.08, 0, 0, 0, 70)

    -- Visual only. render scale and frame bounds must not write body X.
    -- Attack and recover blit the slide-only foot offset on top of the clip
    -- offset, including the last frame held through the chain window.
    local drew = false
    if pres.resource ~= nil then
        local image = HeroSheet.get(vg, pres.resource)
        if image ~= nil then
            local scale = pres.scale or 1
            local offX = pres.offsetX or 0
            local offY = pres.offsetY or 0
            if pres.kind == "light" or pres.kind == "light_recover" then
                offX, offY = Tuning.lightDrawOffsetPx(pres.clip, pres.frame or 0)
                scale = pres.scale or Tuning.ATK_LIGHT_RENDER_SCALE
            end
            local metersPerPx = (Tuning.HERO_DRAW_H / Tuning.CANVAS) * scale
            local ppm = metersToPixels(metersPerPx)
            local rootSx, rootSy = worldToScreen(footX, footY)
            drew = HeroSheet.blit(
                vg, image, rootSx, rootSy, ppm, hero_.facing,
                pres.rootX or Tuning.ATK_LIGHT_ROOT_X,
                pres.rootY or Tuning.ATK_LIGHT_ROOT_Y,
                offX, offY,
                Tuning.CANVAS
            )
        end
    end

    if not drew then
        local state = hero_:visualState()
        local color = BLOCK_COLOR[state]
        if state == "light" or state == "light_recover" then
            local index = hero_:attackDebug().index
            if index == 0 then
                index = 1
            end
            color = BLOCK_COLOR.light[index] or BLOCK_COLOR.light[1]
        end
        if color == nil then
            color = BLOCK_COLOR.idle
        end
        fillWorldRect(vg, pos.x, pos.y, Tuning.HERO_BODY_W, Tuning.HERO_BODY_H, color[1], color[2], color[3], color[4])
        strokeWorldRect(vg, pos.x, pos.y, Tuning.HERO_BODY_W, Tuning.HERO_BODY_H, 30, 24, 18, 255, 2)
        local faceX = pos.x + hero_.facing * (Tuning.HERO_BODY_W * 0.5 + 0.04)
        local faceY = pos.y + Tuning.HERO_BODY_H * 0.28
        fillWorldRect(vg, faceX, faceY, 0.10, 0.16, 40, 32, 24, 255)
        local gx, gy = hero_:gripWorld()
        local tx, ty = hero_:tipWorld()
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
    end

    if debugDraw_ and (pres.kind == "light" or pres.kind == "light_recover") then
        local tipX, tipY, backup = Tuning.lightArtTipForDebug(pres.clip, pres.frame)
        if tipX ~= nil then
            local tipOffX, tipOffY = Tuning.lightDrawOffsetPx(pres.clip, pres.frame or 0)
            local wx, wy = Tuning.sheetPointToWorld(
                footX, footY, hero_.facing, tipX, tipY,
                pres.rootX, pres.rootY, tipOffX, tipOffY,
                pres.scale or Tuning.ATK_LIGHT_RENDER_SCALE
            )
            local sx, sy = worldToScreen(wx, wy)
            nvgBeginPath(vg)
            nvgCircle(vg, sx, sy, 4)
            if backup then
                nvgFillColor(vg, nvgRGBA(255, 196, 64, 230))
            else
                nvgFillColor(vg, nvgRGBA(230, 240, 255, 230))
            end
            nvgFill(vg)
        end
    end

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
    local pres = hero_:presentation()
    local tip = ""
    if pres.clip ~= nil then
        local _, _, backup = Tuning.lightArtTipForDebug(pres.clip, pres.frame or 0)
        if backup then
            tip = "  tip=f017-backup"
        end
    end
    nvgFontSize(vg, 16)
    nvgFontFace(vg, "sans")
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 255))
    nvgTextAlign(vg, NVG_ALIGN_LEFT + NVG_ALIGN_TOP)
    nvgText(vg, 16, 88, string.format(
        "pos (%.2f, %.2f)  vel (%.2f, %.2f)\nground %s  facing %d  phase %s  held %s  combo %.2f  %s f%03d%s",
        pos.x, pos.y, vel.x, vel.y,
        tostring(hero_.onGround),
        hero_.facing,
        atk.phase,
        tostring(atk.held),
        atk.comboReset or 0,
        pres.clip or pres.kind or "",
        pres.frame or 0,
        tip
    ), nil)
end
