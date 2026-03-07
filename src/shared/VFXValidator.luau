local VFXValidator = {}

VFXValidator.Config = {
	["ShootBeamExplosion"] = {
		MaximumRange = 100,
		ExplosionRadius = 10,
		Cooldown = 0.5,
		Damage = 20,
		Duration = 0.5,
	},
	["Astel"] = {
		MaximumRange = 200,
		TotalMeteors = 50,
		SpawnHeight = 50,
		SpawnRadius = 100,
		SpawnOffset = -40,
		MeteorDuration = 0.8,
		MeteorSize = 10,
		ExplosionRadius = 12,
		Damage = 15,
		Cooldown = 5,
	},
}

--- Verify that when VFX are triggered it exists, is off cooldown and the player triggering it exists and is not dead
function VFXValidator.CanPerform(player: Player, actionName: string, lastUsedTime: number): boolean
	-- config does not exist
	local config = VFXValidator.Config[actionName]
	if not config then
		return false
	end

	-- cooldown has not ended
	if tick() - lastUsedTime < config.Cooldown then
		return false
	end

	-- no character found or character is dead
	local character: Model? = player.Character
	if not character or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
		return false
	end

	return true
end

--- Check if target is within range
function VFXValidator.ValidateTarget(player: Player, actionName: string, targetPosition: Vector3): boolean
	-- config does not exist
	local config = VFXValidator.Config[actionName]
	if not config then
		return false
	end

	-- character does not exist
	local character = player.Character
	if not character then
		return false
	end

	-- head does not exist
	local origin = character:FindFirstChild("Head")
	if not origin then
		return false
	end

	local distance = (origin.Position - targetPosition).Magnitude

	return distance <= (config.MaximumRange + 10)
end

return VFXValidator
