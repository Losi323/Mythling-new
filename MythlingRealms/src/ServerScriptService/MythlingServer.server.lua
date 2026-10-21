-- MYTHLING REALMS
-- ServerScriptService > MythlingServer
-- Progression + Quests + Evolution + Emberfall
-- Egg System + Pet Collection + Equip Pet
-- Individual Pet Levels + Individual Pet Evolution

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DATASTORE_NAME = "MythlingRealms_PlayerData_v1"
local AUTOSAVE_SECONDS = 60
local CRYSTAL_RESPAWN_SECONDS = 5
local EGG_COST = 250
local WORLD_UNLOCK_COST = 1000
local EVOLUTION_COST = 500
local MAX_PET_LEVEL = 50

local store = DataStoreService:GetDataStore(DATASTORE_NAME)

--==================================================
-- REMOTES
--==================================================

local remotes = ReplicatedStorage:FindFirstChild("MythlingRemotes")

if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "MythlingRemotes"
	remotes.Parent = ReplicatedStorage
end

local function getOrCreate(className, name)
	local obj = remotes:FindFirstChild(name)

	if obj then
		assert(
			obj.ClassName == className,
			name .. " has an incorrect class"
		)
		return obj
	end

	obj = Instance.new(className)
	obj.Name = name
	obj.Parent = remotes

	return obj
end

local GetState = getOrCreate("RemoteFunction", "GetState")
local ChooseStarter = getOrCreate("RemoteEvent", "ChooseStarter")
local BuyUpgrade = getOrCreate("RemoteEvent", "BuyUpgrade")
local ClaimQuest = getOrCreate("RemoteEvent", "ClaimQuest")
local EvolvePet = getOrCreate("RemoteEvent", "EvolvePet")
local UnlockWorld = getOrCreate("RemoteEvent", "UnlockWorld")
local StateChanged = getOrCreate("RemoteEvent", "StateChanged")
local Notify = getOrCreate("RemoteEvent", "Notify")
local OpenEgg = getOrCreate("RemoteEvent", "OpenEgg")
local EquipPet = getOrCreate("RemoteEvent", "EquipPet")
local ClaimDailyReward = getOrCreate("RemoteEvent", "ClaimDailyReward")
local AttackEnemy = getOrCreate("RemoteEvent", "AttackEnemy")

--==================================================
-- MYTHLINGS
--==================================================

local PETS = {
	EmberFox = {
		displayName = "Ember Fox",
		element = "Ember",
		rarity = "Starter",
		color = Color3.fromRGB(255, 111, 72),
		description = "A brave little fire companion.",
	},

	Mossbun = {
		displayName = "Mossbun",
		element = "Moss",
		rarity = "Starter",
		color = Color3.fromRGB(108, 220, 130),
		description = "A gentle guardian of the forest.",
	},

	Tidefin = {
		displayName = "Tidefin",
		element = "Tide",
		rarity = "Starter",
		color = Color3.fromRGB(76, 190, 255),
		description = "A cheerful companion of the sea.",
	},

	Cinderling = {
		displayName = "Cinderling",
		element = "Ember",
		rarity = "Common",
		color = Color3.fromRGB(255, 145, 75),
		description = "A tiny creature born from warm embers.",
	},

	Pebblit = {
		displayName = "Pebblit",
		element = "Earth",
		rarity = "Common",
		color = Color3.fromRGB(166, 145, 120),
		description = "A sturdy little stone companion.",
	},

	Bloomlet = {
		displayName = "Bloomlet",
		element = "Nature",
		rarity = "Common",
		color = Color3.fromRGB(255, 135, 190),
		description = "A cheerful flower spirit.",
	},

	Sunpup = {
		displayName = "Sunpup",
		element = "Solar",
		rarity = "Uncommon",
		color = Color3.fromRGB(255, 184, 77),
		description = "A cheerful pup that carries a spark of sunlight.",
	},

	Duskmoth = {
		displayName = "Duskmoth",
		element = "Dusk",
		rarity = "Uncommon",
		color = Color3.fromRGB(176, 132, 230),
		description = "A quiet moth drawn to the colors of twilight.",
	},

	Voltkit = {
		displayName = "Voltkit",
		element = "Lightning",
		rarity = "Rare",
		color = Color3.fromRGB(255, 230, 75),
		description = "A quick companion charged with lightning.",
	},

	Stormling = {
		displayName = "Stormling",
		element = "Storm",
		rarity = "Rare",
		color = Color3.fromRGB(83, 177, 235),
		description = "A lively spirit that gathers power from storm clouds.",
	},

	Glacub = {
		displayName = "Glacub",
		element = "Ice",
		rarity = "Epic",
		color = Color3.fromRGB(120, 220, 255),
		description = "A rare cub with the power of ice.",
	},

	Starwhisp = {
		displayName = "Starwhisp",
		element = "Astral",
		rarity = "Legendary",
		color = Color3.fromRGB(220, 160, 255),
		description = "A legendary spirit born from starlight.",
	},
}

local STARTER_PETS = {
	EmberFox = true,
	Mossbun = true,
	Tidefin = true,
}

-- Each entry's weight is its percentage of the 100-point pool.
local EGG_POOL = {
	{ pet = "Cinderling", rarity = "Common", weight = 15 },
	{ pet = "Pebblit", rarity = "Common", weight = 15 },
	{ pet = "Bloomlet", rarity = "Common", weight = 15 },
	{ pet = "Sunpup", rarity = "Uncommon", weight = 12.5 },
	{ pet = "Duskmoth", rarity = "Uncommon", weight = 12.5 },
	{ pet = "Voltkit", rarity = "Rare", weight = 12 },
	{ pet = "Stormling", rarity = "Rare", weight = 6 },
	{ pet = "Glacub", rarity = "Epic", weight = 9 },
	{ pet = "Starwhisp", rarity = "Legendary", weight = 3 },
}

-- Probabilities for the Basic Egg. The weights above total 100.
local EGG_ODDS = {
	Common = 45,
	Uncommon = 25,
	Rare = 18,
	Epic = 9,
	Legendary = 3,
}

-- Fail loudly during development if the egg table and the displayed odds drift
-- apart. This prevents a silent mismatch between rarity labels and roll weights.
do
	local totalWeight = 0
	local rarityWeights = {}

	for _, entry in ipairs(EGG_POOL) do
		assert(PETS[entry.pet], "Unknown Mythling in EGG_POOL: " .. tostring(entry.pet))
		assert(type(entry.weight) == "number" and entry.weight >= 0,
			"Invalid egg weight for " .. tostring(entry.pet))

		totalWeight += entry.weight
		rarityWeights[entry.rarity] = (rarityWeights[entry.rarity] or 0) + entry.weight
	end

	assert(math.abs(totalWeight - 100) < 0.0001,
		"EGG_POOL weights must total 100; got " .. tostring(totalWeight))

	for rarity, expected in pairs(EGG_ODDS) do
		local actual = rarityWeights[rarity] or 0
		assert(math.abs(actual - expected) < 0.0001,
			"EGG_ODDS mismatch for " .. rarity .. ": expected "
				.. tostring(expected) .. ", got " .. tostring(actual))
	end
end

--==================================================
-- QUESTS
--==================================================

