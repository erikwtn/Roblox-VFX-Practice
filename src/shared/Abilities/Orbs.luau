local Orbs = {}

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
local OrbPrefab = Prefabs:WaitForChild("Orb")

--// Variables
Orbs.Config = {
	Damage = 20,
	Cooldown = 1,
	MaximumRange = 20,
	OrbCount = 5,
	ChargeTime = 5,
	TravelDuration = 0.2,
	Spacing = 2,
	Radius = 3,
}

--// Functions
local function getClosestPlayer(originPart: BasePart, maxRange: number, caster: Player)
	local closestTarget = nil
	local shortestDistance = maxRange

	for _, player in pairs(Players:GetPlayers()) do
		if player == caster then
			continue
		end
		local char = player.Character
		local targetRoot = char and char:FindFirstChild("HumanoidRootPart")

		if targetRoot then
			local distance = (originPart.Position - targetRoot.Position).Magnitude
			if distance < shortestDistance then
				shortestDistance = distance
				closestTarget = targetRoot
			end
		end
	end
	return closestTarget
end

function Orbs:Init()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local mouse = player:GetMouse()
	local origin = character.HumanoidRootPart.CFrame
	local targetPosition = mouse.Hit.Position

	return {
		Origin = origin,
		TargetPosition = targetPosition,
	}
end

function Orbs:Run(player: Player, character: Model, props: { any })
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
		task.delay(config.ChargeTime + config.TravelDuration, function()
			local root = character:FindFirstChild("HumanoidRootPart")
			local target = root and getClosestPlayer(root, config.MaximumRange, player)

			if target then
				task.wait(config.TravelDuration)
				DamageTypes.ExplosionDamage(player, target.Position, 2, config.Damage)
			end
		end)
		return
	end

	--// client: render visuals
	local root = character:FindFirstChild("HumanoidRootPart")

	for i = 1, config.OrbCount do
		-- create orb
		local newOrb: Model = OrbPrefab:Clone()
		newOrb.Parent = VFXFolder

		local orbPart = newOrb.PrimaryPart
		orbPart.Anchored = true
		orbPart.CanCollide = false

		local followConnection: RBXScriptConnection
		followConnection = RunService.RenderStepped:Connect(function()
			if root and orbPart then
				-- normalize index to a 0 to 1 range, then multiply by pi to distribute across a semi circle
				local theta = ((i - 1) / (config.OrbCount - 1)) * math.pi

				-- find the point x and y on the circle with the config radius
				local x = -math.cos(theta) * config.Radius
				local y = math.sin(theta) * config.Radius + math.sin((tick() * 5) + i) * 0.5 -- also adds a sine wave bobbing effect on the y axis

				-- set the orb positions relative to the player
				local currentPos = root.CFrame * CFrame.new(x, y + 2, 2)
				orbPart.CFrame = CFrame.lookAt(currentPos.Position, targetPosition)
			else
				followConnection:Disconnect()
			end
		end)

		-- fade orb
		newOrb.PrimaryPart.Transparency = 1
		TweenService:Create(newOrb.PrimaryPart, TweenInfo.new(0.3), { Transparency = 0 }):Play()

		-- hover tween
		task.delay(config.ChargeTime, function()
			if followConnection then
				followConnection:Disconnect()
			end

			local target = getClosestPlayer(root, config.MaximumRange, player)

			if target then
				local flyTween = TweenService:Create(
					newOrb.PrimaryPart,
					TweenInfo.new(config.TravelDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = target.Position }
				)
				flyTween:Play()

				flyTween.Completed:Connect(function()
					newOrb:Destroy()
				end)
			else
				local fadeOut = TweenService:Create(newOrb.PrimaryPart, TweenInfo.new(0.5), { Transparency = 1 })
				fadeOut:Play()
				fadeOut.Completed:Connect(function()
					newOrb:Destroy()
				end)
			end
		end)
	end
end

return Orbs
