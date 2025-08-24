local plugin_name = select(1, ...)
local component_name = select(2, ...)
local signal_table = select(3, ...)
local handle = select(4, ...)

-- Minimal example of plugin structure


-- Parameters
local DEBUG_FILE = true


-- Helpers
local function Debugf(...)
    if DEBUG_FILE then
        Echo(...)
    end
end


-- Main Entrypoint of plugin
--  Called when `Call Plugin X` is run or Pool object is clicked
function Main(display_handle, args)
    Printf(plugin_name .. ": Main")
    Debugf("Hello from %s", component_name)

    Debugf("ToAddr: " .. handle:ToAddr())
    Debugf("Addr:   " .. handle:Addr())

    ErrPrintf("This is an error")
end


-- Called after the Main function returns
function Cleanup()
    Printf(plugin_name .. ": Cleaning up")
end


-- Called when plugin is run with `Go+ Plugin X`
function Execute(type, ...)
    Printf(plugin_name .. ": Executed")
    Debugf(type .. ": " .. ...)
end



-- Export plugin functions
return Main, Cleanup, Execute