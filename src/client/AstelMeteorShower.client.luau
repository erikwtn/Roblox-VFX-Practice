--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

--// Dependencies
local DamageTypes = require(ReplicatedStorage.Shared.DamageTypes)
local VFXValidator = require(ReplicatedStorage.Shared.VFXValidator)

--// Events
local MeteorEvent = ReplicatedStorage:WaitForChild("AstelMeteorExplosionEvent")

--// Constants
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local VFXFolder = Workspace:FindFirstChild("VFX")
local Prefabs = ReplicatedStorage:WaitForChild("Prefabs")

--// VFX Prefabs
local ExplosionPrefab = Prefabs:FindFirstChild("Red Explosion")
local SmokePrefab = Prefabs:FindFirstChild("Smoke1")
local MeteorPrefab = Prefabs:FindFirstChild("Meteor")
local PortalPrefab = Prefabs:FindFirstChild("Portal")

--// Variables
local lastTimeUsed = 0
local explosionTweenInfo: TweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

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

local function createMeteorVisual(startPos: Vector3, endPos: Vector3)
	local config = VFXValidator.Config.Astel

	local portal = PortalPrefab:Clone()
	portal:PivotTo(CFrame.new(startPos) * CFrame.Angles(math.rad(90), 0, 0))
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

	-- create meteor
	local meteor = MeteorPrefab:Clone()
	meteor.Size = Vector3.new(config.MeteorSize, config.MeteorSize, config.MeteorSize)
	meteor.Position = startPos
	meteor.CanCollide = false
	meteor.Anchored = true
	meteor.Parent = VFXFolder

	-- create attachments for trail
	local att0 = Instance.new("Attachment")
	att0.Parent = meteor
	att0.Position = Vector3.new(0, config.MeteorSize / 2, 0)
	local att1 = Instance.new("Attachment")
	att1.Parent = meteor
	att1.Position = Vector3.new(0, -config.MeteorSize / 2, 0)

	-- create trail
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.new(1, 0.682353, 0))
	trail.Lifetime = 0.5
	trail.Parent = meteor

	-- falling tween
	local fallTween = TweenService:Create(meteor, TweenInfo.new(config.MeteorDuration, Enum.EasingStyle.Linear), {
		Position = endPos,
		Orientation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360)),
	})
	fallTween:Play()

	-- impact tween
	fallTween.Completed:Connect(function()
		DamageTypes.ShakeCamera(Player, 1)
		createExplosion(endPos)
		meteor:Destroy()
	end)
end

--// Input
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.MouseButton3 then
		return
	end

	if not VFXValidator.CanPerform(Player, "Astel", lastTimeUsed) then
		return
	end

	lastTimeUsed = tick()
	MeteorEvent:FireServer(Mouse.Hit.Position)
end)

--// Replication
MeteorEvent.OnClientEvent:Connect(function(startPos, endPos)
	createMeteorVisual(startPos, endPos)
end)