local QUESTS = {
	{
		title = "Crystal Collector",
		description = "Collect 10 crystals",
		target = 10,
		reward = 100,
		stat = "totalCollected",
	},
	{
		title = "Growing Together",
		description = "Reach Mythling level 3",
		target = 3,
		reward = 200,
		stat = "petLevel",
	},
	{
		title = "Forest Explorer",
		description = "Collect 30 crystals in total",
		target = 30,
		reward = 300,
		stat = "totalCollected",
	},
	{
		title = "Ready to Evolve",
		description = "Reach Mythling level 5",
		target = 5,
		reward = 400,
		stat = "petLevel",
	},
	{
		title = "New Horizons",
		description = "Unlock the Emberfall world",
		target = 2,
		reward = 250,
		stat = "worldsUnlocked",
	},
	{
		title = "Emberfall Expedition",
		description = "Collect 20 crystals in Emberfall",
		target = 20,
		reward = 500,
		stat = "emberfallCollected",
	},
	{
		title = "Guardian Hunter",
		description = "Defeat 10 creatures",
		target = 10,
		reward = 400,
		stat = "enemiesDefeated",
	},
	{
		title = "Mythling Collector",
		description = "Open 5 eggs",
		target = 5,
		reward = 500,
		stat = "totalEggsOpened",
	},
	{
		title = "Legend in the Making",
		description = "Reach Mythling level 10",
		target = 10,
		reward = 800,
		stat = "petLevel",
	},
}

--==================================================
-- PLAYER DATA
--==================================================

local playerData = {}
local loadingPlayers = {}
local petVisuals = {}
local lastRequest = {}
local savingPlayers = {}

local function defaultData()
	return {
		schemaVersion = 4,
		starshards = 0,
		pet = nil,

		-- Compatibility fields: always mirror the equipped pet.
		petLevel = 1,
		petEvolved = false,

		-- New: each pet has its own progression.
		petLevels = {},
		petXP = {},
		evolvedPets = {},

		totalCollected = 0,
		emberfallCollected = 0,
		enemiesDefeated = 0,
		totalEggsOpened = 0,
		worldsUnlocked = 1,
		questStage = 1,
		lastDailyClaimDay = 0,
		dailyStreak = 0,
		ownedPets = {},
	}
end

local function cloneData(data)
	data = type(data) == "table" and data or {}

	local ownedPets = {}
	local petLevels = {}
	local evolvedPets = {}
	local petXP = {}

	if type(data.ownedPets) == "table" then
		for petName, count in pairs(data.ownedPets) do
			if PETS[petName] and type(count) == "number" then
				ownedPets[petName] = math.clamp(
					math.floor(count),
					0,
					999
				)
			end
		end
	end

	if type(data.petLevels) == "table" then
		for petName, level in pairs(data.petLevels) do
			if PETS[petName] and type(level) == "number" then
				petLevels[petName] = math.clamp(
					math.floor(level),
					1,
					MAX_PET_LEVEL
				)
			end
		end
	end

	if type(data.petXP) == "table" then
		for petName, xp in pairs(data.petXP) do
			if PETS[petName] and type(xp) == "number" then
				petXP[petName] = math.clamp(
					math.floor(xp),
					0,
					100000000
				)
			end
		end
	end

	if type(data.evolvedPets) == "table" then
		for petName, evolved in pairs(data.evolvedPets) do
			if PETS[petName] then
				evolvedPets[petName] = evolved == true
			end
		end
	end

	local currentPet = PETS[data.pet] and data.pet or nil

	-- Preserve ownership of the currently equipped pet.
	if currentPet then
		ownedPets[currentPet] = math.max(
			ownedPets[currentPet] or 0,
			1
		)

		-- Migrate the old global level only if this pet has no
		-- individual level saved yet. Never overwrite newer data.
		if petLevels[currentPet] == nil then
			petLevels[currentPet] = math.clamp(
				math.floor(tonumber(data.petLevel) or 1),
				1,
				MAX_PET_LEVEL
			)
		end

		if evolvedPets[currentPet] == nil then
			evolvedPets[currentPet] = data.petEvolved == true
		end
	end

	-- Ensure every owned pet has its own progression.
	for petName, count in pairs(ownedPets) do
		if count > 0 then
			if petLevels[petName] == nil then
				petLevels[petName] = 1
			end
			if petXP[petName] == nil then
				petXP[petName] = 0
			end

			if evolvedPets[petName] == nil then
				evolvedPets[petName] = false
			end
		end
	end

	local currentLevel = currentPet and petLevels[currentPet] or 1
	local currentEvolved = currentPet
		and evolvedPets[currentPet] == true
		or false

	return {
		schemaVersion = 4,

		starshards = math.max(
			0,
			math.floor(tonumber(data.starshards) or 0)
		),

		pet = currentPet,
		petLevel = currentLevel,
		petEvolved = currentEvolved,

		petLevels = petLevels,
		petXP = petXP,
		evolvedPets = evolvedPets,

		totalCollected = math.max(
			0,
			math.floor(tonumber(data.totalCollected) or 0)
		),

		emberfallCollected = math.max(
			0,
			math.floor(tonumber(data.emberfallCollected) or 0)
		),
		enemiesDefeated = math.max(
			0,
			math.floor(tonumber(data.enemiesDefeated) or 0)
		),
		totalEggsOpened = math.max(
			0,
			math.floor(tonumber(data.totalEggsOpened) or 0)
		),
		lastDailyClaimDay = math.max(
			0,
			math.floor(tonumber(data.lastDailyClaimDay) or 0)
		),
		dailyStreak = math.clamp(
			math.floor(tonumber(data.dailyStreak) or 0),
			0,
			1000
		),

		worldsUnlocked = math.clamp(
			math.floor(tonumber(data.worldsUnlocked) or 1),
			1,
			2
		),

		questStage = math.clamp(
			math.floor(tonumber(data.questStage) or 1),
			1,
			#QUESTS + 1
		),

		ownedPets = ownedPets,
	}
end

-- Keep legacy fields synchronized with the equipped pet.
-- Existing quests, UI, and other systems can continue using petLevel
-- and petEvolved without accidentally sharing progression between pets.
local function syncEquippedPetData(data)
	if not data then return end

	data.petLevels = data.petLevels or {}
	data.evolvedPets = data.evolvedPets or {}
	data.petXP = data.petXP or {}

	if not data.pet or not PETS[data.pet] then
		data.petLevel = 1
		data.petEvolved = false
		return
	end

	if data.petLevels[data.pet] == nil then
		data.petLevels[data.pet] = 1
	end

	if data.evolvedPets[data.pet] == nil then
		data.evolvedPets[data.pet] = false
	end

	data.petLevel = math.clamp(
		math.floor(tonumber(data.petLevels[data.pet]) or 1),
		1,
		MAX_PET_LEVEL
	)

	data.petEvolved = data.evolvedPets[data.pet] == true
end

local function ownsPet(data, petName)
	return data.ownedPets
		and (data.ownedPets[petName] or 0) > 0
end

local function addOwnedPet(data, petName)
	data.ownedPets = data.ownedPets or {}
	data.petLevels = data.petLevels or {}
	data.evolvedPets = data.evolvedPets or {}
	data.petXP = data.petXP or {}	

	data.ownedPets[petName] = math.min(
		(data.ownedPets[petName] or 0) + 1,
		999
	)

	-- A newly discovered pet starts at level 1.
	-- Existing progression is preserved if the player owns it already.
	if data.petLevels[petName] == nil then
		data.petLevels[petName] = 1
	end

	if data.evolvedPets[petName] == nil then
		data.evolvedPets[petName] = false
	end
	if data.petXP[petName] == nil then
		data.petXP[petName] = 0
	end
