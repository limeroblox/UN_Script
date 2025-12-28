local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Head = Character:WaitForChild("Head")

-- Load functionalities (without executing them immediately)
local ExplodeondeathSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/Explodeondeath.lua"))
local PanicSmokeSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/LowHealthPanic.lua"))

-- Store the functions to call later
local Explodeondeath = nil
local PanicSmoke = nil

-- Helper to get executor workspace
local function GetExecutorWorkspace()
    -- Try different executor methods first
    if shared and shared.Workspace then
        return shared.Workspace
    elseif getexecutor and type(getexecutor) == "function" then
        local success, executor = pcall(getexecutor)
        if success and executor and executor.Workspace then
            return executor.Workspace
        end
    elseif _G and _G.ExecutorWorkspace then
        return _G.ExecutorWorkspace
    end
    
    -- Fallback to the game's workspace
    return game:GetService("Workspace")
end

local ExecWS = GetExecutorWorkspace()

-- Function to get all sounds in a folder
local function GetSounds(folder)
    local sounds = {}
    if folder and folder:IsA("Folder") then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Sound") then
                table.insert(sounds, child)
            end
        end
    end
    return sounds
end

-- Initialize sound tables
local HurtSound = {}
local DeathSound = {}

-- Safely load sounds
local function LoadSounds()
    -- Find GeneralSFX folder
    local generalSFX = ExecWS:FindFirstChild("GeneralSFX")
    if not generalSFX then
        warn("GeneralSFX folder not found in workspace")
        return
    end
    
    -- Load hurt sounds
    local hurtFolder = generalSFX:FindFirstChild("Hurt")
    if hurtFolder then
        -- Try to get specific hurt sounds
        for i = 1, 3 do
            local soundName = "Hurt_" .. i .. ".mp3"
            local sound = hurtFolder:FindFirstChild(soundName)
            if sound then
                table.insert(HurtSound, sound)
            end
        end
        
        -- If no specific sounds found, get all sounds in folder
        if #HurtSound == 0 then
            warn("No specific hurt sounds found, getting all sounds in Hurt folder")
            HurtSound = GetSounds(hurtFolder)
        end
    else
        warn("Hurt folder not found in GeneralSFX")
    end
    
    -- Load death sounds
    local deathFolder = generalSFX:FindFirstChild("Death")
    if deathFolder then
        DeathSound = GetSounds(deathFolder)
    else
        warn("Death folder not found in GeneralSFX")
    end
end

-- Call LoadSounds
LoadSounds()

-- Play a random sound from a table
local function PlayExecSound(soundList)
    if not soundList or #soundList == 0 then 
        return -- Silently return if no sounds
    end
    
    local pick = soundList[math.random(1, #soundList)]
    if pick and pick:IsA("Sound") then
        local soundClone = Instance.new("Sound")
        soundClone.SoundId = pick.SoundId
        soundClone.Volume = pick.Volume or 0.5
        soundClone.Parent = Head
        
        -- Handle sound ending
        soundClone.Ended:Connect(function()
            soundClone:Destroy()
        end)
        
        soundClone:Play()
    end
end

-- Cooldown system for hurt sounds
local hurtCooldown = 1
local lastHurtTime = 0
local lastHealth = Humanoid.Health

-- Health change handler
local function OnHealthChanged(health)
    local damage = lastHealth - health
    lastHealth = health
    
    -- Only process positive damage
    if damage > 0 then
        local now = tick()
        
        -- Check if damage is in range and cooldown has passed
        if damage >= 5 and damage <= 15 and (now - lastHurtTime) >= hurtCooldown then
            lastHurtTime = now
            PlayExecSound(HurtSound)
        end
    end
end

-- Death handler
local function OnDied()
    PlayExecSound(DeathSound)
    
    -- Initialize and execute Explodeondeath if available
    if ExplodeondeathSrc then
        local success, func = pcall(ExplodeondeathSrc)
        if success and type(func) == "function" then
            Explodeondeath = func
            local execSuccess, err = pcall(Explodeondeath)
            if not execSuccess then
                warn("Failed to execute Explodeondeath:", err)
            end
        end
    end
end

-- Initialize PanicSmoke on low health
local function SetupPanicSmoke()
    if PanicSmokeSrc then
        local success, func = pcall(PanicSmokeSrc)
        if success and type(func) == "function" then
            PanicSmoke = func
            -- You might want to call this when health is low
            -- For example: if Humanoid.Health < 30 then PanicSmoke() end
        end
    end
end

-- Connect events
Humanoid.HealthChanged:Connect(OnHealthChanged)
Humanoid.Died:Connect(OnDied)

-- Setup PanicSmoke (optional, call when needed)
SetupPanicSmoke()

-- Handle character respawns
LocalPlayer.CharacterAdded:Connect(function(newChar)
    -- Wait for character to load
    repeat
        newChar = LocalPlayer.Character
        task.wait()
    until newChar and newChar:FindFirstChild("Humanoid") and newChar:FindFirstChild("Head")
    
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    Head = Character:WaitForChild("Head")
    
    -- Reset health tracking
    lastHealth = Humanoid.Health
    lastHurtTime = 0
    
    -- Reconnect events
    Humanoid.HealthChanged:Connect(OnHealthChanged)
    Humanoid.Died:Connect(OnDied)
    
    -- Reload sounds for new character
    LoadSounds()
end)

-- Debug: Print loaded sound counts
print("Loaded Hurt Sounds:", #HurtSound)
print("Loaded Death Sounds:", #DeathSound)
