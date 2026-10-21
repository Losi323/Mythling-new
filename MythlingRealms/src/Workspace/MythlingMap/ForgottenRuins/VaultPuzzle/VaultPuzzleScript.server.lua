-- MYTHLING REALMS - FORGOTTEN RUINS VAULT PUZZLE
-- Self-contained puzzle props are created if they are missing from the Rojo tree.
-- The main server script owns the player's saved currency and one-time vault claim.

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local puzzle = script.Parent
assert(puzzle:IsA("Model"), "VaultPuzzleScript must be parented to a Model")

local function ensurePart(name, size, position, color, material)
	local existing = puzzle:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		-- Normalize both fresh Rojo instances and older in-Studio puzzle parts
		-- to the same predictable layout, so no legacy piece is left elsewhere.
		existing.Size = size
		existing.CFrame = CFrame.new(position)
		existing.Anchored = true
		existing.Color = color
		existing.Material = material or Enum.Material.Slate
		return existing
	end
	if existing then
		existing:Destroy()
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material or Enum.Material.Slate
	part.Parent = puzzle
	return part
end

local function ensurePrompt(part, name, actionText, objectText, distance)
	local prompt = part:FindFirstChild(name)
	if prompt and prompt:IsA("ProximityPrompt") then
		return prompt
	end
	if prompt then
		prompt:Destroy()
	end

	prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = distance or 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function notifyPlayer(player, message)
	local remotes = ReplicatedStorage:FindFirstChild("MythlingRemotes")
	local notify = remotes and remotes:FindFirstChild("Notify")
	if notify and notify:IsA("RemoteEvent") and player.Parent == Players then
		notify:FireClient(player, message)
	end
end

