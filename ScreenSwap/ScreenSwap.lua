local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
local myHandle = select(4, ...)

-- Parameters
local numButtons = 10
local screen1 = 1
local screen2 = 2


function ScreenSwap(displayHandle, args)

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
        _, _, arg3 = string.find(args, "/Buttons (%d+)")
        if arg3 ~= nil then
            numButtons = tonumber(arg3)
        end
    end

    Printf("Swapping ViewButtons between Displays %d <-> %d", screen1, screen2)

    -- Get assigned viewbuttons for each screen
    viewbuttons1 = ObjectList("ViewButton " .. screen1 ..".1 thru " .. numButtons)
    viewbuttons2 = ObjectList("ViewButton " .. screen2 ..".1 thru " .. numButtons)

    -- Echo("Screen %d", screen1)
    -- for i = 1, #viewbuttons1 do
    --     Echo("\t ViewButton %d.%d: '%s' -> %s", screen1, viewbuttons1[i].index, viewbuttons1[i].name, tostring(viewbuttons1[i].object))
    -- end
    -- Echo("Screen %d", screen2)
    -- for i = 1, #viewbuttons2 do
    --     Echo("\t ViewButton %d.%d: '%s' -> %s", screen2, viewbuttons2[i].index, viewbuttons2[i].name, tostring(viewbuttons2[i].object))
    -- end

    i1 = 1
    i2 = 1
    for i = 1, numButtons do
        -- Both screens have a view button assigned
        if i1 <= #viewbuttons1 and viewbuttons1[i1].index == i and i2 <= #viewbuttons2 and viewbuttons2[i2].index == i then
            -- swapping the object assigned to each viewbutton
            temp = viewbuttons1[i1].object
            viewbuttons1[i1].object = viewbuttons2[i2].object
            viewbuttons2[i2].object = temp

            i1 = i1 + 1
            i2 = i2 + 1
        -- No viewbutton on screen 2
        elseif i1 <= #viewbuttons1 and viewbuttons1[i1].index == i then
            src  = "ViewButton " .. screen1 .. "." .. viewbuttons1[i1].index
            dest = "ViewButton " .. screen2 .. "." .. viewbuttons1[i1].index
            Cmd("Copy " .. src .. " at " .. dest)
            Cmd("Delete " .. src)
            i1 = i1 + 1
        -- No viewbutton on screen 1
        elseif i2 <= #viewbuttons2 and viewbuttons2[i2].index == i then
            src  = "ViewButton " .. screen2 .. "." .. viewbuttons2[i2].index
            dest = "ViewButton " .. screen1 .. "." .. viewbuttons2[i2].index
            Cmd("Copy " .. src .. " at " .. dest)
            Cmd("Delete " .. src)
            i2 = i2 + 1
        end

    end

end

-- Run the plugin.
return ScreenSwap
    