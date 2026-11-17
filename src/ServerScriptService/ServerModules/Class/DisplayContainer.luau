--!strict
local ServerStorage = game:GetService("ServerStorage")
type Content = {
    Index:number,
    Name:string,
    Model:Model
}

export type ClassType = {
    new: (model:Model) -> ClassType,
    SetItem: (ClassType, name:string, index:number?) -> (number?),
    GetItem: (ClassType, Player:Player, ItemIndex:number) -> (),
    GetContents: (ClassType) -> ({Content}),

    __itens:{Content},
    __model:Model,
    __prefab:Folder,
    __index:ClassType
}

local DisplayContainer = {} :: ClassType
DisplayContainer.__index = DisplayContainer

local function SetupModel(model:Model)
    local prefabs = model:FindFirstChild("Prefabs")
    if not prefabs then return false end

    for index, part in prefabs:GetChildren() do
        if not part:IsA("Part") then continue end
        
        part.Name = tostring(index)
    end

    return true
end

function DisplayContainer.new(model)
    local NewDisplayContainer = {}
    setmetatable(NewDisplayContainer, DisplayContainer)
    assert(SetupModel(model), "[DISPLAYCONTAINER] SetupModel error \n"..debug.traceback())

    NewDisplayContainer.__itens = {}
    NewDisplayContainer.__model = model
    NewDisplayContainer.__prefab = model:FindFirstChild("Prefabs")

    return NewDisplayContainer :: any
end

function DisplayContainer:SetItem(name, index)
    if not index then
        
    end

    local part = self.__prefab:FindFirstChild(tostring(index))
    if not part then return nil end

    local ItensFolder = ServerStorage:FindFirstChild("Itens")
    if not ItensFolder then return nil end

    local Item = ItensFolder:FindFirstChild(name)
    if not Item then return nil end

    return index
end

function DisplayContainer:GetItem()
    
end

function DisplayContainer:GetContents()
    return {}
end


return DisplayContainer