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

-- For Delta iOS, workspace is usually accessed normally
-- But sometimes sound assets need to be loaded from game's Workspace or ReplicatedStorage
local ExecWS = nil

-- Try different locations for Delta iOS
-- Delta often uses the regular workspace or ReplicatedStorage for sounds
local function FindSoundFolders()
    -- Check regular workspace first
    local workspaceSFX = workspace:FindFirstChild("GeneralSFX")
    if workspaceSFX then
        print("Found GeneralSFX in workspace")
        return workspace
    end
    
    -- Check ReplicatedStorage
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local rsSFX = replicatedStorage:FindFirstChild("GeneralSFX")
    if rsSFX then
        print("Found GeneralSFX in ReplicatedStorage")
        return replicatedStorage
    end
    
    -- Check SoundService
    local soundService = game:GetService("SoundService")
    local ssSFX = soundService:FindFirstChild("GeneralSFX")
    if ssSFX then
        print("Found GeneralSFX in SoundService")
        return soundService
    end
    
    -- Check ServerStorage
    local serverStorage = game:GetService("ServerStorage")
    local serverSFX = serverStorage:FindFirstChild("GeneralSFX")
    if serverSFX then
        print("Found GeneralSFX in ServerStorage")
        return serverStorage
    end
    
    -- Last resort: check all services
    print("Searching all services for GeneralSFX...")
    for _, service in pairs(game:GetChildren()) do
        if service:IsA("DataModel") or service:IsA("Workspace") or service:IsA("ReplicatedStorage") or service:IsA("SoundService") then
            local sfx = service:FindFirstChild("GeneralSFX")
            if sfx then
                print("Found GeneralSFX in", service.Name)
                return service
            end
        end
    end
    
    -- Default to workspace
    print("GeneralSFX not found, defaulting to workspace")
    return workspace
end

ExecWS = FindSoundFolders()
print("Using sound source:", ExecWS:GetFullName())

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

