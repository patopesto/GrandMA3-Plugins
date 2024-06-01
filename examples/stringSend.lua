-- grandMA3 Lua Plugin - Send UDP/TCP String
-- jason@badgersan.com

-- USE OF THIS SCRIPT IS PROVIDED WITHOUT WARRANTY, SUPPORT, OR ANY PROMISE OF FUNCTIONALITY. USE AT YOUR OWN RISK.

-- v1.0 - 2020-11-11 - Released. Tested on version 1.3.1.
-- v1.1 - 2020-12-10 - Changes for v 1.4.0.2
-- v1.11 - 2022-2-11 - Change dependency to v1.6.3.x
-- v1.12 - 2023-3-27 - Change dependency to v1.8.x

-- Use by making a CMD entry
-- lua "sendMsg('hello world')"


local pluginName    = select(1,...);
local componentName = select(2,...); 
local ver = Version()

-- Show incompatible version warning
if ver:find('^1.8') then
   Echo('Plugin '..componentName..' was loaded'); -- you will see this message in the system monitor
   Echo('Run plugin to configure destination and port');
   Echo("Use with a macro CMD")
   Echo("lua ''sendMsg('hello world')''")
else
   ErrEcho("Plugin "..componentName.." may not be compatible with %s. Use with caution.",ver)
   Echo('Plugin '..componentName..' was loaded'); -- you will see this message in the system monitor
   Echo('Run plugin to configure destination and port');
   Echo("Use with a macro CMD")
   Echo("lua ''sendMsg('hello world')''")
end

local function sendTestString() --prompt for a test string
    local host, port = GetVar(GlobalVars(),'PLUGIN_SEND_IP'), GetVar(GlobalVars(),'PLUGIN_SEND_PORT')
    local msgFormat = GetVar(GlobalVars(),'PLUGIN_MSG_FORMAT')
    local socket = require("socket.core")
    local sendUDP = socket.udp()
    local sendTCP = assert(socket.tcp())
    sendTCP:settimeout(1)
    if host == nil then
        host = "127.0.0.1"
        SetVar(GlobalVars(),'PLUGIN_SEND_IP',host)
    end
    
    if port == nil then 
        port = "1435"
        SetVar(GlobalVars(),'PLUGIN_SEND_PORT',port)
    end
    
    if msgFormat == nil then 
        msgFormat = "UDP"
        SetVar(GlobalVars(),'PLUGIN_MSG_FORMAT',msgFormat)
    end
    
    gmaString = TextInput('Enter string to send')
    if gmaString == nil then
        Echo('*** User Aborted Plugin ***')
        Printf('Plugin stopped')
    else
        if msgFormat == "UDP" then
            sendUDP:setpeername(host,port)
            sendUDP:send(gmaString)
            Echo('*** UDP Message "'..gmaString..'" sent to '..host..':'..port..' ***')
            Printf('UDP Send : "'..gmaString..'"')
        else
            sendTCP:connect(host, port);
            sendTCP:send(gmaString);
            local status, err
            while true do
                status, err = sendTCP:receive()
                if status == nil then break end
            end
            sendTCP:close()
            if err == "Socket is not connected" then
                ErrEcho('*** TCP Connect Error  - No response from '..host..':'..port..' ***')
                gma.gui.msgbox('TCP String Test','No response from '..host..':'..port)
                return
            elseif err == "timeout" then
                ErrEcho('*** TCP Connect Error  - No response from '..host..':'..port..' ***')
                Printf('TCP Send Error')
                return
            end
            Echo('*** TCP Message "'..gmaString..'" sent to '..host..':'..port..' ***')
            Printf('TCP Send : "'..gmaString..'"')
        end
    end
end

