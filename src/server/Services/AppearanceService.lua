local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HelperModule = require(ReplicatedStorage:WaitForChild("HelperModule"))

local SPECTATOR_TRANSPARENCY = 0.9

local AppearanceService = Knit.CreateService {
    Name = "AppearanceService", -- Service name
}

-- Constructor equivalent for services
function AppearanceService:KnitInit()
    self.OriginalProperties = {} -- Store original properties for each player
    self.IsSpectator = {} -- Keep track of which players are spectators
end

-- Store the player's original properties for resetting later
function AppearanceService:StoreOriginalProperties(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local originalProperties = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalProperties[part] = {
                Transparency = part.Transparency,
                CanCollide = part.CanCollide,
                CanTouch = part.CanTouch,
            }
        elseif part:IsA("Decal") or part:IsA("SurfaceGui") then
            originalProperties[part] = {
                Transparency = part.Transparency,
            }
        end
    end
    self.OriginalProperties[player] = originalProperties
end

-- Apply Spectator Mode
function AppearanceService:SetSpectatorMode(player)
    if self.IsSpectator[player] then return end
    local character = player.Character or player.CharacterAdded:Wait()
    self:StoreOriginalProperties(player)

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = SPECTATOR_TRANSPARENCY
            part.CanCollide = false
            part.CanTouch = false
        elseif part:IsA("Decal") or part:IsA("SurfaceGui") then
            part.Transparency = SPECTATOR_TRANSPARENCY
        end
    end

    self.IsSpectator[player] = true
    print(player.Name .. " is now a spectator.")
end

-- Revert Spectator Mode
function AppearanceService:RevertSpectatorMode(player)
    if not self.IsSpectator[player] then return end
    local character = player.Character or player.CharacterAdded:Wait()

    for _, part in pairs(character:GetDescendants()) do
        local original = self.OriginalProperties[player][part]
        if original then
            if part:IsA("BasePart") then
                part.Transparency = original.Transparency
                part.CanCollide = original.CanCollide
                part.CanTouch = original.CanTouch
            elseif part:IsA("Decal") or part:IsA("SurfaceGui") then
                part.Transparency = original.Transparency
            end
        end
    end

    self.OriginalProperties[player] = nil -- Clear stored properties
    self.IsSpectator[player] = false
    print(player.Name .. " is no longer a spectator.")
end

-- Activate Service for a Session
function AppearanceService:ActivateSession(player)
    self:StoreOriginalProperties(player)
    print("AppearanceService activated for " .. player.Name)
end

-- Deactivate Service
function AppearanceService:DeactivateSession(player)
    self.OriginalProperties[player] = nil
    self.IsSpectator[player] = false
    print("AppearanceService deactivated for " .. player.Name)
end

-- Listen to player leaving the game to reset their appearance
function AppearanceService:KnitStart()
    game.Players.PlayerRemoving:Connect(function(player)
        self:RevertSpectatorMode(player)
    end)
end

return AppearanceService
