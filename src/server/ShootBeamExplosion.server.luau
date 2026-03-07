--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Dependencies
local DamageTypes = require(ReplicatedStorage.Shared.DamageTypes)
local VFXValidator = require(ReplicatedStorage.Shared.VFXValidator)

--// Events
local ExplosionEvent: RemoteEvent = ReplicatedStorage:WaitForChild("ShootBeamExplosionRemote")

--// Variables
local playerCooldowns = {}

ExplosionEvent.OnServerEvent:Connect(function(player: Player, targetPosition: Vector3)
	local lastTimeUsed = playerCooldowns[player] or 0

	local success = VFXValidator.CanPerform(player, "ShootBeamExplosion", lastTimeUsed)
	if not success then
		return
	end

	if not VFXValidator.ValidateTarget(player, "ShootBeamExplosion", targetPosition) then
		return
	end

	local config = VFXValidator.Config.ShootBeamExplosion
	if not config then
		return
	end

	playerCooldowns[player] = tick()
	ExplosionEvent:FireAllClients(targetPosition, player)
	DamageTypes.ExplosionDamage(player, targetPosition, config.ExplosionRadius, config.Damage)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	playerCooldowns[player] = nil
end)
