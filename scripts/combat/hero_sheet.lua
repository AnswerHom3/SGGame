-- NanoVG cache for Zhao Yun sheets. Drawing never writes the body position.
-- Canvas scale and per-frame bounds stay visual; a locked attack foot is not nudged.

local HeroSheet = {
    images_ = {},
    failed_ = {},
    loaded_ = 0,
    total_ = 0,
}

local function imageFlags()
    if NVG_IMAGE_PREMULTIPLIED ~= nil then
        return NVG_IMAGE_PREMULTIPLIED
    end
    -- nanovg.h NVG_IMAGE_PREMULTIPLIED. These sheets were resized premultiplied.
    return 16
end

function HeroSheet.get(vg, resource)
    if resource == nil then
        return nil
    end
    local cached = HeroSheet.images_[resource]
    if cached ~= nil then
        return cached
    end
    if HeroSheet.failed_[resource] then
        return nil
    end
    if vg == nil or nvgCreateImage == nil then
        return nil
    end
    local handle = nvgCreateImage(vg, resource, imageFlags())
    if type(handle) ~= "number" or handle <= 0 then
        HeroSheet.failed_[resource] = true
        print("WARN: hero sheet missing " .. resource)
        return nil
    end
    HeroSheet.images_[resource] = handle
    return handle
end

function HeroSheet.preload(vg, resources)
    local ok = 0
    for _, resource in ipairs(resources) do
        if HeroSheet.get(vg, resource) ~= nil then
            ok = ok + 1
        end
    end
    HeroSheet.loaded_ = ok
    HeroSheet.total_ = #resources
    print(string.format("Hero sheets %d/%d", ok, #resources))
    return ok
end

function HeroSheet.release(vg)
    if vg ~= nil and nvgDeleteImage ~= nil then
        for _, handle in pairs(HeroSheet.images_) do
            pcall(function()
                nvgDeleteImage(vg, handle)
            end)
        end
    end
    HeroSheet.images_ = {}
    HeroSheet.failed_ = {}
    HeroSheet.loaded_ = 0
    HeroSheet.total_ = 0
end

-- rootSx/rootSy is the foot pixel on screen. facing < 0 mirrors around that root.
-- Returns false when NanoVG image paint is unavailable. Does not move the actor.
function HeroSheet.blit(vg, image, rootSx, rootSy, ppm, facing, rootX, rootY, offX, offY, canvas)
    if vg == nil or image == nil or nvgImagePattern == nil then
        return false
    end
    local left = rootSx + (offX - rootX) * ppm * facing
    local top = rootSy + (offY - rootY) * ppm
    local w = canvas * ppm * facing
    local h = canvas * ppm
    local rectX = left
    local rectW = w
    if rectW < 0 then
        rectX = left + rectW
        rectW = -rectW
    end
    local paint = nvgImagePattern(vg, left, top, w, h, 0, image, 1)
    nvgBeginPath(vg)
    nvgRect(vg, rectX, top, rectW, h)
    nvgFillPaint(vg, paint)
    nvgFill(vg)
    return true
end

return HeroSheet