end

local function getUpgradeCost(level)
	return math.floor(50 * (level ^ 1.15))
end

local function stateForClient(data)
	syncEquippedPetData(data)

	local quest = QUESTS[data.questStage]
	local questProgress = 0

	if quest then
		questProgress = math.min(
			data[quest.stat] or 0,
			quest.target
		)
	end

	-- Build safe progression tables for the client.
	local petLevelsForClient = {}
	local evolvedPetsForClient = {}
	local petXPForClient = {}

	for petName in pairs(PETS) do
		petLevelsForClient[petName] =
			data.petLevels[petName] or 1
		petXPForClient[petName] =
			(data.petXP and data.petXP[petName]) or 0

		evolvedPetsForClient[petName] =
			data.evolvedPets[petName] == true
	end

	local todayDay = math.floor(os.time() / 86400)
	local nextDailyStreak = data.lastDailyClaimDay == todayDay - 1
		and math.min((data.dailyStreak or 0) + 1, 8)
		or 1
	local nextDailyReward = 100 + (nextDailyStreak - 1) * 50

	return {
		starshards = data.starshards,
		pet = data.pet,
		petLevel = data.petLevel,
		totalCollected = data.totalCollected,

		upgradeCost = getUpgradeCost(data.petLevel),
		hasChosenPet = data.pet ~= nil,

		pets = PETS,
		ownedPets = data.ownedPets or {},

		-- Individual progression exposed to the UI.
		petLevels = petLevelsForClient,
		petXP = petXPForClient,
		evolvedPets = evolvedPetsForClient,

		-- These two fields always refer to the equipped pet.
		petEvolved = data.petEvolved,

		eggCost = EGG_COST,
		eggOdds = EGG_ODDS,

		enemiesDefeated = data.enemiesDefeated or 0,
		emberfallCollected = data.emberfallCollected or 0,
		totalEggsOpened = data.totalEggsOpened or 0,
		dailyStreak = data.dailyStreak or 0,
		dailyRewardAvailable = (data.lastDailyClaimDay or 0) < todayDay,
		dailyRewardStreak = nextDailyStreak,
		dailyRewardAmount = nextDailyReward,

		questStage = data.questStage,
		questTitle = quest and quest.title or "Forest Guardian",
		questDescription = quest and quest.description
			or "All starter quests completed!",

		questProgress = questProgress,
		questTarget = quest and quest.target or 0,
		questReward = quest and quest.reward or 0,

		questCompleted = quest ~= nil
			and questProgress >= quest.target,

		allQuestsComplete = quest == nil,

		worldsUnlocked = data.worldsUnlocked,
		worldUnlockCost = WORLD_UNLOCK_COST,

		canUnlockWorld = data.worldsUnlocked < 2
			and data.pet ~= nil
			and data.petLevel >= 5
			and data.starshards >= WORLD_UNLOCK_COST,

		evolutionCost = EVOLUTION_COST,

		canEvolve = data.pet ~= nil
			and data.petLevel >= 5
			and data.totalCollected >= 25
			and not data.petEvolved
			and data.starshards >= EVOLUTION_COST,
	}
end

--==================================================
-- PLAYER UI STATE / LEADERSTATS
--==================================================

local function updateLeaderstats(player)
	local data = playerData[player]
	if not data then return end

	syncEquippedPetData(data)

	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = leaderstats:FindFirstChild("Starshards")

	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Starshards"
		coins.Parent = leaderstats
	end

	coins.Value = data.starshards

	local level = leaderstats:FindFirstChild("PetLevel")

	if not level then
		level = Instance.new("IntValue")
		level.Name = "PetLevel"
		level.Parent = leaderstats
	end

	level.Value = data.petLevel
end

local function pushState(player)
	local data = playerData[player]
	if not data then return end

	syncEquippedPetData(data)
	updateLeaderstats(player)

	StateChanged:FireClient(player, stateForClient(data))
end

local function notify(player, message)
	if player and player.Parent == Players then
		Notify:FireClient(player, message)
	end
end

local function actionAllowed(player, actionName, cooldown)
	local key = tostring(player.UserId) .. "_" .. actionName
	local now = os.clock()

	if lastRequest[key]
		and now - lastRequest[key] < (cooldown or 0.6) then
		return false
	end

	lastRequest[key] = now
	return true
end

--==================================================
-- MAP
--==================================================

-- Keep generated gameplay geometry separate from authored/imported map assets.
-- Only this runtime folder is rebuilt; Workspace.MythlingMap and any other
-- user-authored scenery are left untouched.
local oldRuntimeMap = workspace:FindFirstChild("MythlingRealmsRuntime")
if oldRuntimeMap then
	oldRuntimeMap:Destroy()
end

local map = Instance.new("Folder")
map.Name = "MythlingRealmsRuntime"
map.Parent = workspace

local function makePart(
	name,
	size,
	position,
	color,
	material,
	parent
)
	local part = Instance.new("Part")

	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = parent or map

	return part
end

local function makeLabel(part, text)
	local billboard = Instance.new("BillboardGui")

	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(240, 58)
	billboard.StudsOffset = Vector3.new(
		0,
		part.Size.Y / 2 + 2,
		0
	)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")

	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.25
	label.Parent = billboard
end

-- Starter island
makePart(
	"StarfallHavenIsland",
	Vector3.new(180, 8, 180),
	Vector3.new(0, -5, 0),
	Color3.fromRGB(126, 226, 167),
	Enum.Material.Grass
)

makePart(
	"CentralPlaza",
	Vector3.new(48, 1, 48),
	Vector3.new(0, -0.25, 0),
	Color3.fromRGB(164, 208, 255),
	Enum.Material.SmoothPlastic
)

local spawn = Instance.new("SpawnLocation")

