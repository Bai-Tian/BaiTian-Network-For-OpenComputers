-- Baitian Terminal v0.1
-- by Bai_Tian
local shell = require("shell")
local term = require("term")
local text = require("text")
local event = require("event")
local component = require("component")
local computer = require("computer")
if not (component.isAvailable("gpu") and component.isAvailable("modem")) then print("錯誤:請插入modem，gpu") os.exit() end
local gpu = component.gpu
local modem = component.modem

local function exeresult(s, r) if s then if r then print(r) end end end

local Background = 0x4B4B4B
local Foreground = 0x00FF00

if not BaitianLib then BaitianLib = {} end
BaitianLib.fs = component.proxy(computer.getBootAddress())

-- if BaitianLib.fs.exists("baitian_tmodem.lua") then
    -- dofile("/" .. "baitian_tmodem.lua")
-- else
    -- print("網卡庫文件 <baitian_tmodem.lua> 不存在")
-- end

function BaitianLib.write(n, str)
    local h = BaitianLib.fs.open(n, "w")
    BaitianLib.fs.write(h, str)
    BaitianLib.fs.close(h)
end

require("filesystem").setAutorunEnabled(true)
BaitianLib.write("/autorun","os.execute(\"/home/BaitianTerminal\")")

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

function BaitianLib.configrewrite()
    BaitianLib.write(component.computer.address .. "-CFG.lua",
                     BaitianLib.tabletostring(TerminalConfig, "TerminalConfig"))
end

TerminalConfig = {}
TerminalConfig.Monitor = {}
if BaitianLib.fs.exists(component.computer.address .. "-CFG.lua") then
    dofile("/"..component.computer.address .. "-CFG.lua")
else
    TerminalConfig = {
        Welcome = " 0w0 お疲れさまでした~",
        Name = "BaiTian Network"
    }
    BaitianLib.configrewrite()
end

local function setbg()
    gpu.setBackground(Background)
    if Terminalsetbg then
        gpu.setForeground(Foreground)
    else
        gpu.setForeground(0xFFFFFF)
    end
end

local function topbar()
    local x, y = term.getCursor()
    term.setCursor(1, 1)
    local function f(n)
        if not TerminalConfig.Monitor[n] then
            TerminalConfig.Monitor[n] = ""
        end
    end
    f(-1)
    f(-2)
    f(-3)
    print("\x1b[37m\x1b[44m   " .. TerminalConfig.Name .. "   " ..
              TerminalConfig.Monitor[-1] .. TerminalConfig.Monitor[-2] ..
              TerminalConfig.Monitor[-3])
    gpu.setBackground(Background)
    local i = 1
    TerminalConfig.MonitorStr = ""
    while i <= #TerminalConfig.Monitor do
        if TerminalConfig.Monitor[i] ~= "0" then
            TerminalConfig.MonitorStr = TerminalConfig.MonitorStr ..
                                            string.format("%-20.20s",
                                                          tostring(TerminalConfig.Monitor[i]))
        end
        i = i + 1
    end
    print(TerminalConfig.MonitorStr)
    term.setCursor(x, y)
    setbg()
end

local header = {"\x1b[33mcmd>", 4} -- str,len
local function cursorheader()
    print(header[1], "\x1b[1A")
    term.setCursor(header[2] + 1, BaitianLib.sy)
    setbg()
end

local function message(...)
    local arg = {...}
    local from = arg[3]
    if baitian_modem then
    else
        from = "#" .. string.format("%.3s", from)
    end
    if arg[6] == "cmdline" then
        local x, y = term.getCursor()
        gpu.copy(1, y, BaitianLib.sx, 1, 0, 2 - BaitianLib.sy)
        term.setCursor(1, y)
        gpu.fill(1, y, BaitianLib.sx, 1, " ")
        if arg[7] == "warn" then
            print("\x1b[41m\x1b[37m[" .. from .. "]WARN:" .. arg[8]) -- 等待地址解析
        elseif arg[7] == "info" then
            print("[" .. from .. "]INFO:" .. arg[8])
        elseif arg[7] == "error" then
            print("\x1b[31m[" .. from .. "]ERROR:" .. arg[8])
        else
            print("\x1b[31m[" .. from .. "]ERROR:" .. "未知消息協議-" ..
                      arg[8])
        end
        setbg()
        term.setCursor(x, y)
        gpu.copy(1, 1, BaitianLib.sx, 1, 0, BaitianLib.sy - 1)
        gpu.fill(1, 1, BaitianLib.sx, 1, " ")
        topbar()
    end
