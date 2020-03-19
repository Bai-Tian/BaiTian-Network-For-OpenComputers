-- Baitian Relay Server v0.1
-- by Bai_Tian
-- 中继服务器
-- 请使用欺骗网卡+带有高级网卡的中继器
if Baitianrelayisrunning then os.exit() end
Baitianrelayisrunning = true
if not BaitianLib then BaitianLib = {} end
if not baitian_modem then baitian_modem = {} end
Baitianrelay = {}

local event = require("event")
local computer = require("computer")
local component = require("component")
local modem = component.modem
local relay = component.relay
relay.setRepeater(false)
BaitianLib.fs = component.proxy(computer.getBootAddress())
modem.open(54)

-------------启动地址文件-------------
if BaitianLib.fs.exists("SERVERSADDR.lua") then
    dofile("/" .. "SERVERSADDR.lua")
else
    print("地址列表文件 <SERVERSADDR.lua> 不存在")
    computer.beep(1500, 1)
    os.exit()
end
-------------拓展功能-------------
if BaitianLib.fs.exists("relay.lua") then
    dofile("/" .. "relay.lua")
end

-------------服务启动-------------
baitian_modem.msgidcache = {}
local cachei = 0
local function pull(name, selfaddr, from, port, dis, _msgrelay, _msgid, tport,
                    taddr, ...)
    print("$pull",name, selfaddr, from, port, dis, _msgrelay, _msgid, tport, taddr, ...)
    if cachei > 10 then
        cachei = 0
        baitian_modem.msgidcache = {}
    else
        cachei = cachei + 1
    end
    Baitianrelay.data = {...}
    if (_msgrelay == "relay" or _msgrelay == "relay_broadcast" or _msgrelay ==
        "relay_send") and not baitian_modem.msgidcache[_msgid] then
        baitian_modem.msgidcache[_msgid] = 1
        if _msgrelay == "relay_broadcast" then
            print("$relay_broadcast",from, tport, "relay", _msgid, taddr, ...)
            component.modem.broadcast(from, tport, "relay", _msgid, taddr, ...)
            local i = 1
            while i <= #baitian_modem.serversaddr.relay do
                if baitian_modem.serversaddr.relay[i] ~= selfaddr then
                    component.modem.send(baitian_modem.serversaddr.relay[i],
                                         from, 54, _msgrelay, _msgid, tport, ...)
                end
                i = i + 1
            end
        elseif _msgrelay == "relay_send" then
            print("$relay_send",taddr, from, tport, "relay", _msgid, ...)
            component.modem.send(taddr, from, tport, "relay", _msgid, ...)
            local i = 1
            while i <= #baitian_modem.serversaddr.relay do
                if baitian_modem.serversaddr.relay[i] ~= selfaddr then
                    component.modem.send(baitian_modem.serversaddr.relay[i],
                                         from, 54, _msgrelay, _msgid, port, ...)
                end
                i = i + 1
            end
        end
    end

end
event.listen("modem_message", pull)
