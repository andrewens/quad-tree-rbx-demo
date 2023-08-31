--!nonstrict
-- dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuadTree = require(ReplicatedStorage:FindFirstChild("QuadTree"))
local TreeRender = require(ReplicatedStorage:FindFirstChild("TreeRender"))

local RemoteEvents = ReplicatedStorage.RemoteEvents
local Body = QuadTree.Body

-- constant
local BALL_DIAMETER = 1
local CLEARING_COOLDOWN = 15
local SECONDS_PER_FRAME = 0.1
local BUTTON_COLOR = Color3.new(1, 0, 1)
local BLACK = Color3.new(0, 0, 0)
local MAX_ELEMENTS_PER_LEAF = 1
local MAX_DEPTH = 7

-- private
local function frameUpdate(self: Server): nil
	--[[
        For every ball, inserts a Body into the QuadTree and renders the QuadTree
        (this method is specific only to the QuadTree mechanics)
    ]]

	-- clear the quadtree
	self._QuadTree:clear()

	-- add all balls to the quadtree
	for i, BasePart in pairs(self._Balls) do
		local position = Vector2.new(BasePart.Position.X, BasePart.Position.Z)
		self._QuadTree:insert(Body.new(position))
	end

	-- render the quadtree
	self._Render:updateRender(self._QuadTree)
end
local function readyToClear(self: Server): boolean
	--[[
        Returns true if CLEARING_COOLDOWN seconds have passed since the last clearing.
    ]]
	return os.time() >= self._LastCleared + CLEARING_COOLDOWN
end
local function updateButtonColor(self: Server): nil
	--[[
        Updates button color to reflect if it's ready or not for clearing
    ]]

	local enabled = readyToClear(self)
	local ClearButton = self._ClearButton

	ClearButton.Color = enabled and BUTTON_COLOR or BLACK
	ClearButton.Fire.Enabled = enabled
	ClearButton.PointLight.Enabled = enabled
end

-- public
local Server = {}
local ServerMetatable = { __index = Server }

export type Server = {}

function Server.new(ClearButton: BasePart, QuadPlatform: BasePart): Server
	--[[
        Given template items from workspace, construct new Server singleton class.
		The Server holds a QuadTree, a TreeRender, and a set of Ball Instances.

		Every frame, the QuadTree is cleared and all the Balls are added to it.
		The TreeRender is updated to reflect the new structure of the QuadTree.

		When the ClearButton is touched, all of the Balls are destroyed.

		Balls are created when Players fire the NewBall RemoteEvent with their tool.
    ]]

	-- geometric values
	local center = Vector2.new(QuadPlatform.Position.X, QuadPlatform.Position.Z)
	local sideLength = QuadPlatform.Size.X
	local height = QuadPlatform.Position.Y + 0.5 * QuadPlatform.Size.Y

	-- clear button aesthetic
	do
		local Fire = Instance.new("Fire", ClearButton)
		Fire.Color = BUTTON_COLOR

		local Light = Instance.new("PointLight", ClearButton)
		Light.Color = BUTTON_COLOR
		Light.Range = 25
		Light.Brightness = 5
	end

	local self: Server = {
		-- private
		_QuadTree = QuadTree.new(center, sideLength, MAX_ELEMENTS_PER_LEAF, MAX_DEPTH),
		_Render = TreeRender.new(height),
		_Balls = {}, -- array of BaseParts

		_LastCleared = 0,
		_ClearButton = ClearButton,
	}
	return setmetatable(self, ServerMetatable)
end
function Server:initialize(): nil
	--[[
        Initialize demo to start working
    ]]

	-- spawn balls when player uses tool
	RemoteEvents.NewBall.OnServerEvent:Connect(function(Player, ...)
		local Ball = self:newBall(...)
		Ball:SetNetworkOwner(Player) -- this makes the physics a lot smoother
	end)

	-- clear all balls on ClearButton touch
	self._ClearButton.Touched:Connect(function(Part)
		self:clearBalls()
	end)

	-- update the render & button color every frame
	task.spawn(function()
		while true do
			frameUpdate(self) -- update quadtree render
			updateButtonColor(self)

			task.wait(SECONDS_PER_FRAME)
		end
	end)
end
function Server:newBall(position: Vector3, color: Color3): BasePart
	--[[
        Create a new Ball RBX Instance and add it to the Server, to be put into the QuadTree
    ]]

	-- functional properties
	local Ball = Instance.new("Part")
	Ball.Shape = Enum.PartType.Ball
	Ball.Anchored = false
	Ball.CanCollide = true
	Ball.Size = BALL_DIAMETER * Vector3.new(1, 1, 1)
	Ball.Position = position

	-- aesthetic properties
	Ball.Name = "Ball" .. tostring(#self._Balls)
	Ball.Color = color or Color3.new(0, 0, 0)
	Ball.Material = Enum.Material.SmoothPlastic

	-- parent & store
	table.insert(self._Balls, Ball)
	Ball.Parent = workspace

	return Ball
end
function Server:clearBalls(): boolean
	--[[
        Removes all balls from system if the debounce is ready.
        Returns true if successful.
    ]]

	-- has it been long enough?
	if not readyToClear(self) then
		return false
	end

	-- destroy all balls
	for i, BallPart in pairs(self._Balls) do
		BallPart:Destroy()
	end
	self._Balls = {}

	-- update last cleared
	self._LastCleared = os.time()

	return true
end

return Server
