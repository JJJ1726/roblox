local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("MutationLabRemotes")

local MutationConfig = require(sharedFolder:WaitForChild("MutationConfig"))

local controller = {
	state = nil,
	lastShownMutationId = nil,
}

local applyState

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

local function createCard(parent, name, size, position, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(87, 128, 150)
	stroke.Transparency = 0.25
	stroke.Parent = frame

	return frame
end

local function updateButtonState(button, enabled)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.TextTransparency = enabled and 0 or 0.35
	button.BackgroundTransparency = enabled and 0 or 0.25
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MutationLabGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.54)
panel.Size = UDim2.fromOffset(470, 596)
panel.BackgroundColor3 = Color3.fromRGB(15, 23, 30)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 20)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(90, 164, 194)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local titleLabel = createLabel(panel, "Title", "Mutation Chamber", UDim2.fromOffset(300, 40), UDim2.fromOffset(22, 18), 28)
titleLabel.Font = Enum.Font.GothamBlack

local closeButton = createButton(panel, "CloseButton", "Close", UDim2.fromOffset(88, 34), UDim2.fromOffset(360, 20), Color3.fromRGB(233, 110, 110))

local subtitleLabel = createLabel(
	panel,
	"Subtitle",
	"Grow unstable life, then recycle the survivors into research funding.",
	UDim2.fromOffset(410, 40),
	UDim2.fromOffset(22, 56),
	14,
	Color3.fromRGB(180, 202, 219)
)
subtitleLabel.TextWrapped = true

local overviewCard = createCard(panel, "OverviewCard", UDim2.fromOffset(426, 156), UDim2.fromOffset(22, 104), Color3.fromRGB(21, 33, 43))
local mutationCard = createCard(panel, "MutationCard", UDim2.fromOffset(426, 116), UDim2.fromOffset(22, 276), Color3.fromRGB(22, 34, 41))
local researchCard = createCard(panel, "ResearchCard", UDim2.fromOffset(426, 180), UDim2.fromOffset(22, 406), Color3.fromRGB(21, 33, 43))

local currencyLabel = createLabel(overviewCard, "CurrencyLabel", "DNA Credits: 0", UDim2.fromOffset(380, 26), UDim2.fromOffset(16, 12), 20, Color3.fromRGB(153, 241, 155))
currencyLabel.Font = Enum.Font.GothamBold

local inventoryLabel = createLabel(overviewCard, "InventoryLabel", "Proto Slime: 0", UDim2.fromOffset(380, 24), UDim2.fromOffset(16, 42), 17)
local chamberLabel = createLabel(overviewCard, "ChamberLabel", "Loaded specimen: Empty", UDim2.fromOffset(380, 24), UDim2.fromOffset(16, 68), 17)
local timerLabel = createLabel(overviewCard, "TimerLabel", "Timer: Idle", UDim2.fromOffset(380, 24), UDim2.fromOffset(16, 94), 17)
local storageLabel = createLabel(overviewCard, "StorageLabel", "Stored mutants: 0 | Sold: 0", UDim2.fromOffset(380, 24), UDim2.fromOffset(16, 120), 17)

local mutationHeader = createLabel(mutationCard, "MutationHeader", "Mutation Controls", UDim2.fromOffset(240, 24), UDim2.fromOffset(16, 10), 20)
mutationHeader.Font = Enum.Font.GothamBold

local statusLabel = createLabel(
	mutationCard,
	"StatusLabel",
	"Walk to the chamber and press E.",
	UDim2.fromOffset(388, 36),
	UDim2.fromOffset(16, 38),
	14,
	Color3.fromRGB(255, 220, 154)
)

local insertButton = createButton(mutationCard, "InsertButton", "Insert Proto Slime", UDim2.fromOffset(186, 42), UDim2.fromOffset(16, 68), Color3.fromRGB(120, 232, 177))
local mutateButton = createButton(mutationCard, "MutateButton", "Start Mutation", UDim2.fromOffset(186, 42), UDim2.fromOffset(224, 68), Color3.fromRGB(255, 215, 110))

local researchHeader = createLabel(researchCard, "ResearchHeader", "Research Exchange", UDim2.fromOffset(240, 24), UDim2.fromOffset(16, 10), 20)
researchHeader.Font = Enum.Font.GothamBold

local researchHint = createLabel(
	researchCard,
	"ResearchHint",
	"Sell finished mutants for DNA Credits. Higher rarity pays more.",
	UDim2.fromOffset(390, 30),
	UDim2.fromOffset(16, 38),
	14,
	Color3.fromRGB(180, 202, 219)
)

local mutantList = Instance.new("ScrollingFrame")
mutantList.Name = "MutantList"
mutantList.Position = UDim2.fromOffset(12, 68)
mutantList.Size = UDim2.fromOffset(402, 102)
mutantList.BackgroundTransparency = 1
mutantList.BorderSizePixel = 0
mutantList.ScrollBarThickness = 6
mutantList.CanvasSize = UDim2.fromOffset(0, 0)
mutantList.AutomaticCanvasSize = Enum.AutomaticSize.None
mutantList.Parent = researchCard