spawn.Name = "GuardianSpawn"
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = Vector3.new(0, 1, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Color = Color3.fromRGB(255, 229, 128)
spawn.Material = Enum.Material.Neon
spawn.Parent = map

local portal = makePart(
	"WhisperingGrovePortal",
	Vector3.new(12, 16, 2),
	Vector3.new(0, 5, -62),
	Color3.fromRGB(139, 104, 255),
	Enum.Material.Neon
)

portal.Transparency = 0.15

makePart(
	"PathToPortal",
	Vector3.new(12, 1, 48),
	Vector3.new(0, -0.2, -36),
	Color3.fromRGB(213, 220, 255),
	Enum.Material.Slate
)

-- Emberfall island
makePart(
	"EmberfallIsland",
	Vector3.new(180, 8, 180),
	Vector3.new(280, -5, 0),
	Color3.fromRGB(104, 74, 65),
	Enum.Material.Basalt
)

makePart(
	"EmberfallPlaza",
	Vector3.new(42, 1, 42),
	Vector3.new(280, -0.25, 0),
	Color3.fromRGB(126, 86, 78),
	Enum.Material.Slate
)

local emberPortal = makePart(
	"EmberfallPortal",
	Vector3.new(12, 16, 2),
	Vector3.new(280, 5, -62),
	Color3.fromRGB(255, 105, 55),
	Enum.Material.Neon
)

emberPortal.Transparency = 0.12

makeLabel(
	portal,
	"EMBERFALL\nUnlock: 1,000 Starshards + Level 5"
)

makeLabel(
	emberPortal,
	"STARFALL HAVEN\nReturn Portal"
)

local function addPortalPrompt(part, isEmberfall)
	local prompt = Instance.new("ProximityPrompt")

	prompt.ActionText = "Travel"
	prompt.ObjectText = isEmberfall
		and "Return to Starfall Haven"
		or "Travel to Emberfall"

	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	prompt.Triggered:Connect(function(player)
		local data = playerData[player]
		if not data then return end

		if not isEmberfall and data.worldsUnlocked < 2 then
			notify(
				player,
				"Unlock Emberfall first: level 5 and 1,000 Starshards."
			)
			return
		end

		local character = player.Character
		local root = character
			and character:FindFirstChild("HumanoidRootPart")

		if not root then return end

		if isEmberfall then
			root.CFrame = CFrame.new(0, 5, -48)
			notify(player, "Returned to Starfall Haven!")
		else
			root.CFrame = CFrame.new(280, 5, -48)
			notify(player, "Welcome to Emberfall!")
		end
	end)
end

addPortalPrompt(portal, false)
addPortalPrompt(emberPortal, true)

-- Decorative trees
for i = 1, 12 do
	local angle = math.pi * 2 * (i / 12)
	local x = math.cos(angle) * 62
	local z = math.sin(angle) * 62

	makePart(
		"FantasyTreeTrunk",
		Vector3.new(3, 9, 3),
		Vector3.new(x, 2, z),
		Color3.fromRGB(125, 83, 59),
		Enum.Material.Wood
	)

	local crown = makePart(
		"FantasyTreeCrown",
		Vector3.new(10, 10, 10),
		Vector3.new(x, 8, z),
		Color3.fromRGB(
			100 + (i % 3) * 30,
			180,
			180 + (i % 2) * 40
		),
		Enum.Material.SmoothPlastic
	)

	crown.Shape = Enum.PartType.Ball
	crown.CanCollide = false
end

--==================================================
-- CRYSTALS
--==================================================

local crystalFolder = Instance.new("Folder")
crystalFolder.Name = "CollectibleCrystals"
crystalFolder.Parent = map

local function makeCrystal(index, position, worldName)
	local crystal = Instance.new("Part")

	crystal.Name = "StarshardCrystal_" .. index
	crystal.Shape = Enum.PartType.Ball
	crystal.Size = Vector3.new(3, 3, 3)
	crystal.Position = position
	crystal.Anchored = true
	crystal.CanCollide = false
	crystal.Material = Enum.Material.Neon

	crystal.Color = ({
		Color3.fromRGB(88, 207, 255),
		Color3.fromRGB(202, 120, 255),
		Color3.fromRGB(255, 220, 95),
	})[((index - 1) % 3) + 1]

	crystal.Parent = crystalFolder

	local prompt = Instance.new("ProximityPrompt")

	prompt.ActionText = "Collect"
	prompt.ObjectText = "Starshard Crystal"
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = crystal

	local busy = false

	prompt.Triggered:Connect(function(player)
		if busy or not playerData[player] then return end

		local character = player.Character
		local root = character
			and character:FindFirstChild("HumanoidRootPart")

		if not root then return end

		if (root.Position - crystal.Position).Magnitude > 16 then
			return
		end

		busy = true
		prompt.Enabled = false
		crystal.Transparency = 1

		local data = playerData[player]

		-- Server-side world access check: hiding the portal is not enough,
		-- because clients can manipulate their character position.
		if worldName == "Emberfall" and data.worldsUnlocked < 2 then
			notify(player, "Unlock Emberfall before collecting crystals here.")
			return
		end

		syncEquippedPetData(data)

		local baseReward = worldName == "Emberfall" and 25 or 10
		if worldName == "Emberfall" then
			data.emberfallCollected = (data.emberfallCollected or 0) + 1
		end

		local reward = baseReward
			+ math.min(data.petLevel * 2, 30)
			+ (data.petEvolved and 5 or 0)
		data.starshards += reward
		data.totalCollected += 1

		if data.pet then
			data.petLevels = data.petLevels or {}
			data.petXP = data.petXP or {}

			local petName = data.pet
			local currentLevel = math.clamp(
				math.floor(tonumber(data.petLevels[petName]) or data.petLevel or 1),
				1,
				50
			)

			if currentLevel < 50 then
				local xpNeeded = currentLevel * 100

				data.petXP[petName] =
					math.max(0, tonumber(data.petXP[petName]) or 0) + 25

				while currentLevel < 50 and data.petXP[petName] >= xpNeeded do
					data.petXP[petName] -= xpNeeded
					currentLevel += 1
					xpNeeded = currentLevel * 100
				end
			else
				data.petXP[petName] = 0
			end

			data.petLevels[petName] = currentLevel
			data.petLevel = currentLevel
		end

		pushState(player)
		notify(player, "+" .. reward .. " Starshards!")

		task.delay(CRYSTAL_RESPAWN_SECONDS, function()
			if crystal.Parent then
				crystal.Transparency = 0
				prompt.Enabled = true
			end

			busy = false
		end)
	end)
end

local crystalPositions = {
	Vector3.new(18, 2, 12),
	Vector3.new(-18, 2, 12),
	Vector3.new(18, 2, -16),
	Vector3.new(-18, 2, -16),
	Vector3.new(35, 2, 0),
	Vector3.new(-35, 2, 0),
	Vector3.new(0, 2, 28),
	Vector3.new(0, 2, -27),
	Vector3.new(32, 2, 28),
	Vector3.new(-32, 2, 28),
	Vector3.new(32, 2, -30),
	Vector3.new(-32, 2, -30),
	Vector3.new(50, 2, 16),
	Vector3.new(-50, 2, -16),
	Vector3.new(50, 2, -24),
	Vector3.new(-50, 2, 24),
	Vector3.new(12, 2, 48),
	Vector3.new(-12, 2, 48),
}

for i, position in ipairs(crystalPositions) do
	makeCrystal(i, position, "StarfallHaven")
end

local emberCrystalPositions = {
	Vector3.new(248, 2, 12),
	Vector3.new(312, 2, 12),
	Vector3.new(248, 2, -16),
	Vector3.new(312, 2, -16),
	Vector3.new(245, 2, 0),
	Vector3.new(315, 2, 0),
	Vector3.new(280, 2, 28),
	Vector3.new(280, 2, -27),
	Vector3.new(250, 2, 28),
	Vector3.new(310, 2, 28),
	Vector3.new(250, 2, -30),
	Vector3.new(310, 2, -30),
}

for i, position in ipairs(emberCrystalPositions) do
	makeCrystal(100 + i, position, "Emberfall")
end

--==================================================
-- CREATURES AND SERVER-AUTHORITATIVE COMBAT
--==================================================

local enemyFolder = Instance.new("Folder")
enemyFolder.Name = "WorldCreatures"
enemyFolder.Parent = map

local enemyStates = {}

local function createEnemy(name, worldName, position, maxHealth, reward, color)
	local orb = Instance.new("Part")
	orb.Name = name
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(4.5, 4.5, 4.5)
	orb.Position = position
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.Color = color
	orb.Parent = enemyFolder

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.3
	light.Parent = orb

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyStatus"
	billboard.Adornee = orb
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(165, 48)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.Parent = orb

	local label = Instance.new("TextLabel")
	label.Name = "StatusText"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(19, 24, 38)
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.6
	label.TextScaled = true
	label.Text = name .. "\nHP " .. maxHealth .. " / " .. maxHealth
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	enemyStates[orb] = {
		name = name,
		worldName = worldName,
		spawnPosition = position,
		maxHealth = maxHealth,
		health = maxHealth,
		reward = reward,
		color = color,
		label = label,
	}

	return orb
end

local enemySpawns = {
	{ "Grove Wisp", "StarfallHaven", Vector3.new(32, 4, 4), 80, 35, Color3.fromRGB(108, 255, 186) },
	{ "Mossling", "StarfallHaven", Vector3.new(-32, 4, 4), 90, 40, Color3.fromRGB(99, 209, 137) },
	{ "Crystal Sprite", "StarfallHaven", Vector3.new(22, 4, 38), 75, 35, Color3.fromRGB(120, 210, 255) },
	{ "Dusk Wisp", "StarfallHaven", Vector3.new(-22, 4, -38), 100, 45, Color3.fromRGB(181, 125, 255) },
	{ "Cinder Hound", "Emberfall", Vector3.new(260, 4, 10), 190, 90, Color3.fromRGB(255, 115, 65) },
	{ "Ash Guardian", "Emberfall", Vector3.new(300, 4, 10), 240, 110, Color3.fromRGB(255, 174, 82) },
	{ "Magma Wisp", "Emberfall", Vector3.new(280, 4, 35), 175, 85, Color3.fromRGB(255, 87, 62) },
}

for _, info in ipairs(enemySpawns) do
	createEnemy(info[1], info[2], info[3], info[4], info[5], info[6])
end

local function grantCombatXP(data, amount)
	if not data.pet then
		return false
	end

	data.petLevels = data.petLevels or {}
	data.petXP = data.petXP or {}
	local petName = data.pet
	local level = math.clamp(
		math.floor(tonumber(data.petLevels[petName]) or data.petLevel or 1),
		1,
		MAX_PET_LEVEL
	)

	if level >= MAX_PET_LEVEL then
		data.petXP[petName] = 0
		return false
	end

	data.petXP[petName] = math.max(0, tonumber(data.petXP[petName]) or 0) + amount
	local leveledUp = false
	while level < MAX_PET_LEVEL and data.petXP[petName] >= level * 100 do
		data.petXP[petName] -= level * 100
		level += 1
		leveledUp = true
	end

	data.petLevels[petName] = level
	syncEquippedPetData(data)
	return leveledUp
end

AttackEnemy.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then return end
	if not actionAllowed(player, "attack", 0.55) then return end

	if not data.pet then
		notify(player, "Choose and equip a Mythling before fighting.")
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end

	local target = nil
	local targetState = nil
	local closestDistance = 13

	for orb, state in pairs(enemyStates) do
		if orb.Parent and state.health > 0 then
			local distance = (root.Position - orb.Position).Magnitude
			if distance <= closestDistance then
				if state.worldName ~= "Emberfall" or data.worldsUnlocked >= 2 then
					target = orb
					targetState = state
					closestDistance = distance
				end
			end
		end
	end

	if not target or not targetState then
		notify(player, "Move closer to a creature to attack.")
		return
	end

	local damage = 8 + data.petLevel * 2 + (data.petEvolved and 10 or 0)
	targetState.health = math.max(0, targetState.health - damage)

	if targetState.label and targetState.label.Parent then
		targetState.label.Text = targetState.name
			.. "\nHP " .. targetState.health .. " / " .. targetState.maxHealth
	end

	if targetState.health > 0 then
		return
	end

	local enemyName = targetState.name
	local reward = targetState.reward
	local spawnPosition = targetState.spawnPosition
	local worldName = targetState.worldName
	local maxHealth = targetState.maxHealth
	local color = targetState.color

	enemyStates[target] = nil
	target:Destroy()

	data.enemiesDefeated = (data.enemiesDefeated or 0) + 1
	data.starshards += reward
	local leveledUp = grantCombatXP(data, 40)
	pushState(player)

	local message = "Defeated " .. enemyName .. "! +" .. reward .. " Starshards."
	if leveledUp then
		message ..= " Your Mythling leveled up!"
	end
	notify(player, message)
	task.spawn(savePlayer, player)

	task.delay(12, function()
		if enemyFolder.Parent then
			createEnemy(enemyName, worldName, spawnPosition, maxHealth, reward, color)
		end
	end)
end)

