local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local client = Players.LocalPlayer

local common = ReplicatedStorage:WaitForChild("Common")
local imports = ReplicatedStorage:WaitForChild("Imports")
local audio = require(common:WaitForChild("audio"))
local cameraShaker = require(imports:WaitForChild("camerashaker"))
local CameraShakeInstance = cameraShaker.CameraShakeInstance

do
	-- custom camera
	local springModule = require(imports:WaitForChild("spring"))
	local cameraModule = require(common:WaitForChild("camera"))

	local currentHumanoid: Humanoid
	local camera = cameraModule.new()
	camera:setOffset(Vector3.new(0, 2, 0))

	local shakeOffset = CFrame.new()
	local trainShake = CameraShakeInstance.new(0.1, 10, 2, 2)
	trainShake.PositionInfluence = Vector3.new(0, 0.15, 0)
	trainShake.RotationInfluence = Vector3.new(1.25, 0, 4)
	local shaker = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(shake: CFrame)
		shakeOffset = shake
	end)
	shaker:Start()
	shaker:ShakeSustain(trainShake)

	-- bobbing
	local spring = springModule.new(0)
	spring.Speed = 20

	camera:setCallback(function(cf)
		if not currentHumanoid then
			return
		end

		if currentHumanoid.MoveDirection.Magnitude == 0 then
			spring.Target = 0
		else
			spring.Target = math.sin(tick() * 13) * 0.15
		end

		return (cf + Vector3.new(0, spring.Position)) * shakeOffset
	end)

	camera:run(true)

	-- to make better later
	local function addCharacter(character: Model)
		camera:setCharacter(character)
		camera:setSubject(character:WaitForChild("HumanoidRootPart"))
		currentHumanoid = character:WaitForChild("Humanoid")
	end
	client.CharacterAdded:Connect(addCharacter)
	if client.Character then
		addCharacter(client.Character)
	end
end

-- local Lighting = game.Lighting
-- do
-- 	local properties = {
-- 		Ambient = Color3.fromRGB(0, 0, 0),
-- 		ClockTime = 0,
-- 		FogColor = Color3.fromRGB(0, 0, 0),
-- 		FogEnd = 100,
-- 	}

-- 	for prop, val in properties do
-- 		Lighting[prop] = val
-- 	end
-- end

audio.playAudio("TrainAmbient")

local sceneTick = require(common:WaitForChild("scene"))
local trainTick = require(common:WaitForChild("train"))

RunService.RenderStepped:Connect(function(dt: number)
	sceneTick(dt)
	trainTick(dt)
end)
