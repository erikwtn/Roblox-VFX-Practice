local AstelMeteorShower = {}

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Dependencies
local DamageTypes = require(ReplicatedStorage.Shared.DamageTypes)

--// Constants
local VFXFolder = Workspace:WaitForChild("VFX")
local Prefabs = ReplicatedStorage:WaitForChild("Prefabs")

--// VFX Prefabs
local ExplosionPrefab = Prefabs:FindFirstChild("Red Explosion")
local SmokePrefab = Prefabs:FindFirstChild("Smoke1")
local MeteorPrefab = Prefabs:FindFirstChild("Meteor")
local PortalPrefab = Prefabs:FindFirstChild("Portal")

--// Variables
local explosionTweenInfo: TweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
AstelMeteorShower.Config = {
	MaximumRange = 200,
	TotalMeteors = 20,
	SpawnHeight = 50,
	SpawnRadius = 100,
	SpawnOffset = -40,
	MeteorDuration = 0.8,
	MeteorSize = 10,
	ExplosionRadius = 12,
	Damage = 15,
	Cooldown = 5,
}

--// Functions
local function createExplosion(targetPosition: Vector3)
	local explosionModel: Model = ExplosionPrefab:Clone()
	explosionModel:PivotTo(CFrame.new(targetPosition))
	explosionModel.Parent = VFXFolder

	local mainPart = explosionModel.PrimaryPart or explosionModel:FindFirstChildWhichIsA("BasePart")

	if mainPart then
		local particles: ParticleEmitter = SmokePrefab:Clone()
		particles.Transparency = NumberSequence.new(0, 1)
		particles.LockedToPart = true
		particles.Lifetime = NumberRange.new(5)
		particles.Parent = mainPart

		local sizeProxy = Instance.new("NumberValue")
		sizeProxy.Value = 2
		sizeProxy.Changed:Connect(function(val)
			particles.Size = NumberSequence.new(val)
		end)

		task.defer(function()
			particles:Emit(10)
		end)

		TweenService:Create(sizeProxy, explosionTweenInfo, { Value = 15 }):Play()
		Debris:AddItem(sizeProxy, 1)
	end

	local sizeOffset = math.random(1, 4)
	for _, mesh in pairs(explosionModel:GetChildren()) do
		if mesh:IsA("BasePart") then
			mesh.Anchored = true
			mesh.CanCollide = false
			mesh.CFrame = mesh.CFrame
				* CFrame.Angles(math.rad(math.random(360)), math.rad(math.random(360)), math.rad(math.random(360)))

			TweenService:Create(mesh, explosionTweenInfo, {
				Size = mesh.Size * sizeOffset,
				Transparency = 1,
			}):Play()
		end
	end

	Debris:AddItem(explosionModel, 1)
end

function AstelMeteorShower:Init()
	local Mouse = Players.LocalPlayer:GetMouse()
	return {
		TargetPosition = Mouse.Hit.Position,
	}
end

function AstelMeteorShower:Run(player: Player, character: Model, props: { any })
	local targetPosition = props.TargetPosition
	local root = character:FindFirstChild("HumanoidRootPart")

	if not root or not targetPosition then
		return
	end

	-- server: calculate trajectories
	if RunService:IsServer() then
		props.Meteors = {}

		for i = 1, AstelMeteorShower.Config.TotalMeteors do
			local r = AstelMeteorShower.Config.SpawnRadius
			local playerCFrame = root.CFrame
			local right = playerCFrame.RightVector
			local up = playerCFrame.UpVector
			local look = playerCFrame.LookVector

			local sideShift = math.random(-r, r)
			local heightShift = math.random(-r / 2, r / 2)

			local portalCenter = root.Position + (look * AstelMeteorShower.Config.SpawnOffset) + (up * AstelMeteorShower.Config.SpawnHeight)
			local startPos = portalCenter + (right * sideShift) + (up * heightShift)
			local impactPos = targetPosition + (right * sideShift)

			-- save time data
			local delayTime = i * 0.1
			table.insert(props.Meteors, {
				StartPos = startPos,
				ImpactPos = impactPos,
				Delay = delayTime,
			})

			-- trigger damage
			task.delay(delayTime + AstelMeteorShower.Config.MeteorDuration, function()
				DamageTypes.ExplosionDamage(player, impactPos, AstelMeteorShower.Config.ExplosionRadius, AstelMeteorShower.Config.Damage)
			end)
		end
		return
	end

	--// client: render visuals
	if props.Meteors then
		for _, meteorData in ipairs(props.Meteors) do
			task.delay(meteorData.Delay, function()
				local startPos = meteorData.StartPos
				local endPos = meteorData.ImpactPos

				-- create portal
				local portal = PortalPrefab:Clone()
				local baseLookCFrame = CFrame.lookAt(startPos, endPos)
				portal:PivotTo(baseLookCFrame * CFrame.Angles(math.rad(90), 0, 0))
				portal.Parent = VFXFolder

				local scaleValue = Instance.new("NumberValue")
				scaleValue.Value = 0.01
				portal:ScaleTo(scaleValue.Value)

				scaleValue.Changed:Connect(function(newScale)
					portal:ScaleTo(newScale)
				end)

				local targetScale = 10
				local openTween = TweenService:Create(
					scaleValue,
					TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Value = targetScale }
				)
				openTween:Play()

				task.delay(0.5, function()
					local closeTween = TweenService:Create(
						scaleValue,
						TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{ Value = 0.01 }
					)
					closeTween:Play()
					closeTween.Completed:Connect(function()
						portal:Destroy()
						scaleValue:Destroy()
					end)
				end)

				-- create Meteor
				local meteor = MeteorPrefab:Clone()
				meteor.Size = Vector3.new(AstelMeteorShower.Config.MeteorSize, AstelMeteorShower.Config.MeteorSize, AstelMeteorShower.Config.MeteorSize)
				meteor.Position = startPos
				meteor.CanCollide = false
				meteor.Anchored = true
				meteor.Parent = VFXFolder

				local att0 = Instance.new("Attachment")
				att0.Position = Vector3.new(0, AstelMeteorShower.Config.MeteorSize / 2, 0)
				att0.Parent = meteor
				local att1 = Instance.new("Attachment")
				att1.Position = Vector3.new(0, -AstelMeteorShower.Config.MeteorSize / 2, 0)
				att1.Parent = meteor

				-- create trail
				local trail = Instance.new("Trail")
				trail.Attachment0 = att0
				trail.Attachment1 = att1
				trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.new(1, 0.682353, 0))
				trail.Lifetime = 0.5
				trail.Parent = meteor

				-- fall tween
				local fallTween =
					TweenService:Create(meteor, TweenInfo.new(AstelMeteorShower.Config.MeteorDuration, Enum.EasingStyle.Linear), {
						Position = endPos,
						Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
					})
				fallTween:Play()

				fallTween.Completed:Connect(function()
					DamageTypes.ShakeCamera(Players.LocalPlayer, 1)
					createExplosion(endPos)
					meteor:Destroy()
				end)
			end)
		end
	end
end

return AstelMeteorShower
