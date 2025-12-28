local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Torso = Character:FindFirstChild("Torso")

if not Torso then 
    warn("Torso Not Detected")
    return
end

-- container
local Holder = Instance.new("Folder")
Holder.Name = "BeepAttachmentHolder"
Holder.Parent = Character

-- attachment
local Attach = Instance.new("Attachment")
Attach.Name = "BeepAttach"
Attach.Parent = Torso

-- PARTICLES
local Lights = Instance.new("ParticleEmitter")
Lights.Name = "Lights"
Lights.Parent = Attach
Lights.Enabled = false
Lights.Speed = NumberRange.new(0, 0)
Lights.Rotation = NumberRange.new(0, 90)
Lights.Color = ColorSequence.new(Color3.fromRGB(255,58,58), Color3.fromRGB(255,0,0))
Lights.LightEmission = 1
Lights.Texture = "rbxassetid://8855082601"
Lights.Size = NumberSequence.new(1.47, 10)
Lights.Brightness = 50
Lights.Drag = 5
Lights.Lifetime = NumberRange.new(0.25)
Lights.Rate = 5

local Initial = Lights:Clone()
Initial.Name = "Initial"
Initial.Brightness = 100
Initial.Lifetime = NumberRange.new(0.2)
Initial.Parent = Attach

-- SOUNDS
local Beep = Instance.new("Sound")
Beep.Name = "Beep"
Beep.Parent = Attach
Beep.SoundId = "rbxassetid://7112390347"
Beep.Looped = true
Beep.Volume = 2
Beep.RollOffMinDistance = 650
Beep.PlaybackSpeed = 7.5

local Explosion = Instance.new("Sound")
Explosion.Name = "Explosion"
Explosion.Parent = Attach
Explosion.SoundId = "rbxassetid://577577319"
Explosion.RollOffMinDistance = 100
Explosion.RollOffMaxDistance = 650

local Distort = Instance.new("DistortionSoundEffect")
Distort.Level = 0.5
Distort.Parent = Explosion

-- SEQUENCE
task.spawn(function()
    -- initial flash
    Initial:Emit(10)
    Lights.Enabled = true
    Beep:Play()

    -- ramp up beep speed
    for i = 1, 10 do
        Beep.PlaybackSpeed += 0.05
        task.wait(0.1)
    end

    task.wait(5)

    -- stop particles
    Lights.Enabled = false
    Initial.Enabled = false

    -- explosion
    Beep:Stop()
    Explosion:Play()
    Attach:Destroy()
end)
