local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")
local DataService = require(servicesFolder:WaitForChild("DataService"))
local InventoryService = require(servicesFolder:WaitForChild("InventoryService"))
local MutationChamberService = require(servicesFolder:WaitForChild("MutationChamberService"))

DataService:Init()
InventoryService:Init(DataService)
MutationChamberService:Init(DataService, InventoryService)