local function isCloseEnough(player, part, maxDistance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil
		and (root.Position - part.Position).Magnitude <= (maxDistance or 12)
end

-- Map scenery: an accessible bridge from Emberfall to a separate ruins island.
ensurePart(
	"ForgottenRuinsIsland",
	Vector3.new(160, 8, 160),
	Vector3.new(560, -5, 0),
	Color3.fromRGB(79, 91, 86),
	Enum.Material.Rock
).CanCollide = true

ensurePart(
	"BridgeToForgottenRuins",
	Vector3.new(120, 1, 14),
	Vector3.new(430, -0.25, 0),
	Color3.fromRGB(117, 111, 102),
	Enum.Material.Slate
).CanCollide = true

local approach = ensurePart(
	"RuinsApproach",
	Vector3.new(24, 1, 52),
	Vector3.new(530, -0.2, 0),
	Color3.fromRGB(118, 119, 104),
	Enum.Material.Cobblestone
)
approach.CanCollide = true

local signPost = ensurePart(
	"ForgottenRuinsSignPost",
	Vector3.new(1.2, 7, 1.2),
	Vector3.new(511, 2.5, 30),
	Color3.fromRGB(108, 74, 48),
	Enum.Material.Wood
)
signPost.CanCollide = true
local signBoard = ensurePart(
	"ForgottenRuinsSignBoard",
	Vector3.new(20, 6, 1),
	Vector3.new(511, 7, 30),
	Color3.fromRGB(42, 52, 73),
	Enum.Material.Slate
)
signBoard.CanCollide = false
local signGui = signBoard:FindFirstChild("RuinsSignGui")
if not signGui then
	signGui = Instance.new("BillboardGui")
	signGui.Name = "RuinsSignGui"
	signGui.Size = UDim2.fromOffset(280, 86)
	signGui.StudsOffset = Vector3.new(0, 0, 0)
	signGui.AlwaysOnTop = true
	signGui.Parent = signBoard

	local signText = Instance.new("TextLabel")
	signText.Name = "Text"
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
	signText.BackgroundTransparency = 0.08
	signText.BorderSizePixel = 0
	signText.Font = Enum.Font.GothamBold
	signText.Text = "FORGOTTEN RUINS\nActivate all 3 runes to open the vault"
	signText.TextColor3 = Color3.fromRGB(255, 221, 133)
	signText.TextScaled = true
	signText.TextWrapped = true
	signText.Parent = signGui

	local signCorner = Instance.new("UICorner")
	signCorner.CornerRadius = UDim.new(0, 10)
	signCorner.Parent = signText
end

-- Lanterns mark the long bridge from Emberfall to Forgotten Ruins without
-- putting collision parts in the walking lane.
for index, x in ipairs({390, 420, 450, 480}) do
	for _, side in ipairs({-1, 1}) do
		local lanternPost = ensurePart(
			"RuinsBridgeLanternPost_" .. index .. "_" .. side,
			Vector3.new(0.9, 3.6, 0.9),
			Vector3.new(x, 1.8, side * 6),
			Color3.fromRGB(81, 75, 72),
			Enum.Material.Metal
		)
		lanternPost.CanCollide = false

		local lantern = ensurePart(
			"RuinsBridgeLantern_" .. index .. "_" .. side,
			Vector3.new(1.25, 1.25, 1.25),
			Vector3.new(x, 3.9, side * 6),
			Color3.fromRGB(255, 199, 94),
			Enum.Material.Neon
		)
		lantern.Shape = Enum.PartType.Ball
		lantern.CanCollide = false

		-- Neon lanterns remain visible on every post, but only a few carry
		-- dynamic lights to avoid an unnecessarily high mobile lighting cost.
		if index % 2 == 1 and side == 1 then
			local glow = lantern:FindFirstChild("BridgeGlow")
			if not glow then
				glow = Instance.new("PointLight")
				glow.Name = "BridgeGlow"
				glow.Range = 9
				glow.Brightness = 0.6
				glow.Color = lantern.Color
				glow.Parent = lantern
			end
		end
	end
end

local trailSignPost = ensurePart(
	"ForgottenRuinsTrailSignPost",
	Vector3.new(1.2, 7, 1.2),
	Vector3.new(360, 2.5, 16),
	Color3.fromRGB(108, 74, 48),
	Enum.Material.Wood
)
trailSignPost.CanCollide = true
local trailSignBoard = ensurePart(
	"ForgottenRuinsTrailSignBoard",
	Vector3.new(18, 5, 1),
	Vector3.new(360, 7, 16),
	Color3.fromRGB(42, 52, 73),
	Enum.Material.Slate
)
trailSignBoard.CanCollide = false
local trailGui = trailSignBoard:FindFirstChild("TrailSignGui")
if not trailGui then
	trailGui = Instance.new("BillboardGui")
	trailGui.Name = "TrailSignGui"
	trailGui.Size = UDim2.fromOffset(260, 76)
	trailGui.AlwaysOnTop = true
	trailGui.Parent = trailSignBoard

	local trailText = Instance.new("TextLabel")
	trailText.Size = UDim2.fromScale(1, 1)
	trailText.BackgroundColor3 = Color3.fromRGB(28, 35, 52)
	trailText.BackgroundTransparency = 0.08
	trailText.BorderSizePixel = 0
	trailText.Font = Enum.Font.GothamBold
	trailText.Text = "FORGOTTEN RUINS →\nThree runes • One vault reward"
	trailText.TextColor3 = Color3.fromRGB(255, 221, 133)
	trailText.TextScaled = true
	trailText.TextWrapped = true
	trailText.Parent = trailGui

	local trailCorner = Instance.new("UICorner")
	trailCorner.CornerRadius = UDim.new(0, 10)
	trailCorner.Parent = trailText
end

local door = ensurePart(
	"VaultDoor",
	Vector3.new(14, 14, 2),
	Vector3.new(560, 6, -24),
	Color3.fromRGB(66, 86, 105),
	Enum.Material.Metal
)
door.CanCollide = true

local doorTrim = ensurePart(
	"VaultDoorTrim",
	Vector3.new(17, 17, 1),
	Vector3.new(560, 6, -25.6),
	Color3.fromRGB(212, 178, 91),
	Enum.Material.Metal
)
doorTrim.CanCollide = false
doorTrim.Transparency = 0.18

local runePositions = {
	Vector3.new(536, 1.1, 8),
	Vector3.new(560, 1.1, 8),
	Vector3.new(584, 1.1, 8),
}
local runes = {}
for index, position in ipairs(runePositions) do
	local pedestal = ensurePart(
		"RunePedestal" .. index,
		Vector3.new(7, 2, 7),
		Vector3.new(position.X, 0, position.Z),
		Color3.fromRGB(74, 81, 96),
		Enum.Material.Slate
	)
	pedestal.CanCollide = true

	local rune = ensurePart(
		"Rune" .. string.char(64 + index),
		Vector3.new(4, 0.8, 4),
		position,
		({Color3.fromRGB(100, 180, 255), Color3.fromRGB(186, 122, 255), Color3.fromRGB(255, 174, 82)})[index],
		Enum.Material.Neon
	)
	rune.CanCollide = true
	runes[index] = rune

	local runeLight = rune:FindFirstChild("RuneLight")
	if not runeLight then
		runeLight = Instance.new("PointLight")
		runeLight.Name = "RuneLight"
		runeLight.Range = 10
		runeLight.Brightness = 0.8
		runeLight.Parent = rune
	end
end

local chestBase = ensurePart(
	"ChestBase",
	Vector3.new(7, 2.4, 5),
	Vector3.new(560, 0.2, -38),
	Color3.fromRGB(107, 65, 37),
	Enum.Material.WoodPlanks
)
chestBase.CanCollide = true

local lid = ensurePart(
	"ChestLid",
	Vector3.new(7, 1.4, 5),
	Vector3.new(560, 2.1, -38),
	Color3.fromRGB(163, 112, 54),
	Enum.Material.WoodPlanks
)
lid.CanCollide = true

local chestTrim = ensurePart(
	"ChestLock",
	Vector3.new(0.8, 1.2, 0.25),
	Vector3.new(560, 2.0, -40.55),
	Color3.fromRGB(255, 210, 93),
	Enum.Material.Neon
)
chestTrim.CanCollide = false

local runesDone = {}
local solvedByUserId = {}
local claimedByUserId = {}
local doorOpened = false
local lidOpened = false

local doorClosedPosition = door.Position
local doorOpenPosition = doorClosedPosition - Vector3.new(0, door.Size.Y + 1, 0)
local trimClosedPosition = doorTrim.Position
local chestPrompt = ensurePrompt(chestBase, "ProximityPrompt", "Open", "Forgotten Vault", 12)
chestPrompt.Enabled = false

local vaultRewardRequest = ServerScriptService:WaitForChild("MythlingVaultReward")
assert(vaultRewardRequest:IsA("BindableFunction"), "MythlingVaultReward must be a BindableFunction")
local vaultAccessRequest = ServerScriptService:WaitForChild("MythlingVaultCanAccess")
assert(vaultAccessRequest:IsA("BindableFunction"), "MythlingVaultCanAccess must be a BindableFunction")

local function checkVaultAccess(player)
	local callOk, allowed, reason = pcall(function()
		return vaultAccessRequest:Invoke(player)
	end)
	if not callOk then
		warn("[MythlingRealms] Vault access check failed: " .. tostring(allowed))
		return false, "The vault could not check your access. Try again."
	end
	return allowed == true, reason
end

local function setDoorOpen()
	if doorOpened then return end
	doorOpened = true
	puzzle:SetAttribute("VaultOpen", true)
	TweenService:Create(
		door,
		TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{Position = doorOpenPosition}
	):Play()
	TweenService:Create(
		doorTrim,
		TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{Position = trimClosedPosition + (doorOpenPosition - doorClosedPosition)}
	):Play()
	chestPrompt.Enabled = true
end

for _, rune in ipairs(runes) do
	local prompt = ensurePrompt(rune, "ProximityPrompt", "Activate Rune", "Ancient Rune", 12)

	prompt.Triggered:Connect(function(player)
		if not isCloseEnough(player, rune, 14) then return end
		local allowed, reason = checkVaultAccess(player)
		if not allowed then
			notifyPlayer(player, tostring(reason or "Unlock Emberfall before entering Forgotten Ruins."))
			return
		end

		local userId = player.UserId
		if solvedByUserId[userId] then
			notifyPlayer(player, "You have already solved the rune sequence.")
			return
		end

		local playerRunes = runesDone[userId]
		if not playerRunes then
			playerRunes = {}
			runesDone[userId] = playerRunes
		end
		if playerRunes[rune.Name] then
			notifyPlayer(player, "You already activated this rune.")
			return
		end

		playerRunes[rune.Name] = true
		rune.Color = Color3.fromRGB(120, 255, 210)
		rune.Material = Enum.Material.Neon

		local count = 0
		for _, currentRune in ipairs(runes) do
			if playerRunes[currentRune.Name] then
				count += 1
			end
		end

		if count >= #runes then
			solvedByUserId[userId] = true
			setDoorOpen()
			notifyPlayer(player, "The three runes resonate! The vault is open.")
		else
			notifyPlayer(player, "Rune activated: " .. count .. "/" .. #runes)
		end
	end)
end

chestPrompt.Triggered:Connect(function(player)
	if not isCloseEnough(player, chestBase, 14) then return end
	local allowed, reason = checkVaultAccess(player)
	if not allowed then
		notifyPlayer(player, tostring(reason or "Unlock Emberfall before entering Forgotten Ruins."))
		return
	end
	if not solvedByUserId[player.UserId] then
		notifyPlayer(player, "Activate all three runes yourself before opening the vault.")
		return
	end
	if claimedByUserId[player.UserId] then
		notifyPlayer(player, "You have already claimed this vault reward.")
		return
	end

	local callOk, success, result = pcall(function()
		return vaultRewardRequest:Invoke(player)
	end)
	if not callOk then
		warn("[MythlingRealms] Vault reward request failed: " .. tostring(success))
		notifyPlayer(player, "The vault could not grant its reward right now. Try again.")
		return
	end
	if not success then
		local message = tostring(result or "The vault could not grant its reward.")
		notifyPlayer(player, message)
		if message == "This vault reward has already been claimed." then
			claimedByUserId[player.UserId] = true
		end
		return
	end

	claimedByUserId[player.UserId] = true
	puzzle:SetAttribute("LastRewardedUserId", player.UserId)

	if not lidOpened then
		lidOpened = true
		local hinge = lid.CFrame * CFrame.new(0, -0.25, -2.35)
		local goal = hinge * CFrame.Angles(math.rad(-68), 0, 0) * hinge:Inverse() * lid.CFrame
		TweenService:Create(
			lid,
			TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = goal}
		):Play()
		TweenService:Create(
			chestTrim,
			TweenInfo.new(0.65),
			{CFrame = chestTrim.CFrame * CFrame.new(0, 0.15, 0)}
		):Play()
	end
end)

puzzle:SetAttribute("PuzzleVersion", 2)
print("[MythlingRealms] Forgotten Ruins vault puzzle initialized.")
