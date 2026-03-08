local VFXValidator = {}

--- Verify that when VFX are triggered it exists, is off cooldown and the player triggering it exists and is not dead
function VFXValidator.CanPerform(player: Player, actionName: string, config: any, lastUsedTime: number): boolean
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
function VFXValidator.ValidateTarget(player: Player, actionName: string, config: any, targetPosition: Vector3): boolean
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
