local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Head = Character:WaitForChild("Head")

-- Load functionalities ONCE at startup
local ExplodeondeathSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/Explodeondeath.lua"))
local PanicSmokeSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/LowHealthPanic.lua"))

local Explodeondeath = nil
local PanicSmoke = nil

-- Advanced executor workspace detection: Try candidates, pick FIRST with "GeneralSFX"
local function GetExecutorWorkspace()
    local candidates = {
        syn and syn.workspace,
        fluxus and fluxus.workspace,
        Krnl and Krnl.workspace,
        ScriptWare and ScriptWare.workspace,
        Electron and Electron.workspace,
        Valyse and Valyse.workspace,
        Solara and Solara.workspace,
        shared.Workspace,
        shared.workspace,
        getrenv().workspace,
        getgenv().workspace,
        _G.workspace,
        identifyexecutor and getrenv().workspace,
        getexecutorname and getrenv().workspace,
    }

    print("=== Scanning for Executor Workspace with GeneralSFX ===")
    for i, ws in ipairs(candidates) do
        if ws and ws:IsA("Workspace") then
            print("Candidate", i, "- Exists:", ws.Name or ws.ClassName)
            if ws:FindFirstChild("GeneralSFX") then
                print("🎉 FOUND ExecWS with GeneralSFX! (Candidate", i, ")")
                return ws
            end
        end
    end

    warn("❌ No ExecWS with GeneralSFX found. Place your sounds there!")
    print("Tip: Download GeneralSFX folder & put in your executor's sounds/workspace")
    return nil
end

local ExecWS = GetExecutorWorkspace()

-- Get all sounds in folder
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

local HurtSound = {}
local DeathSound = {}

-- Load sounds from GeneralSFX
local function LoadSounds()
    if not ExecWS then
        warn("No ExecWS - skipping sounds")
        return
    end

    local generalSFX = ExecWS:FindFirstChild("GeneralSFX")
    if not generalSFX then
        warn("GeneralSFX missing in ExecWS")
        return
    end
    print("✅ GeneralSFX found!")

    -- Hurt sounds
    local hurtFolder = generalSFX:FindFirstChild("Hurt")
    if hurtFolder then
        print("✅ Hurt folder found")
        -- Specific Hurt_1.mp3 etc.
        for i = 1, 3 do
            local soundName = "Hurt_" .. i .. ".mp3"
            local sound = hurtFolder:FindFirstChild(soundName)
            if sound then
                table.insert(HurtSound, sound)
            end
        end
        -- Fallback: all sounds
        if #HurtSound == 0 then
            HurtSound = GetSounds(hurtFolder)
            print("   Using all sounds in Hurt (fallback)")
        else
            print("   Specific Hurt sounds loaded:", #HurtSound)
        end
    else
        warn("Hurt folder missing")
    end

    -- Death sounds
    local deathFolder = generalSFX:FindFirstChild("Death")
    if deathFolder then
        DeathSound = GetSounds(deathFolder)
        print("✅ Death sounds loaded:", #DeathSound)
    else
        warn("Death folder missing")
    end
end

LoadSounds()

-- Play cloned sound (uses pick.SoundId = "rbxassetid://path/to/file.mp3")
local function PlayExecSound(soundList)
    if #soundList == 0 then return end

    local pick = soundList[math.random(1, #soundList)]
    local soundClone = Instance.new("Sound")
    soundClone.Name = "CustomSound"
    soundClone.SoundId = pick.SoundId  -- This is "rbxassetid://GeneralSFX/Hurt/Hurt_1.mp3" etc.
    soundClone.Volume = pick.Volume > 0 and pick.Volume or 0.5
    soundClone.Parent = Head

    soundClone.Ended:Connect(function()
        soundClone:Destroy()
    end)

    soundClone:Play()
    print("🔊 Played:", pick.Name, "| ID:", pick.SoundId)  -- Debug: remove later if spammy
end

-- Cooldowns & tracking
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

    -- Load & run Explode on Death (once)
    if ExplodeondeathSrc and not Explodeondeath then
        local success, func = pcall(ExplodeondeathSrc)
        if success and type(func) == "function" then
            Explodeondeath = func
            pcall(Explodeondeath)
        end
    elseif Explodeondeath then
        pcall(Explodeondeath)
    end
end

local function SetupPanicSmoke()
    if PanicSmokeSrc and not PanicSmoke then
        local success, func = pcall(PanicSmokeSrc)
        if success and type(func) == "function" then
            PanicSmoke = func
            print("PanicSmoke loaded (call manually or tie to low HP)")
        end
    end
end

-- Connection management to avoid duplicates
local Connections = {}

local function ConnectEvents()
    -- Clear old
    for _, conn in pairs(Connections) do
        if conn then conn:Disconnect() end
    end
    Connections = {}

    -- New
    table.insert(Connections, Humanoid.HealthChanged:Connect(OnHealthChanged))
    table.insert(Connections, Humanoid.Died:Connect(OnDied))
end

-- Initial setup
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
    LoadSounds()  -- Reload sounds if needed
end)

print("🎵 UN_Script Sounds Fixed & Loaded!")
print("Hurt:", #HurtSound, "| Death:", #DeathSound)
print("ExecWS:", ExecWS and ExecWS.Name or "NONE")
