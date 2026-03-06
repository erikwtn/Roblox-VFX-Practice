--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--// Dependencies
local DamageTypes = require(ReplicatedStorage.Shared.DamageTypes)
local VFXValidator = require(ReplicatedStorage.Shared.VFXValidator)

--// Events
local MeteorEvent: RemoteEvent = ReplicatedStorage:WaitForChild("AstelMeteorExplosionEvent")

--// Variables
local playerCooldowns = {}

--// Functions
MeteorEvent.OnServerEvent:Connect(function(player: Player, targetPosition: Vector3)
	local config = VFXValidator.Config.Astel
	local lastTimeUsed = playerCooldowns[player] or 0

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if not VFXValidator.CanPerform(player, "Astel", lastTimeUsed) then
		return
	end

	if not VFXValidator.ValidateTarget(player, "Astel", targetPosition) then
		return
	end

	playerCooldowns[player] = tick()

	for i = 1, config.TotalMeteors do
		local r = config.SpawnRadius
		
		local playerCFrame = root.CFrame
		local right = playerCFrame.RightVector
		local up = playerCFrame.UpVector
		local look = playerCFrame.LookVector
	
		local sideShift = math.random(-r, r)
		local heightShift = math.random(-r/2, r/2)
	
		local portalCenter = root.Position + (look * config.SpawnOffset) + (up * config.SpawnHeight)
		local startPosition = portalCenter + (right * sideShift) + (up * heightShift)
	
		local impactPosition = targetPosition + (right * sideShift)
	
		MeteorEvent:FireAllClients(startPosition, impactPosition)
	
		task.delay(config.MeteorDuration, function()
			DamageTypes.ExplosionDamage(player, impactPosition, config.ExplosionRadius, config.Damage)
		end)
	
		task.wait(0.1)
	end
end)
