local Output = {}

local RunService = game:GetService("RunService")

const Preset = RunService:IsServer() and "SERVER" or "CLIENT"

function Output.Warn(msg:string, callerName:string?)
    local body = (callerName or "") .." warn, "
	warn(debug.traceback("[LUACORE-"..Preset.."] ".. (callerName and body or "").. msg))
end

function Output.Error(msg:string, fake:boolean?, callerName:string?)
    local body = (callerName or "") .." error, "
	
    if fake then
        task.spawn(function()
            error("[LUACORE-"..Preset.."] ".. (callerName and body or "").. msg)
        end)

        return
	end

   error(debug.traceback("[LUACORE-"..Preset.."] ".. (callerName and body or "").. msg))
end

return Output