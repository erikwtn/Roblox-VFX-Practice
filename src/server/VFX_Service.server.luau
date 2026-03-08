--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Constants
local RemotesFolder: Folder = ReplicatedStorage:WaitForChild("Remotes")
local AbilitiesFolder: Folder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Abilities")

--// Events
local VFXEvent: RemoteEvent = RemotesFolder:WaitForChild("VFX")

--// Functions
local VFXValidator = require(ReplicatedStorage.Shared.VFXValidator)
local cooldowns = {}

VFXEvent.OnServerEvent:Connect(function(player: Player, ability: string, props: { any })
	local character = player.Character
	if not character then
		return
	end

	if not cooldowns[player.UserId] then
		cooldowns[player.UserId] = {}
	end
	local lastUsed = cooldowns[player.UserId][ability] or 0

	local module = require(AbilitiesFolder:WaitForChild(ability))

	if not VFXValidator.CanPerform(player, ability, module.Config, lastUsed) then
		return
	end

	if props.TargetPosition and not VFXValidator.ValidateTarget(player, ability, module.Config, props.TargetPosition) then
		return
	end

	cooldowns[player.UserId][ability] = tick()

	module:Run(player, character, props)
	VFXEvent:FireAllClients(player, ability, props)
end)
