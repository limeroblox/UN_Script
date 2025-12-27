-- Converted with ttyyuu12345's model to script plugin v4

local function sandbox(var, func)
	local env = getfenv(func)
	local newenv = setmetatable({}, {
		__index = function(_, k)
			if k == "script" then
				return var
			end
			return env[k]
		end,
	})
	setfenv(func, newenv)
	return func
end

local cors = {}
local mas = Instance.new("Model", game:GetService("Workspace"))

-- Part
local Part0 = Instance.new("Part")
Part0.Name = "SmokePanicLow"
Part0.Parent = mas
Part0.Size = Vector3.new(25, 25, 25)
Part0.Transparency = 1
Part0.Anchored = true
Part0.CanCollide = false
Part0.CanQuery = false
Part0.CanTouch = false
Part0.TopSurface = Enum.SurfaceType.Smooth
Part0.BottomSurface = Enum.SurfaceType.Smooth
-- Particle (black smoke)
local ParticleEmitter1 = Instance.new("ParticleEmitter")
ParticleEmitter1.Name = "particle2"
ParticleEmitter1.Parent = Part0
ParticleEmitter1.Enabled = false
ParticleEmitter1.Texture = "rbxassetid://8581391856"
ParticleEmitter1.Color = ColorSequence.new(Color3.new(0, 0, 0))
ParticleEmitter1.Size = NumberSequence.new(20)
ParticleEmitter1.Transparency = NumberSequence.new(0, 1, 0.988, 0)
ParticleEmitter1.Lifetime = NumberRange.new(1.5)
ParticleEmitter1.Rate = 100
ParticleEmitter1.Drag = 2
ParticleEmitter1.Speed = NumberRange.new(0)
ParticleEmitter1.Rotation = NumberRange.new(-50, 50)
ParticleEmitter1.RotSpeed = NumberRange.new(-30, 30)
ParticleEmitter1.SpreadAngle = Vector2.new(10, 10)
ParticleEmitter1.VelocityInheritance = 1
ParticleEmitter1.VelocitySpread = 10

-- Particle (red panic)
local ParticleEmitter2 = Instance.new("ParticleEmitter")
ParticleEmitter2.Name = "particle1"
ParticleEmitter2.Parent = Part0
ParticleEmitter2.Enabled = false
ParticleEmitter2.Texture = "rbxassetid://8581391856"
ParticleEmitter2.Color = ColorSequence.new(Color3.new(1, 0, 0))
ParticleEmitter2.Size = NumberSequence.new(10)
ParticleEmitter2.Transparency = NumberSequence.new(0, 0.988, 0)
ParticleEmitter2.Lifetime = NumberRange.new(0.1, 5)
ParticleEmitter2.Rate = 5
ParticleEmitter2.Brightness = 100
ParticleEmitter2.ZOffset = -1
ParticleEmitter2.Drag = 2
ParticleEmitter2.Speed = NumberRange.new(0)
ParticleEmitter2.Rotation = NumberRange.new(-50, 50)
ParticleEmitter2.RotSpeed = NumberRange.new(-30, 30)
ParticleEmitter2.SpreadAngle = Vector2.new(10, 10)
ParticleEmitter2.VelocityInheritance = 1
ParticleEmitter2.VelocitySpread = 10
ParrticleEmitter2.Squash = NumberSequence.new(3, -1.13, -3)

-- Sound
local Sound3 = Instance.new("Sound")
Sound3.Name = "SmokeEffect"
Sound3.Parent = Part0
Sound3.SoundId = "rbxassetid://4962360929"
Sound3.Volume = 4
Sound3.RollOffMaxDistance = 650
Sound3.RollOffMinDistance = 100
Sound3.RollOffMode = Enum.RollOffMode.InverseTapered

Instance.new("DistortionSoundEffect", Sound3)

-- Script
local Script5 = Instance.new("Script")
Script5.Parent = Part0

table.insert(cors, sandbox(Script5, function()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local torso = character:WaitForChild("Torso") -- R6

	local part = script.Parent
	local sound = part.SmokeEffect
	local particles = { part.particle1, part.particle2 }

	-- Spawn at torso (burst-style)
	part.CFrame = torso.CFrame

	sound:Play()

	for _, p in ipairs(particles) do
		p.Enabled = true
	end

	sound.Ended:Wait()

	for _, p in ipairs(particles) do
		p.Enabled = false
	end

	task.wait(5)
	part:Destroy()
end))

-- Move to workspace and run
for _, v in ipairs(mas:GetChildren()) do
	v.Parent = workspace
	pcall(function()
		v:MakeJoints()
	end)
end

mas:Destroy()

for _, fn in ipairs(cors) do
	task.spawn(function()
		pcall(fn)
	end)
end
