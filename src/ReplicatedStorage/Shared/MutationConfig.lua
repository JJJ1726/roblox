local MutationConfig = {}

MutationConfig.BaseOrganismOrder = {
	"proto_slime",
}

MutationConfig.BaseOrganisms = {
	proto_slime = {
		id = "proto_slime",
		name = "Proto Slime",
		description = "A stable starter ooze grown for repeatable chamber tests.",
		starterCount = 3,
	},
}

MutationConfig.MutationChamber = {
	DurationSeconds = 10,
	FailureChance = 0.18,
	SecondaryTraitChance = 0.75,
}

MutationConfig.RarityOrder = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
}

MutationConfig.RarityTiers = {
	Common = {
		id = "Common",
		weight = 60,
		color = Color3.fromRGB(153, 241, 155),
	},
	Rare = {
		id = "Rare",
		weight = 28,
		color = Color3.fromRGB(107, 199, 255),
	},
	Epic = {
		id = "Epic",
		weight = 10,
		color = Color3.fromRGB(255, 168, 94),
	},
	Legendary = {
		id = "Legendary",
		weight = 2,
		color = Color3.fromRGB(255, 224, 92),
	},
}

MutationConfig.ResultStyles = {
	Failure = {
		color = Color3.fromRGB(255, 108, 108),
	},
}

MutationConfig.Traits = {
	{ id = "gooey", name = "Gooey", rarity = "Common", weight = 30 },
	{ id = "elastic", name = "Elastic", rarity = "Common", weight = 25 },
	{ id = "spotted", name = "Spotted", rarity = "Common", weight = 18 },
	{ id = "glimmer", name = "Glimmer", rarity = "Rare", weight = 16 },
	{ id = "thorned", name = "Thorned", rarity = "Rare", weight = 14 },
	{ id = "frostbit", name = "Frostbit", rarity = "Rare", weight = 10 },
	{ id = "radiant", name = "Radiant", rarity = "Epic", weight = 8 },
	{ id = "phase_shifted", name = "Phase-Shifted", rarity = "Epic", weight = 6 },
	{ id = "celestial", name = "Celestial", rarity = "Legendary", weight = 2 },
}

MutationConfig.SecondaryTraitWeights = {
	Common = {
		Common = 1,
		Rare = 0.2,
		Epic = 0.05,
		Legendary = 0,
	},
	Rare = {
		Common = 0.7,
		Rare = 1,
		Epic = 0.2,
		Legendary = 0.05,
	},
	Epic = {
		Common = 0.35,
		Rare = 0.8,
		Epic = 1,
		Legendary = 0.15,
	},
	Legendary = {
		Common = 0.15,
		Rare = 0.45,
		Epic = 0.9,
		Legendary = 1,
	},
}

MutationConfig.FailureResult = {
	displayName = "Unstable Sludge",
	summary = "The chamber destabilized and produced inert sludge.",
}

return MutationConfig

