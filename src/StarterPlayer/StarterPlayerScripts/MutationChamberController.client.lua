local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local MutationConfig = nil
local remotes = nil

local controller = {
	state = nil,
	lastShownMutationId = nil,
}

local function createLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(240, 248, 255)
	label.TextSize = textSize or 16
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function createButton(parent, name, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(18, 23, 30)
	button.TextSize = 16
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MutationLabGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

local openLabButton = createButton(
	screenGui,
	"OpenLabButton",
	"Open Lab",
	UDim2.fromOffset(118, 42),
	UDim2.new(1, -138, 0, 20),
	Color3.fromRGB(120, 232, 177)
)
openLabButton.TextSize = 18

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.55)
panel.Size = UDim2.fromOffset(420, 310)
panel.BackgroundColor3 = Color3.fromRGB(16, 25, 34)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(90, 164, 194)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local titleLabel = createLabel(panel, "Title", "Mutation Chamber", UDim2.fromOffset(280, 40), UDim2.fromOffset(20, 16), 26)
titleLabel.Font = Enum.Font.GothamBlack

local closeButton = createButton(panel, "CloseButton", "Close", UDim2.fromOffset(88, 34), UDim2.fromOffset(312, 18), Color3.fromRGB(233, 110, 110))

local subtitleLabel = createLabel(
	panel,
	"Subtitle",
	"Insert a specimen, trigger the chamber, and see what survives.",
	UDim2.fromOffset(370, 40),
	UDim2.fromOffset(20, 52),
	14,
	Color3.fromRGB(180, 202, 219)
)

local inventoryLabel = createLabel(panel, "InventoryLabel", "Inventory", UDim2.fromOffset(370, 28), UDim2.fromOffset(20, 98), 18)
local chamberLabel = createLabel(panel, "ChamberLabel", "Loaded specimen: Empty", UDim2.fromOffset(370, 28), UDim2.fromOffset(20, 134), 18)
local timerLabel = createLabel(panel, "TimerLabel", "Timer: Idle", UDim2.fromOffset(370, 28), UDim2.fromOffset(20, 170), 18)
local storageLabel = createLabel(panel, "StorageLabel", "Stored mutants: 0", UDim2.fromOffset(370, 28), UDim2.fromOffset(20, 206), 18)

local statusLabel = createLabel(
	panel,
	"StatusLabel",
	"Connecting to chamber systems...",
	UDim2.fromOffset(370, 42),
	UDim2.fromOffset(20, 238),
	14,
	Color3.fromRGB(255, 220, 154)
)

local insertButton = createButton(panel, "InsertButton", "Insert Proto Slime", UDim2.fromOffset(180, 42), UDim2.fromOffset(20, 262), Color3.fromRGB(120, 232, 177))
local mutateButton = createButton(panel, "MutateButton", "Start Mutation", UDim2.fromOffset(180, 42), UDim2.fromOffset(220, 262), Color3.fromRGB(255, 215, 110))

local resultPopup = Instance.new("Frame")
resultPopup.Name = "ResultPopup"
resultPopup.AnchorPoint = Vector2.new(0.5, 1)
resultPopup.Position = UDim2.fromScale(0.5, 1.15)
resultPopup.Size = UDim2.fromOffset(360, 132)
resultPopup.BackgroundColor3 = Color3.fromRGB(19, 30, 39)
resultPopup.Visible = false
resultPopup.Parent = screenGui

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 16)
popupCorner.Parent = resultPopup

local popupStroke = Instance.new("UIStroke")
popupStroke.Thickness = 2
popupStroke.Color = Color3.fromRGB(255, 215, 110)
popupStroke.Parent = resultPopup

local popupTitle = createLabel(resultPopup, "PopupTitle", "Mutation Complete", UDim2.fromOffset(320, 28), UDim2.fromOffset(20, 16), 22)
popupTitle.Font = Enum.Font.GothamBlack

local popupName = createLabel(resultPopup, "PopupName", "", UDim2.fromOffset(320, 28), UDim2.fromOffset(20, 48), 20)
local popupSummary = createLabel(resultPopup, "PopupSummary", "", UDim2.fromOffset(320, 44), UDim2.fromOffset(20, 78), 14, Color3.fromRGB(190, 213, 225))

