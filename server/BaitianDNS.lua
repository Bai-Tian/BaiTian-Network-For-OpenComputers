-- Baitian DNS Server v1.0
-- by Bai_Tian
-- 本服务器需要安全网关保证不受外部网络影响
if BaitianDNSisrunning then os.exit() end
BaitianDNSisrunning=true
if not BaitianLib then BaitianLib = {} end
BaitianDNS={}
BaitianDNS.servername = "tb"
BaitianDNS.control = "0"

local event = require("event")
local computer = require("computer")
local component = require("component")
local modem = component.modem
local baitian_modem = require("baitian_modem")
BaitianLib.fs = component.proxy(computer.getBootAddress())

print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
-------------文件读写IO-------------
function BaitianLib.write(n, str)
    local h = BaitianLib.fs.open(n, "w")
    BaitianLib.fs.write(h, str)
    BaitianLib.fs.close(h)
end

function BaitianLib.read(n)
    local h = BaitianLib.fs.open(n)
    local data = ""
    while true do
        local tmp = BaitianLib.fs.read(h, 2048)
        if tmp then
            data = data .. tmp
        else
            break
        end
    end
    BaitianLib.fs.close(h)
    return data
end

function BaitianLib.stringsplit(str, p)
    local t = {}
    string.gsub(str, '[^' .. p .. ']+', function(n) table.insert(t, n) end)
    return t
end

function BaitianLib.tabletostring(ta, taname)
    local function func(ta, taname)
        local result = taname .. "={}\n"
        for k, v in pairs(ta) do
            if v and v~="" then
                if type(v) ~= "table" then
                    if type(v) == "string" then
                        if type(k) == "string" then
                            result = result .. taname .. "[\"" .. k .. "\"]=" .. "\"" .. v .. "\"" .. "\n"
                        else
                            result =
                                result .. taname .. "[" .. k .. "]=" .. "\"" .. v .. "\"" .. "\n"
                        end
                    else
                        if type(k) == "string" then
                            result = result .. taname .. "[\"" .. k .. "\"]=" .. v .. "\n"
                        else
                            result =
                                result .. taname .. "[" .. k .. "]=" .. v .. "\n"
                        end
                    end
                else
                    k = taname .. "." .. k
                    result = result .. func(v, k)
                end
            end
        end
        return result
    end
    local re = func(ta, taname)
    return re
end

-------------启动配置文件-------------
function BaitianLib.configrewrite()
    BaitianLib.write(component.computer.address .. "-DOMAIN.lua",
                     BaitianLib.tabletostring(BaitianDNS.domain, "BaitianDNS.domain"))
end

BaitianDNS.domain = {}
if BaitianLib.fs.exists(component.computer.address .. "-DOMAIN.lua") then
    dofile("/"..component.computer.address .. "-DOMAIN.lua")
else
    BaitianLib.configrewrite()
end

if BaitianDNS.domain["CTRL"] then BaitianDNS.control=BaitianDNS.domain["CTRL"] end
old.component.modem.send(BaitianDNS.control,23,"cmdline","info","DNS server <"..BaitianDNS.servername.."> is starting...")

-------------服务启动-------------
local function dns()
    if BaitianDNS.domain[BaitianDNS.domainpre] then
        modem.send(BaitianDNS.from,53,"succeeded",BaitianDNS.domain[BaitianDNS.domainpre])
        print("$dns succeeded",BaitianDNS.domain[BaitianDNS.domainpre])
    else
        modem.send(BaitianDNS.from,53,"not found")
        print("$dns not found",BaitianDNS.domainpre)
    end
end

local function dns_r()
    if BaitianDNS.domain[BaitianDNS.domainpre] and BaitianDNS.domain[BaitianDNS.domainpre]==BaitianDNS.from then
        BaitianDNS.domain[BaitianDNS.domainpre] =BaitianDNS.from
        old.component.modem.send(BaitianDNS.control,23,"cmdline","info","#"..string.format("%3.3s",BaitianDNS.from).." edited <"..BaitianDNS.domainpre.."."..BaitianDNS.servername..">")
        modem.send(BaitianDNS.from,53,"edited")
        BaitianLib.configrewrite()
        print("$register",BaitianDNS.domainpre,"edited")
    elseif not BaitianDNS.domain[BaitianDNS.domainpre] then
        BaitianDNS.domain[BaitianDNS.domainpre] =BaitianDNS.from
        old.component.modem.send(BaitianDNS.control,23,"cmdline","info","#"..string.format("%3.3s",BaitianDNS.from).." registered <"..BaitianDNS.domainpre.."."..BaitianDNS.servername..">")
        modem.send(BaitianDNS.from,53,"created")
        BaitianLib.configrewrite()
        print("$register",BaitianDNS.domainpre,"created")
    else
        old.component.modem.send(BaitianDNS.control,23,"cmdline","info","#"..string.format("%3.3s",BaitianDNS.from).." tried to register <"..BaitianDNS.domainpre.."."..BaitianDNS.servername..">,but it failed")
        modem.send(BaitianDNS.from,53,"failed")
        print("$register",BaitianDNS.domainpre,"failed")
    end