--==================================================
-- PET VISUALS
--==================================================

local function removePetVisual(player)
	local visual = petVisuals[player]

	if visual then
		visual:Destroy()
		petVisuals[player] = nil
	end
end

local function makePetPiece(model, name, shape, size, position, color, material)
	local part

	if shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
	end

	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function createPetVisual(player)
	removePetVisual(player)

	local data = playerData[player]
	if not data or not data.pet then return end

	syncEquippedPetData(data)

	local definition = PETS[data.pet]
	if not definition then return end

	local model = Instance.new("Model")
	model.Name = player.Name .. "_Mythling"
	model:SetAttribute("PetName", data.pet)
	model.Parent = workspace

	local baseColor = data.petEvolved
		and Color3.fromRGB(255, 220, 120)
		or definition.color
	local darkColor = baseColor:Lerp(Color3.fromRGB(35, 39, 60), 0.24)
	local cream = Color3.fromRGB(255, 239, 214)
	local eyeColor = Color3.fromRGB(32, 30, 44)
	local shine = Color3.fromRGB(255, 255, 255)

	-- Blocky body and oversized square-ish head give the pets a clean Roblox style.
	local body = makePetPiece(
		model, "Body", "Block", Vector3.new(1.72, 1.48, 1.42),
		Vector3.new(0, 0, 0), baseColor
	)
	model.PrimaryPart = body

	makePetPiece(
		model, "Belly", "Block", Vector3.new(0.92, 0.72, 0.18),
		Vector3.new(0, -0.12, -0.61), cream
	)
	makePetPiece(
		model, "Head", "Block", Vector3.new(1.58, 1.42, 1.22),
		Vector3.new(0, 0.68, -0.48), baseColor
	)

	-- Ears differ by species so the pets do not all look identical.
	if data.pet == "Mossbun" then
		makePetPiece(model, "LeftEar", "Ball", Vector3.new(0.38, 1.0, 0.35), Vector3.new(-0.42, 1.55, -0.36), baseColor)
		makePetPiece(model, "RightEar", "Ball", Vector3.new(0.38, 1.0, 0.35), Vector3.new(0.42, 1.55, -0.36), baseColor)
		makePetPiece(model, "LeftInnerEar", "Ball", Vector3.new(0.15, 0.64, 0.12), Vector3.new(-0.42, 1.57, -0.53), cream)
		makePetPiece(model, "RightInnerEar", "Ball", Vector3.new(0.15, 0.64, 0.12), Vector3.new(0.42, 1.57, -0.53), cream)
	elseif data.pet == "Tidefin" or data.pet == "Glacub" then
		makePetPiece(model, "LeftFinEar", "Wedge", Vector3.new(0.52, 0.65, 0.24), Vector3.new(-0.68, 0.92, -0.25), baseColor)
		makePetPiece(model, "RightFinEar", "Wedge", Vector3.new(0.52, 0.65, 0.24), Vector3.new(0.68, 0.92, -0.25), baseColor)
	else
		makePetPiece(model, "LeftEar", "Wedge", Vector3.new(0.48, 0.65, 0.35), Vector3.new(-0.48, 1.22, -0.36), baseColor)
		makePetPiece(model, "RightEar", "Wedge", Vector3.new(0.48, 0.65, 0.35), Vector3.new(0.48, 1.22, -0.36), baseColor)
	end

	-- Eyes, highlights, muzzle and smile are separate 3D pieces.
	for _, side in ipairs({-1, 1}) do
		makePetPiece(model, side < 0 and "LeftEye" or "RightEye", "Ball", Vector3.new(0.17, 0.22, 0.10), Vector3.new(side * 0.31, 0.72, -1.055), eyeColor)
		makePetPiece(model, side < 0 and "LeftEyeShine" or "RightEyeShine", "Ball", Vector3.new(0.055, 0.065, 0.035), Vector3.new(side * 0.31 - 0.025, 0.765, -1.11), shine)
		makePetPiece(model, side < 0 and "LeftCheek" or "RightCheek", "Block", Vector3.new(0.20, 0.11, 0.06), Vector3.new(side * 0.49, 0.42, -1.08), Color3.fromRGB(255, 165, 170))
	end
	makePetPiece(model, "Muzzle", "Block", Vector3.new(0.40, 0.24, 0.18), Vector3.new(0, 0.42, -1.12), cream)
	makePetPiece(model, "Nose", "Ball", Vector3.new(0.12, 0.09, 0.07), Vector3.new(0, 0.49, -1.25), eyeColor)

	-- Four small square feet make the silhouette more blocky and grounded.
	for _, side in ipairs({-1, 1}) do
		for _, depth in ipairs({-1, 1}) do
			makePetPiece(
				model,
				(side < 0 and "Left" or "Right") .. (depth < 0 and "FrontFoot" or "BackFoot"),
				"Block",
				Vector3.new(0.42, 0.32, 0.38),
				Vector3.new(side * 0.48, -0.78, depth * 0.42),
				darkColor
			)
		end
	end

	-- Signature details for each Mythling.
	if data.pet == "EmberFox" or data.pet == "Cinderling" then
		makePetPiece(model, "Tail", "Ball", Vector3.new(0.62, 0.62, 1.12), Vector3.new(0, 0.03, 1.05), baseColor)
		makePetPiece(model, "TailTip", "Ball", Vector3.new(0.43, 0.43, 0.42), Vector3.new(0, 0.08, 1.62), cream)
		makePetPiece(model, "FlameCrest", "Wedge", Vector3.new(0.36, 0.55, 0.3), Vector3.new(0, 1.34, -0.35), Color3.fromRGB(255, 210, 90), Enum.Material.Neon)
	elseif data.pet == "Mossbun" or data.pet == "Bloomlet" or data.pet == "Sunpup" then
		makePetPiece(model, "TailPom", "Ball", Vector3.new(0.48, 0.48, 0.48), Vector3.new(0, 0.05, 0.87), cream)
		if data.pet == "Bloomlet" then
			for i = 1, 5 do
				local a = math.pi * 2 * i / 5
				makePetPiece(model, "Petal" .. i, "Ball", Vector3.new(0.35, 0.35, 0.22), Vector3.new(math.cos(a) * 0.55, 1.08 + math.sin(a) * 0.2, -0.48), Color3.fromRGB(255, 190, 220))
			end
			makePetPiece(model, "FlowerCenter", "Ball", Vector3.new(0.32, 0.32, 0.22), Vector3.new(0, 1.12, -0.63), Color3.fromRGB(255, 218, 95))
		end
	elseif data.pet == "Tidefin" then
		makePetPiece(model, "LeftFin", "Wedge", Vector3.new(0.55, 0.55, 0.22), Vector3.new(-0.91, 0.05, 0.05), baseColor)
		makePetPiece(model, "RightFin", "Wedge", Vector3.new(0.55, 0.55, 0.22), Vector3.new(0.91, 0.05, 0.05), baseColor)
		makePetPiece(model, "TailFin", "Wedge", Vector3.new(0.65, 0.65, 0.28), Vector3.new(0, 0.05, 1.05), cream)
	elseif data.pet == "Pebblit" then
		for i = 1, 3 do
			makePetPiece(model, "StonePlate" .. i, "Ball", Vector3.new(0.42, 0.3, 0.22), Vector3.new((i - 2) * 0.43, 1.0 + (i % 2) * 0.15, -0.5), darkColor)
		end
	elseif data.pet == "Duskmoth" then
		makePetPiece(model, "LeftWing", "Ball", Vector3.new(0.8, 0.92, 0.18), Vector3.new(-0.92, 0.45, 0.18), darkColor)
		makePetPiece(model, "RightWing", "Ball", Vector3.new(0.8, 0.92, 0.18), Vector3.new(0.92, 0.45, 0.18), darkColor)
		makePetPiece(model, "LeftAntenna", "Ball", Vector3.new(0.12, 0.5, 0.12), Vector3.new(-0.22, 1.48, -0.35), cream)
		makePetPiece(model, "RightAntenna", "Ball", Vector3.new(0.12, 0.5, 0.12), Vector3.new(0.22, 1.48, -0.35), cream)
	elseif data.pet == "Voltkit" or data.pet == "Stormling" then
		makePetPiece(model, "LightningTail", "Wedge", Vector3.new(0.38, 0.95, 0.35), Vector3.new(0.35, 0.3, 1.0), Color3.fromRGB(255, 235, 95), Enum.Material.Neon)
		makePetPiece(model, "ForeheadMark", "Ball", Vector3.new(0.18, 0.36, 0.08), Vector3.new(0, 1.0, -1.08), Color3.fromRGB(255, 235, 95), Enum.Material.Neon)
	elseif data.pet == "Glacub" then
		makePetPiece(model, "IceCrystal", "Wedge", Vector3.new(0.28, 0.62, 0.24), Vector3.new(0, 1.35, -0.42), cream, Enum.Material.Glass)
	elseif data.pet == "Starwhisp" then
		makePetPiece(model, "StarOrbLeft", "Ball", Vector3.new(0.3, 0.3, 0.3), Vector3.new(-0.95, 1.0, -0.1), Color3.fromRGB(255, 225, 115), Enum.Material.Neon)
		makePetPiece(model, "StarOrbRight", "Ball", Vector3.new(0.22, 0.22, 0.22), Vector3.new(0.95, 0.35, -0.1), Color3.fromRGB(255, 225, 115), Enum.Material.Neon)
	elseif data.pet == "Sunpup" then
		makePetPiece(model, "SunMark", "Ball", Vector3.new(0.28, 0.28, 0.1), Vector3.new(0, 0.92, -1.07), Color3.fromRGB(255, 232, 125), Enum.Material.Neon)
	end

	if data.petEvolved then
		local aura = makePetPiece(model, "EvolutionAura", "Ball", Vector3.new(2.7, 2.7, 2.7), Vector3.new(0, 0.45, 0), Color3.fromRGB(255, 220, 95), Enum.Material.ForceField)
		aura.Transparency = 0.72
	end

	petVisuals[player] = model

	-- Spawn the model close to its owner so it doesn't slide in from the map origin.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local startPosition = root.Position + root.CFrame.RightVector * 3 + Vector3.new(0, 1.8, 0)
		model:PivotTo(CFrame.lookAt(startPosition, root.Position + Vector3.new(0, 1, 0)))
	end
