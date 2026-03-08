local SkillTemplate = {}

--// Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

--// Dependencies
local DamageTypes = require(ReplicatedStorage.Shared.DamageTypes)

--// Constants
local VFXFolder: Folder = Workspace:WaitForChild("VFX")
local Prefabs: Folder = ReplicatedStorage:WaitForChild("Prefabs")

--// Variables
SkillTemplate.Config = {
	Damage = 20,
	Cooldown = 1,
	MaximumRange = 100,
}

function SkillTemplate:Init()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local mouse = player:GetMouse()
	local origin = character.HumanoidRootPart.Position
	local targetPosition = mouse.Hit.Position

	return {
		Origin = origin,
		TargetPosition = targetPosition,
	}
end

function SkillTemplate:Run(player: Player, character: Model, props: { any })
	if not character then
		return
	end

	local origin = props.Origin
	local targetPosition = props.TargetPosition

	if not origin or not targetPosition then
		return
	end

	local config = self.Config

	-- server handles damage and targeting with randomness 
	if RunService:IsServer() then
		DamageTypes.ExplosionDamage(player, targetPosition, 10, SkillTemplate.Config.Damage)
		return
	end

	--// client: render visuals
end

return SkillTemplate
