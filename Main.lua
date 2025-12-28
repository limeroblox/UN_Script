local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Head = Character:WaitForChild("Head")

-- Load functionalities
local Explodeondeath = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/Explodeondeath.lua"))
local PanicSmoke     = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/LowHealthPanic.lua"))

-- Helper to get executor workspace
local function GetExecutorWorkspace()
    if shared and shared.Workspace then
        return shared.Workspace
    elseif getexecutor and getexecutor().Workspace then
        return getexecutor().Workspace
    elseif _G.ExecutorWorkspace then
        return _G.ExecutorWorkspace
    else
        error("Executor workspace not found!")
    end
end

local ExecWS = GetExecutorWorkspace()

-- Sound tables with exact paths
local HurtFolder = ExecWS:WaitForChild("GeneralSFX"):WaitForChild("Hurt")
local DeathFolder = ExecWS:WaitForChild("GeneralSFX"):WaitForChild("Death")

local HurtSound = {
    HurtFolder:WaitForChild("Hurt_1.mp3"),
    HurtFolder:WaitForChild("Hurt_2.mp3"),
    HurtFolder:WaitForChild("Hurt_3.mp3")
}

local DeathSound = GetSounds(DeathFolder) -- assumes all sounds in Death folder are used

-- Function to get all sounds in a folder
function GetSounds(folder)
    local sounds = {}
    for _, s in pairs(folder:GetChildren()) do
        if s:IsA("Sound") then
            table.insert(sounds, s)
        end
    end
    return sounds
end

-- Play a random sound from a table
local function PlayExecSound(soundList)
    if #soundList == 0 then return end
    local pick = soundList[math.random(1, #soundList)]
    if pick then
        local s = pick:Clone()
        s.Parent = Head
        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
    end
end

-- Cooldown for hurt sounds
local hurtCooldown = 1 -- seconds
local lastHurtTime = 0
local lastHealth = Humanoid.Health

-- Hurt sound trigger (only 5–15 damage and cooldown)
Humanoid.HealthChanged:Connect(function(health)
    local damage = lastHealth - health
    lastHealth = health
    local now = tick()
    if damage >= 5 and damage <= 15 and (now - lastHurtTime) >= hurtCooldown then
        lastHurtTime = now
        PlayExecSound(HurtSound)
    end
end)

-- Death sound trigger
Humanoid.Died:Connect(function()
    PlayExecSound(DeathSound)
    Explodeondeath()
end)
