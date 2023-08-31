--!nonstrict
-- dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuadrantPart = require(script:FindFirstChild("QuadrantPart"))
local QuadTree = require(ReplicatedStorage:FindFirstChild("QuadTree"))

local Types = QuadTree.Types

-- const
local ROUND_PRECISION = 5 -- num of digits after decimal place

-- private
local function getQuadIndex(center: Vector2): string
	--[[
        Each QuadNode has a unique center position, so we map QuadNodes to their respective QuadrantParts
        by converting the center position into a string index we can hash the table with.

        We avoid floating point inconsistencies by rounding the input.
    ]]

	local x = math.round(center.X * 10 ^ ROUND_PRECISION) * 10 ^ -ROUND_PRECISION
	local y = math.round(center.Y * 10 ^ ROUND_PRECISION) * 10 ^ -ROUND_PRECISION

	return tostring(x) .. "_" .. tostring(y)
end
local function renderNodeRecursive(self, ParentNode: Types.QuadNode): nil
	--[[
        Use post-order recursive traversal to render each QuadNode in the QuadTree
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

-- public
local TreeRender = {}
local TreeRenderMetatable = { __index = TreeRender }

export type TreeRender = {
	OldQuadrantParts: { [string]: BasePart },
	NewQuadrantParts: { [string]: BasePart },
	Height: number,
}

function TreeRender.new(height: number): TreeRender
	--[[
        A TreeRender is responsible for rendering QuadTrees as a bunch of outlined boxes.
        Rendered QuadrantParts last between frames and are reused when possible, so a TreeRender
        is mostly a container for managing those QuadrantParts.
    ]]

	local self: TreeRender = {
		OldQuadrantParts = {},
		NewQuadrantParts = {},
		Height = height,
	}
	return setmetatable(self, TreeRenderMetatable)
end
function TreeRender:updateRender(Tree: Types.QuadTree)
	--[[
        Renders a QuadTree, with a selection box for every QuadNode in the QuadTree.	
        The render persists between calls to this method, reusing the same parts for the same QuadNodes.
    ]]

	-- any quadrant part remaining in OldQuadrantParts will get destroyed at the end of this frame
	-- new quadrant parts are the parts we still need
	self.OldQuadrantParts = self.NewQuadrantParts
	self.NewQuadrantParts = {}

	-- update render for every root node, in a post-order traversal
	renderNodeRecursive(self, Tree.RootNode)

	-- destroy the rendered nodes that don't exist anymore
	for i, BasePart in pairs(self.OldQuadrantParts) do
		BasePart:Destroy()
	end
end

return TreeRender
