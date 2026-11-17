--!strict
export type ClassType = {
    new:(states:{string}) -> (ClassType),
    Transit:(ClassType, newState:string) -> (),
    GetState:(ClassType) -> (string),
    Check:(ClassType, state:string) -> (boolean),
    IsValidState:(ClassType, state:string) -> (boolean),
    IsLocked:(ClassType) -> (boolean),
    LockToggle:(ClassType) -> (),
    OnChange:(ClassType, (oldState:string, newState:string) -> ()) -> (),
    OnLock:(ClassType, (lockState:boolean) -> ()) -> (),

    __state:string,
    __validStates:{string},
    __ChangeCallbacks:{(oldState:string, newState:string) -> ()},
    __LockCallbacks:{(lockState:boolean) -> ()},
    __locked:boolean,
    __index:ClassType
}

local StateManager = {} :: ClassType
StateManager.__index = StateManager

local function ActivateCallbacks<T...>(callbacks:{(T...) -> any}, ...: T...)
    for _, callback in callbacks do
        local sucess, errMsg = pcall(callback, ...)

        if not sucess then
            warn("[STATEMANAGER] callback error "..errMsg.."\n", debug.traceback())
        end
    end
end

function StateManager.new(validStates:{string})
    local NewStateManager = {}
    setmetatable(NewStateManager, StateManager)
    assert(typeof(validStates) == "table", "[STATEMANAGER] states must be a table")
    assert(validStates[1], "[STATEMANAGER] states lenght is lower then 1")

    NewStateManager.__validStates = validStates
    NewStateManager.__ChangeCallbacks = {}
    NewStateManager.__LockCallbacks = {}
    NewStateManager.__locked = false
    NewStateManager.__state = validStates[1]

    return NewStateManager :: any
end

function StateManager:Transit(newState)
    if not self:IsValidState(newState) then return end
    if self.__state == newState then return end
    if self.__locked then return end
    assert(typeof(newState) == "string", "[STATEMANAGER] state must be a string")

    local old = self.__state
    self.__state = newState

    ActivateCallbacks(self.__ChangeCallbacks, old, newState)
end

function StateManager:Check(state)
    assert(typeof(state) == "string", "[STATEMANAGER] state must be a string")
    return self.__state == state
end

function StateManager:IsValidState(state)
    assert(typeof(state) == "string", "[STATEMANAGER] state must be a string")
    return table.find(self.__validStates, state) ~= nil
end

function StateManager:LockToggle()
    self.__locked = not self.__locked
    ActivateCallbacks(self.__LockCallbacks, self.__locked)
end

function StateManager:IsLocked()
    return self.__locked
end

function StateManager:OnChange(callback)
    assert(typeof(callback) == "function", "[STATEMANAGER] callback must be a function")
    table.insert(self.__ChangeCallbacks, callback)
end

function StateManager:OnLock(callback)
    assert(typeof(callback) == "function", "[STATEMANAGER] callback must be a function")
    table.insert(self.__LockCallbacks, callback)
end

return StateManager