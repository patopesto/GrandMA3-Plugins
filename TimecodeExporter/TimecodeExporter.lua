local pluginName    = select(1,...)
local componentName = select(2,...) 
local signalTable   = select(3,...) 
local my_handle     = select(4,...)

-- Plugin to export Timecode pool objects events to CSV


-- Parameters
local DEBUG_FILE = true
local DEFAULT_FILENAME = "TimecodeExporter.xml"


-- Helpers
local function Debugf(...)
    if DEBUG_FILE then
        Echo(...)
    end
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


local function TimeToTCString(time, fps)
    fps = fps or 30 -- default frame rate
    if time < 0 then time = 0 end

    local hrs  = math.floor(time / 3600)
    local mins = math.floor((time % 3600) / 60)
    local secs = math.floor(time % 60)

    local frac = time - math.floor(time)
    local frames = math.floor(frac * fps + 0.5) -- round to nearest frame

    -- In the unlikely event rounding pushes us to a full extra frame,
    -- roll it over to the next second/minute/hour.
    if frames >= fps then
        frames = frames - fps
        secs = secs + 1
        if secs >= 60 then
            secs = secs - 60
            mins = mins + 1
            if mins >= 60 then
                mins = mins - 60
                hrs = hrs + 1
            end
        end
    end

    local str = string.format("%.2d:%.2d:%.2d:%.2d", hrs, mins, secs, frames)
    return str
end


local function GetTimecodeEvents(timecode, cues)
    cues = cues or {}

    if timecode:GetClass() ~= "Timecode" then
        return cues
    end

    local _, _, fps = string.find(timecode.framereadout, "<?(%d+) fps>?") -- Remove optional <> around name
    timecodeObjects = timecode:Children()
    for i = 1, #timecode:Children() do
        local trackgroup = timecodeObjects[i]
        for i = 1, #trackgroup:Children() do
            local track = trackgroup[i]
            for i = 1, #track:Children() do
                local timerange = track[i]
                for i = 1, #timerange:Children() do
                    local cmdSubTrack = timerange[i]
                    for i = 1, #cmdSubTrack:Children() do
                        local event = cmdSubTrack[i]
                        local _, _, trackName = string.find(track.name, "<?([%a%d%s]+)>?") -- Remove optional <> around name
                        local cue = {
                            type = event.name,
                            timecode = TimeToTCString(tonumber(event.time), tonumber(fps)),
                            trackgroup = trackgroup.name,
                            track = trackName,
                            pool = timecode.name,
                        }
                        cues[#cues + 1] = cue
                    end
                end
            end
        end
    end

    return cues
end


local function SanitizeCSVField(value, delim)
    -- Convert nil → empty string
    if value == nil then return "" end
    -- Ensure we have a string representation
    value = tostring(value)

    -- If the field contains the delimiter, a quote or a newline,
    -- wrap it in double‑quotes and double any existing quotes.
    if value:find("[\r\n\"%s]") or value:find(delim, 1, true) then
        value = '"' .. value:gsub('"', '""') .. '"'
    end
    return value
end


local function ExportCuesToCsv(cues, filename, opts)
    opts = opts or {}
    local delim = opts.delimiter or ","
    local mode  = opts.encoding or "w"

    local f, err = io.open(filename, mode)
    if not f then return nil, ("Cannot open file: %s"):format(err) end

    if #cues == 0 then
        f:close()
        return nil, "Cue list is empty"
    end

    -- Write headers
    local columns = { "timecode", "type", "track", "trackgroup", "pool" }
    local header = {}
    for _,col in ipairs(columns) do
        local colCap = col:sub(1, 1):upper() .. col:sub(2) -- Capitalise first letter
        table.insert(header, SanitizeCSVField(colCap, delim))
    end
    f:write(table.concat(header, delim) .. "\n")

    -- Write each cue
    for _,cue in ipairs(cues) do
        local row = {}
        for _,col in ipairs(columns) do
            table.insert(row, SanitizeCSVField(cue[col], delim))
        end
        f:write(table.concat(row, delim) .. "\n")
    end

    f:close()
    return true
end


-- Main Entrypoint of plugin
--  Called when `Call Plugin X` is run or Pool object is clicked
function Main(display_handle, args)
    Printf(pluginName .. ": Starting")

    local filename = DEFAULT_FILENAME
    local objects = ""
    if args ~= nil then
        Debugf("args: " .. args)

        i, j, arg2 = string.find(args, "/File ([%a%d%p]+)")
        if arg2 ~= nil then
            filename = arg2
            args = string.sub(args, 1, i-1) .. string.sub(args, j+1) -- remove parsed from args
        end
        objects = args
    else
        ErrPrintf("Error: No objects defined! Example usage: Plugin " .. pluginName .. " \"Timecode X\"")
        return
    end
    
    local timecodes = ObjectList(objects)
    if #timecodes == 0 then
        ErrPrintf("Error: No objects founds! Example usage: Plugin " .. pluginName .. " \"Timecode X\"")
        return
    end

    local cues = {}
    for i = 1, #timecodes do
        local timecode = timecodes[i]
        Printf("Reading Timecode #".. timecode.index .. ": " .. timecode.name)
        cues = GetTimecodeEvents(timecode, cues)
        -- PrintTable(cues)
    end

    local filepath = GetPath(Enums.PathType.Library) .. "/" .. filename
    local ok, err = ExportCuesToCsv(cues, filepath)
    if ok then
        Printf("Exported csv file at: " .. filepath)
    else
        Printf("Error whilst exporting file " .. filepath .. ": " .. err)
    end

    Printf(pluginName .. ": Done")
end



-- Run the plugin
return Main