local ReplicatedStorage = game.ReplicatedStorage

local common = ReplicatedStorage.Common
local remotes = require(common.remotes)
local commonTypes = require(common.types)

local sceneRemote = remotes.createEvent("scene")

local PRELOAD = 6 -- load n scenes at a time

local types = require(script.Parent.types)
local speed = require(script.Parent.speed)

local module = {}
module.__index = module

local currentScenes: { [number]: types.SceneBuilder } = {}
local sceneNumber = 0

function module.new(config: types.SceneBuilderConfig): types.SceneBuilder
	assert(type(config) == "table", "No SceneBuilderConfig provided, please provide a config.")
	assert(config.templates, "No templates provided.")

	local self = setmetatable({}, module)

	-- replicate templates to the client
	do
		local sceneTemplates = Instance.new("Folder")
		for _, template in pairs(config.templates) do
			template.Parent = sceneTemplates
		end
		sceneTemplates.Parent = ReplicatedStorage
	end

	sceneNumber += 1
	self.sceneNumber = sceneNumber
	self._templateConfigs = {}
	self._templateCounter = 0
	self._templates = config.templates
	self._speed = config.speed or speed.seconds.fromStuds(100)
	self._origin = config.origin or CFrame.new()
	self._getTemplate = config.getTemplate or function()
		return 1
	end

	self._thread = coroutine.create(function()
		while true do
			if not self.running then
				coroutine.yield()
			end

			self:_step()
		end
	end)

	return self
end

function module.makeId(self: types.SceneBuilder): number
	self._templateCounter += 1
	return self._templateCounter
end

function module.makeTemplate(self: types.SceneBuilder): { any }
	local templateId, id = self:_getTemplate()
	id = id or self:makeId()

	local config = self._templateConfigs[id] or {}
	self._templateConfigs[id] = nil

	return { templateId, id, { center = config.center, slowingDistance = config.slowingDistance } }
end

function module._shiftTemplates(self: types.SceneBuilder)
	local tracking = self._idTracking
	if #tracking.back == 0 then -- can't shift without a center
		return
	end

	table.insert(tracking.front, 1, tracking.center)
	tracking.center = tracking.back[1]
	table.remove(tracking.back, 1)
end

function module._destroyFirst(self: types.SceneBuilder)
	local front = self._idTracking.front
	local first = #front
	table.remove(front, first)
end

function module._load(self: types.SceneBuilder): { any }
	local sceneOrder = { front = {}, back = {}, center = self:makeTemplate() }
	local last: number
	for i = 1, PRELOAD - 1 do
		local order = if i > (PRELOAD - 1) / 2 then sceneOrder.front else sceneOrder.back
		last = self:makeTemplate()
		table.insert(order, last)
	end
	self._idTracking = sceneOrder

	self._data = {
		sceneNumber = self.sceneNumber,
		templates = self._templates,
		speed = self._speed,
		origin = self._origin,
		order = sceneOrder,
	}

	return last
end

function module._updateData(self: types.SceneBuilder)
	self._data.order = self._idTracking
	self._data.speed = self._speed
end

function module.setSpeed(self: types.SceneBuilder, speedValue: commonTypes.Speed, fadeIn: number?)
	self._speed = speedValue
	remotes.fireAllEvent(sceneRemote, "setSceneSpeed", self.sceneNumber, self._speed, fadeIn)
end

function module._getSegmentSize(self: types.SceneBuilder, templateConfig: { any }): number
	return self._templates[templateConfig[1]]:GetAttribute("SegmentSize")
end

function module._calculateStepTime(self: types.SceneBuilder, templateConfig: { any }): number
	if self._speed._value == 0 then
		self.running = false
	end

	local size = self:_getSegmentSize(templateConfig)
	return (size * self._speed._interval) / self._speed._value
end

function module.run(self: types.SceneBuilder)
	local furthestBack = self:_load()
	table.insert(currentScenes, self)
	remotes.fireAllEvent(sceneRemote, "establishScene", self._data)

	self.running = true
	task.delay(self:_calculateStepTime(furthestBack), coroutine.resume, self._thread)
end

function module._addBack(self: types.SceneBuilder): any
	local next = self:makeTemplate()
	remotes.fireAllEvent(sceneRemote, "addBack", self.sceneNumber, next)
	table.insert(self._idTracking.back, next)
	return next
end

function module._step(self: types.SceneBuilder)
	local next = self:_addBack()
	self:_shiftTemplates()
	self:_destroyFirst()

	local center = self._idTracking.back[1]
	if center[3] and center[3].center then
		coroutine.yield()
	end

	task.wait(self:_calculateStepTime(next))
end

-- extra functions
function module.centerId(self: types.SceneBuilder, id: number, slowingDistance: number)
	local config = self._templateConfigs[id] or {}
	config.center, config.slowingDistance = true, slowingDistance
	self._templateConfigs[id] = config
end

function module.release(self: types.SceneBuilder, fadeTime: number)
	remotes.fireAllEvent(sceneRemote, "release", self.sceneNumber, fadeTime)
	coroutine.resume(self._thread)
end

remotes.listenEvent(sceneRemote, function(client: Player, type: string)
	if type == "getScenes" then
		for _, scene in currentScenes do
			scene:_updateData()
			remotes.fireEvent(sceneRemote, client, "establishScene", scene._data)
		end
	end
end)

return module
