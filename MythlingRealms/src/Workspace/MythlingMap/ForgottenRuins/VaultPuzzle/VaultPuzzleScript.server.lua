local TweenService = game:GetService("TweenService")
local puzzle = script.Parent
local runes = { puzzle:WaitForChild("RuneA"), puzzle:WaitForChild("RuneB"), puzzle:WaitForChild("RuneC") }
local door = puzzle:WaitForChild("VaultDoor")
local chestBase = puzzle:WaitForChild("ChestBase")
local lid = puzzle:WaitForChild("ChestLid")
local chestPrompt = chestBase:WaitForChild("ProximityPrompt")
local done, count, opened = {}, 0, false
chestPrompt.Enabled = false

for _, rune in ipairs(runes) do
	local pp = rune:WaitForChild("ProximityPrompt")
	pp.Triggered:Connect(function(player)
		if done[rune] then return end
		done[rune] = true
		count += 1
		pp.Enabled = false
		rune.Color = Color3.fromRGB(120, 255, 210)
		rune.Material = Enum.Material.Neon
		if count == #runes then
			TweenService:Create(door, TweenInfo.new(3, Enum.EasingStyle.Quad), { Position = door.Position - Vector3.new(0, door.Size.Y + 1, 0) }):Play()
			chestPrompt.Enabled = true
			puzzle:SetAttribute("VaultOpen", true)
		end
	end)
end

chestPrompt.Triggered:Connect(function(player)
	if opened then return end
	opened = true
	chestPrompt.Enabled = false
	local hinge = lid.CFrame * CFrame.new(0, -0.3, -1.1)
	local goal = hinge * CFrame.Angles(math.rad(-70), 0, 0) * hinge:Inverse() * lid.CFrame
	TweenService:Create(lid, TweenInfo.new(0.6), { CFrame = goal }):Play()
	-- TODO: grant the player's reward here by calling your existing Starshards code.
	puzzle:SetAttribute("RewardClaimedBy", player.UserId)
	print(player.Name .. " opened the Forgotten Ruins vault")
end)
