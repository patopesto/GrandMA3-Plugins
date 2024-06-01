local pluginName = select(1, ...)
local componentName = select(2, ...)
local signalTable = select(3, ...)
local myHandle = select(4, ...)

-- Parameters
local numButtons = 11
local screen1 = 1
local screen2 = 2


function ScreenSwap(displayHandle, args)

    -- Parse arguments: "/Screen X /Screen Y"
    _, j, arg1 = string.find(args, "/Screen (%d+)")
    if arg1 ~= nil then
        screen1 = arg1
    end
    _, j, arg2 = string.find(args, "/Screen (%d+)", j) -- start where we left off
    if arg2 ~= nil then
        screen2 = arg2
    end

    Echo("Swapping screens " .. screen1 .. " -> " .. screen2)

    -- Get assigned viewbuttons for each screen
    viewbuttons1 = ObjectList("ViewButton " .. screen1 ..".1 thru " .. numButtons)
    viewbuttons2 = ObjectList("ViewButton " .. screen2 ..".1 thru " .. numButtons)

    -- Printf("Screen 1")
    -- for i = 1, #viewbuttons1 do
    --     Printf("ViewButton: " .. viewbuttons1[i].name .. " " .. viewbuttons1[i].object)
    -- end
    -- Printf("Screen 2")
    -- for i = 1, #viewbuttons2 do
    --     Printf("ViewButton: " .. viewbuttons2[i].name .. " " .. viewbuttons2[i].object)
    -- end

    i1 = 1
    i2 = 1
    for i = 1, numButtons do
        -- Both screens have a view button assigned
        if viewbuttons1[i1].index == i and viewbuttons2[i2].index == i then
            -- swapping the object assigned to each viewbutton
            temp = viewbuttons1[i1].object
            viewbuttons1[i1].object = viewbuttons2[i2].object
            viewbuttons2[i2].object = temp

            i1 = i1 + 1
            i2 = i2 + 1
        -- No viewbutton on screen 2
        elseif viewbuttons1[i1].index == i then
            src  = "ViewButton " .. screen1 .. "." .. i1
            dest = "ViewButton " .. screen2 .. "." .. i1
            Cmd("Copy " .. src .. " at " .. dest)
            Cmd("Delete " .. src)
            i1 = i1 + 1
        -- No viewbutton on screen 1
        elseif viewbuttons2[i2].index == i then
            src  = "ViewButton " .. screen2 .. "." .. i2
            dest = "ViewButton " .. screen1 .. "." .. i2
            Cmd("Copy " .. src .. " at " .. dest)
            Cmd("Delete " .. src)
            i2 = i2 + 1
        else
            ErrEcho("Error: Invalid indexes => index: ".. i .. " i1: " .. i1 .. " i2: ".. i2)
        end

    end

end

-- Run the plugin.
return ScreenSwap
    