end

local function gpuboot() -- gpu
    setbg()
    BaitianLib.sx, BaitianLib.sy = gpu.getViewport()
    term.clear()
    term.setCursor(1, BaitianLib.sy)
    print(TerminalConfig.Welcome)
    BaitianLib.topbartimer = event.timer(1, topbar, math.huge)
end

local function modemboot() -- modem
    modem.open(23)
    modem.open(53)
    event.listen("modem_message", message)
end

TerminalRunning = true
Terminalsetbg = true
gpuboot()
modemboot()

local his = {}
local cmdlist = {"lua", "cd", "ls", "exe", "remote", "exit", "terminalname"}
Baitian = {}

local function tab(line, pos)
    tabtable = {}
    local i = 1
    local ti = 1
    while i <= #cmdlist do
        if string.find(cmdlist[i], string.format("%." .. pos .. "s", line), 1) ==
            1 then
            tabtable[ti] = cmdlist[i]
            ti = ti + 1
        end
        i = i + 1
    end
    return tabtable
end


------------main------------
while TerminalRunning do
    topbar()
    cursorheader()
    local re = term.read(his, true, tab)
    re = tostring(re)
    re = string.gsub(re, "\n", " ", 1)
    re = text.trim(re)
    local rd = re
    re = text.tokenize(re)
    if re[1] == "exit" then
        event.cancel(BaitianLib.topbartimer)
        gpu.setBackground(0x000000)
        event.ignore("modem_message", message)
        term.clear()
        break
    elseif re[1] == "lua" then
        event.cancel(BaitianLib.topbartimer)
        BaitianLib.topbartimer = event.timer(0.05, topbar, math.huge)
        Terminalsetbg = false
        setbg()
        os.execute("lua")
        Terminalsetbg = true
        setbg()
        event.cancel(BaitianLib.topbartimer)
        BaitianLib.topbartimer = event.timer(1, topbar, math.huge)
    elseif re[1] == "terminalname" then
        if re[2] then
            TerminalName = re[2]
        else
            print("[終端]INFO: terminalname <名稱> --修改終端名稱")
        end
    elseif re[1] == "remote" then
        if baitian_modem then
        else
            re[2] = "#" .. string.format("%.3s", re[2])
        end
        modem.send(re[2], 23, re[3])
        if re[2] ~= "#nil" then
            print("\x1b[37m[終端]→[" .. re[2] .. "]SENT:" ..
                      "命令已發送，等待" .. re[2] .. "應答")
        else
            print("[終端]INFO: remote <地址> <命令> --遠程控制命令")
        end
    elseif re[1] == "exe" then
        if re[2] then
            rd = string.gsub(rd, "exe", "", 1)
            Terminalsetbg = false
            setbg()
            event.cancel(BaitianLib.topbartimer)
            xpcall(os.execute, exeresult, rd)
            Terminalsetbg = true
            setbg()
            topbar()
            event.timer(1, topbar, math.huge)
        else
            print("[終端]INFO: exe <命令> --運行OpenOS Shell命令")
        end
    elseif re[1] == "cd" then
        if re[2] then
            xpcall(os.execute, exeresult, shell.setWorkingDirectory(re[2]))
            print("\x1b[37m" .. shell.getWorkingDirectory() .. "：")
        else
            print("[終端]INFO: cd <路徑> --改變Shell當前路徑")
        end
    elseif re[1] == "ls" then
        if not re[2] then re[2] = " " end
        xpcall(os.execute, exeresult, "ls " .. re[2] .. " -hM --no-color")
    elseif not re[1] then
        print("[終端]INFO: 0w0 ?")
    else
        if Baitian[re[1]] then
            Baitian[re[1]].main()
        else
            print("\x1b[31m[終端]ERROR:" .. "未知命令-" .. re[1])
        end
    end
    topbar()
    BaitianLib.configrewrite()
end
