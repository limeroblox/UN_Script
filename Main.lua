local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Head = Character:WaitForChild("Head")

-- Load external functionalities
local ExplodeSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/Explodeondeath.lua"))
local PanicSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/LowHealthPanic.lua"))

-- Tables for loaded sounds
local HurtSounds = {}
local DeathSounds = {}

-- Advanced executor workspace detection
local function GetExecutorWorkspace()
    local candidates = {
        syn and syn.workspace,
        fluxus and fluxus.workspace,
        Krnl and Krnl.workspace,
        ScriptWare and ScriptWare.workspace,
        Solara and Solara.workspace,
        shared.Workspace,
        shared.workspace,
        getrenv().workspace,
        _G.workspace,
    }

    for _, ws in ipairs(candidates) do
        if ws and ws:IsA("Instance") then
            local testFolder = ws:FindFirstChild("GeneralSoundEffects")
            if testFolder then
                print("✅ Found Executor Workspace with GeneralSoundEffects:", ws:GetFullName())
                return ws
            end
        end
    end

    warn("❌ No executor workspace with 'GeneralSoundEffects' found. Create the folder and put Hurt/Death subfolders with .mp3 sounds inside!")
    return nil
end

local ExecWS = GetExecutorWorkspace()

-- Load ALL .mp3 sounds from a folder
local function LoadAllMp3Sounds(folder)
    local sounds = {}
    if folder and folder:IsA("Folder") then
        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Sound") and string.match(obj.Name:lower(), "%.mp3$") then
                table.insert(sounds, obj)
                print("   Loaded:", obj.Name, "| ID:", obj.SoundId)
            end
        end
    end
    return sounds
end

-- Load sounds from GeneralSoundEffects/Hurt and /Death
local function LoadCustomSounds()
    HurtSounds = {}
    DeathSounds = {}

    if not ExecWS then return end

    local mainFolder = ExecWS:FindFirstChild("GeneralSoundEffects")
    if not mainFolder then
        warn("GeneralSoundEffects folder not found!")
        return
    end

    -- Hurt folder
    local hurtFolder = mainFolder:FindFirstChild("Hurt")
    if hurtFolder then
        HurtSounds = LoadAllMp3Sounds(hurtFolder)
        print("✅ Loaded", #HurtSounds, "hurt sound(s)")
    else
        warn("Hurt folder not found inside GeneralSoundEffects")
    end

    -- Death folder
    local deathFolder = mainFolder:FindFirstChild("Death")
    if deathFolder then
        DeathSounds = LoadAllMp3Sounds(deathFolder)
        print("✅ Loaded", #DeathSounds, "death sound(s)")
    else
        warn("Death folder not found inside GeneralSoundEffects")
    end
end

LoadCustomSounds()

-- Play random sound (clones it using the path-based SoundId like rbxassetid://path/to/file.mp3)
local function PlaySound(soundList)
    if #soundList == 0 then return end

    local pick = soundList[math.random(1, #soundList)]
    local clone = Instance.new("Sound")
    clone.SoundId = pick.SoundId  -- This is your rbxassetid://path/to/yourfile.mp3
    clone.Volume = pick.Volume > 0 and pick.Volume or 0.6
    clone.Parent = Head

    clone.Ended:Connect(function()
        clone:Destroy()
    end)

    clone:Play()
end

-- Health/death logic
local lastHealth = Humanoid.Health
local hurtCooldown = 1
local lastHurtTime = 0

local function OnHealthChanged(health)
    local damage = lastHealth - health
    lastHealth = health

    if damage >= 5 and damage <= 15 then
        local now = tick()
        if now - lastHurtTime >= hurtCooldown then
            lastHurtTime = now
            PlaySound(HurtSounds)
        end
    end
end

local function OnDied()
    PlaySound(DeathSounds)

    if ExplodeSrc then
        local success, func = pcall(ExplodeSrc)
        if success and type(func) == "function" then
            pcall(func)
        end
    end
end

local function SetupPanicSmoke()
    if PanicSrc then
        local success, func = pcall(PanicSrc)
        if success and type(func) == "function" then
            -- Call it here or on low health if you want
        end
    end
end

-- Connection management
local Connections = {}
local function ConnectEvents()
    for _, c in pairs(Connections) do c:Disconnect() end
    Connections = {}

    table.insert(Connections, Humanoid.HealthChanged:Connect(OnHealthChanged))
    table.insert(Connections, Humanoid.Died:Connect(OnDied))
end

ConnectEvents()
SetupPanicSmoke()

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    Head = newChar:WaitForChild("Head")

    lastHealth = Humanoid.Health
    lastHurtTime = 0

    ConnectEvents()
    LoadCustomSounds()  -- Reload in case you added new sounds
end)

print("🎵 Custom Sound System Ready!")
print("Put your .mp3 files in executor workspace → GeneralSoundEffects → Hurt or Death")
print("Current Hurt sounds:", #HurtSounds)
print("Current Death sounds:", #DeathSounds)
