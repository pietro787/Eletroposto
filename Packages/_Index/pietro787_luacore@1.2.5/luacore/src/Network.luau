export type Network = {
    GenerateOrder:(root:Folder?) -> (),
    SetNetworkRoot:(folder:Folder) -> (), 
    OnStart:(callback:()->()) -> ()
}

local Network = {}

local RunService = game:GetService("RunService")

local Output = require("./Output")

local loadOrder:{string} = {}
local callbacks = {}
local loaded = false

local rootFolder:Folder

local function ExecuteStart()
    for _, callback in callbacks do
        local sucess, err = pcall(callback)

        if not sucess then
            Output.Warn("Callback error. Error:"..err, "Newtwork")
        end
    end
end

function Network.GenerateOrder(root:Folder?):{string}
    if RunService:IsClient() then return {} end
    if next(loadOrder) then return loadOrder end
    if not rootFolder and root then
        print("setting root by net generator")
        rootFolder = root
    end

    if rootFolder then
        table.clear(loadOrder)
        for _, module in rootFolder:GetChildren() do
            if not module:IsA("ModuleScript") then continue end
            local sucess, err = pcall(require, module)

            if not sucess then
                Output.Warn(module.Name.." require error. "..err, "Network")
                continue
            end

            table.insert(loadOrder, module.Name)
        end

        ExecuteStart()
        return loadOrder
    else
        Output.Warn(" (GenerateOrder) root is nil", "Network")
    end

    return {}
end

function Network.SetNetworkRoot(folder:Folder)
    if typeof(folder) ~= "Instance" then Output.Warn(" (GenerateOrder) root must be a instance", "Network"); return end
    if not folder:IsA("Folder") then Output.Warn(" (GenerateOrder) root must be a folder", "Network"); return end

    rootFolder = folder
end

function Network.OnStart(callback)
    table.insert(callbacks, callback)
end

function Network.Init()
    if loaded then return end
    loaded = true

    local Event:RemoteEvent

    if RunService:IsServer() then
        Event = Instance.new("RemoteEvent")
        Event.Parent = script.Parent

        Event.OnServerEvent:Connect(function(player: Player, ...)
            if not rootFolder then
                Output.Warn("(Event) root is nil", "Network")
                return
            end

            if next(loadOrder) then
                (Event::RemoteEvent):FireClient(player, loadOrder)
                return
            end

            Event:FireClient(player, Network.GenerateOrder())
        end)
    else
        local received = false
        Event = script.Parent:WaitForChild("RemoteEvent", 15)

        if not Event or not Event:IsA("RemoteEvent") then
            Output.Error("LuaCore must be require at server and client")
            return
        end

        Event:FireServer()
        Event.OnClientEvent:Once(function(order) 
            if typeof(order) ~= "table" then return end
            if not rootFolder then 
                Output.Warn("(Event) root is nil", "Network")
                return 
            end

            table.clear(loadOrder)
            for _, packetName in order do
                if typeof(packetName) ~= "string" then continue end

                local module = rootFolder:WaitForChild(packetName, 2)
                if not module:IsA("ModuleScript") then continue end
                
                local sucess, err = pcall(require, module)
                if not sucess then
                    Output.Warn(module.Name.." require error. "..err, "Network")
                    continue
                end

                table.insert(loadOrder, module.Name)
            end

            received = true
            ExecuteStart()
        end)
        
        local MaxTokens = 10
        local DelayPerToken = 0.1
        local Tokens = MaxTokens

        while not received do
            if Tokens < 1 then
                Output.Error("Order event took too long ("..tostring(MaxTokens * DelayPerToken).."s)", false, "Network")
                break 
            end

            Tokens -= 1
            task.wait(DelayPerToken) 
        end
    end
end

return Network