-- Safely load sounds with Delta iOS compatibility
local function LoadSounds()
    -- Find GeneralSFX folder
    local generalSFX = ExecWS:FindFirstChild("GeneralSFX")
    if not generalSFX then
        warn("❌ GeneralSFX folder not found in", ExecWS:GetFullName())
        
        -- Try to create a simple test to see where sounds might be
        print("🔍 Searching for any sound folders...")
        for _, child in ipairs(ExecWS:GetDescendants()) do
            if child:IsA("Sound") then
                print("Found a sound:", child:GetFullName())
            elseif child:IsA("Folder") and (child.Name:find("Hurt") or child.Name:find("hurt") or child.Name:find("Death") or child.Name:find("death")) then
                print("Found potential sound folder:", child:GetFullName())
            end
        end
        return
    end
    
    -- Load hurt sounds
    local hurtFolder = generalSFX:FindFirstChild("Hurt")
    if hurtFolder then
        -- Try to get specific hurt sounds
        local foundAny = false
        for i = 1, 3 do
            local soundName = "Hurt_" .. i .. ".mp3"
            local sound = hurtFolder:FindFirstChild(soundName)
            if sound then
                table.insert(HurtSound, sound)
                foundAny = true
                print("✓ Loaded hurt sound:", soundName)
            else
                -- Try without .mp3 extension
                soundName = "Hurt_" .. i
                sound = hurtFolder:FindFirstChild(soundName)
                if sound and sound:IsA("Sound") then
                    table.insert(HurtSound, sound)
                    foundAny = true
                    print("✓ Loaded hurt sound:", soundName)
                end
            end
        end
        
        -- If no specific sounds found, get all sounds in folder
        if #HurtSound == 0 then
            print("⚠ No specific hurt sounds found, getting all sounds in Hurt folder")
            HurtSound = GetSounds(hurtFolder)
        end
    else
        warn("❌ Hurt folder not found in GeneralSFX")
        -- Check if hurt sounds are directly in GeneralSFX
        for _, child in ipairs(generalSFX:GetChildren()) do
            if child:IsA("Sound") and child.Name:lower():find("hurt") then
                table.insert(HurtSound, child)
                print("✓ Found hurt sound in GeneralSFX:", child.Name)
            end
        end
    end
    
    -- Load death sounds
    local deathFolder = generalSFX:FindFirstChild("Death")
    if deathFolder then
        DeathSound = GetSounds(deathFolder)
        print("✓ Loaded", #DeathSound, "death sounds from Death folder")
    else
        warn("❌ Death folder not found in GeneralSFX")
        -- Check if death sounds are directly in GeneralSFX
        for _, child in ipairs(generalSFX:GetChildren()) do
            if child:IsA("Sound") and child.Name:lower():find("death") then
                table.insert(DeathSound, child)
                print("✓ Found death sound in GeneralSFX:", child.Name)
            end
        end
    end
    
    print("✅ Loaded", #HurtSound, "hurt sounds and", #DeathSound, "death sounds")
end

-- Call LoadSounds
LoadSounds()

-- Play a random sound from a table (Delta iOS compatible)
local function PlayExecSound(soundList)
    if not soundList or #soundList == 0 then 
        warn("⚠ No sounds available to play")
        return
    end
    
    local pick = soundList[math.random(1, #soundList)]
    if pick and pick:IsA("Sound") then
        -- For Delta iOS, we need to handle sounds carefully
        local soundClone = Instance.new("Sound")
        soundClone.SoundId = pick.SoundId
        soundClone.Volume = pick.Volume or 0.5
        soundClone.PlaybackSpeed = pick.PlaybackSpeed or 1
        soundClone.Parent = Head
        
        -- Delta iOS might have issues with sound ending events
        soundClone.Ended:Connect(function()
            task.wait(0.1) -- Small delay for stability
            if soundClone then
                soundClone:Destroy()
            end
        end)
        
        -- Handle if sound fails to play
        soundClone.PlayOnRemove = false
        
        -- Try to play with error handling
        local success, err = pcall(function()
            soundClone:Play()
        end)
        
        if not success then
            warn("❌ Failed to play sound:", err)
            soundClone:Destroy()
        else
            print("🔊 Playing sound:", pick.Name)
        end
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
            print("💥 Executing Explodeondeath...")
            local execSuccess, err = pcall(Explodeondeath)
            if not execSuccess then
                warn("❌ Failed to execute Explodeondeath:", err)
            end
        else
            warn("❌ Failed to load Explodeondeath function")
        end
    else
        warn("❌ ExplodeondeathSrc not loaded")
    end
end

-- Initialize PanicSmoke on low health
local function SetupPanicSmoke()
    if PanicSmokeSrc then
        local success, func = pcall(PanicSmokeSrc)
        if success and type(func) == "function" then
            PanicSmoke = func
            print("💨 PanicSmoke loaded")
            
            -- Monitor health for low health trigger
            local lowHealthTriggered = false
            Humanoid.HealthChanged:Connect(function(health)
                if health < 30 and health > 0 and not lowHealthTriggered then
                    lowHealthTriggered = true
                    print("🚨 Low health detected, triggering PanicSmoke...")
                    local smokeSuccess, smokeErr = pcall(PanicSmoke)
                    if not smokeSuccess then
                        warn("❌ PanicSmoke error:", smokeErr)
                    end
                    
                    -- Reset after some time
                    task.wait(10)
                    lowHealthTriggered = false
                elseif health >= 30 then
                    lowHealthTriggered = false
                end
            end)
        else
            warn("❌ Failed to load PanicSmoke function")
        end
    else
        warn("❌ PanicSmokeSrc not loaded")
    end
end

-- Connect events
Humanoid.HealthChanged:Connect(OnHealthChanged)
Humanoid.Died:Connect(OnDied)

-- Setup PanicSmoke
SetupPanicSmoke()

-- Handle character respawns
local respawnConnection
respawnConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
    -- Disconnect old connection to prevent duplicates
    if respawnConnection then
        respawnConnection:Disconnect()
    end
    
    task.wait(0.5) -- Wait for character to fully load
    
    if newChar and newChar:FindFirstChild("Humanoid") and newChar:FindFirstChild("Head") then
        Character = newChar
        Humanoid = Character:WaitForChild("Humanoid")
        Head = Character:WaitForChild("Head")
        
        -- Reset health tracking
        lastHealth = Humanoid.Health
        lastHurtTime = 0
        
        print("🔄 Character respawned, reconnecting events...")
        
        -- Reconnect events
        Humanoid.HealthChanged:Connect(OnHealthChanged)
        Humanoid.Died:Connect(OnDied)
        
        -- Reload sounds (in case workspace changed)
        LoadSounds()
    end
    
    -- Re-establish connection for next respawn
    respawnConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        -- Recursive call with delay
        task.wait(0.5)
        if char and char:FindFirstChild("Humanoid") then
            respawnConnection:Disconnect()
            LoadSounds()
            Humanoid = char:WaitForChild("Humanoid")
            Head = char:WaitForChild("Head")
            lastHealth = Humanoid.Health
            lastHurtTime = 0
        end
    end)
end)

-- Delta iOS specific: Add a manual sound test command
local function AddTestCommand()
    -- Create a simple test function that can be called from console
    _G.TestSounds = function()
        print("🔊 Testing sound system...")
        print("Hurt sounds available:", #HurtSound)
        print("Death sounds available:", #DeathSound)
        
        if #HurtSound > 0 then
            print("Playing test hurt sound...")
            PlayExecSound(HurtSound)
        else
            print("❌ No hurt sounds available")
        end
        
        task.wait(1)
        
        if #DeathSound > 0 then
            print("Playing test death sound...")
            PlayExecSound(DeathSound)
        else
            print("❌ No death sounds available")
        end
    end
    
    print("✅ Sound system loaded!")
    print("📝 Type '_G.TestSounds()' in console to test sounds")
end

AddTestCommand()

-- Optional: Create a simple UI indicator
if syn and syn.protect_gui then
    local ScreenGui = Instance.new("ScreenGui")
    if syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
    ScreenGui.Parent = game:GetService("CoreGui")
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Text = "🔊 Sound System Active"
    TextLabel.Size = UDim2.new(0, 200, 0, 30)
    TextLabel.Position = UDim2.new(0, 10, 0, 10)
    TextLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Parent = ScreenGui
    
    task.wait(5)
    TextLabel:Destroy()
    task.wait(1)
    ScreenGui:Destroy()
end
