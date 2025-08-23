local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
local myHandle = select(4, ...)


-- Note on grid sizes:
--      Display and ScreenContent objects talk about the grid (the one you set as the 'Width' and 'Height' parameters of the Display)
--      ViewWidgets have the location and size in a sub 2x2 grid, so need to multiply everything by 2


-- Parameters
DEBUG_FILE = false


-- Helpers
function DebugF(...)
    if DEBUG_FILE then
        Echo(...)
    end
end


function round(x) 
    return math.floor(x + 0.49999999999999994)
end


function PrintTable(t, level)
    level = level or 0

    for key, value in pairs(t) do
        if type(value) == "table" then
            DebugF(string.rep("\t", level) .. key .. ": ")
            PrintTable(value, level + 1)
        else
            DebugF(string.rep("\t", level) .. key .. ": " .. tostring(value))
        end
    end
end


-- Main Function
function ViewScaler(displayHandle, args)

    -- Get the index of the display in focus.
    local displayIndex = Obj.Index(GetFocusDisplay())
    if args ~= nil then
        _, _, screen = string.find(args, "/Screen (%d+)")
        if screen ~= nil then
            displayIndex = tonumber(screen)
        end
    end
    DebugF("Display: %d", displayIndex)

    local display = GetDisplayByIndex(displayIndex)
    local uiScreen = display:Ptr(5):Ptr(3):Ptr(1):Ptr(5):Ptr(1) -- Based on Command line when "Configure Display > Width and Height"
    _, _, width = string.find(uiScreen:Get("ViewW"), "<?(%d+)>?") -- "<12>": <,> are added if default value
    _, _, height = string.find(uiScreen:Get("ViewH"), "<?(%d+)>?")
    local displayDims = {
        w = tonumber(width),
        h = tonumber(height),
    }
    DebugF("Display dimensions: %d, %d", displayDims.w, displayDims.h)

    -- Create a handle for the current screen configuration.
    local currentScreenConfig = CurrentScreenConfig()
    local screenContents = currentScreenConfig:Ptr(1) -- First child is ScreenContent objects (1 per display)
    -- Get ScreenContent and dimensions for current view
    local screenContent = screenContents:Ptr(displayIndex)
    _, _, width = string.find(screenContent:Get("RequestedW"), "<?(%d+)>?") -- "<12>": <,> are added if default value
    _, _, height = string.find(screenContent:Get("RequestedH"), "<?(%d+)>?")
    local viewDims = {
        w = tonumber(width),
        h = tonumber(height),
    }
    DebugF("Content dimensions: %d, %d", viewDims.w, viewDims.h)
    
    Printf("Scaling view content (%d, %d) on Display %d (%d, %d)", viewDims.w, viewDims.h, displayIndex, displayDims.w, displayDims.h)

    -- Loop through all widgets in view
    local viewWidgets = screenContent:Children()
    local widgetsDims = {}
    for i = 1, #viewWidgets do
        local widget = viewWidgets[i]
        local dim = {
            name = widget.name,
            index = i,
            x = widget:Get("X"),
            y = widget:Get("Y"),
            w = widget:Get("W"),
            h = widget:Get("H"),
            minw = widget:Get("MinW"),
            minh = widget:Get("MinH"),
            snap = widget:Get("SnapToBlockSize"), -- Snap to the grid
        }
        local scale = {
            x = dim.x / (viewDims.w * 2),
            y = dim.y / (viewDims.h * 2),
            w = dim.w / (viewDims.w * 2),
            h = dim.h / (viewDims.h * 2),
        }
        dim["scale"] = scale

        widgetsDims[i] = dim
    end

    PrintTable(widgetsDims)

    local scaleUp = displayDims.w >= viewDims.w -- Whether we are scaling up or down

    -- Sort based on scale up or down.
    -- If scaling up, we want to move the furthest (max X and Y) widgets first and vice-versa
    table.sort(widgetsDims, function(a, b)
        if scaleUp then
            if a.x == b.x then
                return a.y > b.y
            else
                return a.x > b.x
            end
        else
            if a.x == b.x then
                return a.y < b.y
            else
                return a.x < b.x
            end
        end
    end)

    PrintTable(widgetsDims) 

    -- Move widgets
    for pass = 1, 2 do -- for now run twice to make sure we don't have widget collisions if not moved in the correct order
        for i = 1, #widgetsDims do
            index = widgetsDims[i].index
            x = round(widgetsDims[i].scale.x * displayDims.w) * 2
            y = round(widgetsDims[i].scale.y * displayDims.h) * 2
            w = round(widgetsDims[i].scale.w * displayDims.w) * 2
            h = round(widgetsDims[i].scale.h * displayDims.h) * 2

            Cmd("Set ScreenContent %d.%d X=%d Y=%d W=%d H=%d", displayIndex, index, x, y, w, h)
        end
    end

end



-- Run the plugin
return ViewScaler
    