local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResearchExchangeService = {}

local function ensureRemoteFolder()
	local remoteFolder = ReplicatedStorage:FindFirstChild("MutationLabRemotes")
	if remoteFolder == nil then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "MutationLabRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	return remoteFolder
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

function ResearchExchangeService:Init(inventoryService)
	self._inventoryService = inventoryService

	local remoteFolder = ensureRemoteFolder()
	self._sellMutantRemote = ensureRemoteFunction(remoteFolder, "SellMutant")

	self._sellMutantRemote.OnServerInvoke = function(player, mutantInstanceId)
		local success, payload, soldRecord = self._inventoryService:SellMutant(player, mutantInstanceId)
		if success then
			return {
				success = true,
				state = payload,
				soldRecord = soldRecord,
			}
		end

		return {
			success = false,
			error = payload,
			state = self._inventoryService:GetClientState(player),
		}
	end
end

return ResearchExchangeService
