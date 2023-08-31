--!nonstrict
-- dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuadTree = require(ReplicatedStorage:FindFirstChild("QuadTree"))
local Types = QuadTree.Types

-- constant
local PART_THICKNESS = 0.1
local OUTLINE_COLOR = Color3.fromRGB(166, 255, 0)
local LINE_THICKNESS = 0.02

-- private
local Folder = Instance.new("Folder", workspace)
Folder.Name = "TreeRender"

-- public
local QuadrantPart = {}

function QuadrantPart.new(Node: Types.QuadNode, height: number): BasePart
	--[[
		A QuadrantPart is a BasePart that visualizes a QuadNode.
		It uses a SelectionBox for the green outline.
	]]

	-- match size/position of QuadNode
	local Part = Instance.new("Part")
	Part.CFrame = CFrame.new(Vector3.new(Node.Center.X, height + 0.5 * PART_THICKNESS, Node.Center.Y))
	Part.Size = Vector3.new(Node.SideLength, PART_THICKNESS, Node.SideLength)
	Part.Anchored = true

	-- aesthetic properties
	Part.Name = "QuadrantPart"
	Part.Transparency = 1
	Part.CanCollide = false

	local SelectionBox = Instance.new("SelectionBox")
	SelectionBox.Parent = Part
	SelectionBox.Adornee = Part
	SelectionBox.LineThickness = LINE_THICKNESS
	SelectionBox.Color3 = OUTLINE_COLOR

	Part.Parent = Folder
	return Part -- basepart comes with destroy() already :)
end

return QuadrantPart
