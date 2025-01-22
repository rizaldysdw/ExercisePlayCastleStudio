local Knit = require(game:GetService("ReplicatedStorage").Knit)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

-- Modules
local DynamiteModule = Knit.GetService("DynamiteService")
local TimerModule = Knit.GetService("TimerService")
local AppearanceModule = Knit.GetComponent("AppearanceService")
local HelperModule = require(ReplicatedStorage:WaitForChild("HelperModule"))

-- Events
local UIEvent = ReplicatedStorage:WaitForChild("UIEvent")
local playAreaTeleportPoint = Workspace:WaitForChild("PlayArea"):WaitForChild("__TeleportPoint")

-- Service Definition
local SessionService = Knit.CreateService {
    Name = "SessionService",
    Client = {}, -- Expose functions/events to the client if needed
}

-- State Variables
local playersOnSession = {}
local eliminatedPlayers = {}
local activePlayers = {}
local isDone = false

-- Helper Functions
local function eliminatePlayer(player)
    if table.find(eliminatedPlayers, player) then
        warn("Eliminated player is already in the eliminatedPlayers table")
        return false
    end

    table.insert(eliminatedPlayers, player)
    local playerIndex = table.find(activePlayers, player)
    if not playerIndex then
        warn("Eliminated player not found in activePlayers table")
        return false
    end

    table.remove(activePlayers, playerIndex)
    AppearanceModule.SetSpectatorMode(player)
    UIEvent:FireAllClients("HeaderText", true, player.Name .. " is eliminated!")
    return true
end

local function startSession()
    SessionService:TeleportPlayers(playersOnSession)
    task.wait(2)

    DynamiteModule.Activate(activePlayers)

    -- Wait for DynamiteModule activation
    while not DynamiteModule.IsActive() do
        task.wait(0.5)
    end

    TimerModule.StartTimer()
    print("SESSION STARTED")
end

local function restartSession()
    print("Restarting session... waiting 5 seconds")
    task.wait(5)
    startSession()
end

local function exitSession()
    UIEvent:FireAllClients("HeaderText", true, "Exiting session...")
    print("Exiting session... waiting 5 seconds")
    task.wait(5)

    AppearanceModule.RevertSpectatorModeToAll()
    playersOnSession = {}
    eliminatedPlayers = {}
    activePlayers = {}

    AppearanceModule.Deactive()
    isDone = true
end

local function endSession()
    local dynamitedPlayer = DynamiteModule.GetPlayerWithDynamite()
    local succeed = eliminatePlayer(dynamitedPlayer)

    DynamiteModule.Deactivate()
    TimerModule.StopTimer()

    print("SESSION ENDED")
    print("Waiting 5 seconds...")
    task.wait(5)

    if #activePlayers > 1 then
        restartSession()
    elseif #activePlayers == 1 then
        local winner = activePlayers[1]
        print("WE HAVE A WINNER: " .. winner.Name)
        UIEvent:FireAllClients("HeaderText", true, "The winner is [" .. winner.Name .. "]")
        print("Waiting 5 seconds...")
        task.wait(5)
        exitSession()
    else
        warn("ERROR: No active players left")
        exitSession()
    end
end

-- Knit Methods
function SessionService:TeleportPlayers(players)
    for _, player in ipairs(players) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = playAreaTeleportPoint.CFrame
        end
    end
end

function SessionService:InitializeSession(players)
    UIEvent:FireAllClients("HeaderText", true, "Initializing Session...")
    UIEvent:FireAllClients("BombTimerLabel", true, nil)
    UIEvent:FireAllClients("PlayerCountLabel", false, nil)

    playersOnSession = HelperModule.TableShallowCopy(players)
    activePlayers = HelperModule.TableShallowCopy(playersOnSession)
    eliminatedPlayers = {}

    AppearanceModule.Activate(playersOnSession)

    -- Wait for AppearanceModule activation
    while not AppearanceModule.IsActive() do
        task.wait(0.5)
    end

    startSession()
end

function SessionService:IsDone()
    return isDone
end

-- Knit Lifecycle Methods
function SessionService:KnitStart()
    TimerModule.OnTimeUp:Connect(endSession)
    print("SessionService started!")
end

function SessionService:KnitInit()
    print("SessionService initialized!")
end

return SessionService
