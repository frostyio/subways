local ReplicatedStorage = game:GetService("ReplicatedStorage")

local common = ReplicatedStorage:WaitForChild("Common")
local audio = require(common:WaitForChild("audio"))
local types = require(common.types)
local remotes = require(common:WaitForChild("remotes"))
local trainRemote = "train"

local trainParent = workspace
local trains: { [number]: types.Train } = {}

local function spawnTrain(train: types.Train)
	local clone = train._model:Clone()
	clone:PivotTo(train._origin)
	clone.Parent = trainParent
	train._model = clone
	table.insert(trains, train)
	audio.playAudio("Flange", true, 0.8)
	task.delay(0.8, function()
		-- shaker:Shake(trainPassShake)
		-- print("shaking")
	end)
	task.delay(train._time, function()
		local index = table.find(trains, train)
		train._model = nil
		for k in pairs(trains) do
			trains[k] = nil
		end
		table.remove(trains, index)
		clone:Destroy()
	end)
end

local function prepTrain(train: types.Train)
	audio.playAudio("Horn", true)
	task.wait(0.9)
	spawnTrain(train)
end

remotes.listenEvent(trainRemote, function(train: types.Train)
	prepTrain(train)
end)

return function(dt)
	debug.profilebegin("train movement")
	for _, train: types.Train in trains do
		local model: Model = train._model
		local cf = model:GetPivot()

		local progress = dt * train._speed._value
		train._model:PivotTo(cf + train._origin.LookVector * progress)
	end
	debug.profileend()
end
