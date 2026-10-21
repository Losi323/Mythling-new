
--========================================================
-- MYTHLING REALMS - CLIENT UI
-- StarterPlayer > StarterPlayerScripts > MythlingClient
-- Compact menus, 4-column pet collection, egg shop and hatch
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("MythlingRemotes")

local function getRemote(name)
	return remotes:WaitForChild(name)
end

local GetState = getRemote("GetState")
local ChooseStarter = getRemote("ChooseStarter")
local BuyUpgrade = getRemote("BuyUpgrade")
local ClaimQuest = getRemote("ClaimQuest")
local EvolvePet = getRemote("EvolvePet")
local UnlockWorld = getRemote("UnlockWorld")
local StateChanged = getRemote("StateChanged")
local Notify = getRemote("Notify")
local OpenEgg = getRemote("OpenEgg")
local EquipPet = getRemote("EquipPet")
local ClaimDailyReward = getRemote("ClaimDailyReward")
local AttackEnemy = getRemote("AttackEnemy")
local SpinWheel = getRemote("SpinWheel")
local WheelResult = getRemote("WheelResult")
local PartyAction = getRemote("PartyAction")
local PartyUpdate = getRemote("PartyUpdate")

--========================================================
-- CONFIGURATION
--========================================================

local COLORS = {
	background = Color3.fromRGB(23, 29, 43),
	panel = Color3.fromRGB(33, 41, 59),
	panelLight = Color3.fromRGB(44, 55, 77),
	accent = Color3.fromRGB(117, 104, 255),
	accentLight = Color3.fromRGB(153, 142, 255),
	text = Color3.fromRGB(245, 247, 255),
	muted = Color3.fromRGB(173, 184, 205),
	green = Color3.fromRGB(76, 205, 137),
	gold = Color3.fromRGB(255, 201, 86),
	red = Color3.fromRGB(238, 96, 111),
	border = Color3.fromRGB(74, 86, 115),
}

local PET_INFO = {
	EmberFox = { emoji = "PET", rarity = "Starter", color = Color3.fromRGB(255, 147, 80) },
	Mossbun = { emoji = "PET", rarity = "Starter", color = Color3.fromRGB(112, 205, 135) },
	Tidefin = { emoji = "PET", rarity = "Starter", color = Color3.fromRGB(89, 185, 255) },
	Cinderling = { emoji = "PET", rarity = "Common", color = Color3.fromRGB(255, 145, 75) },
	Pebblit = { emoji = "PET", rarity = "Common", color = Color3.fromRGB(166, 145, 120) },
	Bloomlet = { emoji = "PET", rarity = "Common", color = Color3.fromRGB(255, 135, 190) },
	Sunpup = { emoji = "PET", rarity = "Uncommon", color = Color3.fromRGB(255, 184, 77) },
	Duskmoth = { emoji = "PET", rarity = "Uncommon", color = Color3.fromRGB(176, 132, 230) },
	Voltkit = { emoji = "PET", rarity = "Rare", color = Color3.fromRGB(255, 230, 75) },
	Stormling = { emoji = "PET", rarity = "Rare", color = Color3.fromRGB(83, 177, 235) },
	Glacub = { emoji = "PET", rarity = "Epic", color = Color3.fromRGB(120, 220, 255) },
	Starwhisp = { emoji = "PET", rarity = "Legendary", color = Color3.fromRGB(255, 199, 73) },
	AuroraStag = { emoji = "PET", rarity = "VIP", color = Color3.fromRGB(120, 240, 226) },
}

local PET_ORDER = {
	"EmberFox", "Mossbun", "Tidefin",
	"Cinderling", "Pebblit", "Bloomlet",
	"Sunpup", "Duskmoth", "Voltkit", "Stormling",
	"Glacub", "Starwhisp", "AuroraStag",
}

local STARTERS = { "EmberFox", "Mossbun", "Tidefin" }

local currentState = {}
local currentMenu = nil
local currentPet = nil
local toastId = 0
local hatchId = 0
local busy = false
local wheelBusy = false
local wheelSpinAttempt = 0
local wheelVisual = nil
local wheelButton = nil
local partyState = nil
local partyInvites = {}

--========================================================
-- REMOTE HELPERS
--========================================================

local function invokeRemote(remote, ...)
	if not remote then
		return false, "Remote not found"
	end

	local args = table.pack(...)

	local ok, result = pcall(function()
		if remote:IsA("RemoteFunction") then
			return remote:InvokeServer(table.unpack(args, 1, args.n))
		elseif remote:IsA("RemoteEvent") then
			remote:FireServer(table.unpack(args, 1, args.n))
			return true
		end

		error("Unsupported remote type: " .. remote.ClassName)
	end)

	if not ok then
		warn("[MythlingRealms] Remote error:", result)
		return false, result
	end

	return true, result
end

local function requestState()
	local ok, result = invokeRemote(GetState)

	if ok and type(result) == "table" then
		currentState = result
		return true
	end

	return false
end

--========================================================
-- GUI HELPERS
--========================================================

local existing = playerGui:FindFirstChild("MythlingRealmsUI")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "MythlingRealmsUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(object, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = object
	return c
end

