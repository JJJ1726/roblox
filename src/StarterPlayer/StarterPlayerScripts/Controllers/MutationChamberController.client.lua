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

local function formatTime(secondsRemaining)
	local safeSeconds = math.max(0, secondsRemaining)
	local minutes = math.floor(safeSeconds / 60)
	local seconds = safeSeconds % 60
	return string.format("%02d:%02d", minutes, seconds)
end

local function invokeServer(remoteName, ...)
	local remote = remotes:WaitForChild(remoteName)
	local ok, response = pcall(function()
		return remote:InvokeServer(...)
	end)

	if not ok then
		warn(response)
		return nil
	end

	return response
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
panel.Size = UDim2.fromOffset(470, 688)
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

local titleLabel = createLabel(panel, "Title", "Mutation Lab", UDim2.fromOffset(300, 40), UDim2.fromOffset(22, 18), 28)
titleLabel.Font = Enum.Font.GothamBlack

local closeButton = createButton(panel, "CloseButton", "Close", UDim2.fromOffset(88, 34), UDim2.fromOffset(360, 20), Color3.fromRGB(233, 110, 110))

local subtitleLabel = createLabel(
	panel,
	"Subtitle",
	"Unlock new specimens, mutate them, and recycle the survivors into deeper lab progression.",
	UDim2.fromOffset(410, 40),
	UDim2.fromOffset(22, 56),
	14,
	Color3.fromRGB(180, 202, 219)
)
subtitleLabel.TextWrapped = true

local overviewCard = createCard(panel, "OverviewCard", UDim2.fromOffset(426, 250), UDim2.fromOffset(22, 104), Color3.fromRGB(21, 33, 43))
local mutationCard = createCard(panel, "MutationCard", UDim2.fromOffset(426, 92), UDim2.fromOffset(22, 370), Color3.fromRGB(22, 34, 41))
local researchCard = createCard(panel, "ResearchCard", UDim2.fromOffset(426, 190), UDim2.fromOffset(22, 478), Color3.fromRGB(21, 33, 43))

local currencyLabel = createLabel(overviewCard, "CurrencyLabel", "DNA Credits: 0", UDim2.fromOffset(380, 24), UDim2.fromOffset(16, 12), 20, Color3.fromRGB(153, 241, 155))
currencyLabel.Font = Enum.Font.GothamBold

local inventoryLabel = createLabel(overviewCard, "InventoryLabel", "Unlocked organisms: 1/1", UDim2.fromOffset(390, 20), UDim2.fromOffset(16, 40), 16)
local chamberLabel = createLabel(overviewCard, "ChamberLabel", "Loaded specimen: Empty", UDim2.fromOffset(390, 20), UDim2.fromOffset(16, 62), 16)
local timerLabel = createLabel(overviewCard, "TimerLabel", "Timer: Idle", UDim2.fromOffset(390, 20), UDim2.fromOffset(16, 84), 16)
local storageLabel = createLabel(overviewCard, "StorageLabel", "Stored mutants: 0 | Sold: 0", UDim2.fromOffset(390, 20), UDim2.fromOffset(16, 106), 16)

local organismHeader = createLabel(overviewCard, "OrganismHeader", "Specimen Catalog", UDim2.fromOffset(240, 24), UDim2.fromOffset(16, 140), 18)
organismHeader.Font = Enum.Font.GothamBold

local organismHint = createLabel(
	overviewCard,
	"OrganismHint",
	"Unlock locked organisms with DNA Credits. Load an unlocked specimen directly into the chamber.",
	UDim2.fromOffset(392, 30),
	UDim2.fromOffset(16, 164),
	13,
	Color3.fromRGB(180, 202, 219)
)

local organismListFrame = Instance.new("Frame")
organismListFrame.Name = "OrganismListFrame"
organismListFrame.Position = UDim2.fromOffset(12, 188)
organismListFrame.Size = UDim2.fromOffset(402, 56)
organismListFrame.BackgroundTransparency = 1
organismListFrame.Parent = overviewCard

local organismListLayout = Instance.new("UIListLayout")
organismListLayout.Padding = UDim.new(0, 4)
organismListLayout.Parent = organismListFrame

local mutationHeader = createLabel(mutationCard, "MutationHeader", "Mutation Controls", UDim2.fromOffset(220, 24), UDim2.fromOffset(16, 10), 20)
mutationHeader.Font = Enum.Font.GothamBold

local statusLabel = createLabel(
	mutationCard,
	"StatusLabel",
	"Load a specimen from the catalog, then start the chamber.",
	UDim2.fromOffset(388, 22),
	UDim2.fromOffset(16, 34),
	13,
	Color3.fromRGB(255, 220, 154)
)

local mutateButton = createButton(mutationCard, "MutateButton", "Start Mutation", UDim2.fromOffset(388, 34), UDim2.fromOffset(16, 52), Color3.fromRGB(255, 215, 110))

local researchHeader = createLabel(researchCard, "ResearchHeader", "Research Exchange", UDim2.fromOffset(240, 24), UDim2.fromOffset(16, 10), 20)
researchHeader.Font = Enum.Font.GothamBold

local researchHint = createLabel(
	researchCard,
	"ResearchHint",
	"Sell finished mutants for DNA Credits. That currency now unlocks new specimen types.",
	UDim2.fromOffset(390, 32),
	UDim2.fromOffset(16, 38),
	14,
	Color3.fromRGB(180, 202, 219)
)

