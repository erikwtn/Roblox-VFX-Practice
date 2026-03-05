--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Dependencies

--// Constants
local ExplosionEvent: RemoteEvent = ReplicatedStorage:WaitForChild("ShootBeamExplosionRemote")

--// Variables
-- ideally these would be stored somewhere in a constants folder or something
local beamMaximumRange: number = 100
local explosionDamage: number = 20
local explosionRadius: number = 10

--// Functions
ExplosionEvent.OnServerEvent:Connect(function(player, targetPosition)
	local character: Model = player.Character
	if not character then
		return
	end

	local root: Part = character:FindFirstChild("HumanodiRootPart")
	if not root then
		return
	end

	-- verify the range considering the size of the explosion
	local distance = (root.Position - targetPosition).Magnitude
	if distance > beamMaximumRange + (explosionRadius / 2) then
		return
	end

	-- replicate to all other clients (client checks if player was the one who triggered it)
	ExplosionEvent:FireAllClients(targetPosition, player)

	-- cast an overlap radius to check what the explosion hit, exlude the player who triggered it
	local overlapRadius = OverlapParams.new()
	overlapRadius.FilterDescendantsInstances = {character}

	local hits = Workspace:GetPartBoundsInRadius(targetPosition, explosionRadius, overlapRadius)
	local damaged = {}

	-- check through hits for valid targets and verify it only does damage once (in other instances there might be need for multiple hits)
	for _, part in pairs(hits) do
		local humanoid = part.Parent:FindFirstChild("Humanoid")
		if humanoid and not damaged[humanoid] then
			damaged[humanoid] = true
			humanoid:TakeDamage(explosionDamage)
		end
	end
end)
