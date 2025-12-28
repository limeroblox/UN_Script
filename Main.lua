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

-- Improved executor workspace detection (NO fallback to game.Workspace)
local function GetExecutorWorkspace()
    -- Common executor identifiers
    if identifyexecutor then
        return getrenv().workspace or shared.workspace or nil
    end
    if getexecutorname then
        return getrenv().workspace or shared.workspace or nil
    end
    if syn and syn.request then  -- Synapse
        return shared.Workspace or shared.workspace or nil
    end
    if fluxus and fluxus.request then  -- Fluxus
        return shared.Workspace or shared.workspace or nil
    end
    if Krnl then  -- Krnl
        return shared.Workspace or nil
    end
    if getgc then  -- Generic fallback for many
        return shared.Workspace or shared.workspace or nil
    end

    warn("No executor workspace detected. Sound loading will be skipped.")
    return nil
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

-- Safely load sounds (only if executor workspace exists)
local function LoadSounds()
    if not ExecWS then
        warn("Executor workspace not available - skipping sound load")
        return
    end

    local generalSFX = ExecWS:FindFirstChild("GeneralSFX")
    if not generalSFX then
        warn("GeneralSFX folder not found in executor workspace")
        return
    end

    -- Load hurt sounds
    local hurtFolder = generalSFX:FindFirstChild("Hurt")
    if hurtFolder then
        for i = 1, 3 do
            local soundName = "Hurt_" .. i .. ".mp3"
            local sound = hurtFolder:FindFirstChild(soundName)
            if sound and sound:IsA("Sound") then
                table.insert(HurtSound, sound)
            end
        end

        if #HurtSound == 0 then
            warn("No specific hurt sounds found, falling back to all sounds in Hurt folder")
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

LoadSounds()

-- Play a random sound from a table (cloned to Head for spatial/local playback)
local function PlayExecSound(soundList)
    if not soundList or #soundList == 0 then
        return
    end

    local pick = soundList[math.random(1, #soundList)]
    if pick and pick:IsA("Sound") then
        local soundClone = Instance.new("Sound")
        soundClone.Name = "CustomSound"
        soundClone.SoundId = pick.SoundId
        soundClone.Volume = pick.Volume > 0 and pick.Volume or 0.5
        soundClone.Parent = Head

        soundClone.Ended:Connect(function()
            soundClone:Destroy()
        end)

        soundClone:Play()
    end
end

-- Cooldown for hurt sounds
local hurtCooldown = 1
local lastHurtTime = 0
local lastHealth = Humanoid.Health

local function OnHealthChanged(health)
    local damage = lastHealth - health
    lastHealth = health

    if damage >= 5 and damage <= 15 then
        local now = tick()
        if now - lastHurtTime >= hurtCooldown then
            lastHurtTime = now
            PlayExecSound(HurtSound)
        end
    end
end

local function OnDied()
    PlayExecSound(DeathSound)

    if ExplodeondeathSrc then
        local success, func = pcall(ExplodeondeathSrc)
        if success and type(func) == "function" then
            Explodeondeath = func
            pcall(Explodeondeath)
        else
            warn("Failed to load/run Explodeondeath")
        end
    end
end

local function SetupPanicSmoke()
    if PanicSmokeSrc then
        local success, func = pcall(PanicSmokeSrc)
        if success and type(func) == "function" then
            PanicSmoke = func
            -- Call it here or tie to health if desired
        end
    end
end

-- Initial connections
Humanoid.HealthChanged:Connect(OnHealthChanged)
Humanoid.Died:Connect(OnDied)
SetupPanicSmoke()

-- Handle respawns properly
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    Head = newChar:WaitForChild("Head")

    lastHealth = Humanoid.Health
    lastHurtTime = 0

    -- Reconnect events (disconnect old if needed, but simple reconnect is fine)
    Humanoid.HealthChanged:Connect(OnHealthChanged)
    Humanoid.Died:Connect(OnDied)

    -- Reload sounds in case executor workspace changed/reloaded
    LoadSounds()
end)

-- Debug output
print("Loaded Hurt Sounds:", #HurtSound)
print("Loaded Death Sounds:", #DeathSound)
print("Using executor workspace:", ExecWS ~= nil)
