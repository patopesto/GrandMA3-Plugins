local pluginName    = select(1,...)
local componentName = select(2,...) 
local signalTable   = select(3,...) 
local my_handle     = select(4,...)

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
    Printf(pluginName .. ": Main")
    Debugf("Hello from %s", componentName)
    if args ~= nil then
        Debugf("Arguments: %s", args)
    end

    Debugf("ToAddr: " .. handle:ToAddr())
    Debugf("Addr:   " .. handle:Addr())

    ErrPrintf("This is an error")
end


-- Called after the Main function returns
function Cleanup()
    Printf(pluginName .. ": Cleaning up")
end


-- Called when plugin is run with `Go+ Plugin X`
function Execute(type, ...)
    Printf(pluginName .. ": Executed")
    Debugf(type .. ": " .. ...)
end



-- Export plugin functions
return Main, Cleanup, Execute