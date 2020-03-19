-- Baitian Modem Library v0.1
-- by Bai_Tian
-- 客户端网卡函数库
if not baitian_modem then baitian_modem = {} end
baitian_modem._version = 0.1
if not baitian_modem.domain then baitian_modem.domain = {} end
if not BaitianLib then BaitianLib = {} end
_G.event = require("event")
_G.component = require("component")
local computer = require("computer")
BaitianLib.fs = component.proxy(computer.getBootAddress())
component.modem.open(53) -- DNS
component.modem.open(54) -- relay
component.modem.open(55) -- file

-------------文件读写IO-------------
function BaitianLib.write(n, str)
    local h = BaitianLib.fs.open(n, "w")
    BaitianLib.fs.write(h, str)
    BaitianLib.fs.close(h)
end

function BaitianLib.stringsplit(str, p)
    local t = {}
    string.gsub(str, '[^' .. p .. ']+', function(n) table.insert(t, n) end)
    return t
end
-------------启动地址文件-------------
if BaitianLib.fs.exists("SERVERSADDR.lua") then
    dofile("/" .. "SERVERSADDR.lua")
else
    print("地址列表文件 <SERVERSADDR.lua> 不存在")
    computer.beep(1500, 1)
    os.exit()
end
-------------中继协议-------------
baitian_modem.msgid = 1
old = {component = {modem = {}}, event = {}}
old.component.modem.broadcast = component.modem.broadcast
function _G.component.modem.broadcast(port, ...)
    local arg = {...}
    local id = component.computer.address .. tostring(baitian_modem.msgid)
    baitian_modem.msgid = baitian_modem.msgid + 1
    local i = 1
    while i <= #baitian_modem.serversaddr.relay do
        old.component.modem.send(baitian_modem.serversaddr.relay[i], 54,
                                 "relay_broadcast", id, port, ...)
        i = i + 1
    end
end

old.component.modem.send = component.modem.send
function _G.component.modem.send(addr, port, ...)
    local arg = {...}
    local id = component.computer.address .. tostring(baitian_modem.msgid)
    baitian_modem.msgid = baitian_modem.msgid + 1
    local i = 1
    while i <= #baitian_modem.serversaddr.relay do
        old.component.modem.send(baitian_modem.serversaddr.relay[i], 54,
                                 "relay_send", id, port, addr, ...)
        i = i + 1
    end
end

baitian_modem.msgidcache = {}
local cachei = 0
old.event.listen = event.listen
function _G.event.listen(...)
    local arg = {...}
    if arg[1] == "modem_message" then
        local function func(name, selfaddr, from, port, dis, _msgrelay, _msgid, ...)
            if _msgrelay == "relay" then
                if not baitian_modem.msgidcache[_msgid] then
                    baitian_modem.msgidcache[_msgid] = 1
                    return arg[2](name, selfaddr, from, port, dis, ...)
                end
            else
                return arg[2](name, selfaddr, from, port, dis, _msgrelay,
                              _msgid, ...)
            end
        end
        if cachei > 10 then
            cachei = 0
            baitian_modem.msgidcache = {}
        else
            cachei = cachei + 1
        end
        return old.event.listen(arg[1], func)
    else
        return old.event.listen(...)
    end
end

old.event.pull = event.pull
function _G.event.pull(...)
    local arg = {...}
    if (#arg == 2 and (arg[2] == "modem_message" or arg[2] == "modem")) or
        (#arg == 1 and (arg[1] == "modem_message" or arg[1] == "modem")) then
            baitian_modem.eventpulldata=nil
            local function func(...)
                baitian_modem.eventpulldata={...}
            end
            local t=computer.uptime()
            if #arg==2 then baitian_modem.eventpullsecond=arg[1] end
            local el=event.listen("modem_message",func)
                while not baitian_modem.eventpulldata and computer.uptime()<t+baitian_modem.eventpullsecond do
                    print("waiting",computer.uptime())
                    old.event.pull(0.05,"#$%")
                end
            event.cancel(el)
            if baitian_modem.eventpulldata then return table.unpack(baitian_modem.eventpulldata) else return nil end
    end
    return old.event.pull(...)
end
-------------域名解析-------------
local function domainverification(domain)
    local domainsu = nil
    local domainpre = nil
    local domaintable = {}
    if domain then domaintable = BaitianLib.stringsplit(domain, ".") end
    domainsu = domaintable[#domaintable]
    domainpre = domaintable[#domaintable - 1]
    if domainsu and domainpre then
        return domainsu
    else
        return "domain name is nil"
    end
end

local function bsend(port, ...)
    local arg = {...}
    if arg[1] == "dns" or arg[1] == "dns_register" then
        local domainsu = domainverification(arg[2])
        if baitian_modem.serversaddr.dns[domainsu] then
            component.modem.send(baitian_modem.serversaddr.dns[domainsu], port,
                                 ...)
        end
    end
end

function baitian_modem.dnsp(d)
    bsend(53, "dns", d)
    local i = 0
    repeat
        i = i + 1
        a = {event.pull(0.2, "modem")}
    until (a[1] == "modem_message" and
        (a[6] == "succeeded" or a[6] == "not found")) or i > 5
    if not a[6] then
        a[6] = "connection failed"
    else
        baitian_modem.domain[d] = a[7]
    end
    return a[7], a[6]
end

function baitian_modem.dns(d)
    local a, b
    if baitian_modem.domain[d] then
        a = baitian_modem.domain[d]
        b = "from the cache"
    else
        a, b = baitian_modem.dnsp(d)
    end
    return a, b
end

function baitian_modem.dns_register(d)
    bsend(53, "dns_register", d)
    local i = 0
    repeat
        i = i + 1
        a = {event.pull(0.2, "modem")}
    until (a[1] == "modem_message" and
        (a[6] == "created" or a[6] == "edited" or a[6] == "failed")) or i > 5
    if not a[6] then a[6] = "connection failed" end
    return a[6]
end