end

-- Frame-rate independent smoothing keeps the Mythling floating naturally around
-- the player instead of snapping every 0.12 seconds.
RunService.Heartbeat:Connect(function(dt)
	local alpha = 1 - math.exp(-dt * 8)
	local now = os.clock()

	for player, model in pairs(petVisuals) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if root and model and model.Parent and model.PrimaryPart then
			local orbitAngle = now * 0.72 + (player.UserId % 17) * 0.15
			local radius = 2.8
			local bob = math.sin(now * 2.8 + player.UserId * 0.01) * 0.22
			local localOffset = Vector3.new(
				math.cos(orbitAngle) * radius,
				1.65 + bob,
				math.sin(orbitAngle) * radius
			)
			local targetPosition = root.Position + root.CFrame:VectorToWorldSpace(localOffset)
			local targetCFrame = CFrame.lookAt(
				targetPosition,
				root.Position + Vector3.new(0, 1.1, 0)
			)
			local currentCFrame = model:GetPivot()
			model:PivotTo(currentCFrame:Lerp(targetCFrame, alpha))
		end
	end
end)

--==================================================
-- SAVE / LOAD
--==================================================

local function savePlayer(player)
	local data = playerData[player]
	if not data then
		return false
	end

	-- Serialize saves per player. If autosave is already running when the
	-- player leaves, wait briefly for it to finish instead of silently
	-- skipping the final save.
	local waitDeadline = os.clock() + 12
	while savingPlayers[player] do
		if os.clock() >= waitDeadline then
			warn("[MythlingRealms] Timed out waiting for an earlier save for " .. player.Name)
			return false
		end
		task.wait(0.1)
		if playerData[player] ~= data then
			return false
		end
	end

	-- Re-read current data after waiting, so the final snapshot includes
	-- progress made while a previous save was in flight.
	data = playerData[player]
	if not data then
		return false
	end

	savingPlayers[player] = true
	syncEquippedPetData(data)
	local snapshot = cloneData(data)

	local success, err = pcall(function()
		store:UpdateAsync("player_" .. player.UserId, function()
			return snapshot
		end)
	end)

	savingPlayers[player] = nil

	if not success then
		warn(
			"[MythlingRealms] Save failed for "
				.. player.Name
				.. ": "
				.. tostring(err)
		)
	end

	return success
