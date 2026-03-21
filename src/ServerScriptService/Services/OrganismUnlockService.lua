local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OrganismUnlockService = {}

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

function OrganismUnlockService:Init(inventoryService)
	self._inventoryService = inventoryService

	local remoteFolder = ensureRemoteFolder()
	self._unlockBaseOrganismRemote = ensureRemoteFunction(remoteFolder, "UnlockBaseOrganism")

	self._unlockBaseOrganismRemote.OnServerInvoke = function(player, baseId)
		local success, payload, unlockRecord = self._inventoryService:UnlockBaseOrganism(player, baseId)
		if success then
			return {
				success = true,
				state = payload,
				unlockRecord = unlockRecord,
			}
		end

		return {
			success = false,
			error = payload,
			state = self._inventoryService:GetClientState(player),
		}
	end
end

return OrganismUnlockService
