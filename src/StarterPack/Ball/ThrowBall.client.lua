-- DEPENDENCIES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEvents = ReplicatedStorage.RemoteEvents
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")

-- CONSTANTS
local BALL_SPEED = 0
local COLOR = BrickColor.Random()

-- INITIALIZE
local function throwBall()
	--[[
		Throws a ball toward player's 3d mouse position
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
