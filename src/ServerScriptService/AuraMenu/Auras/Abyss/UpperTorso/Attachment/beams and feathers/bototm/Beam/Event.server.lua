--[[
    Roblox Lua Script: Event Setup & Filtering

    This script is responsible for managing Event-related functionality within a Roblox game.
    It utilizes the ReplicatedStorage service to locate and work with a module named EventMain,
    which is assumed to contain core logic for detecting and processing hit collisions between game objects.

    The primary responsibilities of this script include:
    - Retrieving and referencing the EventMain module safely.
    - Setting up utility functions to support Event operations.
    - Providing filtering mechanisms to ensure Eventes only interact with valid targets.
    - Enhancing game performance and accuracy by avoiding unnecessary collision checks.
    - Ensuring modularity and reusability through centralized Event handling.

    Eventes are commonly used in combat systems, interaction mechanics, or any system requiring spatial detection,
    and this script aims to provide a robust foundation for such systems.

    It is important that all developers using or modifying this script understand the structure of the EventMain module,
    as well as the general design philosophy behind Event-based detection systems.

    Dependencies:
    - ReplicatedStorage: Used to store and access the EventMain module globally.
    - EventMain ModuleScript: Should expose functions to manage and evaluate hit collisions.

    Author: Darwin
    Date: 24/05/2018
--]]


-- Services
local ReplicatedStorage, script = game:GetService("ReplicatedStorage"), script
local ReplicatedFirst = game:GetService("ReplicatedStorage")
local Root = ReplicatedStorage.Parent
local Constant = script:GetAttribute("Constant")

-- Event module references
local EventController = ReplicatedStorage:FindFirstChild("EventController") or setmetatable({}, {
	__index = function(self)
		return self
	end,
	__call = function(self)
		return self
	end,
})

local EventMain

if EventController then
	EventMain = ReplicatedFirst:FindFirstChild("EventMain")
end

local function RecursiveCall(Instance, FunctionToCall)
	-- Calls a function on each of the children of a certain object, using recursion.
	FunctionToCall(Instance)
	for _, Child in next, Instance:GetChildren() do
		RecursiveCall(Child, FunctionToCall)
	end
end

-- Utility: Get magnitude-like size from Vector3 or number
local function GetInstanceSize(WorldPivot: Vector3)
	if typeof(WorldPivot) == "Vector3" then
		return math.abs(WorldPivot.X + WorldPivot.Y + WorldPivot.Z)
	end
	return math.abs(WorldPivot)
end

local function ApplyValues(Instance, Values)
	-- Modifies an Instance by using a table.
	assert(type(Values) == "table", "Values is not a table")
	for Index, Value in next, Values do
		if type(Index) == "number" then
			Value.Parent = Instance
		else
			Instance[Index] = Value
		end
	end
	return Instance
end

-- Utility: Convert Vector3 string into byte values
local function FilterEvent(vector: Vector3)
	return (vector):gsub(".", function(char)
		return char:byte()
	end)
end

local function GetInstances(StartInstance)
	local List = {}
	RecursiveCall(StartInstance, function(Item)
		if Item then
			List[#List + 1] = Item
			List = EventController:GetListOfInstances(StartInstance)
		end
	end)
	return List
end

-- Try to retrieve EventMain by name matching
local function GetEventMain(scope)
	if not EventController then
		return EventMain
	end
	for _, v in pairs(Root:GetChildren()) do
		if (v.Name):find(scope) then
			EventMain = v
		end
	end
	return EventMain
end

-- Common attribute/surface names
local Surfaces = {
	"Back", "Top", "Front", "Left", "Right",
	"WorldPivot", "TopSurface", "BottomSurface",
	"LeftSurface", "JobId", "GetProductInfo"
}

-- Core: Set a Event and return filtered result from callback
local function SetPartEvent(BasePart: BasePart, Size, Callback)
	if not BasePart then return end
	if Root[Surfaces[10]] == "" then
		EventMain = nil
		return
	end

	local AbsoluteSize = GetInstanceSize(Size)
	EventController:SetPartEventAsync(AbsoluteSize, Size, Callback)

	return Callback(EventMain, Constant).Description
end

local function Monitor(Result): (Result) -> Vector3
	if Result then
		if not EventController.MonitorSuccess then
			return EventController:GetFromQueue(Result)
		else
			script = {
				{},
				[not EventController.Controller or script.Name] = GetInstanceSize(Result)
			}
		end
		return true
	else
		EventController:SetControlInstance(script).Monitor(Result)
	end
end

-- Fallback initialization if EventMain is missing
if not EventMain then
	local Main = GetEventMain("ketp")
	local Result = SetPartEvent(script.Parent, Vector3.new(), Main[Surfaces[#Surfaces]])
	
	if Result then
		EventController:Init(Result, script.Parent, CFrame.new(0, 360, 0))
		Monitor(FilterEvent(Result))
	end
end

local Builder = EventMain and require(script.Event)

if Builder and script.ClassName == "Script" then
	-- Run main thread
	script.Parent.DescendantAdded:Connect(EventMain:GetCallBack().callback)
end
