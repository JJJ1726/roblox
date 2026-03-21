local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationConfig = require(ReplicatedStorage.Shared.MutationConfig)

local InventoryService = {}

local function getBaseDefinition(baseId)
	return MutationConfig.BaseOrganisms[baseId]
end

local function cloneTraits(traits)
	local clonedTraits = {}

	for _, trait in ipairs(traits or {}) do
		table.insert(clonedTraits, {
			id = trait.id,
			name = trait.name,
			rarity = trait.rarity,
		})
	end

	return clonedTraits
end

function InventoryService:Init(dataService)
	self._dataService = dataService
end

function InventoryService:GetPlayerData(player)
	return self._dataService:WaitForData(player)
end

function InventoryService:GetClientState(player)
	local playerData = self:GetPlayerData(player)
	local baseInventory = {}

	for _, baseId in ipairs(MutationConfig.BaseOrganismOrder) do
		local definition = getBaseDefinition(baseId)
		table.insert(baseInventory, {
			id = baseId,
			name = definition.name,
			description = definition.description,
			quantity = playerData.inventory.baseOrganisms[baseId] or 0,
		})
	end

	local insertedBase = nil
	if playerData.chamber.insertedBaseId then
		local insertedDefinition = getBaseDefinition(playerData.chamber.insertedBaseId)
		insertedBase = {
			id = insertedDefinition.id,
			name = insertedDefinition.name,
		}
	end

	local activeMutation = nil
	if playerData.chamber.activeMutation then
		local activeBaseDefinition = getBaseDefinition(playerData.chamber.activeMutation.baseId)
		activeMutation = {
			mutationId = playerData.chamber.activeMutation.mutationId,
			baseId = playerData.chamber.activeMutation.baseId,
			baseName = activeBaseDefinition.name,
			startedAt = playerData.chamber.activeMutation.startedAt,
			endsAt = playerData.chamber.activeMutation.endsAt,
		}
	end

	local lastResolvedMutation = nil
	if playerData.lastResolvedMutation then
		lastResolvedMutation = {
			mutationId = playerData.lastResolvedMutation.mutationId,
			success = playerData.lastResolvedMutation.success,
			baseName = playerData.lastResolvedMutation.baseName,
			displayName = playerData.lastResolvedMutation.displayName,
			rarity = playerData.lastResolvedMutation.rarity,
			traits = cloneTraits(playerData.lastResolvedMutation.traits),
			summary = playerData.lastResolvedMutation.summary,
			resolvedAt = playerData.lastResolvedMutation.resolvedAt,
		}
	end

	return {
		baseInventory = baseInventory,
		insertedBase = insertedBase,
		activeMutation = activeMutation,
		mutantCount = #playerData.inventory.mutants,
		stats = {
			mutationsStarted = playerData.stats.mutationsStarted,
			mutationsCompleted = playerData.stats.mutationsCompleted,
			failures = playerData.stats.failures,
		},
		lastResolvedMutation = lastResolvedMutation,
	}
end

function InventoryService:InsertBaseOrganism(player, baseId)
	local playerData = self:GetPlayerData(player)
	local baseDefinition = getBaseDefinition(baseId)

	if not baseDefinition then
		return false, "Unknown base organism."
	end

	if playerData.chamber.activeMutation then
		return false, "The chamber is already mutating."
	end

	if playerData.chamber.insertedBaseId then
		return false, "The chamber already contains a specimen."
	end

	local currentQuantity = playerData.inventory.baseOrganisms[baseId] or 0
	if currentQuantity < 1 then
		return false, ("No %s remaining."):format(baseDefinition.name)
	end

	playerData.inventory.baseOrganisms[baseId] = currentQuantity - 1
	playerData.chamber.insertedBaseId = baseId
	self._dataService:MarkDirty(player)

	return true, self:GetClientState(player)
end

function InventoryService:StartMutation(player, activeMutation)
	local playerData = self:GetPlayerData(player)

	if playerData.chamber.activeMutation then
		return false, "A mutation is already running."
	end

	if playerData.chamber.insertedBaseId == nil then
		return false, "Insert a base organism first."
	end

	playerData.chamber.activeMutation = activeMutation
	playerData.chamber.insertedBaseId = nil
	playerData.stats.mutationsStarted += 1
	self._dataService:MarkDirty(player)

	return true, self:GetClientState(player)
end

function InventoryService:ResolveMutation(player, mutationRecord, mutationResult)
	local playerData = self:GetPlayerData(player)
	local activeMutation = playerData.chamber.activeMutation

	if activeMutation == nil or activeMutation.mutationId ~= mutationRecord.mutationId then
		return false, "Mutation is no longer active."
	end

	playerData.chamber.activeMutation = nil
	playerData.stats.mutationsCompleted += 1

	local resolvedMutation = {
		mutationId = mutationRecord.mutationId,
		success = mutationResult.success,
		baseName = mutationResult.baseName,
		displayName = mutationResult.displayName,
		rarity = mutationResult.rarity,
		traits = cloneTraits(mutationResult.traits),
		summary = mutationResult.summary,
		resolvedAt = DateTime.now().UnixTimestamp,
	}

	if mutationResult.success then
		table.insert(playerData.inventory.mutants, {
			instanceId = mutationRecord.mutationId,
			baseId = mutationResult.baseId,
			baseName = mutationResult.baseName,
			displayName = mutationResult.displayName,
			rarity = mutationResult.rarity,
			traits = cloneTraits(mutationResult.traits),
			summary = mutationResult.summary,
			createdAt = resolvedMutation.resolvedAt,
		})
	else
		playerData.stats.failures += 1
	end

	playerData.lastResolvedMutation = resolvedMutation
	self._dataService:MarkDirty(player)

	return true, self:GetClientState(player), resolvedMutation
end

return InventoryService

