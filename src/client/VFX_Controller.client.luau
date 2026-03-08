--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Constants
local RemotesFolder: Folder = ReplicatedStorage:WaitForChild("Remotes")
local AbilitiesFolder: Folder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Abilities")
local AbilityGuiText: TextLabel = Players.LocalPlayer.PlayerGui:WaitForChild("PrimaryGui").Frame.TextLabel

--// Events
local VFXEvent: RemoteEvent = RemotesFolder:WaitForChild("VFX")

--// Variables
local equippedAbilities: { string } = { "AstelMeteorShower", "ShootBeamExplosion", "Orbs" }
local activeAbility: string = "AstelMeteorShower"
local isBusy: boolean = false

--// Init
AbilityGuiText.Text = activeAbility

--// Functions
local function CycleSkill(direction: number)
	local currentIndex: number = table.find(equippedAbilities, activeAbility)
	local newIndex = currentIndex + direction

	if newIndex > #equippedAbilities then
		activeAbility = equippedAbilities[1]
	elseif newIndex < 1 then
		activeAbility = equippedAbilities[#equippedAbilities]
	else
		activeAbility = equippedAbilities[newIndex]
	end

	AbilityGuiText.Text = activeAbility
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if isBusy then
			return
		end
		isBusy = true

		local abilityModule = require(AbilitiesFolder:WaitForChild(activeAbility))
		local props = abilityModule:Init()
		VFXEvent:FireServer(activeAbility, props)

		task.wait(0.1)
		isBusy = false
	elseif input.KeyCode == Enum.KeyCode.E then
		CycleSkill(1)
	elseif input.KeyCode == Enum.KeyCode.Q then
		CycleSkill(-1)
	end
end)

VFXEvent.OnClientEvent:Connect(function(player: Player, ability: string, props: { any })
	local module = require(AbilitiesFolder:WaitForChild(ability))
	local character = player.Character

	if module and character then
		module:Run(player, character, props)
	end
end)
