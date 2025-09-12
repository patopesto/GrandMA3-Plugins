local plugin_name = select(1, ...)
local component_name = select(2, ...)
local signal_table = select(3, ...)
local handle = select(4, ...)

local json = require("json")

-- Plugin to dump/export some of the LUA API for use in the documentation


-- Parameters
local VERSION_FILENAME = "grandMA3_version.json"
local FUNCS_FILENAME = "grandMA3_lua_functions.json"
local ENUMS_FILENAME = "grandMA3_lua_enums.json"
local TREE_FILENAME = "grandMA3_object_tree.json"

-- Helpers
local function PrintTable(t, level)
    level = level or 0

    for key, value in pairs(t) do
        if type(value) == "table" then
            Echo(string.rep("\t", level) .. key .. ": ")
            PrintTable(value, level + 1)
        else
            Echo(string.rep("\t", level) .. key .. ": " .. tostring(value))
        end
    end
end


local function ExportJsonTable(fileName, tble, useJsonLib)
    useJsonLib = useJsonLib or false

    if (useJsonLib == true) then
        -- Using json library and encoding to string, Has issues with long output being truncated ...
        local tble_str = json.encode(tble)
        local file = io.open(fileName, "w")
        local success, error, error_num = file.write(file, tble_str)
        if (success == nil) then
            Printf("Error " .. error_num .. ": " .. error)
        end
        Printf("Exported json file at: " .. fileName .. " (lib encode)")
    else
        -- Using GrandMA dedicated function. But not really valid JSON output!
        local success = ExportJson(fileName, tble)
        if success then
            Printf("Exported json file at: " .. fileName)
        else
            Printf("Error whilst exporting file " .. fileName)
        end
    end
end


-- Exporters
local function ExportVersion()

    local data = {
        version = "",
        date = os.date("%d/%m/%Y %X"),
        build_details = BuildDetails(),
        host_os = HostOS(),
        showfile = Root().ManetSocket.Showfile,
    }
    data.version = string.sub(data.build_details.BigVersion, 0, 3)
    PrintTable(data)

    local fileName = GetPath(Enums.PathType.Library) .. "/" .. VERSION_FILENAME
    ExportJsonTable(fileName, data, true)

end


local function ExportFunctions()

    local funcs = {
        objectfree = {},
        object = {},
    }

    for key, value in ipairs(GetApiDescriptor()) do
        if value[1] ~= nil then
            funcs.objectfree[value[1]] = {}
        end
        if value[2] ~= nil then
            funcs.objectfree[value[1]]["args"] = value[2]
        end
        if value[3] ~= nil then
            funcs.objectfree[value[1]]["returns"] = value[3]
        end
    end

    for key, value in ipairs(GetObjApiDescriptor()) do
        if value[1] ~= nil then
            funcs.object[value[1]] = {}
        end
        if value[2] ~= nil then
            funcs.object[value[1]]["args"] = value[2]
        end
        if value[3] ~= nil then
            funcs.object[value[1]]["returns"] = value[3]
        end
    end

    -- PrintTable(funcs)
    local fileName = GetPath(Enums.PathType.Library) .. "/" .. FUNCS_FILENAME
    ExportJsonTable(fileName, funcs, true)

end


local function ExportEnums()
    local fileName = GetPath(Enums.PathType.Library) .. "/" .. ENUMS_FILENAME
    ExportJsonTable(fileName, Enums)
end


local function TraverseChildren(object, level)

    if (object == nil or object.Name == nil) then
        return {}
    end

    local data = {
        name = string.gsub(object.Name, '\n', ' '), -- Remove newlines if any
        index = Obj.Index(object),
        path = string.gsub(object:AddrNative(), '\n', ' '), -- Remove newlines if any
        class = object:GetClass(),
    }

    if (data.name == "") then
        data.name = "unnamed"
    end

    local children = object:Children()
    if (#children > 0) then data.children = {} end

    -- Cleanup device/specific data
    for i = 1, #children do
        data.children[i] = TraverseChildren(children[i], level + 1)

        -- Cleanup device-specific data
        if (data.children[i].class == "MIDIDeviceDescription") then
            local new_name = "Midi Device " .. i
            local old_name = data.children[i].name
            data.children[i].name = new_name
            data.children[i].path = string.gsub(data.children[i].path, old_name, new_name)
            break
        elseif (data.children[i].class == "AudioInDeviceDescription") then
            local new_name = "Audio In Device " .. i
            local old_name = data.children[i].name
            data.children[i].name = new_name
            data.children[i].path = string.gsub(data.children[i].path, old_name, new_name)
            break
        elseif (data.children[i].class == "AudioOutDeviceDescription") then
            local new_name = "Audio Out Device " .. i
            local old_name = data.children[i].name
            data.children[i].name = new_name
            data.children[i].path = string.gsub(data.children[i].path, old_name, new_name)
            break
        -- elseif (data.children[i].class == "NetworkStation" or data.children[i].class == "OutputStation") then
        --     local new_name = "Laptop.local"
        --     local old_name = data.children[i].name
        --     data.children[i].name = new_name
        --     data.children[i].path = string.gsub(data.children[i].path, old_name, new_name) -- gsub pattern does not work if name has '.' in it. Instead Modify Station Hostname directly in showfile for correct output
        --     break
        end
    end

    local addr = object:Addr() -- Not sure why, but this function needs to run last as it "destroys" the "object" reference!
    if (addr ~= "") then
        data.addr = addr
    end

    return data
end


local function ExportTree()
    local tree = TraverseChildren(Root(), 0)

    local fileName = GetPath(Enums.PathType.Library) .. "/" .. TREE_FILENAME
    ExportJsonTable(fileName, tree)
end




-- Main Entrypoint of plugin
--  Called when `Call Plugin X` is run or Pool object is clicked
function Main(display_handle, args)
    Printf(plugin_name .. ": Main")
    Printf(plugin_name .. ": Starting exports")

    ExportVersion()
    Cmd("HelpLua")
    ExportFunctions() -- Alternative to HelpLua which outputs to JSON file
    ExportEnums()
    ExportTree()

    Printf(plugin_name .. ": Done")
end


-- Export plugin functions
return Main