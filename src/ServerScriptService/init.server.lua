--[[
	ROBLOX QuadTree interaction demo
	
	Oct. 26, 2022
	Rockraider400
]]

-- type definitions
type Body = {
	Position: Vector2,
	Radius: number,
	Mass: number,
}
type QuadNode = {
	Center: Vector2,
	SideLength: number,
	IsLeaf: boolean,
	Children: nil | { QuadNode },
}
type QuadTree = {
	Center: Vector2,
	SideLength: number,
	MaxElementsPerLeaf: number,
	RootNode: QuadNode,
	MaxDepth: number,
}

-- quadtree implementation
local Body
do
	Body = {}
	Body.Metatable = { __index = Body }

	function Body.new(posVec2: Vector2, radius: number, mass: number)
		--[[
			A body is an element that is stored in a quadtree. In respect to quadtrees, its only necessary 
			data is its position.
		]]

		local self = {
			Position = posVec2,
			Radius = radius,
			Mass = mass,
		}
		return setmetatable(self, Body.Metatable)
	end
end
local QuadNode
do
	QuadNode = {}
	QuadNode.Metatable = { __index = QuadNode }

	function QuadNode.new(center: Vector2, sideLength: number)
		--[[
			A QuadNode represents an axis-aligned two dimensional region in space. 
			QuadNodes either store elements (and we call it a leaf)
			Or a QuadNode stores smaller QuadNodes that subdivide its own region into four quadrants.
			(Quadrants will only exist as necessary to hold elements -- not all four will always be present).
		]]

		local self = {
			Center = center,
			SideLength = sideLength,

			IsLeaf = true,
			Elements = {},
			Children = nil, -- becomes an array when turned into a leaf
		}
		return setmetatable(self, QuadNode.Metatable)
	end
	function QuadNode:insert(body, maxElementsPerLeaf, depth, maxDepth)
		-- ignore bodies outside of our bounds
		local body_x, body_y
		do
			body_x, body_y = body.Position.X, body.Position.Y
			local min = self.Center - self.SideLength * Vector2.new(0.5, 0.5)
			local max = self.Center + self.SideLength * Vector2.new(0.5, 0.5)

			if body_x < min.X or body_x > max.X or body_y < min.Y or body_y > max.Y then
				return false
			end
		end

		if self.IsLeaf then
			if #self.Elements < maxElementsPerLeaf or depth >= maxDepth then
				--[[
					Simple case -- Node is a non-full leaf
				]]

				table.insert(self.Elements, body)

				return true
			else
				--[[
					Split case -- Node is a full leaf that we must split into quad nodes
				]]

				-- save elements
				local Elements = self.Elements

				-- convert node into a branch
				-- a branch doesn't hold elements but instead stores children nodes
				-- children can be branches or leaves
				self.IsLeaf = false
				self.Elements = nil
				self.Children = {}

				-- re-insert elements into children nodes (recursing)
				-- we rely on the Branch Case (see below) to make new children nodes as necessary for us
				for i, otherBody in pairs(Elements) do
					self:insert(otherBody, maxElementsPerLeaf, depth + 1, maxDepth)
				end

				-- note: the original body we're inserting gets inserted below
				-- (this is so we can return a boolean corresponding to that body being inserted successfully)
			end
		end

		if not self.IsLeaf then
			--[[ 
				Branch case -- Node is already a branch
			]]

			-- get the quadrant (child node) the body belongs in
			local quadrantIndex, direction
			local center_x, center_y = self.Center.X, self.Center.Y
			if body_x <= center_x then
				-- we know which quadrant a point belongs in by testing if the point is greater than
				-- or less than the midpoint (here, in two dimensions since it's a 2d quadtree)
				if body_y <= center_y then
					quadrantIndex = 0 -- quadrant indices are pretty arbitrary
					direction = Vector2.new(-1, -1)
				else
					quadrantIndex = 1
					direction = Vector2.new(-1, 1)
				end
			else
				if body_y <= center_y then
					quadrantIndex = 2
					direction = Vector2.new(1, -1)
				else
					quadrantIndex = 3
					direction = Vector2.new(1, 1)
				end
			end

			-- Create a new quadnode if it doesn't exist already
			local ChildNode = self.Children[quadrantIndex]
			if ChildNode == nil then
				local childSideLength = 0.5 * self.SideLength
				local childCenter = self.Center + 0.5 * childSideLength * direction

				ChildNode = QuadNode.new(childCenter, childSideLength) -- quadnodes initialize as leaves
				self.Children[quadrantIndex] = ChildNode
			end

			-- Insert body into the child node
			return ChildNode:insert(body, maxElementsPerLeaf, depth + 1, maxDepth)
		end

		-- (code shouldn't ever get this far)
		return false
	end
end
local QuadTree
do
	QuadTree = {}
	QuadTree.Metatable = { __index = QuadTree }

	function QuadTree.new(
		center: Vector2,
		sideLength: number,
		maxElementsPerLeaf: number, -- int
		maxDepth: number -- int
	)
		--[[ 
			Constructs a new quad tree within a given region
		]]

		local self = {
			Center = center,
			SideLength = sideLength,

			RootNode = QuadNode.new(center, sideLength),
			MaxElementsPerLeaf = maxElementsPerLeaf,
			MaxDepth = maxDepth,
		}
		return setmetatable(self, QuadTree.Metatable)
	end
	function QuadTree:insert(body: Body)
		--[[
			Insert a new element into the quadtree. Returns when element has found a home in a leaf such
			that all leaves have <= number of max elements per leaf.
		]]

		return self.RootNode:insert(
			body,
			self.MaxElementsPerLeaf, -- pass this so we don't have to store it in EVERY QUAD NODE yikes
			0,
			self.MaxDepth
		)
	end
	function QuadTree:clear()
		--[[ 
			Cuts off reference to root node, thus garbage-collecting all QuadNodes in the Tree
		]]

		self.RootNode = QuadNode.new(self.Center, self.SideLength)
	end
end

-- rendering the quadtree
local QuadrantPart
do
	QuadrantPart = {}

	-- CONSTANTS
	local THICKNESS = 0.1

	-- PUBLIC
	local Folder
	function QuadrantPart.new(Node: QuadNode, height: number)
		--[[
			A QuadrantPart is a part that represents a QuadNode and is rendered as a roblox part.
		]]

		-- functional object construction
		local Part = Instance.new("Part")
		Part.CFrame = CFrame.new(Vector3.new(Node.Center.X, height + 0.5 * THICKNESS, Node.Center.Y))
		Part.Size = Vector3.new(Node.SideLength, THICKNESS, Node.SideLength)
		Part.Anchored = true

		local SelectionBox = Instance.new("SelectionBox", Part)
		SelectionBox.Adornee = Part

		-- aesthetic properties
		Part.Name = "QuadrantPart"
		Part.Transparency = 1
		Part.CanCollide = false

		SelectionBox.LineThickness = 0.02
		SelectionBox.Color3 = Color3.fromRGB(166, 255, 0)

		Part.Parent = Folder
		return Part -- basepart comes with destroy() already :)
	end

	Folder = Instance.new("Folder", workspace)
	Folder.Name = "TreeRender"
end
local TreeRender
do
	TreeRender = {}
	TreeRender.Metatable = { __index = TreeRender }

	-- CONSTANTS
	local ROUND_PRECISION = 5 -- num of digits after decimal place

	-- PRIVATE
	local function getQuadIndex(center: Vector2)
		--[[
			Each QuadNode has a unique center position, so we map QuadNodes to their respective QuadrantParts
			by converting the center position into a string index we can hash the table with.
			
			We avoid floating point inconsistencies by rounding the input.
		]]

		local x = math.round(center.X * 10 ^ ROUND_PRECISION) * 10 ^ -ROUND_PRECISION
		local y = math.round(center.Y * 10 ^ ROUND_PRECISION) * 10 ^ -ROUND_PRECISION

		return tostring(x) .. "_" .. tostring(y)
	end
	local function renderNodeRecursive(self, ParentNode)
		--[[
			Post-order traversal for rendering each quad node in a quadtree		
		]]

		-- recurse over children
		if not ParentNode.IsLeaf then
			for i, ChildNode in pairs(ParentNode.Children) do
				renderNodeRecursive(self, ChildNode)
			end
		end

		-- create a new rendered QuadrantPart for this QuadNode
		-- or reuse an old one if it exists
		local parentIndex = getQuadIndex(ParentNode.Center)
		local ExistingQuadrantPart = self.OldQuadrantParts[parentIndex]

		if ExistingQuadrantPart == nil then
			-- create a new render for this quadrant
			ExistingQuadrantPart = QuadrantPart.new(ParentNode, self.Height)
		else
			-- save this reused quadrant part from being destroyed
			self.OldQuadrantParts[parentIndex] = nil
		end

		-- store quadrant part to the TreeRender
		self.NewQuadrantParts[parentIndex] = ExistingQuadrantPart
	end

	-- PUBLIC
	function TreeRender.new(height: number)
		--[[
			A TreeRender is responsible for rendering QuadTrees as a bunch of outlined boxes.
			Rendered QuadrantParts last between frames and are reused when possible, so a TreeRender
			is mostly a container for managing those QuadrantParts.
		]]

		local self = {
			OldQuadrantParts = {},
			NewQuadrantParts = {},

			Height = height,
		}
		return setmetatable(self, TreeRender.Metatable)
	end
	function TreeRender:updateRender(Tree: QuadTree)
		--[[
			Renders a QuadTree, with a selection box for every QuadNode in the QuadTree.	
			The Render persists between calls to this method, reusing rendered parts for the same QuadNodes.
		]]

		-- any quadrant part remaining in OldQuadrantParts will get destroyed at the end of this frame
		-- new quadrant parts are the parts we still need
		self.OldQuadrantParts = self.NewQuadrantParts
		self.NewQuadrantParts = {}

		-- update render for every root node, in a post-order traversal
		renderNodeRecursive(self, Tree.RootNode)

		-- destroy the rendered nodes that don't exist anymore
		for i, QuadrantPart in pairs(self.OldQuadrantParts) do
			QuadrantPart:Destroy()
		end
	end
end

-- running the interactive demo
local Server
do
	Server = {}
	Server.Metatable = { __index = Server }

	-- DEPENDENCIES
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RemoteEvents = ReplicatedStorage.RemoteEvents

	-- CONSTANTS
	local BALL_DIAMETER = 1
	local CLEARING_COOLDOWN = 15
	local SECONDS_PER_FRAME = 0.1
	local BUTTON_COLOR = Color3.new(1, 0, 1)
	local BLACK = Color3.new(0, 0, 0)
	local MAX_ELEMENTS_PER_LEAF = 1
	local MAX_DEPTH = 7

	-- PRIVATE METHODS
	local function frameUpdate(self)
		--[[
			For every ball, inserts a Body into the QuadTree and renders the QuadTree
			(this method is specific only to the QuadTree mechanics)
		]]

		-- clear the quadtree
		local QuadTree = self._QuadTree
		QuadTree:clear()

		-- add all balls to the quadtree
		for i, BasePart in pairs(self._Balls) do
			local position = Vector2.new(BasePart.Position.X, BasePart.Position.Z)

			QuadTree:insert(Body.new(position))
		end

		-- render the quadtree
		self._Render:updateRender(QuadTree)
	end
	local function readyToClear(self)
		--[[
			Returns true if CLEARING_COOLDOWN seconds have passed since the last clearing.
		]]

		return os.time() >= self._LastCleared + CLEARING_COOLDOWN
	end
	local function updateButtonColor(self)
		--[[
			Updates button color to reflect if it's ready or not for clearing
		]]

		local enabled = readyToClear(self)
		local ClearButton = self._ClearButton

		ClearButton.Color = enabled and BUTTON_COLOR or BLACK
		ClearButton.Fire.Enabled = enabled
		ClearButton.PointLight.Enabled = enabled
	end

	-- PUBLIC METHODS
	function Server.new(ClearButton, QuadPlatform)
		--[[
			Given template items from workspace, construct new Server singleton class
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

		local self = {
			-- PRIVATE MEMBERS
			_QuadTree = QuadTree.new(center, sideLength, MAX_ELEMENTS_PER_LEAF, MAX_DEPTH),
			_Render = TreeRender.new(height),
			_Balls = {}, -- array of BaseParts

			_LastCleared = 0,
			_ClearButton = ClearButton,
		}
		return setmetatable(self, Server.Metatable)
	end
	function Server:initialize()
		--[[
			Initialize demo to start working
		]]

		-- remote events
		RemoteEvents.NewBall.OnServerEvent:Connect(function(Player, ...)
			self:newBall(...)
		end)

		-- clear balls on ClearButton touch
		self._ClearButton.Touched:Connect(function(Part)
			self:clearBalls()
		end)

		-- updates on frame
		spawn(function()
			while true do
				-- update quadtree render
				frameUpdate(self)

				-- self explanatory
				updateButtonColor(self)

				wait(SECONDS_PER_FRAME)
			end
		end)
	end
	function Server:newBall(position: Vector3, velocity: Vector3, color: Color3)
		--[[
			Every frame, the ball gets put into the quadtree
			Physics is managed by ROBLOX though
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

		-- I AM SPEED
		Ball.Velocity = velocity
	end
	function Server:clearBalls()
		--[[ 
			Removes all balls from system. Returns true if successful
			
			Note that sufficient time must have passed before Server is ready to clear balls
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
end

-- initialize >:)
local ServerInstance = Server.new(workspace.ClearButton, workspace.QuadPlatform)
ServerInstance:initialize()
