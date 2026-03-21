local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationConfig = require(ReplicatedStorage.Shared.MutationConfig)

local MutationRoller = {}

local rarityPool = {}
local traitsByRarity = {}

local function addToRarityPool()
	if #rarityPool > 0 then
		return
	end

	for _, rarityId in ipairs(MutationConfig.RarityOrder) do
		local rarityDefinition = MutationConfig.RarityTiers[rarityId]
		table.insert(rarityPool, {
			id = rarityId,
			weight = rarityDefinition.weight,
		})
	end
end

local function buildTraitPools()
	if next(traitsByRarity) ~= nil then
		return
	end

	for _, trait in ipairs(MutationConfig.Traits) do
		traitsByRarity[trait.rarity] = traitsByRarity[trait.rarity] or {}
		table.insert(traitsByRarity[trait.rarity], trait)
	end
end

local function pickWeighted(randomObject, weightedItems)
	local totalWeight = 0

	for _, item in ipairs(weightedItems) do
		totalWeight += item.weight
	end

	local roll = randomObject:NextNumber(0, totalWeight)
	local cursor = 0

	for _, item in ipairs(weightedItems) do
		cursor += item.weight
		if roll <= cursor then
			return item
		end
	end

	return weightedItems[#weightedItems]
end

local function buildSecondaryTraitPool(primaryTrait, rarityId)
	local adjustedPool = {}
	local rarityWeights = MutationConfig.SecondaryTraitWeights[rarityId] or {}

	for _, trait in ipairs(MutationConfig.Traits) do
		if trait.id ~= primaryTrait.id then
			local rarityMultiplier = rarityWeights[trait.rarity] or 0
			local adjustedWeight = trait.weight * rarityMultiplier

			if adjustedWeight > 0 then
				table.insert(adjustedPool, {
					id = trait.id,
					name = trait.name,
					rarity = trait.rarity,
					weight = adjustedWeight,
				})
			end
		end
	end

	return adjustedPool
end

function MutationRoller.Roll(baseId, seed)
	addToRarityPool()
	buildTraitPools()

	local baseDefinition = MutationConfig.BaseOrganisms[baseId]
	assert(baseDefinition, ("Unknown base organism: %s"):format(tostring(baseId)))

	local randomObject = Random.new(seed)
	if randomObject:NextNumber() <= MutationConfig.MutationChamber.FailureChance then
		return {
			success = false,
			baseId = baseId,
			baseName = baseDefinition.name,
			displayName = MutationConfig.FailureResult.displayName,
			rarity = "Failure",
			traits = {},
			summary = MutationConfig.FailureResult.summary,
		}
	end

	local rarityRoll = pickWeighted(randomObject, rarityPool)
	local primaryTrait = pickWeighted(randomObject, traitsByRarity[rarityRoll.id])
	local traits = {
		{
			id = primaryTrait.id,
			name = primaryTrait.name,
			rarity = primaryTrait.rarity,
		},
	}

	if randomObject:NextNumber() <= MutationConfig.MutationChamber.SecondaryTraitChance then
		local secondaryTraitPool = buildSecondaryTraitPool(primaryTrait, rarityRoll.id)
		if #secondaryTraitPool > 0 then
			local secondaryTrait = pickWeighted(randomObject, secondaryTraitPool)
			table.insert(traits, {
				id = secondaryTrait.id,
				name = secondaryTrait.name,
				rarity = secondaryTrait.rarity,
			})
		end
	end

	local summary
	if traits[2] then
		summary = ("%s core stabilized with %s residue."):format(traits[1].name, traits[2].name)
	else
		summary = ("%s core stabilized cleanly."):format(traits[1].name)
	end

	return {
		success = true,
		baseId = baseId,
		baseName = baseDefinition.name,
		displayName = ("%s %s"):format(traits[1].name, baseDefinition.name),
		rarity = rarityRoll.id,
		traits = traits,
		summary = summary,
	}
end

return MutationRoller

