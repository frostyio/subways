local ServerStorage = game.ServerStorage
local ReplicatedStorage = game.ReplicatedStorage

local resources = ReplicatedStorage.Resources
local flyByTrain = resources.FlyByTrain

local serverCommon = ServerStorage.Common
local sceneBuilder = require(serverCommon.sceneBuilder)
local speed = require(serverCommon.speed)
local train = require(serverCommon.train)
local types = require(serverCommon.types)

local function makeTemplate(model: Model): Model
	if not (model.PrimaryPart and model:FindFirstChild("Front") and model:FindFirstChild("End")) then
		return warn("invalid template, missing required...")
	end

	local template = model:Clone()
	model:Destroy()
	return template
end

local origin = workspace.Origin.CFrame
local trainSpawn = workspace.TrainSpawn.CFrame

local templatesFolder = workspace.Scenes
local templates = {}

local function addTemplate(name: string)
	table.insert(templates, makeTemplate(templatesFolder:FindFirstChild(name)))
end

addTemplate("Tunnel")
addTemplate("Station")

local startTime = tick()
local hasSpawnedStation = false

math.randomseed(tick())
local s = sceneBuilder.new({
	templates = templates,
	speed = speed.seconds.fromStuds(75),
	origin = origin,

	getTemplate = function(scene: types.SceneBuilder)
		local id = scene:makeId()
		local value = 1

		if tick() - startTime > 30 and hasSpawnedStation == false then
			value = 2
			scene:centerId(id, 250)
			hasSpawnedStation = true
			task.delay(17, function()
				scene:release(10)
				startTime = tick()
				hasSpawnedStation = false
			end)
		end

		return value, id
	end,
})

if not game:GetService("RunService"):IsStudio() then
	game.Players.PlayerAdded:Connect(function(plr)
		plr.Chatted:Connect(function(msg)
			if msg:sub(1, 6) == "/start" then
				startTime = tick()
				s:run()
			end
		end)
	end)
else
	s:run()
end

local trainSpawner = train.new({
	speed = speed.seconds.fromStuds(140),
	origin = trainSpawn,
	time = 5,
	model = flyByTrain,
})

-- local lastTrain = tick()
-- local TRAIN_COOLDOWN = 1 --60

while true do
	task.wait(30)
	print("running train loop")

	-- if math.random(1, 10) <= 11 and tick() - lastTrain < TRAIN_COOLDOWN then
	-- lastTrain = tick()
	trainSpawner:spawn()
	print("spawning train")
	-- end
end
