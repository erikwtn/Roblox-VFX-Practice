local ShootBeamExplosion = {}

--// Services
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Dependencies
local DamageTypes = require(ReplicatedStorage.Shared.DamageTypes)

--// Constants
local VFXFolder: Folder = Workspace:WaitForChild("VFX")
local Prefabs: Folder = ReplicatedStorage:WaitForChild("Prefabs")
local ExplosionPrefab = Prefabs:FindFirstChild("Red Explosion")
local SmokePrefab = Prefabs:FindFirstChild("Smoke1")

--// Variables
local explosionTweenInfo: TweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
ShootBeamExplosion.Config = {
	MaximumRange = 100,
	ExplosionRadius = 10,
	Cooldown = 0.5,
	Damage = 20,
	Duration = 0.5,
}

--// Functions
local function createBeam(origin: Part, targetPosition: Vector3)
	if not origin or not targetPosition then
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
		if timeElapsed > ShootBeamExplosion.Config.Duration or not origin or not origin.Parent then
			connection:Disconnect()
			beam:Destroy()
			return
		end

		-- calculate the size, length and transparency of the beam depending on time elapsed
		local distance: number = (origin.Position - targetPosition).Magnitude
		local targetTransparency: number = timeElapsed / ShootBeamExplosion.Config.Duration
		local targetThickness: number = 0.8 * (1 - (timeElapsed / ShootBeamExplosion.Config.Duration))

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

	DamageTypes.ShakeCamera(Players.LocalPlayer, 1)
	Debris:AddItem(explosionModel, 1)
end

function ShootBeamExplosion:Init()
	local Player = Players.LocalPlayer
	local character = Player.Character
	local origin = character and character:FindFirstChild("Head")

	if not origin then
		return
	end

	local Mouse = Player:GetMouse()

	Mouse.TargetFilter = VFXFolder
	local mousePos = Mouse.Hit.Position

	-- clamp to range
	local difference = (mousePos - origin.Position)
	local targetPos = (difference.Magnitude > ShootBeamExplosion.Config.MaximumRange)
			and (origin.Position + difference.Unit * ShootBeamExplosion.Config.MaximumRange)
		or mousePos

	return {
		TargetPosition = targetPos,
	}
end

function ShootBeamExplosion:Run(player: Player, character: Model, props: { any })
	local targetPosition = props.TargetPosition
	if not targetPosition then
		return
	end

	--// server
	if RunService:IsServer() then
		DamageTypes.ExplosionDamage(player, targetPosition, ShootBeamExplosion.Config.ExplosionRadius, ShootBeamExplosion.Config.Damage)
		return
	end

	--// client
	local origin: Part = character:FindFirstChild("Head")
	if not origin then
		return
	end

	createBeam(origin, targetPosition)
	createExplosion(targetPosition)
end

return ShootBeamExplosion
