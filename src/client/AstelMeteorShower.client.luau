--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

--// Dependencies
local VFXValidator = require(ReplicatedStorage.Shared.VFXValidator)

--// Constants
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local MeteorEvent = ReplicatedStorage:WaitForChild("AstelMeteorExplosionEvent")
local VFXFolder = Workspace:FindFirstChild("VFX")

--// Variables
local lastTimeUsed = 0

--// Functions
local function createMeteorVisual(startPos: Vector3, endPos: Vector3)
	local config = VFXValidator.Config.Astel

	-- create meteor
	local meteor = Instance.new("Part")
	meteor.Size = Vector3.new(config.MeteorSize, config.MeteorSize, config.MeteorSize)
	meteor.Position = startPos
	meteor.Shape = Enum.PartType.Ball
	meteor.Material = Enum.Material.Neon
	meteor.Color = Color3.new(1, 1, 1)
	meteor.CanCollide = false
	meteor.Anchored = true
	meteor.Parent = VFXFolder

	-- create attachments for trail
	local att0 = Instance.new("Attachment")
	att0.Parent = meteor
	att0.Position = Vector3.new(0, config.MeteorSize/2, 0)
	local att1 = Instance.new("Attachment")
	att1.Parent = meteor
	att1.Position = Vector3.new(0, -config.MeteorSize/2, 0)

	-- create trail
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.new(0,0,0))
	trail.Lifetime = 0.5
	trail.Parent = meteor

	-- falling tween
	local fallTween = TweenService:Create(meteor, TweenInfo.new(config.MeteorDuration, Enum.EasingStyle.Linear), {
		Position = endPos,
		Orientation = Vector3.new(math.random(0,360), math.random(0,360), math.random(0,360))
	})
	fallTween:Play()

	-- impact tween
	fallTween.Completed:Connect(function()
		local blast = Instance.new("Part")
		blast.Shape = Enum.PartType.Ball
		blast.Material = Enum.Material.Neon
		blast.Color = Color3.fromRGB(255, 255, 255)
		blast.Position = endPos
		blast.Size = Vector3.new(2, 2, 2)
		blast.Anchored = true
		blast.CanCollide = false
		blast.Parent = VFXFolder

		TweenService:Create(blast, TweenInfo.new(0.5), {
			Size = Vector3.new(config.ExplosionRadius * 2, config.ExplosionRadius * 2, config.ExplosionRadius * 2),
			Transparency = 1
		}):Play()

		Debris:AddItem(blast, 0.5)
		meteor:Destroy()
	end)
end

--// Input
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.MouseButton2 then 
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