local mutantList = Instance.new("ScrollingFrame")
mutantList.Name = "MutantList"
mutantList.Position = UDim2.fromOffset(12, 78)
mutantList.Size = UDim2.fromOffset(402, 100)
mutantList.BackgroundTransparency = 1
mutantList.BorderSizePixel = 0
mutantList.ScrollBarThickness = 6
mutantList.CanvasSize = UDim2.fromOffset(0, 0)
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
	UDim2.fromOffset(16, 116),
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
				setStatus("Server call failed. Check output for errors.", Color3.fromRGB(255, 143, 143))
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

local function renderOrganismList()
	for _, child in ipairs(organismListFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local state = controller.state
	if state == nil then
		return
	end

	local dnaBalance = state.economy and state.economy.dna or 0
	local insertedBase = state.insertedBase
	local mutationActive = state.activeMutation ~= nil

	for _, baseEntry in ipairs(state.baseInventory or {}) do
		local rowColor = baseEntry.unlocked and Color3.fromRGB(26, 40, 51) or Color3.fromRGB(34, 34, 43)
		local row = createCard(organismListFrame, baseEntry.id, UDim2.new(1, 0, 0, 26), UDim2.fromOffset(0, 0), rowColor)

		local nameColor = baseEntry.unlocked and Color3.fromRGB(240, 248, 255) or Color3.fromRGB(187, 161, 255)
		local nameLabel = createLabel(row, "NameLabel", baseEntry.name, UDim2.fromOffset(126, 14), UDim2.fromOffset(10, 6), 13, nameColor)
		nameLabel.Font = Enum.Font.GothamBold

		local detailText
		if baseEntry.unlocked then
			detailText = ("Stock: %d"):format(baseEntry.quantity)
		else
			detailText = ("Unlock: %d DNA"):format(baseEntry.unlockCost or 0)
		end
		createLabel(row, "DetailLabel", detailText, UDim2.fromOffset(130, 14), UDim2.fromOffset(144, 6), 12, Color3.fromRGB(180, 202, 219))

		local buttonText = "Load"
		local buttonColor = Color3.fromRGB(120, 232, 177)
		local buttonEnabled = true
		local actionName = "load"

		if baseEntry.unlocked then
			if mutationActive then
				buttonText = "Busy"
				buttonEnabled = false
			elseif insertedBase then
				if insertedBase.id == baseEntry.id then
					buttonText = "Loaded"
				else
					buttonText = "Full"
				end
				buttonEnabled = false
			elseif baseEntry.quantity < 1 then
				buttonText = "Empty"
				buttonEnabled = false
			end
		else
			actionName = "unlock"
			buttonText = ("Unlock %d"):format(baseEntry.unlockCost or 0)
			buttonColor = Color3.fromRGB(168, 185, 255)
			if dnaBalance < (baseEntry.unlockCost or 0) then
				buttonText = ("Need %d"):format(baseEntry.unlockCost or 0)
				buttonEnabled = false
			end
		end

		local actionButton = createButton(row, "ActionButton", buttonText, UDim2.fromOffset(100, 20), UDim2.fromOffset(290, 3), buttonColor)
		actionButton.TextSize = 11
		updateButtonState(actionButton, buttonEnabled)

		if buttonEnabled then
			actionButton.Activated:Connect(function()
				local response
				if actionName == "unlock" then
					response = invokeServer("UnlockBaseOrganism", baseEntry.id)
				else
					response = invokeServer("InsertBaseOrganism", baseEntry.id)
				end

				if response == nil then
					setStatus("Server call failed. Check output for errors.", Color3.fromRGB(255, 143, 143))
					return
				end

				if response.state then
					applyState(response.state)
				end

				if actionName == "unlock" then
					if response.success and response.unlockRecord then
						setStatus(
							("Unlocked %s and stocked %d samples."):format(response.unlockRecord.name, response.unlockRecord.grantedQuantity),
							Color3.fromRGB(153, 241, 155)
						)
					else
						setStatus(response.error or "Unlock failed.", Color3.fromRGB(255, 143, 143))
					end
				else
					if response.success then
						setStatus(("Loaded %s into the chamber."):format(baseEntry.name), Color3.fromRGB(153, 241, 155))
					else
						setStatus(response.error or "Load failed.", Color3.fromRGB(255, 143, 143))
					end
				end
			end)
		end
	end
end

local function render()
	if controller.state == nil then
		return
	end

	local state = controller.state
	local economy = state.economy or {
		currencyName = MutationConfig.Economy.CurrencyName,
		dna = 0,
	}
	local organismSummary = state.organismSummary or {
		unlockedCount = 0,
		totalCount = #MutationConfig.BaseOrganismOrder,
	}

	currencyLabel.Text = string.format("%s: %d", economy.currencyName, economy.dna or 0)
	inventoryLabel.Text = string.format("Unlocked organisms: %d/%d", organismSummary.unlockedCount or 0, organismSummary.totalCount or 0)

	if state.insertedBase then
		chamberLabel.Text = ("Loaded specimen: %s"):format(state.insertedBase.name)
	else
		chamberLabel.Text = "Loaded specimen: Empty"
	end

	storageLabel.Text = ("Stored mutants: %d | Sold: %d"):format(
		state.mutantCount or 0,
		state.stats and state.stats.mutantsSold or 0
	)

	local canMutate = state.insertedBase ~= nil and state.activeMutation == nil
	updateButtonState(mutateButton, canMutate)

	renderOrganismList()
	renderMutantList()
	showResultPopup(state.lastResolvedMutation)
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

mutateButton.Activated:Connect(function()
	local response = invokeServer("StartMutation")
	if response == nil then
		setStatus("Server call failed. Check output for errors.", Color3.fromRGB(255, 143, 143))
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

local initialState = invokeServer("GetState")
if initialState then
	applyState(initialState)
end
