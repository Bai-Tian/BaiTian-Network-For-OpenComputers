servername = "tb"

----------白天网络服务器 by Bai_Tian----------
swm= nil
ctrl = "0"
K = {}
K.fs = component.proxy(computer.getBootAddress())
modem = component.proxy(component.list("modem")())

-------------文件读写IO-------------
function K.write(n, str) -- 写入文件 "w"删除内容 "a"不删除
    local h = K.fs.open(n, "w")
    K.fs.write(h, str)
    K.fs.close(h)
end

function K.read(n) -- 读文件
    local h = K.fs.open(n)
    local data = ""
    while true do
        local tmp = K.fs.read(h, 2048)
        if tmp then
            data = data .. tmp
        else
            break
        end
    end
    K.fs.close(h)
    return data
end

function K.dofile(n) -- 编译文件
    local data = K.read(n)
    local fn, msg = load(data, "=" .. n)
    if fn then
        return fn()
    else
        modem.send(53,ctrl,msg)
    end
end
-------------字符串操作函数-------------
function K.stringsplit(str, p)
    local t = {}
    string.gsub(str, '[^' .. p .. ']+', function(n) table.insert(t, n) end)
    return t
end

function K.tabletostring(ta, taname)
    local function func(ta, taname)
        local result = taname .. "={}\n"
        for k, v in pairs(ta) do
            if type(v) ~= "table" then
                if type(v) == "string" then
                    result = result .. taname .. "[\"" .. k .. "\"]=" .. "\"" .. v ..
                                 "\"" .. "\n"
                else
                    result = result .. taname .. "[\"" .. k .. "\"]=" .. v .. "\n"
                end
            else
                k = taname .. "." .. k
                result = result .. func(v, k)
            end
        end
        return result
    end
    local re = func(ta, taname)
    return re
end
-------------启动配置文件-------------

function K.configrewrite() K.write("/config.lua",K.tabletostring(_CFG, "_CFG")) end
_CFG={}
if K.fs.exists("/config.lua") then
    K.dofile("/config.lua")
else
    K.configrewrite()
end

-------------服务启动-------------

function dns()
    if _CFG[domainpre] then
        modem.send(from,53,"succeeded",_CFG[domainpre])
    else
        modem.send(from,53,"not found")
    end
end

function dns_r()
    if _CFG[domainpre] and _CFG[domainpre]==from then
        _CFG[domainpre] =from
        modem.send(from,53,"edited")
        K.configrewrite()
    elseif not _CFG[domainpre] then
        _CFG[domainpre] =from
        modem.send(from,53,"created")
        K.configrewrite()
    else
        modem.send(from,53,"failed")
    end
end

function dns_l()
	modem.send(ctrl,53,K.read("/config.lua"))
end

function dns_sa()
	if swm then
		modem.setWakeMessage(swm)
		modem.send(ctrl,53,"setwakemessage")
	else
		modem.send(ctrl,53,"setwakemessage failed")
	end
end

function dns_st()
	modem.send(ctrl,53,"shutdown")
	computer.shutdown()
end

function dns_e()
if not _CFG[domainpre] then
        _CFG[domainpre] =from
        modem.send(from,53,"created")
        K.configrewrite()
	else
    _CFG[domainpre] =from
    modem.send(from,53,"edited")
    K.configrewrite()
	end
end

function domainverification(a)
    domainsu=nil
    domainpre=nil
	domaintable={}
    if domain then domaintable = K.stringsplit(domain, ".") end
    domainsu = domaintable[#domaintable]
    domainpre = domaintable[#domaintable-1]
    if domainpre and domainsu==servername and a==0 then dns() end
    if domainpre and domainsu==servername and a==1 then dns_r() end
	if domain==servername and a==10 then dns_l() end
	if domain==servername and a==11 then dns_sa() end
	if domain==servername and a==12 then dns_st() end
	if domainpre and domainsu==servername and a==13 then dns_e() end
end

function pull()
    data=nil from=nil cmd=nil domain=nil
    data = {computer.pullSignal(1)}
	if not data then data = {} end
    if data[4] == 53 and data[1] == "modem_message" then
        from=data[3]
        cmd=data[6]
		domain=data[7]
        if cmd=="dns" then
            domainverification(0)
        elseif cmd=="dns_register" then
			if from==ctrl then domainverification(13) else domainverification(1) end
		elseif cmd=="dns_list" and from==ctrl then
			domainverification(10)
		elseif cmd=="dns_setawake" and from==ctrl then
			swm=data[8]
			domainverification(11)
		elseif cmd=="dns_shutdown" and from==ctrl then
			domainverification(12)
        elseif cmd=="relay" then
            
        end
    end
    return false
end

modem.open(53)
while true do
	if _CFG["CTRL"] then ctrl=_CFG["CTRL"] end
    pull()
end
