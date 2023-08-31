--!nonstrict
-- dependencies
local Server = require(script:FindFirstChild("Server"))

-- run the interactive demo
local PlatformModel = workspace.Platform
local ServerInstance = Server.new(PlatformModel.ClearButton, PlatformModel.QuadPlatform)
ServerInstance:initialize()
