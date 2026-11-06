-- Bottom-left virtual joystick. Horizontal axis only.
-- Release snaps the knob to center and reports 0 the same frame.
-- Deadzone and proportional speed live in combat.tuning.

local Tuning = require("combat.tuning")

local MoveInput = {}
MoveInput.__index = MoveInput

function MoveInput.new()
    return setmetatable({
        raw = 0,
        axis = 0,
        capture = nil,
        layout_ = nil,
    }, MoveInput)
end

function MoveInput:layout(width, height)
    local marginX = 24
    local marginY = 28
    local trackW = 220
    if width > 0 then
        trackW = math.min(trackW, math.max(120, width * 0.46))
        if trackW > width - 32 then
            trackW = math.max(80, width - 32)
        end
    end
    local trackH = 52
    local knob = trackH - 10
    local travel = (trackW - knob) * 0.5
    if travel < 1 then
        travel = 1
    end
    return {
        cx = marginX + trackW * 0.5,
        cy = height - marginY - trackH * 0.5,
        trackW = trackW,
        trackH = trackH,
        knob = knob,
        travel = travel,
        hitPad = 40,
    }
end

function MoveInput:inside(layout, x, y)
    local halfW = layout.trackW * 0.5 + layout.hitPad
    local halfH = layout.trackH * 0.5 + layout.hitPad
    return math.abs(x - layout.cx) <= halfW and math.abs(y - layout.cy) <= halfH
end

function MoveInput:setFromPointer(layout, x)
    local dx = x - layout.cx
    local travel = layout.travel
    if dx > travel then
        dx = travel
    end
    if dx < -travel then
        dx = -travel
    end
    self.raw = dx / travel
    self.axis = Tuning.moveAxis(self.raw)
end

function MoveInput:release()
    self.raw = 0
    self.axis = 0
    self.capture = nil
end

local function componentXY(point)
    if point == nil then
        return nil, nil
    end
    local x = point.x
    local y = point.y
    if type(x) ~= "number" or type(y) ~= "number" then
        return nil, nil
    end
    return x, y
end

function MoveInput:touches()
    if input == nil or input.GetNumTouches == nil then
        return {}
    end
    local ok, n = pcall(function()
        return input:GetNumTouches()
    end)
    if not ok or type(n) ~= "number" or n <= 0 then
        return {}
    end
    local list = {}
    for i = 0, n - 1 do
        local okTouch, touch = pcall(function()
            return input:GetTouch(i)
        end)
        if okTouch and touch ~= nil then
            local x, y = componentXY(touch.position)
            local id = touch.touchID
            if id == nil then
                id = touch.id
            end
            if x ~= nil and id ~= nil then
                list[#list + 1] = { id = id, x = x, y = y }
            end
        end
    end
    return list
end

function MoveInput:trackedTouch(layout)
    local touches = self:touches()
    if self.capture ~= nil and self.capture ~= "mouse" then
        for i = 1, #touches do
            if touches[i].id == self.capture then
                return touches[i]
            end
        end
        return nil
    end
    for i = 1, #touches do
        local touch = touches[i]
        if self:inside(layout, touch.x, touch.y) then
            return touch
        end
    end
    return nil
end

function MoveInput:mouseDown()
    if input == nil or input.GetMouseButtonDown == nil or MOUSEB_LEFT == nil then
        return false
    end
    local ok, down = pcall(function()
        return input:GetMouseButtonDown(MOUSEB_LEFT)
    end)
    return ok and (down == true or down == 1)
end

function MoveInput:mouseXY()
    if input == nil or input.GetMousePosition == nil then
        return nil, nil
    end
    local ok, pos = pcall(function()
        return input:GetMousePosition()
    end)
    if not ok then
        return nil, nil
    end
    return componentXY(pos)
end

-- Touch wins over the mouse so a finger is not also a synthetic click.
function MoveInput:pointer(layout)
    local touch = self:trackedTouch(layout)
    if touch ~= nil then
        self.capture = touch.id
        return touch
    end
    if self.capture ~= nil and self.capture ~= "mouse" then
        self.capture = nil
    end

    if not self:mouseDown() then
        if self.capture == "mouse" then
            self.capture = nil
        end
        return nil
    end

    local x, y = self:mouseXY()
    if x == nil then
        return nil
    end
    if self.capture == "mouse" or self:inside(layout, x, y) then
        self.capture = "mouse"
        return { x = x, y = y }
    end
    return nil
end

function MoveInput:update(width, height)
    if width == nil or height == nil or width < 1 or height < 1 then
        self:release()
        return
    end
    local layout = self:layout(width, height)
    self.layout_ = layout
    local pointer = self:pointer(layout)
    if pointer == nil then
        self.raw = 0
        self.axis = 0
        return
    end
    -- Horizontal only: vertical finger travel does not change the axis.
    self:setFromPointer(layout, pointer.x)
end

function MoveInput:draw(vg, width, height)
    local layout = self.layout_
    if layout == nil then
        layout = self:layout(width, height)
    end
    local left = layout.cx - layout.trackW * 0.5
    local top = layout.cy - layout.trackH * 0.5

    nvgBeginPath(vg)
    nvgRect(vg, left, top, layout.trackW, layout.trackH)
    nvgFillColor(vg, nvgRGBA(8, 10, 16, 150))
    nvgFill(vg)
    nvgBeginPath(vg)
    nvgRect(vg, left, top, layout.trackW, layout.trackH)
    nvgStrokeWidth(vg, 2)
    nvgStrokeColor(vg, nvgRGBA(230, 210, 160, 180))
    nvgStroke(vg)

    local dead = layout.travel * Tuning.MOVE_DEADZONE
    nvgBeginPath(vg)
    nvgRect(vg, layout.cx - dead, top + 8, dead * 2, layout.trackH - 16)
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 36))
    nvgFill(vg)

    local knobX = layout.cx + self.raw * layout.travel
    nvgBeginPath(vg)
    nvgCircle(vg, knobX, layout.cy, layout.knob * 0.5)
    nvgFillColor(vg, nvgRGBA(232, 196, 120, 235))
    nvgFill(vg)
end

return MoveInput
