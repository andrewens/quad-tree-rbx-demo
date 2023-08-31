--!nonstrict
-- dependencies
local Types = require(script.Parent:FindFirstChild("Types"))

-- public
local Body = {}
local BodyMetatable = { __index = Body }

function Body.new(posVec2: Vector2, radius: number, mass: number): Types.Body
	--[[
        A Body is an element that is stored in a quadtree.
        In respect to quadtrees, its only necessary data is its position.

		For a larger project I would probably define this separately from the QuadTree
		so they're not married to each other.
    ]]

	local self: Types.Body = {
		Position = posVec2,
		Radius = radius,
		Mass = mass,
	}
	return setmetatable(self, BodyMetatable)
end

return Body