local function stroke(object, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.border
	s.Thickness = thickness or 1
	s.Transparency = 0.15
	s.Parent = object
	return s
end

local function newFrame(parent, name, size, position, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = color or COLORS.panel
	f.BorderSizePixel = 0
	f.Parent = parent
	corner(f, 14)
	return f
end

local function newLabel(parent, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.Gotham
	label.Text = tostring(text or "")
	label.TextSize = textSize or 14
	label.TextColor3 = color or COLORS.text
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function newButton(parent, text, size, position, callback, color)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color or COLORS.accent
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextSize = 14
	button.TextColor3 = COLORS.text
	button.TextWrapped = true
	button.AutoButtonColor = true
	button.Parent = parent
	corner(button, 10)

	button.Activated:Connect(function()
		if callback then
			callback()
		end
	end)

	return button
end

local function clearChildren(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout")
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function formatNumber(value)
	value = tonumber(value) or 0
	return tostring(math.floor(value))
end

local function getCurrency()
	return currentState.starshards
		or currentState.Starshards
		or currentState.currency
		or currentState.coins
		or 0
end

local function getEquippedPet()
	return currentState.pet
		or currentState.equippedPet
		or currentState.currentPet
end

local function getPetLevel(petName)
	local levels = currentState.petLevels
	if type(levels) == "table" and petName then
		return tonumber(levels[petName]) or 1
	end

	if petName == getEquippedPet() then
		return tonumber(currentState.petLevel) or 1
	end

	return 1
end

local function getPetXP(petName)
	local xpTable = currentState.petXP

	if type(xpTable) == "table" and petName then
		return tonumber(xpTable[petName]) or 0
	end

	return 0
end

local function getPetEvolved(petName)
	local evolved = currentState.evolvedPets
	if type(evolved) == "table" and petName then
		return evolved[petName] == true
	end

	if petName == getEquippedPet() then
		return currentState.petEvolved == true
	end

	return false
end

local function getPetEmoji(petName)
	local info = PET_INFO[petName]
	return info and info.emoji or "PET"
end

-- Draws a tiny mascot portrait with Roblox UI shapes instead of emoji glyphs.
-- This avoids question-mark boxes on systems/fonts that do not support emoji.
local function makePetBadge(parent, petName, badgeSize, position, zIndex)
	local info = PET_INFO[petName] or {
		color = COLORS.accent,
		rarity = "Unknown",
	}
	local baseColor = info.color
	local darkColor = baseColor:Lerp(Color3.fromRGB(30, 35, 55), 0.22)
	local z = zIndex or 1

	local badge = Instance.new("Frame")
	badge.Name = "PetPortrait_" .. tostring(petName)
	badge.Size = UDim2.fromOffset(badgeSize, badgeSize)
	badge.Position = position or UDim2.new()
	badge.BackgroundTransparency = 1
	badge.BorderSizePixel = 0
	badge.ZIndex = z
	badge.Parent = parent

	local function shape(name, size, pos, color, radius, rotation)
		local part = Instance.new("Frame")
		part.Name = name
		part.Size = size
		part.Position = pos
		part.BackgroundColor3 = color
		part.BorderSizePixel = 0
		part.Rotation = rotation or 0
		part.ZIndex = z + 1
		part.Parent = badge
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(radius or 1, 0)
		c.Parent = part
		return part
	end

	local s = badgeSize
	local earColor = darkColor
	if petName == "Tidefin" or petName == "Glacub" then
		shape("LeftFin", UDim2.fromOffset(s*0.24, s*0.34), UDim2.fromOffset(s*0.08, s*0.27), darkColor, 0.35, -28)
		shape("RightFin", UDim2.fromOffset(s*0.24, s*0.34), UDim2.fromOffset(s*0.68, s*0.27), darkColor, 0.35, 28)
	elseif petName == "Mossbun" then
		shape("LeftEar", UDim2.fromOffset(s*0.22, s*0.48), UDim2.fromOffset(s*0.2, s*0.02), baseColor, 0.5, -12)
		shape("RightEar", UDim2.fromOffset(s*0.22, s*0.48), UDim2.fromOffset(s*0.58, s*0.02), baseColor, 0.5, 12)
	else
		shape("LeftEar", UDim2.fromOffset(s*0.28, s*0.34), UDim2.fromOffset(s*0.13, s*0.13), earColor, 0.18, -28)
		shape("RightEar", UDim2.fromOffset(s*0.28, s*0.34), UDim2.fromOffset(s*0.59, s*0.13), earColor, 0.18, 28)
	end

	-- Species accessories are intentionally simple so they remain readable at small sizes.
	if petName == "Duskmoth" then
		shape("LeftWing", UDim2.fromOffset(s*0.34, s*0.38), UDim2.fromOffset(s*0.01, s*0.36), darkColor, 0.45, -18)
		shape("RightWing", UDim2.fromOffset(s*0.34, s*0.38), UDim2.fromOffset(s*0.65, s*0.36), darkColor, 0.45, 18)
	elseif petName == "Bloomlet" then
		for i = 1, 5 do
			local angle = math.pi * 2 * i / 5
			shape("Petal" .. i, UDim2.fromOffset(s*0.22, s*0.22), UDim2.fromOffset(s*(0.39 + math.cos(angle)*0.15), s*(0.22 + math.sin(angle)*0.12)), Color3.fromRGB(255, 195, 220), 1)
		end
	elseif petName == "Starwhisp" then
		shape("StarOrb", UDim2.fromOffset(s*0.19, s*0.19), UDim2.fromOffset(s*0.72, s*0.05), Color3.fromRGB(255, 224, 120), 1)
	elseif petName == "Voltkit" or petName == "Stormling" then
		shape("LightningMark", UDim2.fromOffset(s*0.13, s*0.3), UDim2.fromOffset(s*0.44, s*0.1), Color3.fromRGB(255, 235, 100), 0.12, 20)
	end

	shape("Head", UDim2.fromOffset(s*0.72, s*0.66), UDim2.fromOffset(s*0.14, s*0.25), baseColor, 0.48)
	shape("LeftEye", UDim2.fromOffset(s*0.075, s*0.11), UDim2.fromOffset(s*0.34, s*0.48), Color3.fromRGB(30, 30, 42), 1)
	shape("RightEye", UDim2.fromOffset(s*0.075, s*0.11), UDim2.fromOffset(s*0.59, s*0.48), Color3.fromRGB(30, 30, 42), 1)
	shape("Muzzle", UDim2.fromOffset(s*0.2, s*0.13), UDim2.fromOffset(s*0.4, s*0.62), Color3.fromRGB(255, 239, 220), 1)
	shape("Nose", UDim2.fromOffset(s*0.055, s*0.05), UDim2.fromOffset(s*0.47, s*0.64), Color3.fromRGB(45, 35, 45), 1)

	return badge
end

local function makeEggBadge(parent, size, position, glowColor)
	-- Stylized oval egg with mottled shell spots; this is a temporary drawn
	-- icon, so no uploaded image IDs are needed yet.
	local holder = Instance.new("Frame")
	holder.Name = "EggBadgeHolder"
	holder.Size = UDim2.fromOffset(size, size)
	holder.Position = position or UDim2.new()
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 2
	holder.Parent = parent

	local egg = Instance.new("Frame")
	egg.Name = "SpottedOvalEgg"
	egg.Size = UDim2.new(0.68, 0, 0.88, 0)
	egg.Position = UDim2.new(0.16, 0, 0.06, 0)
	egg.BackgroundColor3 = Color3.fromRGB(239, 218, 176)
	egg.BorderSizePixel = 0
	egg.Rotation = -5
	egg.ZIndex = 3
	egg.Parent = holder
	corner(egg, 999)
	stroke(egg, glowColor or Color3.fromRGB(177, 137, 87), math.max(1, math.floor(size / 22)))

	local function spot(name, x, y, w, h, color)
		local item = Instance.new("Frame")
		item.Name = name
		item.Size = UDim2.new(w, 0, h, 0)
		item.Position = UDim2.new(x, 0, y, 0)
		item.BackgroundColor3 = color or Color3.fromRGB(169, 125, 86)
		item.BorderSizePixel = 0
		item.Rotation = math.random(-25, 25)
		item.ZIndex = 4
		item.Parent = egg
		corner(item, 999)
	end
	spot("ShellSpot1", 0.22, 0.24, 0.19, 0.13)
	spot("ShellSpot2", 0.59, 0.36, 0.16, 0.11)
	spot("ShellSpot3", 0.31, 0.59, 0.22, 0.14)
	spot("ShellSpot4", 0.63, 0.73, 0.12, 0.09)

	local highlight = Instance.new("Frame")
	highlight.Name = "EggHighlight"
	highlight.Size = UDim2.new(0.12, 0, 0.5, 0)
	highlight.Position = UDim2.new(0.18, 0, 0.18, 0)
	highlight.BackgroundColor3 = Color3.fromRGB(255, 250, 226)
	highlight.BackgroundTransparency = 0.15
	highlight.BorderSizePixel = 0
	highlight.ZIndex = 5
	highlight.Parent = egg
	corner(highlight, 999)
	return holder, egg
end

local function getPetRarity(petName)
	local info = PET_INFO[petName]
	return info and info.rarity or "Unknown"
end

local function showToast(message, color)
	toastId += 1
	local thisToast = toastId

	local toast = newFrame(
		gui,
		"Toast",
		UDim2.new(0.8, 0, 0, 48),
		UDim2.new(0.5, 0, 0, 18),
		color or COLORS.panel
	)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Size = UDim2.new(0.8, 0, 0, 48)
	toast.BackgroundTransparency = 0.05
	toast.ZIndex = 100
	stroke(toast, COLORS.accent, 1)

	local label = newLabel(
		toast,
		message,
		UDim2.new(1, -20, 1, -8),
		UDim2.new(0, 10, 0, 4),
		14,
		COLORS.text
	)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.ZIndex = 101

	toast.Position = UDim2.new(0.5, 0, 0, -60)
	TweenService:Create(
		toast,
		TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 18) }
	):Play()

	task.delay(2.8, function()
		if toast.Parent and thisToast == toastId then
			local tween = TweenService:Create(
				toast,
				TweenInfo.new(0.18),
				{ Position = UDim2.new(0.5, 0, 0, -65) }
			)
			tween:Play()
			tween.Completed:Wait()
			if toast.Parent then
				toast:Destroy()
			end
		elseif toast.Parent then
			toast:Destroy()
		end
	end)
end

--========================================================
-- MENU SHELL
--========================================================

local menuLayer = Instance.new("Frame")
menuLayer.Name = "MenuLayer"
menuLayer.BackgroundTransparency = 1
menuLayer.Size = UDim2.fromScale(1, 1)
menuLayer.Parent = gui

local menuOverlay = Instance.new("TextButton")
menuOverlay.Name = "MenuOverlay"
menuOverlay.Size = UDim2.fromScale(1, 1)
menuOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
menuOverlay.BackgroundTransparency = 0.55
menuOverlay.Text = ""
menuOverlay.AutoButtonColor = false
menuOverlay.Visible = false
menuOverlay.Parent = menuLayer

local menuFrame = newFrame(
	menuLayer,
	"ActiveMenu",
	UDim2.new(0.86, 0, 0.72, 0),
	UDim2.fromScale(0.5, 0.5),
	COLORS.background
)
menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.Visible = false
menuFrame.ClipsDescendants = true
stroke(menuFrame, COLORS.border, 1.5)

local menuHeader = newFrame(
	menuFrame,
	"Header",
	UDim2.new(1, 0, 0, 52),
	UDim2.new(0, 0, 0, 0),
	COLORS.panel
)
menuHeader.BackgroundTransparency = 0
corner(menuHeader, 14)

local menuTitle = newLabel(
	menuHeader,
	"Menu",
	UDim2.new(1, -70, 1, 0),
	UDim2.new(0, 16, 0, 0),
	19,
	COLORS.text
)
menuTitle.Font = Enum.Font.GothamBold

local closeButton = newButton(
	menuHeader,
	"X",
	UDim2.new(0, 38, 0, 38),
	UDim2.new(1, -46, 0, 7),
	function()
		currentMenu = nil
		menuFrame.Visible = false
		menuOverlay.Visible = false
	end,
	COLORS.red
)
closeButton.TextSize = 18

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 1, -66)
content.Position = UDim2.new(0, 10, 0, 58)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 5
content.ScrollBarImageColor3 = COLORS.accentLight
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = menuFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 4)
contentPadding.PaddingBottom = UDim.new(0, 12)
contentPadding.PaddingLeft = UDim.new(0, 4)
contentPadding.PaddingRight = UDim.new(0, 4)
contentPadding.Parent = content

local function openMenu(name, title)
	currentMenu = name
	menuTitle.Text = title
	menuOverlay.Visible = true
	menuFrame.Visible = true
	menuFrame.Size = UDim2.new(0.86, 0, 0.72, 0)

	local camera = workspace.CurrentCamera
	if camera and camera.ViewportSize.X < 600 then
		menuFrame.Size = UDim2.new(0.94, 0, 0.78, 0)
	end

	clearChildren(content)
end

local function closeMenu()
	currentMenu = nil
	menuFrame.Visible = false
	menuOverlay.Visible = false
end

menuOverlay.Activated:Connect(closeMenu)

--========================================================
-- PET INVENTORY NORMALIZATION
--========================================================

local function getInventory()
	local inventory = currentState.ownedPets
		or currentState.inventory
		or currentState.petInventory
		or {}

	local normalized = {}

	-- Inventário em formato de dicionário:
	-- ownedPets = { EmberFox = 1, Mossbun = 2 }
	if type(inventory) == "table" then
		for petName, amount in pairs(inventory) do
			if type(petName) == "string" and type(amount) == "number" and amount > 0 then
				normalized[petName] = amount
			end
		end
	end

	return normalized
end

local function getOwnedPetNames()
	local owned = getInventory()
	local result = {}

	for _, petName in ipairs(PET_ORDER) do
		if owned[petName] and owned[petName] > 0 then
			table.insert(result, petName)
		end
	end

	for petName, amount in pairs(owned) do
		if amount > 0 and not table.find(result, petName) then
			table.insert(result, petName)
		end
	end

	return result, owned
end

--========================================================
-- PET COLLECTION
--========================================================

local function showPetDetails(petName, amount)
	currentPet = petName
	openMenu("PetDetails", petName)

	local info = PET_INFO[petName] or {
		emoji = "PET",
		rarity = "Unknown",
		color = COLORS.accent,
	}

	local card = newFrame(
		content,
		"PetDetailsCard",
		UDim2.new(1, -8, 0, 160),
		UDim2.new(),
		COLORS.panel
	)
	card.LayoutOrder = 1
	stroke(card, info.color, 1.5)

	makePetBadge(card, petName, 88, UDim2.new(0, 12, 0, 10), 3)

	local details = newLabel(
		card,
		petName .. "\n" .. info.rarity
			.. "\nLevel " .. getPetLevel(petName)
			.. (getPetEvolved(petName) and "\nEVOLVED" or "")
			.. "\nOwned: " .. tostring(amount or 1),
		UDim2.new(1, -125, 0, 108),
		UDim2.new(0, 112, 0, 8),
		14,
		COLORS.text
	)
	details.TextYAlignment = Enum.TextYAlignment.Top

	local equipped = getEquippedPet() == petName
	local evolved = getPetEvolved(petName)
	newButton(
		card,
		equipped and "EQUIPPED" or "Equip Pet",
		UDim2.new(0.44, 0, 0, 34),
		UDim2.new(0, 10, 1, -42),
		function()
			local ok = invokeRemote(EquipPet, petName)
			if ok then
				showToast("Equip request sent")
				task.delay(0.25, function()
					requestState()
					if currentMenu == "PetDetails" then
						showPetDetails(petName, amount)
					end
				end)
			end
		end,
		equipped and COLORS.green or COLORS.accent
	)

	local evolutionButton = newButton(
		card,
		evolved and "ALREADY EVOLVED" or (equipped and "EVOLUTION" or "EQUIP TO EVOLVE"),
		UDim2.new(0.44, 0, 0, 34),
		UDim2.new(0.52, 0, 1, -42),
		function()
			if not equipped then
				showToast("Equip this Mythling before evolving it.", COLORS.gold)
				return
			end
			if evolved then
				showToast("This Mythling has already evolved.", COLORS.gold)
				return
			end

			local success = invokeRemote(EvolvePet)
			if success then
				showToast("Evolution request sent")
				task.delay(0.25, function()
					requestState()
					if currentMenu == "PetDetails" then
						showPetDetails(petName, amount)
					end
				end)
			end
		end,
		evolved and COLORS.green or (equipped and COLORS.panelLight or COLORS.border)
	)
	evolutionButton.Active = equipped and not evolved
	evolutionButton.AutoButtonColor = equipped and not evolved

	local note = newLabel(
		content,
		"Evolution availability and costs are checked by the server.",
		UDim2.new(1, -8, 0, 40),
		UDim2.new(),
		12,
		COLORS.muted
	)
	note.LayoutOrder = 2
