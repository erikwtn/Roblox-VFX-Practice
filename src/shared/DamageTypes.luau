local Workspace = game:GetService("Workspace")
local DamageTypes = {}

function DamageTypes.ExplosionDamage(player: Player, targetPosition: Vector3, radius: number, damage: number)
	-- cast an overlap radius to check what the explosion
	local overlapParameters = OverlapParams.new()
	overlapParameters.FilterDescendantsInstances = { player.Character }
	overlapParameters.FilterType = Enum.RaycastFilterType.Exclude

	local hits = Workspace:GetPartBoundsInRadius(targetPosition, radius, overlapParameters)
	local damaged = {}

	-- check through hits for valid targets and verify it only does damage once (in other instances there might be need for multiple hits)
	for _, part in pairs(hits) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")

		if humanoid and not damaged[humanoid] then
			damaged[humanoid] = true
			humanoid:TakeDamage(damage)
		end
	end
end

return DamageTypes