local function setupSend()
    local host, port = GetVar(GlobalVars(),'PLUGIN_SEND_IP'), GetVar(GlobalVars(),'PLUGIN_SEND_PORT')
    local msgFormat = GetVar(GlobalVars(),'PLUGIN_MSG_FORMAT')
    local gmaString
    if host == nil then
        host = "127.0.0.1"
        SetVar(GlobalVars(),'PLUGIN_SEND_IP',host)
    end
    
    if port == nil then 
        port = "1435"
        SetVar(GlobalVars(),'PLUGIN_SEND_PORT',port)
    end
    
    if msgFormat == nil then 
        msgFormat = "UDP"
        SetVar(GlobalVars(),'PLUGIN_MSG_FORMAT',msgFormat)
    end
    
    -- Are we changing the current info
    local change = {
           title="Config UDP/TCP Send",                        
           backColor="Global.Focus",                       
           --timeout=10000,                   --Only needed if the box needs to self close                
           --timeoutResultCancel=false,                      
           --timeoutResultID=-1,                             
           icon="wizard",                                 
           titleTextColor="Global.Selected",              
           messageTextColor=nil,                           
           message="Current Settings\nIP Address: "..host.."\nPort: "..port.."\nFormat: "..msgFormat.."\n\nChange or send string using current settings?",   
           display= nil,                                   
           commands={
               {value=0, name="Close"},                       
               {value=1, name="Edit"},
               {value=2, name="Test"}
           },
        }
    local c = MessageBox(change) -- Draw the message box with the above options and call it variable 'c'
    
    -- Changing the info and then sending a string
    if c.result == 1 then
        local usingUdp, usingTcp
        if msgFormat == "UDP" then
           usingUdp = true
           usingTcp = false
        else
           usingUdp = false
           usingTcp = true
        end
   
        local config = {
           title="Config UDP/TCP Destination",                        
           backColor="Global.Focus",                       
           --timeout=10000,                   --Only needed if the box needs to self close                
           --timeoutResultCancel=false,                      
           --timeoutResultID=-1,                             
           icon="wizard",                                 
           titleTextColor="Global.Selected",              
           messageTextColor=nil,                           
           message="Current Settings\nIP Address: "..host.."\nPort: "..port.."\nFormat: "..msgFormat,   
           display= nil,                                   
           commands={
               {value=0, name="Cancel"},                       
               {value=1, name="Save"},
           },
           inputs={
               {name="IP Address", value=host, blackFilter="", whiteFilter="", vkPlugin="IP4Prefix", maxTextLength = 15},
               {name="Port", value=port, blackFilter="=", whiteFilter="", vkPlugin="TextInputNumOnly", maxTextLength = 5},
           },
           states={
               {name="UDP", state = usingUdp, group = 1,},
               {name="TCP", state = usingTcp, group = 1,},
           }
        }
        local r = MessageBox(config) -- Draw the message box with the above options and call it variable 'r'

        if r.result == 1 then -- Looks at the commands value, if 1 then save the settings
            host        = r.inputs["IP Address"]
            port        = r.inputs["Port"]
            if r.states["UDP"] then
                msgFormat = "UDP"
            else
                msgFormat = "TCP"
            end
            SetVar(GlobalVars(),'PLUGIN_MSG_FORMAT',msgFormat)
            SetVar(GlobalVars(),'PLUGIN_SEND_IP',host)
            SetVar(GlobalVars(),'PLUGIN_SEND_PORT',port)
            Echo('*** '..msgFormat..' IP Destination set to '..host..':'..port..' ***')
            Printf('Send '..msgFormat..' : IP set to '..host..':'..port..'')
            Printf("Use with a macro CMD")
            Printf("lua ''sendMsg('hello world')''")
        else -- don't change the info
            Echo("*** TCP/UDP string settings NOT changed ***")
            Echo('*** '..msgFormat..' IP Destination is currently '..host..':'..port..' ***')
            Printf('Send '..msgFormat..' : settings not changed')
            Printf("Use with a macro CMD")
            Printf("lua ''sendMsg('hello world')''")
        end
    elseif c.result == 2 then -- send a test string
        sendTestString()
    else
        Echo('*** User Aborted Plugin ***')
        Printf('Plugin Aborted')
        Echo('*** TCP/UDP string settings NOT changed ***')
        Echo('*** '..msgFormat..' IP Destination is currently '..host..':'..port..' ***')
        Printf('Send '..msgFormat..' : settings not changed')
        Printf("Use with a macro CMD")
        Printf("lua ''sendMsg('hello world')''")
    end
end


function sendMsg(gmaString) --CMD send string
    local host, port = GetVar(GlobalVars(),'PLUGIN_SEND_IP'), GetVar(GlobalVars(),'PLUGIN_SEND_PORT')
    local msgFormat = GetVar(GlobalVars(),'PLUGIN_MSG_FORMAT')
    local socket = require("socket.core")
    local sendUDP = socket.udp()
    local sendTCP = assert(socket.tcp())
    sendTCP:settimeout(1)
    if host == nil then
        setupSend()
    end
    
    if port == nil then
        setupSend()
    end
    
    if msgFormat == nil then
        setupSend()
    end
    
    if gmaString == nil then
        Echo('*** User Aborted Plugin ***')
        Printf('Plugin stopped')
    else
        if msgFormat == "UDP" then
            sendUDP:setpeername(host,port)
            sendUDP:send(gmaString)
            Echo('*** UDP Message "'..gmaString..'" sent to '..host..':'..port..' ***')
            Printf('UDP Send : "'..gmaString..'"')
        else
            sendTCP:connect(host, port);
            sendTCP:send(gmaString);
            local status, err
            while true do
                status, err = sendTCP:receive()
                if status == nil then break end
            end
            sendTCP:close()
            if err == "Socket is not connected" then
                ErrEcho('*** TCP Connect Error  - No response from '..host..':'..port..' ***')
                gma.gui.msgbox('TCP String Test','No response from '..host..':'..port)
                return
            elseif err == "timeout" then
                ErrEcho('*** TCP Connect Error  - No response from '..host..':'..port..' ***')
                Printf('TCP Send Error')
                return
            end
            Echo('*** TCP Message "'..gmaString..'" sent to '..host..':'..port..' ***')
            Printf('TCP Send : "'..gmaString..'"')
        end
    end
end

return setupSend