end

local function showPets()
	openMenu("Pets", "YOUR PETS")

	local ownedNames, owned = getOwnedPetNames()

	local summary = newLabel(
		content,
		"Owned pets: " .. tostring(#ownedNames)
			.. " unique species - Select a pet for details",
		UDim2.new(1, -8, 0, 34),
		UDim2.new(),
		12,
		COLORS.muted
	)
	summary.LayoutOrder = 1

	local gridHolder = Instance.new("Frame")
	gridHolder.Name = "PetGrid"
	gridHolder.Size = UDim2.new(1, -8, 0, 0)
	gridHolder.AutomaticSize = Enum.AutomaticSize.Y
	gridHolder.BackgroundTransparency = 1
	gridHolder.LayoutOrder = 2
	gridHolder.Parent = content

	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.CellSize = UDim2.new(0.25, -8, 0, 126)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = gridHolder

	local smallScreen = workspace.CurrentCamera
		and workspace.CurrentCamera.ViewportSize.X < 500

	if smallScreen then
		grid.CellSize = UDim2.new(0.5, -6, 0, 124)
	end

	for index, petName in ipairs(ownedNames) do
		local info = PET_INFO[petName] or {
			emoji = "PET",
			rarity = "Unknown",
			color = COLORS.accent,
		}

		local amount = owned[petName] or 1
		local isEquipped = getEquippedPet() == petName

		local tile = newButton(
			gridHolder,
			"",
			UDim2.new(),
			UDim2.new(),
			function()
				showPetDetails(petName, amount)
			end,
			COLORS.panel
		)
		tile.LayoutOrder = index
		tile.Size = UDim2.new(0, 100, 0, 126)
		tile.AutomaticSize = Enum.AutomaticSize.None
		stroke(tile, isEquipped and COLORS.green or info.color, 1.2)

		makePetBadge(tile, petName, 48, UDim2.new(0.5, -24, 0, 5), 3)

		local nameLabel = newLabel(
			tile,
			petName,
			UDim2.new(1, -6, 0, 28),
			UDim2.new(0, 3, 0, 55),
			11,
			COLORS.text
		)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center

		local levelLabel = newLabel(
			tile,
			"Lv. " .. getPetLevel(petName)
				.. (amount > 1 and ("  x" .. amount) or ""),
			UDim2.new(1, -4, 0, 18),
			UDim2.new(0, 2, 0, 83),
			10,
			COLORS.muted
		)
		levelLabel.TextXAlignment = Enum.TextXAlignment.Center

		local rarityLabel = newLabel(
			tile,
			info.rarity .. (isEquipped and " [EQUIPPED]" or ""),
			UDim2.new(1, -4, 0, 18),
			UDim2.new(0, 2, 0, 102),
			10,
			info.color
		)
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
	end

	if #ownedNames == 0 then
		local empty = newLabel(
			gridHolder,
			"No pets yet. Open an egg to get your first pet!",
			UDim2.new(1, -8, 0, 70),
			UDim2.new(),
			14,
			COLORS.muted
		)
		empty.TextXAlignment = Enum.TextXAlignment.Center
	end
end

--========================================================
-- EGG SHOP AND COMPACT HATCH ROULETTE
--========================================================

local eggFrame

local function getRarityColor(rarity)
	local colors = {
		Common = Color3.fromRGB(175, 190, 205),
		Uncommon = Color3.fromRGB(87, 211, 137),
		Rare = Color3.fromRGB(81, 177, 255),
		Epic = Color3.fromRGB(190, 113, 255),
		Legendary = Color3.fromRGB(255, 199, 73),
		VIP = Color3.fromRGB(120, 240, 226),
		Starter = COLORS.accentLight,
	}
	return colors[rarity] or COLORS.gold
end

local function showEggResult(petName, rarity)
	hatchId += 1
	local thisHatch = hatchId
	rarity = rarity or getPetRarity(petName)
	local rarityColor = getRarityColor(rarity)

	-- Suspense overlay: the server already chose the pet, but we delay
	-- revealing it so the player sees the egg crack first.
	local suspense = Instance.new("Frame")
	suspense.Name = "EggHatchSuspense"
	suspense.Size = UDim2.fromScale(1, 1)
	suspense.Position = UDim2.fromScale(0, 0)
	suspense.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
	suspense.BackgroundTransparency = 0.22
	suspense.BorderSizePixel = 0
	suspense.ZIndex = 80
	suspense.Parent = gui

	local panel = newFrame(
		suspense,
		"SuspensePanel",
		UDim2.new(0, 330, 0, 285),
		UDim2.new(0.5, 0, 0.5, 0),
		COLORS.background
	)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.ZIndex = 81
	stroke(panel, COLORS.border, 2)

	local suspenseTitle = newLabel(
		panel,
		"A MYTHLING IS INSIDE...",
		UDim2.new(1, -20, 0, 34),
		UDim2.new(0, 10, 0, 12),
		15,
		COLORS.text
	)
	suspenseTitle.Font = Enum.Font.GothamBold
	suspenseTitle.TextXAlignment = Enum.TextXAlignment.Center
	suspenseTitle.ZIndex = 82

	local eggShell = Instance.new("Frame")
	eggShell.Name = "EggShell"
	eggShell.Size = UDim2.new(0, 96, 0, 132)
	eggShell.Position = UDim2.new(0.5, 0, 0.5, -8)
	eggShell.AnchorPoint = Vector2.new(0.5, 0.5)
	eggShell.BackgroundColor3 = Color3.fromRGB(239, 218, 176)
	eggShell.BorderSizePixel = 0
	eggShell.Rotation = -4
	eggShell.ZIndex = 83
	eggShell.Parent = panel
	corner(eggShell, 999)
	stroke(eggShell, Color3.fromRGB(177, 137, 87), 3)

	for i, spotData in ipairs({
		{0.18, 0.25, 15}, {0.61, 0.32, 12}, {0.34, 0.58, 17}, {0.64, 0.75, 10},
		}) do
		local spot = Instance.new("Frame")
		spot.Name = "ShellSpot" .. i
		spot.Size = UDim2.new(0, spotData[3], 0, spotData[3] * 0.72)
		spot.Position = UDim2.new(spotData[1], 0, spotData[2], 0)
		spot.BackgroundColor3 = Color3.fromRGB(169, 125, 86)
		spot.BorderSizePixel = 0
		spot.ZIndex = 84
		spot.Parent = eggShell
		corner(spot, 999)
	end

	local eggHighlight = Instance.new("Frame")
	eggHighlight.Name = "EggHighlight"
	eggHighlight.Size = UDim2.new(0, 18, 0, 64)
	eggHighlight.Position = UDim2.new(0, 18, 0, 20)
	eggHighlight.BackgroundColor3 = Color3.fromRGB(255, 250, 220)
	eggHighlight.BackgroundTransparency = 0.2
	eggHighlight.BorderSizePixel = 0
	eggHighlight.Rotation = 12
	eggHighlight.ZIndex = 84
	eggHighlight.Parent = eggShell
	corner(eggHighlight, 10)

	local crack = Instance.new("Frame")
	crack.Name = "CrackLines"
	crack.Size = UDim2.fromOffset(54, 70)
	crack.Position = UDim2.new(0.5, -27, 0.5, -35)
	crack.BackgroundTransparency = 1
	crack.Visible = false
	crack.ZIndex = 85
	crack.Parent = eggShell

	local crackSegments = {}
	local function addCrackSegment(x1, y1, x2, y2, width)
		local segment = Instance.new("Frame")
		segment.Name = "CrackSegment"
		segment.AnchorPoint = Vector2.new(0.5, 0.5)
		segment.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
		local dx, dy = x2 - x1, y2 - y1
		segment.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), width or 3)
		segment.Rotation = math.deg(math.atan2(dy, dx))
		segment.BackgroundColor3 = Color3.fromRGB(126, 76, 35)
		segment.BorderSizePixel = 0
		segment.ZIndex = 86
		segment.Parent = crack
		table.insert(crackSegments, segment)
	end
	addCrackSegment(27, 2, 22, 17, 3)
	addCrackSegment(22, 17, 31, 28, 3)
	addCrackSegment(31, 28, 24, 41, 3)
	addCrackSegment(24, 41, 35, 51, 3)
	addCrackSegment(35, 51, 29, 68, 3)
	addCrackSegment(22, 17, 10, 23, 3)
	addCrackSegment(31, 28, 45, 24, 3)


	local suspenseStatus = newLabel(
		panel,
		"The egg is glowing...",
		UDim2.new(1, -20, 0, 28),
		UDim2.new(0, 10, 1, -44),
		13,
		COLORS.muted
	)
	suspenseStatus.TextXAlignment = Enum.TextXAlignment.Center
	suspenseStatus.ZIndex = 82

	panel.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(
		panel,
		TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 330, 0, 285) }
	):Play()

	-- The shell starts with a subtle rarity-colored glow.
	TweenService:Create(eggShell, TweenInfo.new(0.65), {BackgroundColor3 = Color3.fromRGB(247, 230, 197)}):Play()
	local rarityGlow = Instance.new("UIStroke")
	rarityGlow.Name = "RarityGlow"
	rarityGlow.Color = COLORS.border
	rarityGlow.Thickness = 3
	rarityGlow.Transparency = 0.12
	rarityGlow.Parent = eggShell

	-- Phase 1: anticipation and increasingly strong shaking.
	task.spawn(function()
		local phases = {
			{ duration = 0.65, angle = 7, status = "The egg is glowing..." },
			{ duration = 0.75, angle = 12, status = "Something is moving inside!" },
			{ duration = 0.8, angle = 17, status = "It's about to hatch!" },
		}

		for _, phase in ipairs(phases) do
			if not suspense.Parent or thisHatch ~= hatchId then
				return
			end

			suspenseStatus.Text = phase.status
			local elapsed = 0

			while elapsed < phase.duration do
				if not suspense.Parent or thisHatch ~= hatchId then
					return
				end

				local angle = (math.random(0, 1) == 0 and -1 or 1) * phase.angle
				local shake = TweenService:Create(
					eggShell,
					TweenInfo.new(0.075, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Rotation = angle }
				)
				shake:Play()
				shake.Completed:Wait()
				elapsed += 0.075
			end
		end

		if not suspense.Parent or thisHatch ~= hatchId then
			return
		end

		-- Phase 2: visible cracks and a short flash before the reveal.
		crack.Visible = true
		-- Keep the rarity hidden until the egg visibly cracks.
		-- The color is applied only at this point, not when the egg is purchased.
		local panelStroke = panel:FindFirstChildOfClass("UIStroke")
		if panelStroke then
			panelStroke.Color = rarityColor
		end
		rarityGlow.Color = rarityColor
		for _, segment in ipairs(crackSegments) do
			segment.BackgroundColor3 = rarityColor
		end
		TweenService:Create(rarityGlow, TweenInfo.new(0.3), {Thickness = 8, Transparency = 0}):Play()
		suspenseStatus.Text = "CRACK!"
		TweenService:Create(
			eggShell,
			TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Rotation = 0, Size = UDim2.new(0, 116, 0, 140) }
		):Play()
		task.wait(0.25)

		if not suspense.Parent or thisHatch ~= hatchId then
			return
		end

		for _, segment in ipairs(crackSegments) do
			segment.BackgroundColor3 = rarityColor
			segment.Size = UDim2.fromOffset(segment.Size.X.Offset, 4)
		end
		suspenseStatus.Text = "IT'S HATCHING!"
		TweenService:Create(
			eggShell,
			TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = rarityColor, Size = UDim2.new(0, 132, 0, 154) }
		):Play()

		local flash = Instance.new("Frame")
		flash.Name = "HatchFlash"
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundColor3 = Color3.new(1, 1, 1)
		flash.BackgroundTransparency = 1
		flash.BorderSizePixel = 0
		flash.ZIndex = 100
		flash.Parent = gui

		TweenService:Create(
			flash,
			TweenInfo.new(0.12),
			{ BackgroundTransparency = 0.12 }
		):Play()
		task.wait(0.14)
		TweenService:Create(
			flash,
			TweenInfo.new(0.28),
			{ BackgroundTransparency = 1 }
		):Play()

		suspense:Destroy()
		task.delay(0.3, function()
			if flash.Parent then
				flash:Destroy()
			end
		end)

		if thisHatch ~= hatchId then
			return
		end

		-- Phase 3: reveal the Mythling and its rarity.
		local result = newFrame(
			gui,
			"HatchResult",
			UDim2.new(0, 330, 0, 245),
			UDim2.new(0.5, 0, 0.5, 0),
			COLORS.background
		)
		result.AnchorPoint = Vector2.new(0.5, 0.5)
		result.ZIndex = 90
		stroke(result, rarityColor, rarity == "Legendary" and 4 or 2)

		local resultTitle = newLabel(
			result,
			"YOU HATCHED!",
			UDim2.new(1, -20, 0, 30),
			UDim2.new(0, 10, 0, 10),
			16,
			rarityColor
		)
		resultTitle.Font = Enum.Font.GothamBlack
		resultTitle.TextXAlignment = Enum.TextXAlignment.Center
		resultTitle.ZIndex = 91

		local rarityLabel = newLabel(
			result,
			string.upper(tostring(rarity)),
			UDim2.new(1, -20, 0, 22),
			UDim2.new(0, 10, 0, 40),
			12,
			rarityColor
		)
		rarityLabel.Font = Enum.Font.GothamBold
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
		rarityLabel.ZIndex = 91

		local icon = makePetBadge(result, petName, 78, UDim2.new(0.5, -39, 0, 63), 92)
		icon.Rotation = -18
		icon.Size = UDim2.fromOffset(8, 8)
		TweenService:Create(
			icon,
			TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Rotation = 0, Size = UDim2.fromOffset(78, 78) }
		):Play()

		local name = newLabel(
			result,
			tostring(petName),
			UDim2.new(1, -20, 0, 28),
			UDim2.new(0, 10, 0, 150),
			18,
			COLORS.text
		)
		name.Font = Enum.Font.GothamBlack
		name.TextXAlignment = Enum.TextXAlignment.Center
		name.ZIndex = 91

		local rarityDescription = newLabel(
			result,
			tostring(rarity) .. " Mythling discovered!",
			UDim2.new(1, -20, 0, 22),
			UDim2.new(0, 10, 0, 177),
			12,
			rarityColor
		)
		rarityDescription.TextXAlignment = Enum.TextXAlignment.Center
		rarityDescription.ZIndex = 91

		local close = newButton(
			result,
			"Awesome!",
			UDim2.new(0.65, 0, 0, 32),
			UDim2.new(0.175, 0, 1, -40),
			function()
				if result.Parent then
					result:Destroy()
				end
			end,
			COLORS.accent
		)
		close.ZIndex = 92

		result.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(
			result,
			TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 330, 0, 245) }
		):Play()

		task.delay(12, function()
			if result.Parent and thisHatch == hatchId then
				result:Destroy()
			end
		end)
	end)
