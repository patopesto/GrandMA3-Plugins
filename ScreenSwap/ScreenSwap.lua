local plugin_name = select(1, ...)
local component_name = select(2, ...)
local signal_table = select(3, ...)
local handle = select(4, ...)


-- Main Function
function ScreenSwap(display_handle, args)

    -- Parameters
    local screen1 = 1
    local screen2 = 2
    local buttons = "1 Thru 10"

    -- Parse arguments: "/Screen X /Screen Y /Buttons Z"
    if args ~= nil then
        _, j, arg1 = string.find(args, "/Screen (%d+)")
        if arg1 ~= nil then
            screen1 = tonumber(arg1)
        end
        _, j, arg2 = string.find(args, "/Screen (%d+)", j) -- start where we left off
        if arg2 ~= nil then
            screen2 = tonumber(arg2)
        end
        _, _, arg3 = string.find(args, "/Buttons ([%a%d%s]+)")
        if arg3 ~= nil then
            buttons = arg3
        end
    end

    Printf("Swapping ViewButtons %s between Displays %d <-> %d", buttons, screen1, screen2)

    -- Get assigned viewbuttons for each screen
    viewbuttons1 = ObjectList("ViewButton " .. screen1 .."." .. buttons)
    viewbuttons2 = ObjectList("ViewButton " .. screen2 .."." .. buttons)

    -- Echo("Screen %d", screen1)
    -- for i = 1, #viewbuttons1 do
    --     Echo("\t ViewButton %d.%d: '%s' -> %s", screen1, viewbuttons1[i].index, viewbuttons1[i].name, tostring(viewbuttons1[i].object))
    -- end
    -- Echo("Screen %d", screen2)
    -- for i = 1, #viewbuttons2 do
    --     Echo("\t ViewButton %d.%d: '%s' -> %s", screen2, viewbuttons2[i].index, viewbuttons2[i].name, tostring(viewbuttons2[i].object))
    -- end

    local start_index = 1
    _, j, match = string.find(buttons, "(%d+) thru %d*")
    if match ~= nil then
        start_index = tonumber(match)
    end

    local end_index = math.max(viewbuttons1[#viewbuttons1].index, viewbuttons2[#viewbuttons2].index)

    local i1 = 1
    local i2 = 1
    for i = start_index, end_index do
        -- Both screens have a view button assigned
        if i1 <= #viewbuttons1 and viewbuttons1[i1].index == i and i2 <= #viewbuttons2 and viewbuttons2[i2].index == i then
            -- swapping the object assigned to each viewbutton
            local temp = viewbuttons1[i1].object
            viewbuttons1[i1].object = viewbuttons2[i2].object
            viewbuttons2[i2].object = temp

            i1 = i1 + 1
            i2 = i2 + 1
        -- No viewbutton on screen 2
        elseif i1 <= #viewbuttons1 and viewbuttons1[i1].index == i then
            local src  = "ViewButton " .. screen1 .. "." .. viewbuttons1[i1].index
            local dest = "ViewButton " .. screen2 .. "." .. viewbuttons1[i1].index
            Cmd("Move " .. src .. " at " .. dest)
            i1 = i1 + 1
        -- No viewbutton on screen 1
        elseif i2 <= #viewbuttons2 and viewbuttons2[i2].index == i then
            local src  = "ViewButton " .. screen2 .. "." .. viewbuttons2[i2].index
            local dest = "ViewButton " .. screen1 .. "." .. viewbuttons2[i2].index
            Cmd("Move " .. src .. " at " .. dest)
            i2 = i2 + 1
        end

    end

end


-- Run the plugin
return ScreenSwap
    