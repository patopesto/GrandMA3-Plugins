local plugin_name = select(1, ...)
local component_name = select(2, ...)
local signal_table = select(3, ...)
local handle = select(4, ...)


-- Note on grid sizes:
--      Display and ScreenContent objects talk about the grid (the one you set as the 'Width' and 'Height' parameters of the Display)
--      ViewWidgets have the location and size in a sub 2x2 grid, so need to multiply everything by 2


-- Parameters
local DEBUG_FILE = true


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


-- The main logic of the plugin
local function ViewScaler(display_index)

    local display = GetDisplayByIndex(display_index)
    if display == nil then
        ErrPrintf("Display %d is not available", display_index)
        return
    end

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
    
    Printf("%s: Scaling view content (%d, %d) on Display %d (%d, %d)", plugin_name, view_dims.w, view_dims.h, display_index, display_dims.w, display_dims.h)

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

    Printf(plugin_name .. ": Done")

end


local function CreateUIPopup(display_index)

    local display = GetDisplayByIndex(display_index)
    local screen_overlay = display.ScreenOverlay
    screen_overlay:ClearUIChildren() -- Delete any UI elements currently displayed on the overlay.


    -- Get the colors
    local colorTransparent = Root().ColorTheme.ColorGroups.Global.Transparent

    -- Create the overlay base
    local overlay_dim = {
        width = 400,
        height = 500,
    }
    local baseInput = screen_overlay:Append("BaseInput")
    baseInput.Name = "ViewScaler"
    baseInput.W = overlay_dim.width
    baseInput.H = overlay_dim.height
    baseInput.MaxSize = string.format("%s,%s", display.W * 0.8, display.H)
    baseInput.MinSize = string.format("%s,0", overlay_dim.width - 100)
    baseInput.Columns = 1  
    baseInput.Rows = 2
    baseInput[1][1].SizePolicy = "Fixed"
    baseInput[1][1].Size = "60"
    baseInput[1][2].SizePolicy = "Stretch"
    baseInput.AutoClose = "Yes"
    baseInput.CloseOnEscape = "Yes"
  
    -- Create the title bar
    local titleBar = baseInput:Append("TitleBar")
    titleBar.Columns = 2  
    titleBar.Rows = 1
    titleBar.Anchors = "0,0"
    titleBar[2][2].SizePolicy = "Fixed"
    titleBar[2][2].Size = "50"
    titleBar.Texture = "corner2"

    local titleBarIcon = titleBar:Append("TitleButton")
    titleBarIcon.Text = "ViewScaler"
    titleBarIcon.Texture = "corner1"
    titleBarIcon.Anchors = "0,0"
    titleBarIcon.Icon = "star"

    local titleBarCloseButton = titleBar:Append("CloseButton")
    titleBarCloseButton.Anchors = "1,0"
    titleBarCloseButton.Texture = "corner2"


    -- Create the dialog's main frame
    local dlgFrame = baseInput:Append("DialogFrame")
    dlgFrame.H = "100%"
    dlgFrame.W = "100%"
    dlgFrame.Columns = 1
    dlgFrame.Rows = 2
    dlgFrame.DefaultMargin = 10
    dlgFrame.DefaultMarginOnBorders = "Yes"
    dlgFrame.Anchors = {
        left = 0,
        right = 0,
        top = 1,
        bottom = 1,
    }
    dlgFrame[1][1].SizePolicy = "Stretch"
    dlgFrame[1][1].Size = "2"
    dlgFrame[1][2].SizePolicy = "Stretch"
    dlgFrame[1][2].Size = "9"   


    -- Create the sub title (row 1 of the dlgFrame)
    local subTitle = dlgFrame:Append("UIObject")
    subTitle.Text = "Select screen to scale content on"
    subTitle.ContentDriven = "Yes"
    subTitle.ContentWidth = "No"
    subTitle.TextAutoAdjust = "No"
    subTitle.Anchors = "0,0"
    subTitle.Padding = {
        left = 20,
        right = 20,
        top = 15,
        bottom = 15
    }
    subTitle.Font = "Medium20"
    subTitle.HasHover = "No"
    subTitle.BackColor = colorTransparent  

    -- Create the display buttom grid (row 2 of the dlgFrame)
    local displayGrid = dlgFrame:Append("UILayoutGrid")
    displayGrid.Columns = 3
    displayGrid.Rows = 3
    displayGrid.Anchors = "0,1"
    displayGrid.DefaultMargin = 4

    local display4 = displayGrid:Append("IndicatorControl")
    display4.Anchors = "2,0"
    display4.Text = "External 4"
    display4.Texture = "corner2"
    display4.Property = "ScreenContentDisplay4"
    display4.PluginComponent = handle
    display4.Clicked = "OnDisplayClicked"

    local display5 = displayGrid:Append("IndicatorControl")
    display5.Anchors = "0,0"
    display5.Text = "External 5"
    display5.Texture = "corner1"
    display5.Property = "ScreenContentDisplay5"
    display5.PluginComponent = handle
    display5.Clicked = "OnDisplayClicked"

    local display1 = displayGrid:Append("IndicatorControl")
    display1.Anchors = "2,1"
    display1.Text = "Internal 1"
    display1.Property = "ScreenContentDisplay1"
    display1.PluginComponent = handle
    display1.Clicked = "OnDisplayClicked"

    local display2 = displayGrid:Append("IndicatorControl")
    display2.Anchors = "1,1"
    display2.Text = "Internal 2"
    display2.Property = "ScreenContentDisplay2"
    display2.PluginComponent = handle
    display2.Clicked = "OnDisplayClicked"

    local display3 = displayGrid:Append("IndicatorControl")
    display3.Anchors = "0,1"
    display3.Text = "Internal 3"
    display3.Property = "ScreenContentDisplay3"
    display3.PluginComponent = handle
    display3.Clicked = "OnDisplayClicked"

    local display6 = displayGrid:Append("IndicatorControl")
    display6.Anchors = "2,2"
    display6.Text = "Small 6"
    display6.Texture = "corner8"
    display6.Property = "ScreenContentDisplay6"
    display6.PluginComponent = handle
    display6.Clicked = "OnDisplayClicked"

    local display7 = displayGrid:Append("IndicatorControl")
    display7.Anchors = "0,2"
    display7.Text = "Small 7"
    display7.Texture = "corner4"
    display7.Property = "ScreenContentDisplay7"
    display7.PluginComponent = handle
    display7.Clicked = "OnDisplayClicked"


    local resizeCorner = baseInput:Append("ResizeCorner")
    resizeCorner.Anchors = "0,1"
    resizeCorner.AlignmentH = "Right"
    resizeCorner.AlignmentV = "Bottom"


    signal_table.OnDisplayClicked = function(caller)
        Debugf("Display button clicked")

        if caller == display1 then
            ViewScaler(1)
        elseif caller == display2 then
            ViewScaler(2)
        elseif caller == display3 then
            ViewScaler(3)
        elseif caller == display4 then
            ViewScaler(4)
        elseif caller == display5 then
            ViewScaler(5)
        elseif caller == display6 then
            ViewScaler(6)
        elseif caller == display7 then
            ViewScaler(7)
        end

        Obj.Delete(screen_overlay, Obj.Index(baseInput)) -- Close overlay
    end

end



-- Main Entrypoint of plugin
--  Called when `Call Plugin X` is run or Pool object is clicked
local function Main(display_handle, args)

    local display_index = 0
    if args ~= nil then
        _, _, screen = string.find(args, "/Screen (%d+)")
        if screen ~= nil then
            display_index = tonumber(screen)
        end
    end

    if display_index <= 0 or display_index > 7 then
        display_index = Obj.Index(GetFocusDisplay())
        CreateUIPopup(display_index)
    else
        Debugf("Display: %d", display_index)
        ViewScaler(display_index)
    end

end



-- Run the plugin
return Main
    