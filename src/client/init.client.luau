local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KnitClient = require(ReplicatedStorage.Packages.Knit)
local Roact = require(ReplicatedStorage.Packages.Roact)
local Root
local RoduxHooks = require(ReplicatedStorage.Packages.roduxhooks)
local Store = require(StarterPlayer.StarterPlayerScripts.Client.Rodux.Store)

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))

-- Configurable, and you can choose multiple keys
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })

-- Controllers
for _, file in pairs(script.Controllers:GetChildren()) do
	require(file)
end

-- Init Components
local function _initComponents()
	for _, component in script.Components:GetDescendants() do
		if component:IsA("ModuleScript") then
			return component
		end
	end
end

--_initComponents()



-- Knit start
KnitClient.Start()
	:andThen(function()
		Root = require(StarterPlayer.StarterPlayerScripts.Client.Roact.Root.Application)
		print("Knit Client Successfully Started")
	end)
	:catch(warn)
	:await()

local synchronizationCallback = require(StarterPlayer.StarterPlayerScripts.Client.Modules.Synchronization)
synchronizationCallback()

Roact.mount(
	Roact.createElement(RoduxHooks.Provider, {
		store = Store,
	}, {
		GameScreenGui = Roact.createElement(Root.Game),
	}),
	Players.LocalPlayer.PlayerGui,
	"UI"
)
