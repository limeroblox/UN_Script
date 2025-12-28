local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Head = Character:WaitForChild("Head")

-- Load external functionalities
local ExplodeSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/Explodeondeath.lua"))
local PanicSrc = loadstring(game:HttpGet("https://raw.githubusercontent.com/limeroblox/UN_Script/refs/heads/main/Functionalities/LowHealthPanic.lua"))

-- ================ CONFIG ================
local HURT_FOLDER = "GeneralSFX/Hurt"
local DEATH_FOLDER = "GeneralSFX/Death"
local HURT_VOLUME = 1
local DEATH_VOLUME = 1
local TEMP_PREFIX = "TempSound_"

-- Asset maker detection
local assetMaker = getsynasset or getcustomasset or get_custom_asset or get_synasset or getsyn
if not assetMaker then
    warn("❌ No asset maker found! Custom MP3s won't work.")
end

-- Cache for loaded assets
local LoadedHurtAssets = {}
local LoadedDeathAssets = {}

-- ================ FILE SYSTEM FUNCTIONS ================
local function GetAllMp3s(folderPath)
    local mp3s = {}
    if not isfolder(folderPath) then
        makefolder(folderPath)
        warn("Created folder:", folderPath, "— put your .mp3 files there!")
        return mp3s
    end

    local files = listfiles(folderPath)
    for _, fullPath in ipairs(files) do
        local filename = fullPath:match("[\\/]([^\\/]+)$")
        if filename and filename:lower():match("%.mp3$") then
            table.insert(mp3s, fullPath)
            print("Found:", fullPath)
        end
    end
    return mp3s
end

local function LoadMp3Asset(filePath)
    if LoadedHurtAssets[filePath] or LoadedDeathAssets[filePath] then
        return LoadedHurtAssets[filePath] or LoadedDeathAssets[filePath]
    end

    local success, data = pcall(readfile, filePath)
    if not success then
        warn("Failed to read:", filePath)
        return nil
    end

    local tempName = TEMP_PREFIX .. tick() .. ".mp3"
    pcall(writefile, tempName, data)

    local assetId = nil
    for _, tryPath in ipairs({tempName, filePath}) do
        local ok, res = pcall(assetMaker, tryPath)
        if ok and res then
            assetId = res
            break
        end
    end

    pcall(delfile, tempName)  -- Cleanup

    if assetId then
        if filePath:find(HURT_FOLDER) then
            LoadedHurtAssets[filePath] = assetId
        elseif filePath:find(DEATH_FOLDER) then
            LoadedDeathAssets[filePath] = assetId
        end
        print("✅ Loaded:", filePath, "→", assetId)
    else
        warn("Failed to create asset for:", filePath)
    end

    return assetId
end

-- ================ LOAD ALL SOUNDS ================
print("🔍 Scanning for sounds...")

local hurtFiles = GetAllMp3s(HURT_FOLDER)
local deathFiles = GetAllMp3s(DEATH_FOLDER)

-- Preload hurt sounds
for _, filePath in ipairs(hurtFiles) do
    LoadMp3Asset(filePath)
end

-- Preload death sounds
for _, filePath in ipairs(deathFiles) do
    LoadMp3Asset(filePath)
end

-- Working asset lists
local WorkingHurtIds = {}
local WorkingDeathIds = {}

for _, id in pairs(LoadedHurtAssets) do
    table.insert(WorkingHurtIds, id)
end
for _, id in pairs(LoadedDeathAssets) do
    table.insert(WorkingDeathIds, id)
end

print("✅ Hurt sounds ready:", #WorkingHurtIds)
print("✅ Death sounds ready:", #WorkingDeathIds)

-- ================ PLAY FUNCTIONS ================
local function PlaySound(soundList, volume)
    if #soundList == 0 then return end

    local chosen = soundList[math.random(1, #soundList)]
    local sound = Instance.new("Sound")
    sound.SoundId = chosen
    sound.Volume = volume or 0.6
    sound.Parent = Head

    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    sound:Play()
end

-- ================ HEALTH/DEATH LOGIC ================
local lastHealth = Humanoid.Health
local hurtCooldown = 0.5  -- Faster cooldown
local lastHurtTime = 0

local function OnHealthChanged(health)
    local damage = lastHealth - health
    lastHealth = health
    
    if damage > 0 then  -- ANY damage triggers
        local now = tick()
        if now - lastHurtTime >= hurtCooldown then
            lastHurtTime = now
            PlaySound(WorkingHurtIds, HURT_VOLUME)
        end
    end
end

local function OnDied()
    PlaySound(WorkingDeathIds, DEATH_VOLUME)
    
    if ExplodeSrc then
        local success, func = pcall(ExplodeSrc)
        if success and type(func) == "function" then
            pcall(func)
        end
    end
end

-- ================ CONNECTION MANAGEMENT ================
local Connections = {}

local function ConnectEvents()
    for _, c in pairs(Connections) do
        if c then pcall(function() c:Disconnect() end) end
    end
    Connections = {}
    
    table.insert(Connections, Humanoid.HealthChanged:Connect(OnHealthChanged))
    table.insert(Connections, Humanoid.Died:Connect(OnDied))
end

ConnectEvents()

local function SetupPanicSmoke()
    if PanicSrc then
        local success, func = pcall(PanicSrc)
        if success and type(func) == "function" then
            pcall(func)  -- Execute immediately
        end
    end
end

SetupPanicSmoke()

-- ================ RESPAWN HANDLER ================
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    Head = newChar:WaitForChild("Head")
    
    lastHealth = Humanoid.Health
    lastHurtTime = 0
    
    ConnectEvents()
end)

print("🎵 UN_Script Sound System ACTIVE!")
print("📁 Folders:", HURT_FOLDER, "and", DEATH_FOLDER)
print("🔊 Hurt:", #WorkingHurtIds, "| Death:", #WorkingDeathIds)
print("✅ Plays on ANY damage + death explosion!")
