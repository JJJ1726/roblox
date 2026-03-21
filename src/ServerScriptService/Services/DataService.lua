local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = {}

local MutationConfig = require(ReplicatedStorage.Shared.MutationConfig)

local DATASTORE_NAME = "MutationLab_PlayerData_v1"
local AUTOSAVE_INTERVAL_SECONDS = 60

local playerDataLoadedSignal = Instance.new("BindableEvent")
local playerStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local loadedDataByPlayer = {}
local dirtyPlayers = {}

DataService.PlayerDataLoaded = playerDataLoadedSignal.Event

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopy(nestedValue)
	end

	return copy
end

local function createDefaultData()
	local starterInventory = {}

	for _, baseId in ipairs(MutationConfig.BaseOrganismOrder) do
		local baseDefinition = MutationConfig.BaseOrganisms[baseId]
		starterInventory[baseId] = baseDefinition.starterCount or 0
	end

	return {
		version = 1,
		inventory = {
			baseOrganisms = starterInventory,
			mutants = {},
		},
		chamber = {
			insertedBaseId = nil,
			activeMutation = nil,
		},
		stats = {
			mutationsStarted = 0,
			mutationsCompleted = 0,
			failures = 0,
		},
		lastResolvedMutation = nil,
	}
end

local function mergeDefaults(target, defaults)
	for key, defaultValue in pairs(defaults) do
		if target[key] == nil then
			target[key] = deepCopy(defaultValue)
		elseif type(target[key]) == "table" and type(defaultValue) == "table" then
			mergeDefaults(target[key], defaultValue)
		end
	end
end

local function sanitizeLoadedData(rawData)
	local sanitizedData = type(rawData) == "table" and rawData or {}
	mergeDefaults(sanitizedData, createDefaultData())
	return sanitizedData
end

function DataService:Init()
	if self._initialized then
		return
	end

	self._initialized = true

	Players.PlayerAdded:Connect(function(player)
		self:_loadPlayerData(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_saveAndReleasePlayerData(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_loadPlayerData(player)
		end)
	end

	task.spawn(function()
		self:_autosaveLoop()
	end)

	game:BindToClose(function()
		self:_flushAllPlayers()
	end)
end

function DataService:_loadPlayerData(player)
	if loadedDataByPlayer[player] then
		return
	end

	local loadedData = createDefaultData()
	local success, result = pcall(function()
		return playerStore:GetAsync(tostring(player.UserId))
	end)

	if success and result ~= nil then
		loadedData = sanitizeLoadedData(result)
	elseif not success then
		warn(("[DataService] Failed to load data for %s: %s"):format(player.Name, tostring(result)))
	end

	loadedDataByPlayer[player] = loadedData
	dirtyPlayers[player] = false
	playerDataLoadedSignal:Fire(player)
end

function DataService:GetData(player)
	return loadedDataByPlayer[player]
end

function DataService:WaitForData(player)
	while player.Parent ~= nil and loadedDataByPlayer[player] == nil do
		task.wait()
	end

	return loadedDataByPlayer[player]
end

function DataService:MarkDirty(player)
	if loadedDataByPlayer[player] ~= nil then
		dirtyPlayers[player] = true
	end
end

function DataService:SavePlayerData(player)
	local playerData = loadedDataByPlayer[player]
	if playerData == nil then
		return true
	end

	if not dirtyPlayers[player] then
		return true
	end

	local payload = deepCopy(playerData)
	local success, err = pcall(function()
		playerStore:UpdateAsync(tostring(player.UserId), function()
			return payload
		end)
	end)

	if not success then
		warn(("[DataService] Failed to save data for %s: %s"):format(player.Name, tostring(err)))
		return false, err
	end

	dirtyPlayers[player] = false
	return true
end

function DataService:_saveAndReleasePlayerData(player)
	self:SavePlayerData(player)
	loadedDataByPlayer[player] = nil
	dirtyPlayers[player] = nil
end

function DataService:_autosaveLoop()
	while self._initialized do
		task.wait(AUTOSAVE_INTERVAL_SECONDS)

		for _, player in ipairs(Players:GetPlayers()) do
			self:SavePlayerData(player)
		end
	end
end

function DataService:_flushAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		self:SavePlayerData(player)
	end
end

return DataService