end

local function dns_l()
	old.component.modem.send(BaitianDNS.control,23,"cmdline","info",BaitianLib.read("/"..component.computer.address .. "-DOMAIN.lua"))
end

local function dns_sa()
	if BaitianDNS.swm then
		modem.setWakeMessage(BaitianDNS.swm)
		old.component.modem.send(BaitianDNS.control,23,"cmdline","info","setwakemessage")
	else
		old.component.modem.send(BaitianDNS.control,23,"cmdline","warn","setwakemessage failed")
	end
end

local function dns_st()
	old.component.modem.send(BaitianDNS.control,23,"cmdline","info","shutdown")
	computer.shutdown()
end

local function dns_e()
if not BaitianDNS.domain[BaitianDNS.domainpre] then
        BaitianDNS.domain[BaitianDNS.domainpre] =BaitianDNS.from
        modem.send(BaitianDNS.from,53,"created")
        BaitianLib.configrewrite()
	else
    BaitianDNS.domain[BaitianDNS.domainpre] =BaitianDNS.from
    modem.send(BaitianDNS.from,53,"edited")
    BaitianLib.configrewrite()
	end
end

local function domainverification(a)
    BaitianDNS.domainsu=nil
    BaitianDNS.domainpre=nil
	BaitianDNS.domaintable={}
    if domain then BaitianDNS.domaintable = BaitianLib.stringsplit(domain, ".") end
    BaitianDNS.domainsu = BaitianDNS.domaintable[#BaitianDNS.domaintable]
    BaitianDNS.domainpre = BaitianDNS.domaintable[#BaitianDNS.domaintable-1]
    if BaitianDNS.domainpre and BaitianDNS.domainsu==BaitianDNS.servername and a==0 then dns() end
    if BaitianDNS.domainpre and BaitianDNS.domainsu==BaitianDNS.servername and a==1 then dns_r() end
	if domain==BaitianDNS.servername and a==10 then dns_l() end
	if domain==BaitianDNS.servername and a==11 then dns_sa() end
	if domain==BaitianDNS.servername and a==12 then dns_st() end
	if BaitianDNS.domainpre and BaitianDNS.domainsu==BaitianDNS.servername and a==13 then dns_e() end
end

local function pull(...)
    print("$pull",...)
    BaitianDNS.data=nil BaitianDNS.from=nil BaitianDNS.cmd=nil domain=nil
    BaitianDNS.data = {...}
	if not BaitianDNS.data then BaitianDNS.data = {} end
        BaitianDNS.from=BaitianDNS.data[3]
        BaitianDNS.cmd=BaitianDNS.data[6]
		domain=BaitianDNS.data[7]
        if BaitianDNS.cmd=="dns" then
            domainverification(0)
        elseif BaitianDNS.cmd=="dns_register" then
			if BaitianDNS.from==BaitianDNS.control then domainverification(13) else domainverification(1) end
		elseif BaitianDNS.cmd=="dns_list" and BaitianDNS.from==BaitianDNS.control then
			domainverification(10)
		elseif BaitianDNS.cmd=="dns_setawake" and BaitianDNS.from==BaitianDNS.control then
			BaitianDNS.swm=BaitianDNS.data[8]
			domainverification(11)
		elseif BaitianDNS.cmd=="dns_shutdown" and BaitianDNS.from==BaitianDNS.control then
			domainverification(12)
        end
        if BaitianDNS.domain["CTRL"] then BaitianDNS.control=BaitianDNS.domain["CTRL"] end
end

modem.open(53)
event.listen("modem_message", pull)
old.component.modem.send(BaitianDNS.control,23,"cmdline","info","DNS service has been started successfully!")
print("$DNS service has been started successfully!")