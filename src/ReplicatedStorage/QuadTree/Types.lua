--!nonstrict
--[[
    Type definitions for Luau's built-in type inference engine
]]

-- A Body is an object we put into the Quadtree -- like a star or planet if we're simulating gravity.
-- The quadtree only cares about the position, but a physics algorithm might need radius or mass too!
export type Body = {
	Position: Vector2,
	Radius: number,
	Mass: number,
}

-- A QuadNode is a single square in the QuadTree.
-- It holds Bodies and other QuadNodes in a recursive tree structure
export type QuadNode = {
	Center: Vector2,
	SideLength: number,
	IsLeaf: boolean,
	Children: nil | { QuadNode },
}

-- The QuadTree stores a reference to the root QuadNode
-- and defines how deep we're willing to recurse,
-- and how many Bodies fit in a QuadNode before it should split QuadNodes
export type QuadTree = {
	Center: Vector2,
	SideLength: number,
	MaxElementsPerLeaf: number,
	RootNode: QuadNode,
	MaxDepth: number,
}

return {}
