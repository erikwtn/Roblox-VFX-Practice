--// Services
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Dependencies
local DamageTypes = require(ReplicatedStorage.Shared.DamageTypes)
local VFXValidator = require(ReplicatedStorage.Shared.VFXValidator)

--// Events
local ExplosionEvent: RemoteEvent = ReplicatedStorage:WaitForChild("ShootBeamExplosionRemote")

--// Constants
local Player = Players.LocalPlayer
local Mouse: Mouse = Player:GetMouse()
local VFXFolder: Folder = Workspace:WaitForChild("VFX")
local Prefabs = ReplicatedStorage:WaitForChild("Prefabs")
local ExplosionPrefab = Prefabs:FindFirstChild("Red Explosion")
local SmokePrefab = Prefabs:FindFirstChild("Smoke1")

--// Variables
local explosionTweenInfo: TweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local lastTimeUsed = 0

--// Functions
local function createBeam(origin: Part, targetPosition: Vector3)
	if not origin or not targetPosition then
		return
	end

	local config = VFXValidator.Config["ShootBeamExplosion"]
	if not config then
		return
	end

	-- create beam
	local beam: Part = Instance.new("Part")
	beam.Shape = Enum.PartType.Cylinder
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.new(1, 0, 0)
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Parent = VFXFolder

	local timeElapsed: number = 0
	-- subscribe to function so loop can be stopped appropriately
	local connection: RBXScriptConnection

	-- every frame check if the timer has run out, if not it
	-- continues to update the beams position, size, and transparency
	-- otherwise, disconnect
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		timeElapsed += deltaTime

		-- check if timer ran out or origin stops existing, if so stop loop
		if timeElapsed > config.Duration or not origin or not origin.Parent then
			connection:Disconnect()
			beam:Destroy()
			return
		end

		-- calculate the size, length and transparency of the beam depending on time elapsed
		local distance: number = (origin.Position - targetPosition).Magnitude
		local targetTransparency: number = timeElapsed / config.Duration
		local targetThickness: number = 0.8 * (1 - (timeElapsed / config.Duration))

		-- set the beam's size, length and transparency
		beam.Size = Vector3.new(distance, targetThickness, targetThickness)
		beam.CFrame = CFrame.lookAt(origin.Position, targetPosition)
			* CFrame.new(0, 0, -distance / 2)
			* CFrame.Angles(0, math.rad(90), 0)
		beam.Transparency = targetTransparency
	end)
end

local function createExplosion(targetPosition: Vector3)
	local explosionModel: Model = ExplosionPrefab:Clone()
	explosionModel:PivotTo(CFrame.new(targetPosition))
	explosionModel.Parent = VFXFolder

	local mainPart = explosionModel.PrimaryPart or explosionModel:FindFirstChildWhichIsA("BasePart")

	if mainPart then
		local particles: ParticleEmitter = SmokePrefab:Clone()
		particles.Transparency = NumberSequence.new(0, 1)
		particles.LockedToPart = true
		particles.Lifetime = NumberRange.new(3)
		particles.Parent = mainPart

		local sizeProxy = Instance.new("NumberValue")
		sizeProxy.Value = 1
		sizeProxy.Changed:Connect(function(val)
			particles.Size = NumberSequence.new(val)
		end)

		task.defer(function()
			particles:Emit(10)
		end)

		TweenService:Create(sizeProxy, explosionTweenInfo, { Value = 6 }):Play()
		Debris:AddItem(sizeProxy, 1)
	end

	for _, mesh in pairs(explosionModel:GetChildren()) do
		if mesh:IsA("BasePart") then
			mesh.Anchored = true
			mesh.CanCollide = false

			mesh.CFrame = mesh.CFrame
				* CFrame.Angles(math.rad(math.random(360)), math.rad(math.random(360)), math.rad(math.random(360)))

			TweenService:Create(mesh, explosionTweenInfo, {
				Size = mesh.Size * 2,
				Transparency = 1,
			}):Play()
		end
	end

	DamageTypes.ShakeCamera(Player, 1)
	Debris:AddItem(explosionModel, 1)
end

--// Replication
ExplosionEvent.OnClientEvent:Connect(function(targetPosition: Vector3, originPlayer: Player)
	if originPlayer == Player then
		return
	end

	local character = originPlayer.Character
	if not character then
		return
	end

	local origin: Part = character:FindFirstChild("Head")
	if not origin then
		return
	end

	createBeam(origin, targetPosition)
	createExplosion(targetPosition)
end)

--// Input
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if not VFXValidator.CanPerform(Player, "ShootBeamExplosion", lastTimeUsed) then
		return
	end

	local character = Player.Character
	local origin = character and character:FindFirstChild("Head")
	if not origin then
		return
	end

	local config = VFXValidator.Config["ShootBeamExplosion"]
	if not config then
		return
	end

	Mouse.TargetFilter = VFXFolder
	local mousePos = Mouse.Hit.Position

	-- clamp to range
	local difference = (mousePos - origin.Position)
	local targetPos = (difference.Magnitude > config.MaximumRange)
			and (origin.Position + difference.Unit * config.MaximumRange)
		or mousePos

	lastTimeUsed = tick()
	createBeam(origin, targetPos)
	createExplosion(targetPos)
	ExplosionEvent:FireServer(targetPos)
end)