end

local function loadPlayer(player)
	if playerData[player] or loadingPlayers[player] then
		return
	end

	loadingPlayers[player] = true

	local success, saved = pcall(function()
		return store:GetAsync("player_" .. player.UserId)
	end)

	if not success then
		warn(
			"[MythlingRealms] Failed to load data for "
				.. player.Name
				.. ". Player data was not initialized to avoid overwriting saves."
		)

		loadingPlayers[player] = nil

		player:Kick(
			"Your data could not be loaded safely. Please rejoin in a moment."
		)

		return
	end

	-- A player can disconnect while GetAsync is yielding. Do not create
	-- runtime state or visuals for a player who has already left.
	if player.Parent ~= Players then
		loadingPlayers[player] = nil
		return
	end

	local data

	if type(saved) == "table" then
		data = cloneData(saved)
	else
		data = defaultData()
	end

	syncEquippedPetData(data)
	playerData[player] = data

	updateLeaderstats(player)

	if data.pet then
		createPetVisual(player)
	end

	pushState(player)
	loadingPlayers[player] = nil
end

GetState.OnServerInvoke = function(player)
	local timeout = 15
	local startTime = os.clock()

	while not playerData[player] and loadingPlayers[player] do
		if os.clock() - startTime >= timeout then
			return nil
		end

		task.wait(0.1)
	end

	local data = playerData[player]

	if not data then
		return nil
	end

	return stateForClient(data)
end

--==================================================
-- CHOOSE STARTER
--==================================================

ChooseStarter.OnServerEvent:Connect(function(player, petName)
	local data = playerData[player]
	if not data then return end

	if not actionAllowed(player, "chooseStarter", 1) then
		return
	end

	if data.pet then
		notify(player, "You already chose your starter Mythling.")
		return
	end

	if type(petName) ~= "string" or not STARTER_PETS[petName] then
		notify(player, "That starter Mythling is not available.")
		return
	end

	data.pet = petName
	data.petLevels[petName] = data.petLevels[petName] or 1
	data.evolvedPets[petName] = data.evolvedPets[petName] or false

	addOwnedPet(data, petName)
	syncEquippedPetData(data)

	createPetVisual(player)
	pushState(player)

	notify(
		player,
		"Your " .. PETS[petName].displayName
			.. " is ready to explore!"
	)

	task.spawn(savePlayer, player)
end)

--==================================================
-- PET UPGRADES
--==================================================

BuyUpgrade.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then return end

	if not data.pet then
		notify(player, "Choose a starter Mythling first.")
		return
	end

	if not actionAllowed(player, "upgrade", 0.5) then
		return
	end

	syncEquippedPetData(data)

	if data.petLevel >= MAX_PET_LEVEL then
		notify(player, "Your Mythling reached the level cap!")
		return
	end

	local cost = getUpgradeCost(data.petLevel)

	if data.starshards < cost then
		notify(player, "You need " .. cost .. " Starshards.")
		return
	end

	data.starshards -= cost

	-- Only upgrade the currently equipped pet.
	data.petLevels[data.pet] = data.petLevel + 1
	syncEquippedPetData(data)

	pushState(player)

	notify(
		player,
		"Mythling level increased to " .. data.petLevel .. "!"
	)

	task.spawn(savePlayer, player)
end)

--==================================================
-- OPEN EGG
--==================================================

local function rollEgg()
	local roll = math.random() * 100
	local accumulated = 0

	for _, entry in ipairs(EGG_POOL) do
		accumulated += entry.weight

		if roll <= accumulated then
			return entry.pet, entry.rarity
		end
	end

	return "Cinderling", "Common"
end

OpenEgg.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then return end

	if not actionAllowed(player, "openEgg", 0.75) then
		return
	end

	if data.starshards < EGG_COST then
		notify(
			player,
			"You need " .. EGG_COST .. " Starshards to open this egg."
		)
		return
	end

	local petName, rarity = rollEgg()

	-- The server determines the actual result.
	-- The client animation is visual only.
	if not PETS[petName] then
		notify(player, "Egg opening failed. Please try again.")
		return
	end

	data.starshards -= EGG_COST
	data.totalEggsOpened = (data.totalEggsOpened or 0) + 1
	addOwnedPet(data, petName)

	-- Equip the new pet only if the player has no pet equipped.
	if not data.pet then
		data.pet = petName
		syncEquippedPetData(data)
		createPetVisual(player)
	end

	pushState(player)

	-- Send the internal pet key and rarity separately so the client can
	-- run the suspense animation without spoiling the result in a toast.
	Notify:FireClient(
		player,
		"Egg opened!",
		petName,
		rarity
	)

	task.spawn(savePlayer, player)
end)

--==================================================
-- EQUIP PET
--==================================================

