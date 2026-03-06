--// Services
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Dependencies
local VFXValidator = require(ReplicatedStorage.Shared.VFXValidator)

--// Constants
local Player = Players.LocalPlayer
local Mouse: Mouse = Player:GetMouse()
local VFXFolder: Folder = Workspace:WaitForChild("VFX")
local ExplosionEvent: RemoteEvent = ReplicatedStorage:WaitForChild("ShootBeamExplosionRemote")

--// Variables
local explosionTweenInfo: TweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
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
	beam.Color = Color3.new(1, 1, 1)
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
		beam.CFrame = CFrame.lookAt(origin.Position, targetPosition) * CFrame.new(0, 0, -distance/2) * CFrame.Angles(0, math.rad(90), 0)
		beam.Transparency = targetTransparency
	end)
end

local function createExplosion(targetPosition: Vector3)
	-- create explosion part
	local explosion: Part = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(1, 1, 1)
	explosion.Position = targetPosition
	explosion.Anchored = true
	explosion.CanCollide = false
	explosion.CanQuery = false
	explosion.Color = Color3.new(1, 1, 1)
	explosion.Material = Enum.Material.Neon
	explosion.Parent = VFXFolder

	-- create particle effect
	local particles: ParticleEmitter = Instance.new("ParticleEmitter")
	particles.LightEmission = 1
	particles.Transparency = NumberSequence.new(0)
	particles.Speed = NumberRange.new(30, 60)
	particles.SpreadAngle = Vector2.new(-90, 90)
	particles.Lifetime = NumberRange.new(0.2, 0.4)
	particles.Parent = explosion

	-- wait a sec to start particles
	task.defer(function()
		particles:Emit(50)
	end)

	-- tween explosion part larger over time
	TweenService:Create(explosion, explosionTweenInfo, { Size = Vector3.new(20, 20, 20), Transparency = 1}):Play()

	-- mark explosion for cleanup
	Debris:AddItem(explosion, 1)
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
	local targetPos = (difference.Magnitude > config.MaximumRange) and (origin.Position + difference.Unit * config.MaximumRange) or mousePos

	lastTimeUsed = tick()
	createBeam(origin, targetPos)
	createExplosion(targetPos)
	ExplosionEvent:FireServer(targetPos)
end)