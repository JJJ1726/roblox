local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")
local DataService = require(servicesFolder:WaitForChild("DataService"))
local InventoryService = require(servicesFolder:WaitForChild("InventoryService"))
local MutationChamberService = require(servicesFolder:WaitForChild("MutationChamberService"))
local ResearchExchangeService = require(servicesFolder:WaitForChild("ResearchExchangeService"))
local OrganismUnlockService = require(servicesFolder:WaitForChild("OrganismUnlockService"))

DataService:Init()
InventoryService:Init(DataService)
MutationChamberService:Init(DataService, InventoryService)
ResearchExchangeService:Init(InventoryService)
OrganismUnlockService:Init(InventoryService)