local function setStatus(message, color)
	statusLabel.Text = message
	statusLabel.TextColor3 = color or Color3.fromRGB(255, 220, 154)
end

local function formatTime(secondsRemaining)
	local safeSeconds = math.max(0, secondsRemaining)
	local minutes = math.floor(safeSeconds / 60)
	local seconds = safeSeconds % 60
	return string.format("%02d:%02d", minutes, seconds)
end

local function getRarityColor(rarityId)
	if MutationConfig == nil then
		return Color3.fromRGB(240, 248, 255)
	end

	local rarityDefinition = MutationConfig.RarityTiers[rarityId]
	if rarityDefinition then
		return rarityDefinition.color
	end

	local resultStyle = MutationConfig.ResultStyles[rarityId]
	if resultStyle then
		return resultStyle.color
	end

	return Color3.fromRGB(240, 248, 255)
end

local function getPrimaryBaseEntry()
	if controller.state == nil then
		return nil
	end

	for _, entry in ipairs(controller.state.baseInventory or {}) do
		if entry.quantity > 0 then
			return entry
		end
	end

	return controller.state.baseInventory and controller.state.baseInventory[1] or nil
end

local function updateButtonState(button, enabled)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.TextTransparency = enabled and 0 or 0.35
	button.BackgroundTransparency = enabled and 0 or 0.25
end

local function render()
	if controller.state == nil then
		return
	end

	local baseEntry = controller.state.baseInventory and controller.state.baseInventory[1]
	if baseEntry then
		inventoryLabel.Text = string.format("%s: %d", baseEntry.name, baseEntry.quantity)
		insertButton.Text = ("Insert %s"):format(baseEntry.name)
	end

	if controller.state.insertedBase then
		chamberLabel.Text = ("Loaded specimen: %s"):format(controller.state.insertedBase.name)
	else
		chamberLabel.Text = "Loaded specimen: Empty"
	end

	storageLabel.Text = ("Stored mutants: %d | Failures: %d"):format(
		controller.state.mutantCount or 0,
		controller.state.stats and controller.state.stats.failures or 0
	)

	local canInsert = false
	local activeMutation = controller.state.activeMutation
	if activeMutation == nil and controller.state.insertedBase == nil then
		local insertEntry = getPrimaryBaseEntry()
		canInsert = insertEntry ~= nil and insertEntry.quantity > 0
	end

	local canMutate = controller.state.insertedBase ~= nil and activeMutation == nil
	updateButtonState(insertButton, canInsert)
	updateButtonState(mutateButton, canMutate)
end

local function showResultPopup(result)
	if result == nil or result.mutationId == controller.lastShownMutationId then
		return
	end

	controller.lastShownMutationId = result.mutationId
	resultPopup.Visible = true
	resultPopup.Position = UDim2.fromScale(0.5, 1.15)

	popupName.Text = result.displayName
	popupName.TextColor3 = getRarityColor(result.rarity)
	popupSummary.Text = result.summary or ""
	popupStroke.Color = getRarityColor(result.rarity)

	if result.success then
		popupTitle.Text = ("Mutation Complete [%s]"):format(result.rarity)
		setStatus("Mutation resolved successfully.", Color3.fromRGB(153, 241, 155))
	else
		popupTitle.Text = "Mutation Failed"
		setStatus("The chamber produced unstable sludge.", Color3.fromRGB(255, 143, 143))
	end

	local tweenIn = TweenService:Create(
		resultPopup,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.93) }
	)
	tweenIn:Play()

	task.delay(4, function()
		if controller.lastShownMutationId ~= result.mutationId then
			return
		end

		local tweenOut = TweenService:Create(
			resultPopup,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromScale(0.5, 1.15) }
		)
		tweenOut:Play()
		tweenOut.Completed:Wait()

		if controller.lastShownMutationId == result.mutationId then
			resultPopup.Visible = false
		end
	end)
end

local function applyState(newState)
	if newState == nil then
		return
	end

	controller.state = newState
	render()
	showResultPopup(newState.lastResolvedMutation)
end

