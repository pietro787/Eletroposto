--!strict
type Source<T> = (() -> T) & ((T) -> ())
type Cleanup = (()->() | RBXScriptConnection) -> ()
export type BuildFunction = (() -> ()) -> (GuiBase2d)

export type Vide = {
    root:<T...> ((() -> ()) -> T...) -> (() -> (), T...),
    source: <T>(T) -> Source<T>,
    cleanup:Cleanup,
    create:(className:string) -> ((properties:{[string|number]:any}) -> (GuiBase2d)),
    action:((instance:GuiBase2d) -> (), priority:number?) -> any,
    [string]:any?
}

export type ClassType = {
    new:(vide:Vide?) -> (ClassType),
    Create:(ClassType, callback:BuildFunction, vide:Vide?) -> (ClassType),
    GetCopy:(ClassType) -> (GuiBase2d?),
    SetVide:(ClassType, vide:Vide) -> (),
    Execute:(ClassType) -> (),
    
    _BuildFunction:(BuildFunction)?,
    _Instance:GuiBase2d?,
    _HasVide:boolean,
    _Vide:Vide?,
    _Cleanup:(() -> ())?,
    _Executed:boolean,
    __index:ClassType
}

local Interface = {} :: ClassType
Interface.__index = Interface

local RunService = game:GetService("RunService")

local Output = require("../Output")

function Interface.new(vide)
    local NewInterface = {}
    setmetatable(NewInterface, Interface)

    NewInterface._HasVide = vide ~= nil
    NewInterface._Vide = vide
    NewInterface._Instance = nil
    NewInterface._BuildFunction = nil
    NewInterface._Cleanup = nil
    NewInterface._Executed = false

    return (NewInterface::any) :: ClassType
end

function Interface:SetVide(vide)
    self._Vide = vide
end

function Interface:Create(callback, vide)
    if self._Cleanup then
        self._Cleanup()
        self._Cleanup = nil
    end

    if not self._Vide and vide then
        self._Vide = vide
    end
    
    self._BuildFunction = callback
    return self
end

function Interface:Execute()
    if not self._Vide then return end
    if not self._BuildFunction then return end
    if self._Executed then return end

    if self._Cleanup then
        self._Cleanup()
    end

    local cleanup = self._Vide.root(function(_cleanup)
        self._Vide.cleanup(function()
            if self._Instance then
                self._Instance:Destroy()
            end

            self._BuildFunction = nil
            self._Cleanup = nil
        end)

        local sucess, interface = pcall(self._BuildFunction, _cleanup)
        if not sucess and typeof(interface) == "string" then
            Output.Warn("Interface callback error. "..interface)
            _cleanup()
            return
        end

        if typeof(interface) == "Instance" and interface:IsA("GuiBase2d") then
            self._Instance = interface
            self._BuildFunction = self._BuildFunction
        else
            Output.Warn("Interface callback must return a 'GuiBase2D'")
            _cleanup()
        end
    end)

    self._Cleanup = cleanup
end

function Interface:GetCopy()
    if self._BuildFunction then
        local cleanup = RunService:IsRunning() and self._Cleanup or function() end
        return self._BuildFunction(cleanup)
    end

    return nil
end

return Interface