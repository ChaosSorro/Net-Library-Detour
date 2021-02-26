-- Made with love <3 | https://cosmicnetworks.co/

function file.Read( filename, path )

	if ( path == true ) then path = "GAME" end
	if ( path == nil || path == false ) then path = "DATA" end

	local f = file.Open( filename, "rb", path )
	if ( !f ) then return end

	local str = f:Read( f:Size() )

	f:Close()

	if ( !str ) then str = "" end
	return str

end

function file.Write( filename, contents )

	local f = file.Open( filename, "wb", "DATA" )
	if ( !f ) then return end

	f:Write( contents )
	f:Close()

end

function file.Append( filename, contents )

	local f = file.Open( filename, "ab", "DATA" )
	if ( !f ) then return end

	f:Write( contents )
	f:Close()

end

if SERVER then
    --[[
        Because some servers said so...
        Your welcome - Anthony(76561198130115660)
    ]]

    local CFG = {
        consoleprint = false,

        recordargs = false,
        recordreturns = false,
    }

    -- Localize to prevent anything from altering the system, idk because backdoors can be smart
    local _print = print
    local _isfunction = isfunction
    local _tostring = tostring
    local _type = type
    local dbg = debug.getinfo
    local _util_TableToJSON = util.TableToJSON
    local _jit_util_funcinfo = jit.util.funcinfo
    local _concommand_Add = concommand.Add
    local _IsValid = IsValid

    _concommand_Add('detour_printconsole', function(pl)
        if _IsValid(pl) then return end
        if CFG.consoleprint then
            CFG.consoleprint = false
        else
            CFG.consoleprint = true
        end
    end)

    _concommand_Add('detour_recordargs', function(pl)
        if _IsValid(pl) then return end
        if CFG.recordargs then
            CFG.recordargs = false
        else
            CFG.recordargs = true
        end
    end)

    _concommand_Add('detour_recordreturns', function(pl)
        if _IsValid(pl) then return end
        if CFG.recordreturns then
            CFG.recordreturns = false
        else
            CFG.recordreturns = true
        end
    end)

    _print('[Detour] Created by Anthony(76561198130115660)')
    _print('[Detour] initializing...')

    local function DetourPrint(str)
        if CFG.consoleprint then
            _print('[Detour] ' .. str)
        end

        if CFG.writingprint then
            _print('[Detour] ' .. str)
        end
    end

    -- Stores all new functions with the old ones in pairs
    local RealFuncs = {}

    -- Perform a manuel detour and return the new function to override
    local function Detour(name, func, newfunc)
        DetourPrint('Manuel Detouring "' .. name .. '"')
        RealFuncs[newfunc] = func
        return newfunc
    end

    -- Define what the argument is
    local function definearg(arg)
        if arg == nil then
            arg = '[NIL]'
        else
            local _type_ = _type(arg)
            if _type_ == 'CUserCmd' then
                arg = 'Unsupported Value Type ' .. _type_
            elseif _type_ == 'Player' then
                arg = '[' .. _type_ .. '] ' .. arg:Nick() .. '(' .. arg:SteamID() .. ')'
            elseif _type_ == 'string' then
                arg = '[' .. _type_ .. '] "' .. arg .. '"'
            elseif _type_ == 'table' then
                arg = _util_TableToJSON(arg, false)
            else
                arg = '[' .. _type_ .. '] ' .. _tostring(arg)
            end
        end
        return arg
    end

    -- Perform an automatic printing detour and return the new function to override
    local function DetourAuto(name, func, args, retargs)
        DetourPrint('Auto Detouring "' .. name .. '"')
        if not retargs then
            retargs = {1,2,3,4,5,6,7}
        end
        local function newfunc(...)
            local source = dbg(2, 'S').source

            if args ~= nil then
                if CFG.recordargs then
                    local passedargs, printables = {...}, ''
                    for i=1, #args do
                        local arg = passedargs[args[i]]
                        if arg ~= nil then
                            printables = printables .. (i > 1 and ' :: ' or '') .. '(' .. i .. ')' .. definearg(arg)
                        end
                    end
                    if printables ~= '' then
                        if CFG.consoleprint then
                            _print('[Source: ' .. source .. '] ' .. name .. ' > ' .. printables)
                        end
                    elseif CFG.consoleprint then
                        _print('[Source: ' .. source .. '] ' .. name)
                    end
                elseif CFG.consoleprint then
                    _print('[Source: ' .. source .. '] ' .. name)
                end
            end

            if CFG.recordreturns then
                local a, b, c, d, e, f, g = func(...)
                if (a or b or c or d or e or f or g) then
                    local tbl = {}
                    tbl[#tbl+1] = (a ~= nil and a or '[NIL]')
                    tbl[#tbl+1] = (b ~= nil and b or '[NIL]')
                    tbl[#tbl+1] = (c ~= nil and c or '[NIL]')
                    tbl[#tbl+1] = (d ~= nil and d or '[NIL]')
                    tbl[#tbl+1] = (e ~= nil and e or '[NIL]')
                    tbl[#tbl+1] = (f ~= nil and f or '[NIL]')
                    tbl[#tbl+1] = (g ~= nil and g or '[NIL]')
                    local printables = ''
                    for i=1, #retargs do
                        local arg = tbl[retargs[i]]
                        if arg ~= '[NIL]' then
                            printables = printables .. (i > 1 and ' :: ' or '') .. '(' .. i .. ')' .. definearg(arg)
                        end
                    end
                    if CFG.consoleprint then
                        _print('[Source: ' .. source .. ']' .. ' [return] ' .. name .. ' > ' .. printables)
                    end
                end
                return a, b, c, d, e, f, g
            end

            return func(...)
        end
        RealFuncs[newfunc] = func
        return newfunc
    end

    -- Detour these two functions so that if they try and use this to check if a detour is in
    -- place they won't be able to know it's even active
    debug.getinfo = Detour("debug.getinfo", debug.getinfo, function(func, _type, ...)
        if _isfunction(func) and RealFuncs[func] then
            return dbg(RealFuncs[func], _type, ...)
        end
        return dbg(func, _type, ...)
    end)

    jit.util.funcinfo = Detour("jit.util.funcinfo", jit.util.funcinfo, function(func, pos, ...)
        if _isfunction(func) and RealFuncs[func] then
            return _jit_util_funcinfo(RealFuncs[func], pos, ...)
        end
        return _jit_util_funcinfo(func, pos, ...)
    end)

    -- Lets start this detouring yea?
    -- Uncomment these if you want the full logs of every net message
    -- Note* this break media player for what ever reason... i don't know why.
    --[[
    net.Start = DetourAuto("net.Start", net.Start, {1})
    net.Send = DetourAuto("net.Send", net.Send, {1,2})
    net.Broadcast = DetourAuto("net.Send", net.Broadcast, {1})

    net.WriteAngle = DetourAuto("net.WriteAngle", net.WriteAngle, {1})
    net.WriteBit = DetourAuto("net.WriteBit", net.WriteBit, {1})
    net.WriteBool = DetourAuto("net.WriteBool", net.WriteBool, {1})
    net.WriteColor = DetourAuto("net.WriteColor", net.WriteColor, {1})
    net.WriteData = DetourAuto("net.WriteData", net.WriteData, {1,2})
    net.WriteDouble = DetourAuto("net.WriteDouble", net.WriteDouble, {1})
    net.WriteEntity = DetourAuto("net.WriteEntity", net.WriteEntity, {1})
    net.WriteFloat = DetourAuto("net.WriteFloat", net.WriteFloat, {1})
    net.WriteInt = DetourAuto("net.WriteInt", net.WriteInt, {1,2})
    net.WriteMatrix = DetourAuto("net.WriteMatrix", net.WriteMatrix, {1})
    net.WriteString = DetourAuto("net.WriteString", net.WriteString, {1})
    net.WriteTable = DetourAuto("net.WriteTable", net.WriteTable, {1})
    net.WriteType = DetourAuto("net.WriteType", net.WriteType, {1})
    net.WriteUInt = DetourAuto("net.WriteUInt", net.WriteUInt, {1,2})
    net.WriteVector = DetourAuto("net.WriteVector", net.WriteVector, {1})

    net.ReadAngle = DetourAuto("net.ReadAngle", net.ReadAngle)
    net.ReadBit = DetourAuto("net.ReadBit", net.ReadBit)
    net.ReadBool = DetourAuto("net.ReadBool", net.ReadBool)
    net.ReadColor = DetourAuto("net.ReadColor", net.ReadColor)
    net.ReadData = DetourAuto("net.ReadData", net.ReadData, {1})
    net.ReadDouble = DetourAuto("net.ReadDouble", net.ReadDouble)
    net.ReadEntity = DetourAuto("net.ReadEntity", net.ReadEntity)
    net.ReadFloat = DetourAuto("net.ReadFloat", net.ReadFloat)
    net.ReadInt = DetourAuto("net.ReadInt", net.ReadInt, {1})
    net.ReadMatrix = DetourAuto("net.ReadMatrix", net.ReadMatrix)
    net.ReadString = DetourAuto("net.ReadString", net.ReadString)
    net.ReadTable = DetourAuto("net.ReadTable", net.ReadTable)
    net.ReadType = DetourAuto("net.ReadType", net.ReadType)
    net.ReadUInt = DetourAuto("net.ReadUInt", net.ReadUInt, {1})
    net.ReadVector = DetourAuto("net.ReadVector", net.ReadVector)
    ]]

    local _net_Receive = net.Receive
    net.Receive = Detour("net.Receive", net.Receive, function(name, func)
        local source = dbg(2, 'S').source
        local _name, _func = definearg(name), definearg(func)
        if CFG.consoleprint then
            _print("[Source: ".. source .. "] net.Receive > " .. _name)
        end
        local _oldfunc = func
        func = function(len, plr, ...)
            local source = dbg(2, 'S').source
            if CFG.consoleprint then
                _print("[Source: ".. source .. "] net.Receive [" .. name .. "] > " .. plr:Nick() .. '(' .. plr:SteamID() .. ')')
            end
            return _oldfunc(len, plr, ...)
        end
        return _net_Receive(name, func)
    end)

    _print('[Detour] Ready to go!')
end