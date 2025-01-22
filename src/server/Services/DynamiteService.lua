local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)

local DynamiteService = Knit.CreateService {
    Name = "DynamiteService",
    Client = { -- Define client-side events/methods
        DynamiteAssigned = Knit.CreateSignal(),
        HeaderTextUpdated = Knit.CreateSignal(),
    },
}

local NORMAL_WALKSPEED = 16
local HOLDER_WALKSPEED = 20
local COOLDOWN_DURATION = 1.0

local dynamite = workspace:WaitForChild("Dynamite") -- Original reference
local dynamiteClone = nil
local funcConnection = nil

local playerTable = {}
local playerWithDynamite = nil
local isActive = false
local isOnCooldown = false
local cooldownCounter = 0.0

-- Utility Functions
local function getRandomPlayer(players)
    if #players > 0 then
        return players[math.random(1, #players)]
    end
    return nil
end

local function setWalkSpeed(player, speed)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = speed
    print("Set " .. player.Name .. "'s walkspeed to " .. tostring(speed))
end

local function createClone(ref)
    local clone = ref:Clone()
    clone.Parent = workspace
    clone.Name = "DynamiteClone"
    return clone
end

local function startCooldown()
    isOnCooldown = true
    cooldownCounter = COOLDOWN_DURATION
    print("Cooldown started for " .. tostring(COOLDOWN_DURATION) .. " seconds.")

    while cooldownCounter > 0 do
        task.wait(1)
        cooldownCounter -= 1
    end

    isOnCooldown = false
    print("Cooldown ended.")
end

-- Core Dynamite Logic
function DynamiteService:AssignDynamiteToPlayer(player)
    if not player then
        warn("Dynamite assignment failed: Player is nil.")
        return
    end

    playerWithDynamite = player
    dynamiteClone = createClone(dynamite)
    dynamiteClone.Parent = player.Character or player.CharacterAdded:Wait()

    setWalkSpeed(player, HOLDER_WALKSPEED)

    -- Prevent unequipping
    funcConnection = dynamiteClone.Unequipped:Connect(function()
        warn(player.Name .. " attempted to unequip the dynamite. Re-equipping...")
        self:EquipDynamite()
    end)

    -- Notify clients
    self.Client.DynamiteAssigned:FireAll(player.Name)
    self.Client.HeaderTextUpdated:FireAll(player.Name .. " is holding the dynamite!")

    task.spawn(startCooldown)
end

function DynamiteService:EquipDynamite()
    if dynamiteClone and playerWithDynamite then
        dynamiteClone.Parent = playerWithDynamite.Character or playerWithDynamite.CharacterAdded:Wait()
        dynamiteClone:Activate()
    end
end

function DynamiteService:DismissDynamiteFromPlayer()
    if not playerWithDynamite then
        warn("No player is currently holding the dynamite.")
        return
    end

    setWalkSpeed(playerWithDynamite, NORMAL_WALKSPEED)

    if dynamiteClone then
        dynamiteClone:Destroy()
        dynamiteClone = nil
    end

    if funcConnection then
        funcConnection:Disconnect()
        funcConnection = nil
    end

    playerWithDynamite = nil
end

-- Service Methods
function DynamiteService:Activate(activePlayers)
    if isActive then
        warn("DynamiteService is already active!")
        return
    end

    if #activePlayers == 0 then
        warn("Cannot activate DynamiteService: No active players.")
        return
    end

    playerTable = activePlayers
    local randomPlayer = getRandomPlayer(activePlayers)
    self:AssignDynamiteToPlayer(randomPlayer)

    isActive = true
    print("DynamiteService activated.")
end

function DynamiteService:Deactivate()
    if not isActive then
        warn("DynamiteService is not active.")
        return
    end

    self:DismissDynamiteFromPlayer()
    playerTable = {}
    isActive = false
    print("DynamiteService deactivated.")
end

function DynamiteService:GetPlayerWithDynamite()
    return playerWithDynamite
end

function DynamiteService:IsActive()
    return isActive
end

-- Client Method Example
function DynamiteService.Client:RequestTransfer(player)
    if not isActive or isOnCooldown then
        warn(player.Name .. " attempted a transfer during cooldown or inactive state.")
        return false
    end

    if player == playerWithDynamite then
        warn("Transfer failed: Player already holds the dynamite.")
        return false
    end

    self.Server:DismissDynamiteFromPlayer()
    self.Server:AssignDynamiteToPlayer(player)

    return true
end

return DynamiteService