local function invokeServer(remoteName, ...)
	if remotes == nil then
		setStatus("Lab services are still loading.", Color3.fromRGB(255, 143, 143))
		return nil
	end

	local remote = remotes:WaitForChild(remoteName)
	local ok, response = pcall(function()
		return remote:InvokeServer(...)
	end)

	if not ok then
		setStatus("Server call failed. Check output for errors.", Color3.fromRGB(255, 143, 143))
		warn(response)
		return nil
	end

	return response
end

local function refreshState()
	local state = invokeServer("GetState")
	if state then
		applyState(state)
	end
end

local function openPanel()
	panel.Visible = true
	setStatus("Chamber linked. Ready for input.", Color3.fromRGB(153, 241, 155))
	task.spawn(refreshState)
end

openLabButton.Activated:Connect(openPanel)

closeButton.Activated:Connect(function()
	panel.Visible = false
end)

insertButton.Activated:Connect(function()
	local baseEntry = getPrimaryBaseEntry()
	if not baseEntry then
		setStatus("No base organism is available to insert.", Color3.fromRGB(255, 143, 143))
		return
	end

	local response = invokeServer("InsertBaseOrganism", baseEntry.id)
	if response == nil then
		return
	end

	if response.state then
		applyState(response.state)
	end

	if response.success then
		setStatus("Specimen inserted. Start the mutation when ready.", Color3.fromRGB(153, 241, 155))
	else
		setStatus(response.error or "Insert failed.", Color3.fromRGB(255, 143, 143))
	end
end)

mutateButton.Activated:Connect(function()
	local response = invokeServer("StartMutation")
	if response == nil then
		return
	end

	if response.state then
		applyState(response.state)
	end

	if response.success then
		setStatus("Mutation sequence started.", Color3.fromRGB(153, 241, 155))
	else
		setStatus(response.error or "Mutation failed to start.", Color3.fromRGB(255, 143, 143))
	end
end)

local function bindRemotes()
	remotes:WaitForChild("OpenChamber").OnClientEvent:Connect(openPanel)

	remotes:WaitForChild("StateUpdated").OnClientEvent:Connect(function(newState)
		applyState(newState)
	end)

	remotes:WaitForChild("MutationResolved").OnClientEvent:Connect(function(result)
		if controller.state then
			controller.state.lastResolvedMutation = result
		end
		showResultPopup(result)
		refreshState()
	end)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "OpenPrompt" then
		openPanel()
	end
end)

RunService.RenderStepped:Connect(function()
	if controller.state == nil then
		return
	end

	local activeMutation = controller.state.activeMutation
	if activeMutation then
		local secondsRemaining = math.max(activeMutation.endsAt - DateTime.now().UnixTimestamp, 0)
		if secondsRemaining > 0 then
			timerLabel.Text = ("Timer: %s remaining"):format(formatTime(secondsRemaining))
		else
			timerLabel.Text = "Timer: Finalizing..."
		end
	else
		timerLabel.Text = "Timer: Idle"
	end
end)

task.spawn(function()
	warn("[MutationChamberController] GUI bootstrap started")

	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	if sharedFolder == nil then
		setStatus("Shared config missing. Check Rojo sync.", Color3.fromRGB(255, 143, 143))
		return
	end

	local mutationConfigModule = sharedFolder:WaitForChild("MutationConfig", 10)
	if mutationConfigModule == nil then
		setStatus("MutationConfig missing. Check Rojo sync.", Color3.fromRGB(255, 143, 143))
		return
	end

	local ok, loadedConfig = pcall(require, mutationConfigModule)
	if not ok then
		setStatus("MutationConfig failed to load. Check Output.", Color3.fromRGB(255, 143, 143))
		warn("[MutationChamberController] Failed to load MutationConfig:", loadedConfig)
		return
	end

	MutationConfig = loadedConfig
	remotes = ReplicatedStorage:WaitForChild("MutationLabRemotes", 10)
	if remotes == nil then
		setStatus("Lab remotes missing. Check server bootstrap.", Color3.fromRGB(255, 143, 143))
		return
	end

	bindRemotes()
	setStatus("Lab systems online. Press E or Open Lab.", Color3.fromRGB(153, 241, 155))
	refreshState()
end)
