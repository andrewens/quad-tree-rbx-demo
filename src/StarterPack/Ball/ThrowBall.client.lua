-- dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEvents = ReplicatedStorage.RemoteEvents
local Player = Players.LocalPlayer
local Tool = script.Parent

local Mouse = Player:GetMouse()
local Handle = Tool:WaitForChild("Handle")

-- constant
local BALL_SPEED = 0 -- it's set to 0 so you can drop balls on top of each other, but you can change it if you'd like :)
local COLOR = BrickColor.Random()

-- initialize
local function throwBall()
	--[[
		Throws a ball toward player's 3d mouse position.
		Balls are initialized on the server, so we fire a RemoteEvent to make a new ball.
	]]

	-- get character root part (return if nil)
	local RootPart
	do
		local Char = Player.Character
		if Char == nil then
			return
		end

		RootPart = Char:FindFirstChild("HumanoidRootPart")
		if RootPart == nil then
			return
		end
	end

	-- throw a ball
	local direction = (Mouse.Hit.Position - RootPart.Position).Unit
	RemoteEvents.NewBall:FireServer(Handle.Position, direction * BALL_SPEED, COLOR.Color)
end
Tool.Activated:Connect(throwBall)
