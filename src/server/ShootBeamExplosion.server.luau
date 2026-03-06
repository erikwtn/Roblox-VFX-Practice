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

local function applyExplosionDamage(player: Player, targetPosition: Vector3)
	local config = VFXValidator.Config.ShootBeamExplosion

	-- cast an overlap radius to check what the explosion
	local overlapParameters = OverlapParams.new()
	overlapParameters.FilterDescendantsInstances = { player.Character }
	overlapParameters.FilterType = Enum.RaycastFilterType.Exclude

	local hits = Workspace:GetPartBoundsInRadius(targetPosition, config.ExplosionRadius, overlapParameters)
	local damaged = {}

	-- check through hits for valid targets and verify it only does damage once (in other instances there might be need for multiple hits)
	for _, part in pairs(hits) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")

		if humanoid and not damaged[humanoid] then
			damaged[humanoid] = true
			humanoid:TakeDamage(config.Damage)
		end
	end
end

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