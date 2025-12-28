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

-- Try to get executor workspace using exploit-specific methods
local ExecWS = nil

-- Method 1: Check if exploit provides direct access
if getexecutorname and type(getexecutorname) == "function" then
    -- For exploits that expose executor workspace in global environment
    if syn and syn.get_thread_identity then
        local old_identity = syn.get_thread_identity()
        syn.set_thread_identity(7) -- Set to script identity for access
        ExecWS = workspace
        syn.set_thread_identity(old_identity)
    elseif get_hidden_gui then
        -- Some exploits like Script-Ware
        ExecWS = get_hidden_gui():FindFirstAncestorWhichIsA("Workspace")
    end
end

-- Method 2: Check common exploit global variables
if not ExecWS then
    if _G.__EXECUTOR and _G.__EXECUTOR.Workspace then
        ExecWS = _G.__EXECUTOR.Workspace
    elseif shared and shared.workspace then
        ExecWS = shared.workspace
    elseif _G.Workspace then
        ExecWS = _G.Workspace
    end
end

-- Method 3: Try to find it through CoreGui or other containers
if not ExecWS then
    local success, result = pcall(function()
        return game:GetService("CoreGui"):FindFirstChild("ExecutorWorkspace") or 
               game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("ExecutorWorkspace")
    end)
    if success and result then
        ExecWS = result
    end
end

-- Method 4: Last resort - check all possible parent objects
if not ExecWS then
    warn("Executor workspace not found, checking all possible locations...")
    
    -- Check if there's a special workspace created by the executor
    for _, obj in pairs(game:GetDescendants()) do
        if obj.Name == "ExecutorWorkspace" or obj.Name == "ScriptWorkspace" then
            ExecWS = obj
            break
        end
    end
end

-- Fallback to game workspace if executor workspace not found
ExecWS = ExecWS or workspace

print("Using workspace:", ExecWS:GetFullName())

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
        warn("GeneralSFX folder not found in", ExecWS:GetFullName())
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
    
    print("Loaded", #HurtSound, "hurt sounds and", #DeathSound, "death sounds")
end

-- Call LoadSounds
LoadSounds()

-- Play a random sound from a table
local function PlayExecSound(soundList)
    if not soundList or #soundList == 0 then 
        return
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
            -- You can call this when needed
            Humanoid.HealthChanged:Connect(function(health)
                if health < 30 and health > 0 then
                    local success, err = pcall(PanicSmoke)
                    if not success then
                        warn("PanicSmoke error:", err)
                    end
                end
            end)
        end
    end
end

-- Connect events
Humanoid.HealthChanged:Connect(OnHealthChanged)
Humanoid.Died:Connect(OnDied)

-- Setup PanicSmoke
SetupPanicSmoke()

-- Handle character respawns
LocalPlayer.CharacterAdded:Connect(function(newChar)
    -- Wait for character to load
    repeat
        task.wait(0.1)
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

-- Debug menu (optional - remove if not needed)
local function CreateDebugMenu()
    if ExecWS ~= workspace then
        print("=== DEBUG INFO ===")
        print("Executor Workspace:", ExecWS:GetFullName())
        print("Hurt Sounds Loaded:", #HurtSound)
        print("Death Sounds Loaded:", #DeathSound)
        print("==================")
    end
end

CreateDebugMenu()
