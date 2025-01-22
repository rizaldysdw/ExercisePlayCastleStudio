local Knit = require(game:GetService("ReplicatedStorage").Knit)

local Players = game:GetService("Players")
local UILobbyCountFunction = game:GetService("ReplicatedStorage"):WaitForChild("UILobbyCountFunction")
local joinCylinder = workspace:WaitForChild("Lobby"):WaitForChild("Lobby"):WaitForChild("__JoinCylinder")
local playAreaTeleportPoint = workspace:WaitForChild("PlayArea"):WaitForChild("__TeleportPoint")
local lobbyTeleportPoint = workspace:WaitForChild("Lobby"):WaitForChild("Lobby"):WaitForChild("__TeleportPoint")

local MIN_PLAYERS = 1
local COUNTDOWN_TIME = 10.0

-- Service Definition
local LobbyService = Knit.CreateService {
    Name = "LobbyService",
    Client = {}, -- Expose functions to the client (if needed)
}

local isOnSession = false
local playersOnCylinder = {} -- Tracks players on the cylinder
local playersOnSession = {}
local isCountingDown = false
local countdownCounter = 0.0

-- Function to check if a character belongs to a player
local function isPlayer(character)
    return Players:GetPlayerFromCharacter(character)
end

function LobbyService:TeleportPlayers(players)
    for _, player in ipairs(players) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local teleportPointCFrame = lobbyTeleportPoint.CFrame
            player.Character.HumanoidRootPart.CFrame = teleportPointCFrame
        end
    end
end

function LobbyService:SetOnSession(boolInput)
    if boolInput then
        print("Set OnSession to true")
        playersOnSession = playersOnCylinder
        isOnSession = true
    else
        print("Set OnSession to false")
        playersOnSession = {}
        isOnSession = false
    end
end

local function countingDown()
    countdownCounter = COUNTDOWN_TIME
    isCountingDown = true

    while isCountingDown do
        task.wait(1.0)
        countdownCounter -= 1.0
        print("Game starting in " .. countdownCounter .. " seconds!")

        if countdownCounter <= 0.0 then
            if not isCountingDown then break end -- Extra safeguard
            print("Countdown finished")
            isCountingDown = false
            LobbyService:SetOnSession(true)
        end
    end

    print("countingDown coroutine terminated")
end

local function checkStoppingCountdown()
    if not isCountingDown then return end
    if #playersOnCylinder >= MIN_PLAYERS then return end
    print("WARNING: not enough players while countdown is running, stopping countdown!")
    isCountingDown = false
end

local function checkStartingSession()
    if isCountingDown then return end
    if #playersOnCylinder < MIN_PLAYERS then return end
    print("Enough players on the cylinder. Starting session in " .. COUNTDOWN_TIME .. " seconds!")
    task.spawn(countingDown)
end

-- Handle Join Cylinder Touch Events
joinCylinder.Touched:Connect(function(hit)
    if isOnSession then return end

    local isTorso = hit.Name == "Torso" or hit.Name == "UpperTorso"
    if not isTorso then return end

    local character = hit.Parent
    local player = isPlayer(character)
    if player and not table.find(playersOnCylinder, player) then
        table.insert(playersOnCylinder, player)
        print(player.Name .. " entered the joinCylinder!")
    end

    checkStartingSession()
end)

joinCylinder.TouchEnded:Connect(function(hit)
    if isOnSession then return end

    local isTorso = hit.Name == "Torso" or hit.Name == "UpperTorso"
    if not isTorso then return end

    local character = hit.Parent
    local player = isPlayer(character)
    if player then
        for i, p in ipairs(playersOnCylinder) do
            if p == player then
                table.remove(playersOnCylinder, i)
                print(player.Name .. " exited the joinCylinder!")
                break
            end
        end
    end

    checkStoppingCountdown()
end)

-- Knit Lifecycle Methods
function LobbyService:KnitInit()
    UILobbyCountFunction.OnServerInvoke = function()
        return #playersOnCylinder
    end
end

function LobbyService:KnitStart()
    print("LobbyService started!")
end

return LobbyService
