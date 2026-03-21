local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationConfig = require(ReplicatedStorage.Shared.MutationConfig)

local InventoryService = {}

local function getBaseDefinition(baseId)
	return MutationConfig.BaseOrganisms[baseId]
end

local function isBaseOrganismUnlocked(playerData, baseId)
	return playerData.progression
		and playerData.progression.unlockedBaseOrganisms
		and playerData.progression.unlockedBaseOrganisms[baseId] == true
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

local function getSellValueForRarity(rarity)
	return MutationConfig.Economy.SellValuesByRarity[rarity] or 0
end

local function cloneMutantForClient(mutantRecord)
	return {
		instanceId = mutantRecord.instanceId,
		baseName = mutantRecord.baseName,
		displayName = mutantRecord.displayName,
		rarity = mutantRecord.rarity,
		traits = cloneTraits(mutantRecord.traits),
		summary = mutantRecord.summary,
		createdAt = mutantRecord.createdAt,
		sellValue = getSellValueForRarity(mutantRecord.rarity),
	}
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
	local recentMutants = {}
	local unlockedCount = 0

	for _, baseId in ipairs(MutationConfig.BaseOrganismOrder) do
		local definition = getBaseDefinition(baseId)
		local isUnlocked = isBaseOrganismUnlocked(playerData, baseId)
		if isUnlocked then
			unlockedCount += 1
		end

		table.insert(baseInventory, {
			id = baseId,
			name = definition.name,
			description = definition.description,
			unlocked = isUnlocked,
			quantity = playerData.inventory.baseOrganisms[baseId] or 0,
			unlockCost = definition.unlockCost or 0,
			unlockGrantCount = definition.unlockGrantCount or 0,
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

	for index = #playerData.inventory.mutants, math.max(#playerData.inventory.mutants - 5, 1), -1 do
		local mutantRecord = playerData.inventory.mutants[index]
		if mutantRecord then
			table.insert(recentMutants, cloneMutantForClient(mutantRecord))
		end
	end

	return {
		economy = {
			currencyName = MutationConfig.Economy.CurrencyName,
			dna = playerData.currencies.dna or 0,
		},
		baseInventory = baseInventory,
		organismSummary = {
			unlockedCount = unlockedCount,
			totalCount = #MutationConfig.BaseOrganismOrder,
		},
		insertedBase = insertedBase,
		activeMutation = activeMutation,
		mutantCount = #playerData.inventory.mutants,
		recentMutants = recentMutants,
		stats = {
			mutationsStarted = playerData.stats.mutationsStarted,
			mutationsCompleted = playerData.stats.mutationsCompleted,
			failures = playerData.stats.failures,
			mutantsSold = playerData.stats.mutantsSold,
			dnaEarned = playerData.stats.dnaEarned,
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

	if not isBaseOrganismUnlocked(playerData, baseId) then
		return false, ("Unlock %s before using it."):format(baseDefinition.name)
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

function InventoryService:UnlockBaseOrganism(player, baseId)
	local playerData = self:GetPlayerData(player)
	local baseDefinition = getBaseDefinition(baseId)

	if not baseDefinition then
		return false, "Unknown base organism."
	end

	if isBaseOrganismUnlocked(playerData, baseId) then
		return false, ("%s is already unlocked."):format(baseDefinition.name)
	end

	local unlockCost = baseDefinition.unlockCost or 0
	if unlockCost <= 0 then
		return false, "This organism cannot be unlocked."
	end

	local currentDna = playerData.currencies.dna or 0
	if currentDna < unlockCost then
		return false, ("You need %d DNA Credits to unlock %s."):format(unlockCost, baseDefinition.name)
	end

	playerData.currencies.dna = currentDna - unlockCost
	playerData.progression.unlockedBaseOrganisms[baseId] = true
	playerData.inventory.baseOrganisms[baseId] = (playerData.inventory.baseOrganisms[baseId] or 0) + (baseDefinition.unlockGrantCount or 0)
	self._dataService:MarkDirty(player)

	return true, self:GetClientState(player), {
		baseId = baseId,
		name = baseDefinition.name,
		unlockCost = unlockCost,
		grantedQuantity = baseDefinition.unlockGrantCount or 0,
	}
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

function InventoryService:SellMutant(player, mutantInstanceId)
	local playerData = self:GetPlayerData(player)

	for index, mutantRecord in ipairs(playerData.inventory.mutants) do
		if mutantRecord.instanceId == mutantInstanceId then
			local sellValue = getSellValueForRarity(mutantRecord.rarity)
			if sellValue <= 0 then
				return false, "This mutant cannot be sold."
			end

			table.remove(playerData.inventory.mutants, index)
			playerData.currencies.dna = (playerData.currencies.dna or 0) + sellValue
			playerData.stats.mutantsSold += 1
			playerData.stats.dnaEarned += sellValue
			self._dataService:MarkDirty(player)

			return true, self:GetClientState(player), {
				instanceId = mutantRecord.instanceId,
				displayName = mutantRecord.displayName,
				rarity = mutantRecord.rarity,
				sellValue = sellValue,
			}
		end
	end

	return false, "Mutant not found."
end

return InventoryService
