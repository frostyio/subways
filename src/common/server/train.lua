local ReplicatedStorage = game.ReplicatedStorage

local common = ReplicatedStorage.Common
local commonTypes = require(common.types)
local remotes = require(common.remotes)

local trainEvent = remotes.createEvent("train")

local speed = require(script.Parent.speed)

local module = {}
module.__index = module

type Config = {
	origin: CFrame,
	speed: commonTypes.Speed,
	model: Model,
	time: number,
}

function module.new(config: Config)
	local self: commonTypes.Train = setmetatable({}, module)

	self._origin = config.origin or CFrame.new()
	self._speed = config.speed or speed.seconds.fromStuds(100)
	self._model = config.model
	self._time = config.time

	return self
end

function module.spawn(self: commonTypes.Train)
	remotes.fireAllEvent(trainEvent, self) -- lmao
end

return module