EquipPet.OnServerEvent:Connect(function(player, petName)
	local data = playerData[player]
	if not data then return end

	if not actionAllowed(player, "equipPet", 0.4) then
		return
	end

	if type(petName) ~= "string" or not PETS[petName] then
		notify(player, "That Mythling does not exist.")
		return
	end

	if not ownsPet(data, petName) then
		notify(player, "You haven't discovered this Mythling yet.")
		return
	end

	data.pet = petName
	syncEquippedPetData(data)

	createPetVisual(player)
	pushState(player)

	notify(
		player,
		"Equipped " .. PETS[petName].displayName
			.. " (Level " .. data.petLevel .. ")!"
	)

	task.spawn(savePlayer, player)
end)

--==================================================
-- CLAIM QUEST
--==================================================

ClaimQuest.OnServerEvent:Connect(function(player, requestedQuestTitle)
	local data = playerData[player]
	if not data then return end

	if not actionAllowed(player, "quest") then
		return
	end

	syncEquippedPetData(data)

	local quest = QUESTS[data.questStage]

	if not quest then
		notify(player, "All starter quests are completed!")
		return
	end

	-- The client may send the displayed title. Validate it against the
	-- server's current quest so a stale UI cannot claim another objective.
	if requestedQuestTitle ~= nil
		and requestedQuestTitle ~= quest.title then
		pushState(player)
		notify(player, "Your active quest changed. The quest list was refreshed.")
		return
	end

	local progress = data[quest.stat] or 0

	if progress < quest.target then
		notify(
			player,
			quest.description
				.. " (" .. progress .. "/" .. quest.target .. ")"
		)
		return
	end

	data.starshards += quest.reward
	data.questStage += 1

	pushState(player)

	notify(
		player,
		"Quest complete! +" .. quest.reward .. " Starshards."
	)

	task.spawn(savePlayer, player)
end)

--==================================================
-- DAILY REWARD
--==================================================

ClaimDailyReward.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then return end

	if not actionAllowed(player, "dailyReward", 1.5) then
		return
	end

	local todayDay = math.floor(os.time() / 86400)
	if (data.lastDailyClaimDay or 0) >= todayDay then
		notify(player, "Your daily reward has already been claimed. Come back tomorrow!")
		pushState(player)
		return
	end

	if data.lastDailyClaimDay == todayDay - 1 then
		data.dailyStreak = math.min((data.dailyStreak or 0) + 1, 8)
	else
		data.dailyStreak = 1
	end

	local reward = 100 + (data.dailyStreak - 1) * 50
	data.starshards += reward
	data.lastDailyClaimDay = todayDay

	pushState(player)
	notify(player, "Daily reward claimed! +" .. reward .. " Starshards. Streak: " .. data.dailyStreak)
	task.spawn(savePlayer, player)
end)

--==================================================
-- EVOLUTION
--==================================================

EvolvePet.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then return end

	if not actionAllowed(player, "evolve") then
		return
	end

	if not data.pet then
		notify(player, "Choose a Mythling first.")
		return
	end

	syncEquippedPetData(data)

	if data.petEvolved then
		notify(player, "Your Mythling has already evolved!")
		return
	end

	if data.petLevel < 5 or data.totalCollected < 25 then
		notify(
			player,
			"Evolution requires level 5 and 25 crystals collected."
		)
		return
	end

	if data.starshards < EVOLUTION_COST then
		notify(player, "Evolution costs 500 Starshards.")
		return
	end

	data.starshards -= EVOLUTION_COST

	-- Evolve only the currently equipped pet.
	data.evolvedPets[data.pet] = true
	syncEquippedPetData(data)

	createPetVisual(player)
	pushState(player)

	notify(
		player,
		"Evolution unlocked! +5 Starshards per crystal."
	)

	task.spawn(savePlayer, player)
end)

--==================================================
-- UNLOCK EMBERFALL
--==================================================

UnlockWorld.OnServerEvent:Connect(function(player)
	local data = playerData[player]
	if not data then return end

	if not actionAllowed(player, "world") then
		return
	end

	if data.worldsUnlocked >= 2 then
		notify(player, "Emberfall is already unlocked!")
		return
	end

	syncEquippedPetData(data)

	if not data.pet or data.petLevel < 5 then
		notify(player, "Reach Mythling level 5 to unlock Emberfall.")
		return
	end

	if data.starshards < WORLD_UNLOCK_COST then
		notify(player, "You need 1,000 Starshards to unlock Emberfall.")
		return
	end

	data.starshards -= WORLD_UNLOCK_COST
	data.worldsUnlocked = 2

	pushState(player)

	notify(
		player,
		"Emberfall unlocked! Visit the orange portal."
	)

	task.spawn(savePlayer, player)
end)

--==================================================
-- PLAYER LIFECYCLE
--==================================================

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Loading and saving both yield. Wait briefly for an in-flight load to
	-- finish before attempting the final save, otherwise a fast disconnect
	-- could leave the session without ever saving its loaded data.
	local loadDeadline = os.clock() + 12
	while loadingPlayers[player] and os.clock() < loadDeadline do
		task.wait(0.1)
	end

	if loadingPlayers[player] then
		warn("[MythlingRealms] Timed out waiting for data load on leave: " .. player.Name)
	else
		-- Attempt to save before removing in-memory data.
		local saved = savePlayer(player)
		if not saved and playerData[player] then
			warn("[MythlingRealms] Final save did not complete for " .. player.Name)
		end
	end

	removePetVisual(player)

	playerData[player] = nil
	savingPlayers[player] = nil

	local prefix = tostring(player.UserId) .. "_"

	for key in pairs(lastRequest) do
		if string.sub(key, 1, #prefix) == prefix then
			lastRequest[key] = nil
		end
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, player)
end

task.spawn(function()
	while task.wait(AUTOSAVE_SECONDS) do
		for player in pairs(playerData) do
			task.spawn(savePlayer, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0

	for player in pairs(playerData) do
		pending += 1

		task.spawn(function()
			savePlayer(player)
			pending -= 1
		end)
	end

	-- Roblox gives BindToClose a limited shutdown window. Allow enough
	-- time for in-flight DataStore operations to finish, while staying
	-- below the platform's approximate 30-second shutdown limit.
	local deadline = os.clock() + 25

	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
	
end)
--==================================================
-- DEV COMMAND: GIVE STARSHARDS
-- Only works in Roblox Studio
--==================================================

local RunService = game:GetService("RunService")

local function setupDevCommands(player)
	player.Chatted:Connect(function(message)
		if not RunService:IsStudio() then
			return
		end

		local amountText = message:match("^!shards%s+(%d+)$")
		if not amountText then
			return
		end

		local amount = tonumber(amountText)

		if not amount or amount < 1 or amount > 1000000 then
			return
		end

		local data = playerData[player]
		if not data then
			warn("[DEV] Dados do jogador ainda não carregaram.")
			return
		end

		data.starshards += amount

		pushState(player)
		task.spawn(savePlayer, player)

		notify(player, "+" .. amount .. " Starshards (DEV)")

		print(
			"[DEV] Adicionadas "
				.. amount
				.. " Starshards para "
				.. player.Name
		)
	end)
end

Players.PlayerAdded:Connect(setupDevCommands)

for _, player in ipairs(Players:GetPlayers()) do
	setupDevCommands(player)
end
print("[MythlingRealms] Server systems initialized.")