local mutantListLayout = Instance.new("UIListLayout")
mutantListLayout.Padding = UDim.new(0, 8)
mutantListLayout.Parent = mutantList

local mutantListPadding = Instance.new("UIPadding")
mutantListPadding.PaddingLeft = UDim.new(0, 4)
mutantListPadding.PaddingRight = UDim.new(0, 4)
mutantListPadding.PaddingTop = UDim.new(0, 2)
mutantListPadding.PaddingBottom = UDim.new(0, 2)
mutantListPadding.Parent = mutantList

local emptyMutantsLabel = createLabel(
	researchCard,
	"EmptyMutantsLabel",
	"No mutants stored yet. Finish a mutation first.",
	UDim2.fromOffset(390, 24),
	UDim2.fromOffset(16, 106),
	14,
	Color3.fromRGB(133, 157, 171)
)

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

local function invokeServer(remoteName, ...)
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

local function refreshState()
	local state = invokeServer("GetState")
	if state then
		controller.state = state
	end
end

local function renderMutantList()
	for _, child in ipairs(mutantList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local recentMutants = controller.state and controller.state.recentMutants or {}
	emptyMutantsLabel.Visible = #recentMutants == 0

	for _, mutant in ipairs(recentMutants) do
		local row = createCard(mutantList, mutant.instanceId, UDim2.new(1, -8, 0, 58), UDim2.fromOffset(0, 0), Color3.fromRGB(26, 40, 51))
		row.AutomaticSize = Enum.AutomaticSize.None

		local nameLabel = createLabel(row, "NameLabel", mutant.displayName, UDim2.fromOffset(210, 22), UDim2.fromOffset(12, 8), 16, getRarityColor(mutant.rarity))
		nameLabel.Font = Enum.Font.GothamBold

		local detailText = string.format("%s | Sell: %d", mutant.rarity, mutant.sellValue or 0)
		createLabel(row, "DetailLabel", detailText, UDim2.fromOffset(160, 18), UDim2.fromOffset(12, 30), 13, Color3.fromRGB(180, 202, 219))

		local summaryLabel = createLabel(row, "SummaryLabel", mutant.summary or "", UDim2.fromOffset(114, 34), UDim2.fromOffset(174, 10), 12, Color3.fromRGB(146, 170, 184))
		summaryLabel.TextXAlignment = Enum.TextXAlignment.Left

		local sellButton = createButton(row, "SellButton", "Sell", UDim2.fromOffset(76, 32), UDim2.fromOffset(306, 13), Color3.fromRGB(255, 195, 96))
		sellButton.TextSize = 14
		sellButton.Activated:Connect(function()
			local response = invokeServer("SellMutant", mutant.instanceId)
			if response == nil then
				return
			end

			if response.state then
				applyState(response.state)
			end

			if response.success and response.soldRecord then
				local currencyName = controller.state.economy and controller.state.economy.currencyName or MutationConfig.Economy.CurrencyName
				setStatus(
					("Sold %s for %d %s."):format(response.soldRecord.displayName, response.soldRecord.sellValue, currencyName),
					Color3.fromRGB(153, 241, 155)
				)
			else
				setStatus(response.error or "Sale failed.", Color3.fromRGB(255, 143, 143))
			end
		end)
	end

	mutantList.CanvasSize = UDim2.fromOffset(0, mutantListLayout.AbsoluteContentSize.Y + 8)
end

local function render()
	if controller.state == nil then
		return
	end

	local economy = controller.state.economy or {
		currencyName = MutationConfig.Economy.CurrencyName,
		dna = 0,
	}
	currencyLabel.Text = string.format("%s: %d", economy.currencyName, economy.dna or 0)

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

	storageLabel.Text = ("Stored mutants: %d | Sold: %d"):format(
		controller.state.mutantCount or 0,
		controller.state.stats and controller.state.stats.mutantsSold or 0
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

	renderMutantList()
	showResultPopup(controller.state.lastResolvedMutation)
end

applyState = function(newState)
	if newState == nil then
		return
	end

	controller.state = newState
	render()
end

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

remotes:WaitForChild("OpenChamber").OnClientEvent:Connect(function()
	panel.Visible = true
	setStatus("Chamber linked. Ready for input.", Color3.fromRGB(153, 241, 155))
	local state = invokeServer("GetState")
	if state then
		applyState(state)
	end
end)

remotes:WaitForChild("StateUpdated").OnClientEvent:Connect(function(newState)
	applyState(newState)
end)

remotes:WaitForChild("MutationResolved").OnClientEvent:Connect(function(result)
	if controller.state then
		controller.state.lastResolvedMutation = result
	end
	showResultPopup(result)

	local state = invokeServer("GetState")
	if state then
		applyState(state)
	end
end)

mutantListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mutantList.CanvasSize = UDim2.fromOffset(0, mutantListLayout.AbsoluteContentSize.Y + 8)
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

refreshState()
render()
