local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MutationConfig = require(ReplicatedStorage.Shared.MutationConfig)
local MutationRoller = require(ReplicatedStorage.Shared.MutationRoller)

local MutationChamberService = {}

local function ensureRemoteEvent(parent, name)
	local remote = parent:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	if remote then
		remote:Destroy()
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

local function ensureRemoteFunction(parent, name)
	local remote = parent:FindFirstChild(name)
	if remote and remote:IsA("RemoteFunction") then
		return remote
	end

	if remote then
		remote:Destroy()
	end

	remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function MutationChamberService:Init(dataService, inventoryService)
	self._dataService = dataService
	self._inventoryService = inventoryService
	self._scheduledMutations = {}

	self:_ensureRemotes()
	self:_ensureLabScene()
	self:_connectRemoteHandlers()

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:_onPlayerAdded(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._scheduledMutations[player.UserId] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_onPlayerAdded(player)
		end)
	end
end

function MutationChamberService:_ensureRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("MutationLabRemotes")
	if remoteFolder == nil then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "MutationLabRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	self._remotes = {
		OpenChamber = ensureRemoteEvent(remoteFolder, "OpenChamber"),
		StateUpdated = ensureRemoteEvent(remoteFolder, "StateUpdated"),
		MutationResolved = ensureRemoteEvent(remoteFolder, "MutationResolved"),
		GetState = ensureRemoteFunction(remoteFolder, "GetState"),
		InsertBaseOrganism = ensureRemoteFunction(remoteFolder, "InsertBaseOrganism"),
		StartMutation = ensureRemoteFunction(remoteFolder, "StartMutation"),
	}
end

function MutationChamberService:_ensureLabScene()
	local labFolder = workspace:FindFirstChild("MutationLab")
	if labFolder == nil then
		labFolder = Instance.new("Folder")
		labFolder.Name = "MutationLab"
		labFolder.Parent = workspace
	end

	local platform = labFolder:FindFirstChild("Platform")
	if platform == nil then
		platform = Instance.new("Part")
		platform.Name = "Platform"
		platform.Size = Vector3.new(30, 1, 30)
		platform.Position = Vector3.new(0, 0, 0)
		platform.Anchored = true
		platform.Material = Enum.Material.Metal
		platform.Color = Color3.fromRGB(45, 55, 70)
		platform.Parent = labFolder
	end

	local spawnPad = labFolder:FindFirstChild("SpawnPad")
	if spawnPad == nil then
		spawnPad = Instance.new("SpawnLocation")
		spawnPad.Name = "SpawnPad"
		spawnPad.Size = Vector3.new(8, 1, 8)
		spawnPad.Position = Vector3.new(0, 2, 12)
		spawnPad.Anchored = true
		spawnPad.Neutral = true
		spawnPad.Transparency = 0.15
		spawnPad.Material = Enum.Material.Neon
		spawnPad.Color = Color3.fromRGB(96, 255, 174)
		spawnPad.Parent = labFolder
	end

	local chamber = labFolder:FindFirstChild("Chamber")
	if chamber == nil then
		chamber = Instance.new("Part")
		chamber.Name = "Chamber"
		chamber.Size = Vector3.new(8, 10, 8)
		chamber.Position = Vector3.new(0, 5.5, -8)
		chamber.Anchored = true
		chamber.Material = Enum.Material.Glass
		chamber.Transparency = 0.2
		chamber.Color = Color3.fromRGB(89, 222, 255)
		chamber.Parent = labFolder

		local pointLight = Instance.new("PointLight")
		pointLight.Range = 14
		pointLight.Brightness = 2
		pointLight.Color = Color3.fromRGB(89, 222, 255)
		pointLight.Parent = chamber
	end

	local prompt = chamber:FindFirstChild("OpenPrompt")
	if prompt == nil then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "OpenPrompt"
		prompt.ActionText = "Open Chamber"
		prompt.ObjectText = "Mutation Lab"
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0.2
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.RequiresLineOfSight = false
		prompt.Parent = chamber
	end

	prompt.Triggered:Connect(function(player)
		self._remotes.OpenChamber:FireClient(player)
		self:PushState(player)
	end)
