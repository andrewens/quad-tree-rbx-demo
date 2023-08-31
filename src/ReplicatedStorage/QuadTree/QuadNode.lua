--!nonstrict
-- dependencies
local Types = require(script.Parent:FindFirstChild("Types"))

-- public
local QuadNode = {}
local QuadNodeMetatable = { __index = QuadNode }

function QuadNode.new(center: Vector2, sideLength: number): Types.QuadNode
	--[[
        A QuadNode represents an axis-aligned two dimensional region in space.
        QuadNodes either store elements (and we call it a leaf)
        Or a QuadNode stores smaller QuadNodes that subdivide its own region into four quadrants.
        (Quadrants will only exist as necessary to hold elements -- not all four will always be present).
    ]]

	local self: Types.QuadNode = {
		Center = center,
		SideLength = sideLength,

		IsLeaf = true,
		Elements = {},
		Children = nil, -- becomes an array when turned into a leaf
	}
	return setmetatable(self, QuadNodeMetatable)
end
function QuadNode:insert(body: Types.Body, maxElementsPerLeaf: number, depth: number, maxDepth: number): boolean
	--[[
        Insert a Body into this QuadNode.
        QuadNode will split into child QuadNodes if it's a leaf and the number of Bodies it's holding exceeds maxElementsPerLeaf.

        Returns true if successful (i.e. the Body is in-bounds), false if not
    ]]

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
                Simple case -- this QuadNode is a non-full leaf
            ]]

			table.insert(self.Elements, body)
			return true
		else
			--[[
                Split case -- this QuadNode is a full leaf that we must split into quad nodes
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
            Branch case -- this QuadNode is already a branch
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

return QuadNode
