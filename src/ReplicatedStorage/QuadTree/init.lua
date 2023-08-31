--!nonstrict
-- dependencies
local Body = require(script:FindFirstChild("Body"))
local QuadNode = require(script:FindFirstChild("QuadNode"))
local Types = require(script:FindFirstChild("Types"))

-- public
local QuadTree = {}
local QuadTreeMetatable = { __index = QuadTree }

QuadTree.Types = Types -- exposing public APIs to use QuadTree with
QuadTree.Body = Body

function QuadTree.new(
	center: Vector2,
	sideLength: number,
	maxElementsPerLeaf: number, -- int
	maxDepth: number -- int
): Types.QuadTree
	--[[
        Constructs a new quadtree within a given axis-aligned 2D region
        A QuadTree is a spatial partitioning data structure that allows you to quickly
        retrieve a set of points in a given region of 2D space.
        You can also use it to find nearby points, but I haven't implemented that here.
    ]]

	local self = {
		Center = center,
		SideLength = sideLength,

		RootNode = QuadNode.new(center, sideLength),
		MaxElementsPerLeaf = maxElementsPerLeaf,
		MaxDepth = maxDepth,
	}
	return setmetatable(self, QuadTreeMetatable)
end
function QuadTree:insert(body: Types.Body): boolean
	--[[
        Insert a new element into the quadtree. Returns when element has found a home in a leaf such
        that all leaves have <= number of max elements per leaf.

        Returns true if successful (i.e. the body is within the QuadTree's spatial bounds)
    ]]

	return self.RootNode:insert(
		body,
		self.MaxElementsPerLeaf, -- This is a parameter to avoid storing it in every QuadNode (that's a lot of memory)
        0,
		self.MaxDepth
	)
end
function QuadTree:clear(): nil
	--[[
        Cuts off reference to root node, thus garbage-collecting all QuadNodes in the Tree
    ]]

	self.RootNode = QuadNode.new(self.Center, self.SideLength)
end

return QuadTree