end

function MutationChamberService:_connectRemoteHandlers()
	self._remotes.GetState.OnServerInvoke = function(player)
		return self._inventoryService:GetClientState(player)
	end

	self._remotes.InsertBaseOrganism.OnServerInvoke = function(player, baseId)
		local success, response = self._inventoryService:InsertBaseOrganism(player, baseId)
		self:PushState(player)

		if success then
			return {
				success = true,
				state = response,
			}
		end

		return {
			success = false,
			error = response,
			state = self._inventoryService:GetClientState(player),
		}
	end

	self._remotes.StartMutation.OnServerInvoke = function(player)
		return self:_startMutation(player)
	end
end

function MutationChamberService:_onPlayerAdded(player)
	local playerData = self._dataService:WaitForData(player)
	if playerData == nil then
		return
	end

	local activeMutation = playerData.chamber.activeMutation
	if activeMutation then
		local currentTime = DateTime.now().UnixTimestamp
		if activeMutation.endsAt <= currentTime then
			self:_resolveMutation(player, activeMutation)
		else
			self:_scheduleMutation(player, activeMutation)
		end
	end

	self:PushState(player)
end

function MutationChamberService:_startMutation(player)
	local playerData = self._dataService:WaitForData(player)
	if playerData == nil then
		return {
			success = false,
			error = "Player data is not ready.",
		}
	end

	if playerData.chamber.activeMutation then
		return {
			success = false,
			error = "A mutation is already running.",
			state = self._inventoryService:GetClientState(player),
		}
	end

	local insertedBaseId = playerData.chamber.insertedBaseId
	if insertedBaseId == nil then
		return {
			success = false,
			error = "Insert a base organism first.",
			state = self._inventoryService:GetClientState(player),
		}
	end

	local startTimestamp = DateTime.now().UnixTimestamp
	local mutationRecord = {
		mutationId = HttpService:GenerateGUID(false),
		baseId = insertedBaseId,
		startedAt = startTimestamp,
		endsAt = startTimestamp + MutationConfig.MutationChamber.DurationSeconds,
		seed = Random.new():NextInteger(1, 2000000000),
	}

	local success, response = self._inventoryService:StartMutation(player, mutationRecord)
	if not success then
		return {
			success = false,
			error = response,
			state = self._inventoryService:GetClientState(player),
		}
	end

	self:_scheduleMutation(player, mutationRecord)
	self:PushState(player)

	return {
		success = true,
		state = response,
	}
end

function MutationChamberService:_scheduleMutation(player, mutationRecord)
	local userId = player.UserId
	self._scheduledMutations[userId] = mutationRecord.mutationId

	local remainingSeconds = math.max(mutationRecord.endsAt - DateTime.now().UnixTimestamp, 0)
	task.delay(remainingSeconds, function()
		if self._scheduledMutations[userId] ~= mutationRecord.mutationId then
			return
		end

		self:_resolveMutation(player, mutationRecord)
	end)
end

function MutationChamberService:_resolveMutation(player, mutationRecord)
	local playerData = self._dataService:GetData(player)
	if playerData == nil then
		return
	end

	local activeMutation = playerData.chamber.activeMutation
	if activeMutation == nil or activeMutation.mutationId ~= mutationRecord.mutationId then
		return
	end

	local result = MutationRoller.Roll(activeMutation.baseId, activeMutation.seed)
	local success, clientState, resolvedMutation = self._inventoryService:ResolveMutation(player, activeMutation, result)
	if not success then
		return
	end

	self._scheduledMutations[player.UserId] = nil
	if player.Parent == Players then
		self._remotes.StateUpdated:FireClient(player, clientState)
		self._remotes.MutationResolved:FireClient(player, resolvedMutation)
	end
end

function MutationChamberService:PushState(player)
	if player.Parent == nil then
		return
	end

	self._remotes.StateUpdated:FireClient(player, self._inventoryService:GetClientState(player))
end

return MutationChamberService