end

local function showEggShop()
	openMenu("EggShop", "EGG SHOP")

	local intro = newLabel(
		content,
		"Choose an egg and discover a new Mythling.",
		UDim2.new(1, -8, 0, 34),
		UDim2.new(),
		13,
		COLORS.muted
	)
	intro.LayoutOrder = 1

	local eggCard = newFrame(
		content,
		"BasicEgg",
		UDim2.new(1, -8, 0, 150),
		UDim2.new(),
		COLORS.panel
	)
	eggCard.LayoutOrder = 2
	stroke(eggCard, COLORS.accent, 1.2)

	local eggIcon = makeEggBadge(
		eggCard,
		66,
		UDim2.new(0, 18, 0, 15)
	)

	local eggTitle = newLabel(
		eggCard,
		"Basic Egg",
		UDim2.new(1, -115, 0, 28),
		UDim2.new(0, 100, 0, 12),
		16,
		COLORS.text
	)
	eggTitle.Font = Enum.Font.GothamBold

	local price = newLabel(
		eggCard,
		"Cost: 250 Starshards",
		UDim2.new(1, -115, 0, 25),
		UDim2.new(0, 100, 0, 43),
		12,
		COLORS.gold
	)

	-- Read the same odds table sent by the server so the shop display
	-- cannot silently drift away from the actual egg roll configuration.
	local eggOdds = currentState.eggOdds or {
		Common = 45,
		Uncommon = 25,
		Rare = 18,
		Epic = 9,
		Legendary = 3,
	}
	local oddsText = string.format(
		"Common %s%% - Uncommon %s%%\nRare %s%% - Epic %s%% - Legendary %s%%",
		tostring(eggOdds.Common or 0),
		tostring(eggOdds.Uncommon or 0),
		tostring(eggOdds.Rare or 0),
		tostring(eggOdds.Epic or 0),
		tostring(eggOdds.Legendary or 0)
	)
	local odds = newLabel(
		eggCard,
		oddsText,
		UDim2.new(1, -115, 0, 40),
		UDim2.new(0, 100, 0, 67),
		10,
		COLORS.muted
	)
	odds.TextYAlignment = Enum.TextYAlignment.Top


	local openButton
	openButton = newButton(
		eggCard,
		"Open Egg",
		UDim2.new(0, 125, 0, 32),
		UDim2.new(0, 12, 1, -40),
		function()
			if busy then
				return
			end

			busy = true
			openButton.Text = "Opening..."
			eggIcon.Rotation = 0
			task.spawn(function()
				for _ = 1, 8 do
					if not eggIcon.Parent then return end
					local direction = (_ % 2 == 0) and 1 or -1
					local shake = TweenService:Create(
						eggIcon,
						TweenInfo.new(0.07, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
						{ Rotation = direction * 12 }
					)
					shake:Play()
					shake.Completed:Wait()
				end
				if eggIcon.Parent then
					TweenService:Create(eggIcon, TweenInfo.new(0.12), { Rotation = 0 }):Play()
				end
			end)

			local ok, result = invokeRemote(OpenEgg)

			if not ok then
				showToast("Could not open the egg.", COLORS.red)
			elseif type(result) == "table" and result.success == false then
				showToast(result.message or "You cannot open this egg.", COLORS.red)
			-- Successful hatches are announced by Notify with the server's
			-- authoritative pet and rarity. Avoid a duplicate generic success toast.
			end

			task.delay(4.5, function()
				busy = false

				if openButton and openButton.Parent then
					openButton.Text = "Open Egg"
				end
			end)
		end,
		COLORS.accent
	)

	local balance = newLabel(
		content,
		"Your Starshards: " .. formatNumber(getCurrency()),
		UDim2.new(1, -8, 0, 28),
		UDim2.new(),
		13,
		COLORS.gold
	)
	balance.LayoutOrder = 3
end

--========================================================
-- DAILY REWARDS
--========================================================

local function showDailyReward()
	openMenu("DailyReward", "DAILY REWARD")

	local available = currentState.dailyRewardAvailable == true
	local streak = tonumber(currentState.dailyRewardStreak) or 1
	local reward = tonumber(currentState.dailyRewardAmount) or 100
	local currentStreak = tonumber(currentState.dailyStreak) or 0

	local intro = newLabel(
		content,
		"Log in every day to grow your Starshard reward. The streak is capped at 8 days.",
		UDim2.new(1, -8, 0, 54),
		UDim2.new(),
		13,
		COLORS.muted
	)
	intro.LayoutOrder = 1
	intro.TextWrapped = true
	intro.TextYAlignment = Enum.TextYAlignment.Top

	local card = newFrame(
		content,
		"DailyRewardCard",
		UDim2.new(1, -8, 0, 128),
		UDim2.new(),
		COLORS.panel
	)
	card.LayoutOrder = 2
	stroke(card, COLORS.gold, 1.5)

	local amountLabel = newLabel(
		card,
		available and ("+" .. formatNumber(reward) .. " STARSHARDS") or "REWARD CLAIMED",
		UDim2.new(1, -20, 0, 34),
		UDim2.new(0, 10, 0, 14),
		20,
		available and COLORS.gold or COLORS.green
	)
	amountLabel.TextXAlignment = Enum.TextXAlignment.Center
	amountLabel.Font = Enum.Font.GothamBlack

	local streakLabel = newLabel(
		card,
		"Current streak: " .. currentStreak .. " day(s)\nNext claim streak: " .. streak,
		UDim2.new(1, -20, 0, 45),
		UDim2.new(0, 10, 0, 48),
		13,
		COLORS.text
	)
	streakLabel.TextWrapped = true
	streakLabel.TextXAlignment = Enum.TextXAlignment.Center

	local claim = newButton(
		content,
		available and "CLAIM DAILY REWARD" or "COME BACK TOMORROW",
		UDim2.new(1, -8, 0, 42),
		UDim2.new(),
		function()
			if not available then
				showToast("Your daily reward is already claimed.", COLORS.gold)
				return
			end

			local ok = invokeRemote(ClaimDailyReward)
			if ok then
				task.delay(0.25, function()
					requestState()
					if currentMenu == "DailyReward" then
						showDailyReward()
					end
				end)
			end
		end,
		available and COLORS.green or COLORS.panelLight
	)
	claim.LayoutOrder = 3
	claim.Active = available
	claim.AutoButtonColor = available

	local schedule = newLabel(
		content,
		"Rewards: 100, 150, 200, 250, 300, 350, 400, then 450 Starshards per consecutive day.",
		UDim2.new(1, -8, 0, 50),
		UDim2.new(),
		12,
		COLORS.muted
	)
	schedule.LayoutOrder = 4
	schedule.TextWrapped = true

	local wheelCard = newFrame(
		content,
		"DailyWheelCard",
		UDim2.new(1, -8, 0, 310),
		UDim2.new(),
		COLORS.panel
	)
	wheelCard.LayoutOrder = 5
	stroke(wheelCard, COLORS.accent, 1.5)

	local wheelTitle = newLabel(
		wheelCard,
		"DAILY STARSHARD WHEEL",
		UDim2.new(1, -16, 0, 28),
		UDim2.new(0, 8, 0, 8),
		15,
		COLORS.gold
	)
	wheelTitle.Font = Enum.Font.GothamBlack
	wheelTitle.TextXAlignment = Enum.TextXAlignment.Center

	local pointer = newLabel(
		wheelCard,
		"▼",
		UDim2.new(0, 28, 0, 22),
		UDim2.new(0.5, -14, 0, 36),
		19,
		COLORS.gold
	)
	pointer.TextXAlignment = Enum.TextXAlignment.Center

	wheelVisual = newFrame(
		wheelCard,
		"WheelDisk",
		UDim2.fromOffset(210, 210),
		UDim2.new(0.5, -105, 0, 54),
		COLORS.background
	)
	corner(wheelVisual, 999)
	stroke(wheelVisual, COLORS.gold, 3)

	local wheelEntries = currentState.wheelRewards or {
		{amount = 100, weight = 40},
		{amount = 250, weight = 30},
		{amount = 500, weight = 18},
		{amount = 1000, weight = 10},
		{amount = 2500, weight = 2},
	}
	-- Five prize markers are evenly spaced around a circle. The result
	-- animation rotates the server-selected marker under the top pointer.
	local wheelPositions = {
		UDim2.fromOffset(74, 20),
		UDim2.fromOffset(139, 67),
		UDim2.fromOffset(114, 143),
		UDim2.fromOffset(34, 143),
		UDim2.fromOffset(9, 67),
	}
	local wheelColors = {
		Color3.fromRGB(74, 151, 255),
		Color3.fromRGB(76, 205, 137),
		Color3.fromRGB(255, 201, 86),
		Color3.fromRGB(190, 113, 255),
		Color3.fromRGB(255, 96, 111),
	}
	for index, entry in ipairs(wheelEntries) do
		local position = wheelPositions[index]
		if position then
			local chip = newFrame(
				wheelVisual,
				"Prize_" .. index,
				UDim2.fromOffset(62, 36),
				position,
				wheelColors[index] or COLORS.accent
			)
			corner(chip, 9)
			local prizeText = newLabel(
				chip,
				formatNumber(tonumber(entry.amount) or 0),
				UDim2.fromScale(1, 1),
				UDim2.new(),
				10,
				COLORS.background
			)
			prizeText.Font = Enum.Font.GothamBlack
			prizeText.TextXAlignment = Enum.TextXAlignment.Center
		end
	end

	local center = newFrame(
		wheelVisual,
		"WheelCenter",
		UDim2.fromOffset(42, 42),
		UDim2.new(0.5, -21, 0.5, -21),
		COLORS.panel
	)
	corner(center, 999)
	stroke(center, COLORS.text, 1)
	local star = newLabel(
		center,
		"★",
		UDim2.fromScale(1, 1),
		UDim2.new(),
		22,
		COLORS.gold
	)
	star.TextXAlignment = Enum.TextXAlignment.Center

	wheelButton = newButton(
		wheelCard,
		currentState.dailyWheelAvailable and "SPIN THE WHEEL" or "COME BACK TOMORROW",
		UDim2.new(1, -20, 0, 34),
		UDim2.new(0, 10, 1, -42),
		function()
			if wheelBusy then return end
			if not currentState.dailyWheelAvailable then
				showToast("The daily wheel is already used.", COLORS.gold)
				return
			end

			wheelBusy = true
			wheelSpinAttempt += 1
			local thisAttempt = wheelSpinAttempt
			if wheelButton and wheelButton.Parent then
				wheelButton.Text = "SPINNING..."
				wheelButton.Active = false
				wheelButton.AutoButtonColor = false
			end
			local ok = invokeRemote(SpinWheel)
			if not ok then
				wheelBusy = false
				if wheelButton and wheelButton.Parent then
					wheelButton.Text = "SPIN THE WHEEL"
					wheelButton.Active = true
					wheelButton.AutoButtonColor = true
				end
			end
			task.delay(8, function()
				if wheelBusy and wheelSpinAttempt == thisAttempt then
					wheelBusy = false
					if wheelButton and wheelButton.Parent then
						local available = currentState.dailyWheelAvailable == true
						wheelButton.Text = available and "SPIN THE WHEEL" or "COME BACK TOMORROW"
						wheelButton.Active = available
						wheelButton.AutoButtonColor = available
					end
					showToast("The wheel did not respond. Please refresh your state.", COLORS.red)
				end
			end)
		end,
		currentState.dailyWheelAvailable and COLORS.accent or COLORS.panelLight
	)
	wheelButton.LayoutOrder = 6
	wheelButton.Active = currentState.dailyWheelAvailable
	wheelButton.AutoButtonColor = currentState.dailyWheelAvailable

	local oddsParts = {}
	for _, entry in ipairs(wheelEntries) do
		table.insert(
			oddsParts,
			formatNumber(tonumber(entry.amount) or 0)
				.. " (" .. tostring(entry.weight or 0) .. "%)"
		)
	end
	local wheelOdds = newLabel(
		content,
		"Prize odds: " .. table.concat(oddsParts, ", ") .. " Starshards.",
		UDim2.new(1, -8, 0, 44),
		UDim2.new(),
		12,
		COLORS.muted
	)
	wheelOdds.LayoutOrder = 6
	wheelOdds.TextWrapped = true
end

--========================================================
-- QUESTS AND PROGRESSION
--========================================================

local function showPremiumShop()
	openMenu("PremiumShop", "SUPPORT MYTHLING REALMS")

	local intro = newLabel(
		content,
		"Optional purchases. Every benefit is explained before you buy; Roblox displays the final price in its secure purchase window.",
		UDim2.new(1, -8, 0, 56),
		UDim2.new(),
		13,
		COLORS.muted
	)
	intro.LayoutOrder = 1
	intro.TextWrapped = true
	intro.TextYAlignment = Enum.TextYAlignment.Top

	local passes = currentState.gamePasses or {}
	for index, pass in ipairs(passes) do
		local card = newFrame(
			content,
			"Pass_" .. tostring(pass.key),
			UDim2.new(1, -8, 0, 112),
			UDim2.new(),
			COLORS.panel
		)
		card.LayoutOrder = index + 1
		stroke(card, pass.key == "VIPCompanion" and COLORS.gold or COLORS.accent, 1.3)

		local titleLabel = newLabel(
			card,
			tostring(pass.name or "Game Pass"),
			UDim2.new(1, -18, 0, 26),
			UDim2.new(0, 9, 0, 8),
			15,
			pass.key == "VIPCompanion" and COLORS.gold or COLORS.text
		)
		titleLabel.Font = Enum.Font.GothamBold

		local description = newLabel(
			card,
			tostring(pass.description or "Optional cosmetic or gameplay benefit."),
			UDim2.new(1, -18, 0, 32),
			UDim2.new(0, 9, 0, 35),
			11,
			COLORS.muted
		)
		description.TextWrapped = true
		description.TextYAlignment = Enum.TextYAlignment.Top

		local owned = pass.owned == true
		local passId = tonumber(pass.passId) or 0
		local configured = pass.configured == true and passId > 0
		local buttonText = owned and "OWNED" or (configured and "BUY PASS" or "SETUP REQUIRED")
		local actionButton = newButton(
			card,
			buttonText,
			UDim2.new(0, 130, 0, 30),
			UDim2.new(1, -140, 1, -36),
			function()
				if owned then
					showToast("You already own this pass.", COLORS.green)
					return
				end
				if not configured then
					showToast("This pass is disabled until its real ID is configured.", COLORS.gold)
					return
				end

				local ok, err = pcall(function()
					MarketplaceService:PromptGamePassPurchase(player, passId)
				end)
				if not ok then
					warn("[MythlingRealms] Could not open Game Pass prompt:", err)
					showToast("Roblox could not open the purchase prompt.", COLORS.red)
				end
			end,
			owned and COLORS.green or (configured and COLORS.accent or COLORS.panelLight)
		)
		actionButton.Active = not owned and configured
		actionButton.AutoButtonColor = not owned and configured
	end

	local products = currentState.developerProducts or {}
	for index, product in ipairs(products) do
		local card = newFrame(
			content,
			"Product_" .. tostring(product.key),
			UDim2.new(1, -8, 0, 112),
			UDim2.new(),
			COLORS.panel
		)
		card.LayoutOrder = #passes + index + 1
		stroke(card, COLORS.green, 1.2)

		local titleLabel = newLabel(
			card,
			tostring(product.name or "Starshard Pack"),
			UDim2.new(1, -18, 0, 26),
			UDim2.new(0, 9, 0, 8),
			15,
			COLORS.green
		)
		titleLabel.Font = Enum.Font.GothamBold

		local description = newLabel(
			card,
			tostring(product.description or "A Starshard currency pack.")
				.. "\n+" .. formatNumber(tonumber(product.starshards) or 0) .. " Starshards",
			UDim2.new(1, -18, 0, 38),
			UDim2.new(0, 9, 0, 35),
			11,
			COLORS.muted
		)
		description.TextWrapped = true
		description.TextYAlignment = Enum.TextYAlignment.Top

		local productId = tonumber(product.productId) or 0
		local configured = product.configured == true and productId > 0
		local actionButton = newButton(
			card,
			configured and "BUY STARSHARDS" or "SETUP REQUIRED",
			UDim2.new(0, 142, 0, 30),
			UDim2.new(1, -152, 1, -36),
			function()
				if not configured then
					showToast("This pack is disabled until its real Developer Product ID is configured.", COLORS.gold)
					return
				end

				local ok, err = pcall(function()
					MarketplaceService:PromptProductPurchase(player, productId)
				end)
				if not ok then
					warn("[MythlingRealms] Could not open Developer Product prompt:", err)
					showToast("Roblox could not open the purchase prompt.", COLORS.red)
				end
			end,
			configured and COLORS.green or COLORS.panelLight
		)
		actionButton.Active = configured
		actionButton.AutoButtonColor = configured
	end

	local note = newLabel(
		content,
		"Prices are shown by Roblox before purchase. Purchases stay disabled until you configure real IDs in MythlingServer.server.lua; no fake prices or IDs are used.",
		UDim2.new(1, -8, 0, 48),
		UDim2.new(),
		12,
		COLORS.muted
	)
	note.LayoutOrder = #passes + #products + 2
	note.TextWrapped = true
end

--========================================================
-- PARTY / CO-OP
--========================================================

local function showParty()
	openMenu("Party", "PARTY & CO-OP")

	local party = partyState
	local intro = newLabel(
		content,
		"Create a party of up to 4 players, invite friends, and hunt creatures together. Nearby contributors share creature rewards.",
		UDim2.new(1, -8, 0, 56),
		UDim2.new(),
		13,
		COLORS.muted
	)
	intro.LayoutOrder = 1
	intro.TextWrapped = true
	intro.TextYAlignment = Enum.TextYAlignment.Top

	local summary = newFrame(
		content,
		"PartySummary",
		UDim2.new(1, -8, 0, 112),
		UDim2.new(),
		COLORS.panel
	)
	summary.LayoutOrder = 2
	stroke(summary, party and COLORS.green or COLORS.border, 1.2)

	local heading = newLabel(
		summary,
		party and ("PARTY · " .. tostring(party.memberCount or 1) .. "/" .. tostring(party.maxMembers or 4)) or "YOU ARE NOT IN A PARTY",
		UDim2.new(1, -18, 0, 26),
		UDim2.new(0, 9, 0, 8),
		15,
		party and COLORS.green or COLORS.text
	)
	heading.Font = Enum.Font.GothamBold

	local memberNames = {}
	if party and type(party.members) == "table" then
		for _, member in ipairs(party.members) do
			local label = tostring(member.name or member.username or "Player")
			if member.isLeader then label ..= " (Leader)" end
			table.insert(memberNames, label)
		end
	end
	local members = newLabel(
		summary,
		party and table.concat(memberNames, "\n") or "Invite friends to start a cooperative party.",
		UDim2.new(1, -18, 0, 52),
		UDim2.new(0, 9, 0, 36),
		12,
		COLORS.muted
	)
	members.TextWrapped = true
	members.TextYAlignment = Enum.TextYAlignment.Top

	if party then
		local leaveButton = newButton(
			content,
			party.isLeader and "DISBAND PARTY" or "LEAVE PARTY",
			UDim2.new(1, -8, 0, 36),
			UDim2.new(),
			function()
				invokeRemote(PartyAction, "LEAVE")
			end,
			COLORS.red
		)
		leaveButton.LayoutOrder = 3
	end

	local inviteHeading = newLabel(
		content,
		"PARTY INVITATIONS",
		UDim2.new(1, -8, 0, 25),
		UDim2.new(),
		13,
		COLORS.gold
	)
	inviteHeading.LayoutOrder = 4

	local inviteCount = 0
	for _, invitation in ipairs(partyInvites) do
		inviteCount += 1
		local card = newFrame(
			content,
			"PartyInvite_" .. tostring(invitation.leaderUserId),
			UDim2.new(1, -8, 0, 76),
			UDim2.new(),
			COLORS.panel
		)
		card.LayoutOrder = 4 + inviteCount
		stroke(card, COLORS.gold, 1)

		local inviteLabel = newLabel(
			card,
			tostring(invitation.leaderName or "Player") .. " invited you",
			UDim2.new(1, -16, 0, 24),
			UDim2.new(0, 8, 0, 6),
			12,
			COLORS.text
		)
		inviteLabel.Font = Enum.Font.GothamBold

		newButton(
			card,
			"ACCEPT",
			UDim2.new(0.46, -5, 0, 30),
			UDim2.new(0, 8, 1, -36),
			function()
				invokeRemote(PartyAction, "ACCEPT", invitation.leaderUserId)
			end,
			COLORS.green
		)
		newButton(
			card,
			"DECLINE",
			UDim2.new(0.46, -5, 0, 30),
			UDim2.new(0.54, 0, 1, -36),
			function()
				invokeRemote(PartyAction, "DECLINE", invitation.leaderUserId)
			end,
			COLORS.panelLight
		)
	end

	if inviteCount == 0 then
		local noInvites = newLabel(
			content,
			"No pending invitations.",
			UDim2.new(1, -8, 0, 30),
			UDim2.new(),
			12,
			COLORS.muted
		)
		noInvites.LayoutOrder = 5
	end

	local canInvite = not party or party.isLeader == true
	local partyFull = party and (tonumber(party.memberCount) or 1) >= (tonumber(party.maxMembers) or 4)
	local playerHeading = newLabel(
		content,
		canInvite and "INVITE A PLAYER" or "ONLY THE PARTY LEADER CAN INVITE",
		UDim2.new(1, -8, 0, 25),
		UDim2.new(),
		13,
		COLORS.accentLight
	)
	playerHeading.LayoutOrder = 6 + inviteCount

	local candidates = {}
	for _, candidate in ipairs(Players:GetPlayers()) do
		if candidate ~= player and candidate.Parent == Players then
			table.insert(candidates, candidate)
		end
	end
	table.sort(candidates, function(a, b)
		local an = a.DisplayName ~= "" and a.DisplayName or a.Name
		local bn = b.DisplayName ~= "" and b.DisplayName or b.Name
		return string.lower(an) < string.lower(bn)
	end)

	local candidateOrder = 7 + inviteCount
	local availableCandidates = 0
	for _, candidate in ipairs(candidates) do
		local alreadyMember = false
		if party and type(party.members) == "table" then
			for _, member in ipairs(party.members) do
				if member.userId == candidate.UserId then
					alreadyMember = true
					break
				end
			end
		end

		if not alreadyMember then
			availableCandidates += 1
			local candidateCard = newFrame(
				content,
				"InvitePlayer_" .. tostring(candidate.UserId),
				UDim2.new(1, -8, 0, 54),
				UDim2.new(),
				COLORS.panel
			)
			candidateCard.LayoutOrder = candidateOrder
			candidateOrder += 1

			local name = candidate.DisplayName ~= "" and candidate.DisplayName or candidate.Name
			local candidateLabel = newLabel(
				candidateCard,
				name,
				UDim2.new(1, -125, 1, 0),
				UDim2.new(0, 8, 0, 0),
				12,
				COLORS.text
			)
			candidateLabel.TextTruncate = Enum.TextTruncate.AtEnd

			local inviteButton = newButton(
				candidateCard,
				partyFull and "FULL" or (canInvite and "INVITE" or "LEADER ONLY"),
				UDim2.new(0, 112, 0, 32),
				UDim2.new(1, -120, 0.5, -16),
				function()
					if not canInvite then
						showToast("Only the party leader can invite players.", COLORS.gold)
						return
					end
					if partyFull then
						showToast("Your party is full.", COLORS.gold)
						return
					end
					invokeRemote(PartyAction, "INVITE", candidate.UserId)
				end,
				canInvite and not partyFull and COLORS.accent or COLORS.panelLight
			)
			inviteButton.Active = canInvite and not partyFull
			inviteButton.AutoButtonColor = canInvite and not partyFull
		end
	end

	if availableCandidates == 0 then
		local noPlayers = newLabel(
			content,
			"No other players are available in this server right now.",
			UDim2.new(1, -8, 0, 34),
			UDim2.new(),
			12,
			COLORS.muted
		)
		noPlayers.LayoutOrder = candidateOrder
	end
end

local function showQuests()
	openMenu("Quests", "QUESTS & PROGRESS")

	local intro = newLabel(
		content,
		"Complete objectives to earn rewards.",
		UDim2.new(1, -8, 0, 32),
		UDim2.new(),
		13,
		COLORS.muted
	)
	intro.LayoutOrder = 1

	-- The server currently exposes one active quest as flat fields,
	-- not as a quests dictionary. Read that contract directly.
	local questTitle = currentState.questTitle or "Loading quest..."
	local questDescription = currentState.questDescription or "No quest description available."
	local questProgress = tonumber(currentState.questProgress) or 0
	local questTarget = tonumber(currentState.questTarget) or 0
	local questReward = tonumber(currentState.questReward) or 0
	local questCompleted = currentState.questCompleted == true
	local allQuestsComplete = currentState.allQuestsComplete == true

	local card = newFrame(
		content,
		"ActiveQuest",
		UDim2.new(1, -8, 0, 112),
		UDim2.new(),
		COLORS.panel
	)
	card.LayoutOrder = 2
	stroke(card, questCompleted and COLORS.green or COLORS.border, 1.2)

	local titleLabel = newLabel(
		card,
		allQuestsComplete and "ALL QUESTS COMPLETE" or questTitle,
		UDim2.new(1, -20, 0, 24),
		UDim2.new(0, 10, 0, 7),
		13,
		COLORS.text
	)
	titleLabel.Font = Enum.Font.GothamBold

	newLabel(
		card,
		allQuestsComplete and "You have completed all current quests." or questDescription,
		UDim2.new(1, -20, 0, 26),
		UDim2.new(0, 10, 0, 32),
		11,
		COLORS.muted
	)

	newLabel(
		card,
		allQuestsComplete and "Rewards claimed" or (
			tostring(questProgress) .. " / " .. tostring(questTarget)
			.. "  •  Reward: " .. tostring(questReward) .. " Starshards"
		),
		UDim2.new(1, -20, 0, 22),
		UDim2.new(0, 10, 0, 61),
		11,
		questCompleted and COLORS.green or COLORS.gold
	)

	local claimButton = newButton(
		card,
		allQuestsComplete and "COMPLETED" or (questCompleted and "CLAIM REWARD" or "IN PROGRESS"),
		UDim2.new(0, 126, 0, 30),
		UDim2.new(1, -136, 1, -37),
		function()
			if allQuestsComplete then
				showToast("All starter quests are completed!", COLORS.green)
				return
			end
			if not questCompleted then
				showToast("Complete the objective before claiming.", COLORS.gold)
				return
			end

			local ok = invokeRemote(ClaimQuest, questTitle)
			if ok then
				showToast("Quest claim sent", COLORS.green)
				task.delay(0.3, function()
					requestState()
					if currentMenu == "Quests" then
						showQuests()
					end
				end)
			end
		end,
		questCompleted and COLORS.green or COLORS.panelLight
	)
	claimButton.Active = questCompleted and not allQuestsComplete
	claimButton.AutoButtonColor = questCompleted and not allQuestsComplete

	local equippedPetName = getEquippedPet()
	local equippedLevel = tonumber(currentState.petLevel) or 1
	local equippedEvolved = currentState.petEvolved == true
	local canEvolve = currentState.canEvolve == true
	local evolutionLabel
	if not equippedPetName then
		evolutionLabel = "CHOOSE A MYTHLING FIRST"
	elseif equippedEvolved then
		evolutionLabel = "MYTHLING ALREADY EVOLVED"
	elseif equippedLevel < 5 then
		evolutionLabel = "REACH LEVEL 5 TO EVOLVE"
	elseif (tonumber(currentState.totalCollected) or 0) < 25 then
		evolutionLabel = "COLLECT 25 CRYSTALS TO EVOLVE"
	elseif getCurrency() < (tonumber(currentState.evolutionCost) or 500) then
		evolutionLabel = "NEED 500 STARSHARDS TO EVOLVE"
	else
		evolutionLabel = "EVOLVE EQUIPPED MYTHLING"
	end

	local evolutionButton = newButton(
		content,
		evolutionLabel,
		UDim2.new(1, -8, 0, 42),
		UDim2.new(),
		function()
			if not canEvolve then
				showToast("Evolution requires level 5, 25 crystals and 500 Starshards.", COLORS.gold)
				return
			end
			local ok = invokeRemote(EvolvePet)
			if ok then
				task.delay(0.3, function()
					requestState()
					if currentMenu == "Quests" then
						showQuests()
					end
				end)
			end
		end,
		canEvolve and COLORS.accent or COLORS.panelLight
	)
	evolutionButton.LayoutOrder = 100
	evolutionButton.Active = canEvolve
	evolutionButton.AutoButtonColor = canEvolve

	local worldsUnlocked = tonumber(currentState.worldsUnlocked) or 1
	local worldUnlockCost = tonumber(currentState.worldUnlockCost) or 1000
	local canUnlockWorld = currentState.canUnlockWorld == true
	local unlockLabel
	if worldsUnlocked >= 2 then
		unlockLabel = "EMBERFALL UNLOCKED"
	elseif not getEquippedPet() then
		unlockLabel = "CHOOSE A MYTHLING FIRST"
	elseif (tonumber(currentState.petLevel) or 1) < 5 then
		unlockLabel = "REACH LEVEL 5 TO UNLOCK"
	elseif getCurrency() < worldUnlockCost then
		unlockLabel = "NEED " .. formatNumber(worldUnlockCost) .. " STARSHARDS"
	else
		unlockLabel = "UNLOCK EMBERFALL"
	end

	local unlockButton = newButton(
		content,
		unlockLabel,
		UDim2.new(1, -8, 0, 42),
		UDim2.new(),
		function()
			if worldsUnlocked >= 2 then
				showToast("Emberfall is already unlocked.", COLORS.green)
				return
			end
			if not canUnlockWorld then
				showToast("Reach level 5 and collect " .. formatNumber(worldUnlockCost) .. " Starshards.", COLORS.gold)
				return
			end
			local ok = invokeRemote(UnlockWorld)
			if ok then
				task.delay(0.25, function()
					requestState()
					if currentMenu == "Quests" then showQuests() end
				end)
			end
		end,
		worldsUnlocked >= 2 and COLORS.green or (canUnlockWorld and COLORS.accent or COLORS.panelLight)
	)
	unlockButton.LayoutOrder = 101
	unlockButton.Active = worldsUnlocked < 2 and canUnlockWorld
	unlockButton.AutoButtonColor = unlockButton.Active

	local upgradeCost = tonumber(currentState.upgradeCost) or 50
	local canUpgrade = equippedPetName ~= nil
		and equippedLevel < 50
		and getCurrency() >= upgradeCost
	local upgradeLabel
	if not equippedPetName then
		upgradeLabel = "CHOOSE A MYTHLING FIRST"
	elseif equippedLevel >= 50 then
		upgradeLabel = "MYTHLING LEVEL MAX"
	elseif getCurrency() < upgradeCost then
		upgradeLabel = "NEED " .. formatNumber(upgradeCost) .. " STARSHARDS"
	else
		upgradeLabel = "BUY UPGRADE · " .. formatNumber(upgradeCost) .. " STARSHARDS"
	end

	local upgradeButton = newButton(
		content,
		upgradeLabel,
		UDim2.new(1, -8, 0, 42),
		UDim2.new(),
		function()
			if not canUpgrade then
				showToast("Choose a Mythling and have enough Starshards for its next level.", COLORS.gold)
				return
			end
			local ok = invokeRemote(BuyUpgrade)
			if ok then
				task.delay(0.25, function()
					requestState()
					if currentMenu == "Quests" then showQuests() end
				end)
			end
		end,
		canUpgrade and COLORS.accent or COLORS.panelLight
	)
	upgradeButton.LayoutOrder = 102
	upgradeButton.Active = canUpgrade
	upgradeButton.AutoButtonColor = canUpgrade
end

--========================================================
-- STARTER SELECTION
--========================================================

local function showStarterSelection()
	openMenu("Starter", "Choose Your First Pet")

	local intro = newLabel(
		content,
		"Choose a starter Mythling. Pick the one you like most!",
		UDim2.new(1, -8, 0, 42),
		UDim2.new(),
		13,
		COLORS.muted
	)
	intro.LayoutOrder = 1

	for index, petName in ipairs(STARTERS) do
		local info = PET_INFO[petName]
		local card = newFrame(
			content,
			"Starter_" .. petName,
			UDim2.new(1, -8, 0, 100),
			UDim2.new(),
			COLORS.panel
		)
		card.LayoutOrder = index + 1
		stroke(card, info.color, 1.2)

		makePetBadge(card, petName, 70, UDim2.new(0, 10, 0, 15), 3)

		local definition = currentState.pets and currentState.pets[petName]
		local displayName = definition and definition.displayName or petName
		newLabel(
			card,
			displayName,
			UDim2.new(0.46, 0, 0, 28),
			UDim2.new(0, 88, 0, 12),
			15,
			COLORS.text
		)

		local elementDescription = definition
			and (tostring(definition.element or "Mythling") .. " · " .. tostring(definition.description or "Ready to explore."))
			or "Ready to explore."
		local description = newLabel(
			card,
			elementDescription,
			UDim2.new(0.48, 0, 0, 42),
			UDim2.new(0, 88, 0, 42),
			11,
			COLORS.muted
		)
		description.TextWrapped = true
		description.TextYAlignment = Enum.TextYAlignment.Top

		newButton(
			card,
			"Choose",
			UDim2.new(0, 105, 0, 34),
			UDim2.new(1, -115, 0.5, -17),
			function()
				local ok = invokeRemote(ChooseStarter, petName)
				if ok then
					showToast("Starter selection sent")
					task.delay(0.4, function()
						requestState()
						closeMenu()
						renderState()
					end)
				end
			end,
			COLORS.accent
		)
	end
end

--========================================================
-- SMALL HUD BUTTONS
--========================================================

local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.BackgroundTransparency = 1
hud.Size = UDim2.fromScale(1, 1)
hud.Parent = gui

local currencyPill = newFrame(
	hud,
	"Currency",
	UDim2.new(0, 170, 0, 42),
	UDim2.new(1, -182, 0, 12),
	COLORS.background
)
currencyPill.BackgroundTransparency = 0.08
stroke(currencyPill, COLORS.gold, 1)

local currencyLabel = newLabel(
	currencyPill,
	"STARSHARDS: " .. formatNumber(getCurrency()),
	UDim2.new(1, -12, 1, 0),
	UDim2.new(0, 8, 0, 0),
	14,
	COLORS.gold
)
currencyLabel.Font = Enum.Font.GothamBold
currencyLabel.TextXAlignment = Enum.TextXAlignment.Center

local eventBanner = newFrame(
	hud,
	"ActiveEventBanner",
	UDim2.new(0, 390, 0, 44),
	UDim2.new(0.5, -195, 0, 12),
	COLORS.background
)
eventBanner.BackgroundTransparency = 0.08
stroke(eventBanner, COLORS.accentLight, 1)

local eventBannerLabel = newLabel(
	eventBanner,
	"EVENT: LOADING...",
	UDim2.new(1, -12, 1, -6),
	UDim2.new(0, 6, 0, 3),
	11,
	COLORS.text
)
eventBannerLabel.Font = Enum.Font.GothamBold
eventBannerLabel.TextXAlignment = Enum.TextXAlignment.Center
eventBannerLabel.TextWrapped = true

local function positionEventBanner()
	local camera = workspace.CurrentCamera
	if not camera then return end

	if camera.ViewportSize.X < 600 then
		eventBanner.Size = UDim2.new(0, 270, 0, 38)
		eventBanner.Position = UDim2.new(0.5, -135, 0, 58)
		eventBannerLabel.TextSize = 10
	else
		eventBanner.Size = UDim2.new(0, 390, 0, 44)
		eventBanner.Position = UDim2.new(0.5, -195, 0, 12)
		eventBannerLabel.TextSize = 11
	end
end

positionEventBanner()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(positionEventBanner)
end

local function updateEventBanner()
	local eventInfo = currentState.activeEvent
	if type(eventInfo) ~= "table" then
		eventBannerLabel.Text = "EVENT: LOADING..."
		return
	end

	local secondsRemaining = math.max(0, (tonumber(eventInfo.endsAt) or os.time()) - os.time())
	local minutesRemaining = math.ceil(secondsRemaining / 60)
	local compactDescription = eventInfo.id == "CRYSTAL_RUSH"
		and "+50% crystal rewards"
		or "+50% creature rewards"
	eventBannerLabel.Text = string.upper(tostring(eventInfo.name or "WORLD EVENT"))
		.. " · " .. compactDescription
		.. " (" .. minutesRemaining .. "m)"
end
--========================================================
-- EQUIPPED MYTHLING STATUS PANEL
--========================================================

local equippedPetPanel = newFrame(
	hud,
	"EquippedPetPanel",
	UDim2.new(0, 220, 0, 122),
	UDim2.new(1, -232, 1, -134),
	COLORS.background
)
equippedPetPanel.BackgroundTransparency = 0.08
stroke(equippedPetPanel, COLORS.accent, 1.2)

local equippedPetNameLabel = newLabel(
	equippedPetPanel,
	"No Mythling equipped",
	UDim2.new(1, -16, 0, 28),
	UDim2.new(0, 8, 0, 5),
	14,
	COLORS.text
)
equippedPetNameLabel.Font = Enum.Font.GothamBold

local equippedPetLevelLabel = newLabel(
	equippedPetPanel,
	"Level: -- / 50",
	UDim2.new(1, -16, 0, 20),
	UDim2.new(0, 8, 0, 33),
	12,
	COLORS.gold
)

local equippedPetXPLabel = newLabel(
	equippedPetPanel,
	"XP: 0 / 100",
	UDim2.new(1, -16, 0, 18),
	UDim2.new(0, 8, 0, 53),
	11,
	COLORS.gold
)

local equippedPetEvolutionLabel = newLabel(
	equippedPetPanel,
	"Evolution: Not evolved",
	UDim2.new(1, -16, 0, 20),
	UDim2.new(0, 8, 0, 54),
	11,
	COLORS.muted
)

local evolveHudButton = newButton(
	equippedPetPanel,
	"EVOLVE - 500",
	UDim2.new(1, -16, 0, 28),
	UDim2.new(0, 8, 0, 86),
	function()
		if busy then
			return
		end

		if getEquippedPet() == nil then
			showToast("Equip a Mythling first!", COLORS.red)
			return
		end

		if getPetEvolved(getEquippedPet()) then
			showToast("This Mythling has already evolved!", COLORS.red)
			return
		end

		busy = true
		invokeRemote(EvolvePet)

		task.delay(1, function()
			busy = false
			requestState()
		end)
	end,
	COLORS.accent
)

evolveHudButton.TextSize = 11
evolveHudButton.Font = Enum.Font.GothamBold

local initialViewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
local compactNavigation = initialViewport ~= nil
	and (initialViewport.X < 600 or initialViewport.Y < 650)
local navButtonHeight = compactNavigation and 40 or 48
local navBarWidth = compactNavigation and 116 or 132
local navGap = compactNavigation and 4 or 7
local navBarHeight = compactNavigation and 338 or 410

local buttonBar = newFrame(
	hud,
	"ButtonBar",
	UDim2.new(0, navBarWidth, 0, navBarHeight),
	UDim2.new(0, 12, 0.5, -navBarHeight / 2),
	COLORS.background
)
buttonBar.BackgroundTransparency = 0.12
stroke(buttonBar, COLORS.border, 1)

local barLayout = Instance.new("UIListLayout")
barLayout.Padding = UDim.new(0, navGap)
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.SortOrder = Enum.SortOrder.LayoutOrder
barLayout.Parent = buttonBar

local barPadding = Instance.new("UIPadding")
barPadding.PaddingTop = UDim.new(0, 8)
barPadding.PaddingBottom = UDim.new(0, 8)
barPadding.PaddingLeft = UDim.new(0, 6)
barPadding.PaddingRight = UDim.new(0, 6)
barPadding.Parent = buttonBar

local function addHudButton(order, iconKind, label, callback, color)
	-- Horizontal navigation: icon on the left, label beside it.
	local button = newButton(
		buttonBar,
		"",
		UDim2.new(1, 0, 0, navButtonHeight),
		UDim2.new(),
		callback,
		color or COLORS.panelLight
	)
	button.LayoutOrder = order
	button.Text = ""
	button.AutoButtonColor = true

	local iconSize = compactNavigation and 28 or 34
	local iconX = 8
	local iconY = math.floor((navButtonHeight - iconSize) / 2)
	if iconKind == "Egg" then
		makeEggBadge(button, iconSize, UDim2.fromOffset(iconX, iconY), COLORS.gold)
	elseif iconKind == "Pet" then
		makePetBadge(button, "EmberFox", iconSize, UDim2.fromOffset(iconX, iconY), 3)
	else
		local icon = Instance.new("Frame")
		icon.Name = iconKind .. "Icon"
		local baseIconSize = compactNavigation and 24 or 28
		icon.Size = UDim2.fromOffset(baseIconSize, baseIconSize)
		icon.Position = UDim2.fromOffset(10, math.floor((navButtonHeight - baseIconSize) / 2))
		icon.BackgroundColor3 = iconKind == "Quest" and COLORS.gold or COLORS.accentLight
		icon.BorderSizePixel = 0
		icon.ZIndex = 3
		icon.Parent = button
		corner(icon, iconKind == "World" and 999 or 6)
		if iconKind == "Quest" then
			stroke(icon, Color3.fromRGB(255, 239, 178), 1)
			for i = 1, 2 do
				local line = Instance.new("Frame")
				line.Size = UDim2.new(0.52, 0, 0, 3)
				line.Position = UDim2.new(0.24, 0, i == 1 and 0.35 or 0.58, 0)
				line.BackgroundColor3 = COLORS.background
				line.BorderSizePixel = 0
				line.ZIndex = 4
				line.Parent = icon
			end
		else
			local land = Instance.new("Frame")
			land.Size = UDim2.new(0.55, 0, 0.36, 0)
			land.Position = UDim2.new(0.23, 0, 0.32, 0)
			land.BackgroundColor3 = Color3.fromRGB(115, 205, 139)
			land.BorderSizePixel = 0
			land.ZIndex = 4
			land.Parent = icon
			corner(land, 999)
		end
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "NavigationLabel"
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Position = UDim2.fromOffset(compactNavigation and 41 or 47, 0)
	textLabel.Size = UDim2.new(1, compactNavigation and -47 or -53, 1, 0)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = label
	textLabel.TextColor3 = COLORS.text
	textLabel.TextSize = 12
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.ZIndex = 5
	textLabel.Parent = button
	return button
end

addHudButton(1, "Pet", "PETS", showPets, COLORS.accent)
addHudButton(2, "Egg", "EGGS", showEggShop, COLORS.panelLight)
addHudButton(3, "Quest", "QUESTS", showQuests, COLORS.panelLight)
addHudButton(4, "Daily", "DAILY", showDailyReward, COLORS.panelLight)
addHudButton(5, "Fight", "ATTACK", function()
	if not getEquippedPet() then
		showToast("Choose a starter Mythling first.", COLORS.gold)
		return
	end
	invokeRemote(AttackEnemy)
end, COLORS.red)
addHudButton(6, "Shop", "SHOP", showPremiumShop, COLORS.panelLight)
addHudButton(7, "Party", "PARTY", showParty, COLORS.panelLight)

--========================================================
-- STATE RENDERING
--========================================================

function renderState()
	currencyLabel.Text = "STARSHARDS: " .. formatNumber(getCurrency())
	updateEventBanner()

	local equipped = getEquippedPet()
	if type(equipped) ~= "string" then
		equipped = "None"
	end

	-- Update equipped Mythling panel
	if equipped == "None" then
		evolveHudButton.Text = "EQUIP A MYTHLING"
		evolveHudButton.Active = false
		evolveHudButton.AutoButtonColor = false
		equippedPetNameLabel.Text = "No Mythling equipped"
		equippedPetLevelLabel.Text = "Level: -- / 50"
		equippedPetXPLabel.Text = "XP: --"
		equippedPetEvolutionLabel.Text = "Evolution: Not available"
	else
		local petLevel = getPetLevel(equipped)
		local petEvolved = getPetEvolved(equipped)

		equippedPetNameLabel.Text = equipped
		equippedPetLevelLabel.Text = "Level: "
			.. tostring(petLevel or 1) .. " / 50"

		local petXP = getPetXP(equipped)
		local xpNeeded = (petLevel or 1) * 100

		equippedPetXPLabel.Text = "XP: "
			.. tostring(petXP)
			.. " / "
			.. tostring(xpNeeded)

		if petEvolved then
			evolveHudButton.Text = "EVOLVED"
			evolveHudButton.BackgroundColor3 = COLORS.panelLight
			evolveHudButton.Active = false
			evolveHudButton.AutoButtonColor = false
			equippedPetEvolutionLabel.Text = "Evolution: Evolved"
			equippedPetEvolutionLabel.TextColor3 = COLORS.accent
		else
			evolveHudButton.Text = "EVOLVE - 500"
			evolveHudButton.BackgroundColor3 = COLORS.accent
			evolveHudButton.Active = true
			evolveHudButton.AutoButtonColor = true
			equippedPetEvolutionLabel.Text = "Evolution: Not evolved"
			equippedPetEvolutionLabel.TextColor3 = COLORS.muted
		end
	end

	local starterChosen = currentState.starterChosen
		or currentState.hasStarter
		or currentState.starterPet ~= nil
		or getEquippedPet() ~= nil

	if not starterChosen then
		task.defer(function()
			if not currentMenu then
				showStarterSelection()
			end
		end)
	end

	if currentMenu == "Pets" then
		showPets()
	elseif currentMenu == "EggShop" then
		showEggShop()
	elseif currentMenu == "DailyReward" then
		showDailyReward()
	elseif currentMenu == "PremiumShop" then
		showPremiumShop()
	elseif currentMenu == "Party" then
		showParty()
	elseif currentMenu == "Quests" then
		showQuests()
	elseif currentMenu == "PetDetails" and currentPet then
		local inventory = getInventory()
		showPetDetails(currentPet, inventory[currentPet] or 1)
	end
end

--========================================================
-- SERVER NOTIFICATIONS
--========================================================

if PartyUpdate:IsA("RemoteEvent") then
	PartyUpdate.OnClientEvent:Connect(function(kind, payload, invites)
		if kind == "SYNC" then
			partyState = type(payload) == "table" and payload or nil
			partyInvites = type(invites) == "table" and invites or {}
			if currentMenu == "Party" then
				showParty()
			end
		elseif kind == "INVITE" then
			local leaderName = tostring(invites or "A player")
			showToast(leaderName .. " invited you to a party.", COLORS.accentLight)
			if currentMenu == "Party" then
				showParty()
			end
		end
	end)
end

if StateChanged:IsA("RemoteEvent") then
	StateChanged.OnClientEvent:Connect(function(newState)
		if type(newState) == "table" then
			currentState = newState
		else
			requestState()
		end
		renderState()
	end)
end

if WheelResult:IsA("RemoteEvent") then
	WheelResult.OnClientEvent:Connect(function(rewardIndex, rewardAmount)
		local index = math.clamp(math.floor(tonumber(rewardIndex) or 1), 1, 5)
		local amount = math.max(0, math.floor(tonumber(rewardAmount) or 0))
		local thisVisual = wheelVisual

		wheelSpinAttempt += 1
		wheelBusy = false
		if wheelButton and wheelButton.Parent then
			wheelButton.Text = "COME BACK TOMORROW"
			wheelButton.Active = false
			wheelButton.AutoButtonColor = false
		end

		if thisVisual and thisVisual.Parent then
			local targetRotation = thisVisual.Rotation + 1440 + (((6 - index) % 5) * 72)
			local tween = TweenService:Create(
				thisVisual,
				TweenInfo.new(3.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Rotation = targetRotation }
			)
			tween:Play()
			tween.Completed:Wait()
		end

		showToast("Daily Wheel: +" .. formatNumber(amount) .. " Starshards!", COLORS.gold)
		requestState()
		if currentMenu == "DailyReward" then
			showDailyReward()
		end
	end)
end

if Notify:IsA("RemoteEvent") then
	Notify.OnClientEvent:Connect(function(message, ...)
		if type(message) ~= "string" then
			showToast("Game update received")
			return
		end

		local extra = { ... }
		local petName = nil
		local rarity = nil

		-- Egg results arrive with the exact pet key and rarity from the server.
		-- Do not show the normal toast here, because that would spoil the reveal.
		if type(extra[1]) == "string" and PET_INFO[extra[1]] then
			petName = extra[1]
			if type(extra[2]) == "string" then
				rarity = extra[2]
			end
		end

		-- Backward-compatible parsing if an older server script is still running.
		if not petName then
			local displayName = string.match(message, "You hatched (.+) %[%w+%]")
			if displayName then
				for key, info in pairs(PET_INFO) do
					local knownNames = {
						EmberFox = "Ember Fox",
						Mossbun = "Mossbun",
						Tidefin = "Tidefin",
						Cinderling = "Cinderling",
						Pebblit = "Pebblit",
						Bloomlet = "Bloomlet",
						Sunpup = "Sunpup",
						Duskmoth = "Duskmoth",
						Voltkit = "Voltkit",
						Stormling = "Stormling",
						Glacub = "Glacub",
						Starwhisp = "Starwhisp",
					}
					if knownNames[key] == displayName then
						petName = key
						rarity = info.rarity
						break
					end
				end
			end
		end

		if petName then
			showEggResult(petName, rarity or getPetRarity(petName))
			task.delay(3.8, function()
				requestState()
				renderState()
			end)
		else
			showToast(message)
		end
	end)
end

--========================================================
-- INITIAL LOAD
--========================================================

local ok = requestState()
if ok then
	renderState()
else
	warn("[MythlingRealms] Initial state could not be loaded.")
	showToast("Couldn't load your data. Please rejoin.", COLORS.red)
end

-- Refresh rotating global event metadata without rebuilding whichever menu
-- the player is currently using.
task.spawn(function()
	while gui.Parent and player.Parent do
		task.wait(60)
		if gui.Parent and player.Parent then
			local wasDailyAvailable = currentState.dailyRewardAvailable
			local wasWheelAvailable = currentState.dailyWheelAvailable
			if requestState() then
				updateEventBanner()
				if currentMenu == "DailyReward"
					and (
						wasDailyAvailable ~= currentState.dailyRewardAvailable
						or wasWheelAvailable ~= currentState.dailyWheelAvailable
					) then
					showDailyReward()
				end
			end
		end
	end
end)

print("[MythlingRealms] Compact client UI initialized.")
