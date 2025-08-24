local plugin_name = select(1, ...)
local component_name = select(2, ...)
local signal_table = select(3, ...)
local handle = select(4, ...)


-- Note on grid sizes:
--      Display and ScreenContent objects talk about the grid (the one you set as the 'Width' and 'Height' parameters of the Display)
--      ViewWidgets have the location and size in a sub 2x2 grid, so need to multiply everything by 2


-- Parameters
local DEBUG_FILE = false


-- Helpers
local function Debugf(...)
    if DEBUG_FILE then
        Echo(...)
    end
end


local function round(x) 
    return math.floor(x + 0.49999999999999994)
end


local function PrintTable(t, level)
    level = level or 0

    for key, value in pairs(t) do
        if type(value) == "table" then
            Debugf(string.rep("\t", level) .. key .. ": ")
            PrintTable(value, level + 1)
        else
            Debugf(string.rep("\t", level) .. key .. ": " .. tostring(value))
        end
    end
end


-- Main Function
function ViewScaler(display_handle, args)

    -- Get the index of the display in focus.
    local display_index = Obj.Index(GetFocusDisplay())
    if args ~= nil then
        _, _, screen = string.find(args, "/Screen (%d+)")
        if screen ~= nil then
            display_index = tonumber(screen)
        end
    end
    Debugf("Display: %d", display_index)

    local display = GetDisplayByIndex(display_index)
    local ui_screen = FromAddr(display:Addr() .. ".5.3.1.5.1") -- Based on Command line when "Configure Display > Width and Height"
    _, _, width = string.find(ui_screen:Get("ViewW"), "<?(%d+)>?") -- "<12>": <,> are added if default value
    _, _, height = string.find(ui_screen:Get("ViewH"), "<?(%d+)>?")
    local display_dims = {
        w = tonumber(width),
        h = tonumber(height),
    }
    Debugf("Display dimensions: %d, %d", display_dims.w, display_dims.h)

    -- Create a handle for the current screen configuration.
    local current_screenconfig = CurrentScreenConfig()
    local screencontents = current_screenconfig:Ptr(1) -- First child is ScreenContent objects (1 per display)
    -- Get ScreenContent and dimensions for current view
    local screencontent = screencontents:Ptr(display_index)
    _, _, width = string.find(screencontent:Get("RequestedW"), "<?(%d+)>?") -- "<12>": <,> are added if default value
    _, _, height = string.find(screencontent:Get("RequestedH"), "<?(%d+)>?")
    local view_dims = {
        w = tonumber(width),
        h = tonumber(height),
    }
    Debugf("Content dimensions: %d, %d", view_dims.w, view_dims.h)
    
    Printf("Scaling view content (%d, %d) on Display %d (%d, %d)", view_dims.w, view_dims.h, display_index, display_dims.w, display_dims.h)

    -- Loop through all widgets in view
    local view_widgets = screencontent:Children()
    local widgets_dims = {}
    for i = 1, #view_widgets do
        local widget = view_widgets[i]
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
            x = dim.x / (view_dims.w * 2),
            y = dim.y / (view_dims.h * 2),
            w = dim.w / (view_dims.w * 2),
            h = dim.h / (view_dims.h * 2),
        }
        dim["scale"] = scale

        widgets_dims[i] = dim
    end

    PrintTable(widgets_dims)

    local scaleUp = display_dims.w >= view_dims.w -- Whether we are scaling up or down

    -- Sort based on scale up or down.
    -- If scaling up, we want to move the furthest (max X and Y) widgets first and vice-versa
    table.sort(widgets_dims, function(a, b)
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

    PrintTable(widgets_dims) 

    -- Move widgets
    for pass = 1, 2 do -- for now run twice to make sure we don't have widget collisions if not moved in the correct order
        for i = 1, #widgets_dims do
            local index = widgets_dims[i].index
            local x = round(widgets_dims[i].scale.x * display_dims.w) * 2
            local y = round(widgets_dims[i].scale.y * display_dims.h) * 2
            local w = round(widgets_dims[i].scale.w * display_dims.w) * 2
            local h = round(widgets_dims[i].scale.h * display_dims.h) * 2

            Cmd("Set ScreenContent %d.%d X=%d Y=%d W=%d H=%d", display_index, index, x, y, w, h)
        end
    end

end


-- Run the plugin
return ViewScaler
    