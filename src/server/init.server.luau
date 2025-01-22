local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Knit = require(ReplicatedStorage.Packages.Knit)
local Cmdr = require(ReplicatedStorage.Packages.cmdr)

-- Services
for _, file in pairs(script.Services:GetChildren()) do
	require(file)
end

Cmdr:RegisterDefaultCommands()

Knit.Start()
    :andThen(function()

        print("[SERVER] Server started successfully")
    end)
    :catch(warn)
    :await()
