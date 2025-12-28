local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Head = Character:WaitForChild("Head")

-- Load functionalities
local Explodeondeath = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/Explodeondeath.lua"))()
local PanicSmoke = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/LowHealthPanic.lua"))()

-- Helper to get executor workspace - FIXED
local function GetExecutorWorkspace()
    -- Try different methods to get the workspace
    if shared and shared.Workspace then
        return shared.Workspace
    elseif getexecutor and type(getexecutor) == "function" then
        local executor = getexecutor()
        if executor and executor.Workspace then
            return executor.Workspace
        end
    elseif _G and _G.ExecutorWorkspace then
        return _G.ExecutorWorkspace
    else
        -- Fall back to game workspace
        return game:GetService("Workspace")
    end
end

local ExecWS = GetExecutorWorkspace()

-- Function to get all sounds in a folder - MOVED BEFORE USE
local function GetSounds(folder)
    local sounds = {}
    if folder then
        for _, s in pairs(folder:GetChildren()) do
            if s:IsA("Sound") then
                table.insert(sounds, s)
            end
        end
    end
    return sounds
end

-- Wait for folders and initialize sounds
local HurtSound = {}
local DeathSound = {}

-- Use pcall to handle potential errors
local success1, hurtFolder = pcall(function()
    return ExecWS:WaitForChild("GeneralSFX"):WaitForChild("Hurt")
end)

local success2, deathFolder = pcall(function()
    return ExecWS:WaitForChild("GeneralSFX"):WaitForChild("Death")
end)

if success1 and hurtFolder then
    -- Get specific hurt sounds
    for i = 1, 3 do
        local soundName = "Hurt_" .. i .. ".mp3"
        local sound = hurtFolder:FindFirstChild(soundName)
        if sound then
            table.insert(HurtSound, sound)
        end
    end
end

if success2 and deathFolder then
    DeathSound = GetSounds(deathFolder)
end

-- Play a random sound from a table
local function PlayExecSound(soundList)
    if #soundList == 0 then 
        warn("No sounds available in the list")
        return 
    end
    local pick = soundList[math.random(1, #soundList)]
    if pick then
        local s = Instance.new("Sound")
        s.SoundId = pick.SoundId
        s.Volume = pick.Volume or 1
        s.Parent = Head
        s:Play()
        game:GetService("Debris"):AddItem(s, s.TimeLength + 0.1)
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
    
    -- Only process if damage occurred
    if damage > 0 then
        local now = tick()
        if damage >= 5 and damage <= 15 and (now - lastHurtTime) >= hurtCooldown then
            lastHurtTime = now
            PlayExecSound(HurtSound)
        end
    end
end)

-- Death sound trigger
Humanoid.Died:Connect(function()
    PlayExecSound(DeathSound)
    
    -- Use pcall for safety with external scripts
    local success, err = pcall(function()
        Explodeondeath()
    end)
    
    if not success then
        warn("Failed to execute Explodeondeath:", err)
    end
end)

-- Reconnect when character respawns
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    Head = Character:WaitForChild("Head")
    lastHealth = Humanoid.Health
    lastHurtTime = 0
    
    -- Reconnect health changed event
    Humanoid.HealthChanged:Connect(function(health)
        local damage = lastHealth - health
        lastHealth = health
        
        if damage > 0 then
            local now = tick()
            if damage >= 5 and damage <= 15 and (now - lastHurtTime) >= hurtCooldown then
                lastHurtTime = now
                PlayExecSound(HurtSound)
            end
        end
    end)
    
    -- Reconnect death event
    Humanoid.Died:Connect(function()
        PlayExecSound(DeathSound)
        local success, err = pcall(function()
            Explodeondeath()
        end)
        if not success then
            warn("Failed to execute Explodeondeath:", err)
        end
    end)
end)
