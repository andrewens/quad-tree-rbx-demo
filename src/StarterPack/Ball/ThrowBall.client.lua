-- dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage.RemoteEvents
local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")

-- constant
local COLOR = BrickColor.Random().Color

-- initialize
local function throwBall()
	--[[
		Balls are initialized on the server, so we fire a RemoteEvent to make a new ball.
	]]
	-- make a ball at handle position
	RemoteEvents.NewBall:FireServer(Handle.Position, COLOR)
end
Tool.Activated:Connect(throwBall)
