local ReplicatedStorage = game:GetService("ReplicatedStorage")

local common = ReplicatedStorage:WaitForChild("Common")
local types = require(common.types)
local remotes = require(common:WaitForChild("remotes"))
local tweenClass = require(common:WaitForChild("tween"))

local sceneRemote = "scene"

local scenes = {}
local sceneParent = workspace

--

local tweens = {}
local function addTween(tween: any)
	table.insert(tweens, tween)
	task.delay(tween.duration, function()
		table.remove(tweens, table.find(tweens, tween))
	end)
end
local function updateTweens(dt: number)
	for _, tween in tweens do
		tween:update(dt)
	end
end

-- use for pooling later
local MAX_POOL_PER_TEMPLATE = 1
local availableTemplates: { [{ Model }]: { [number]: { Model } } } = {}

local function getNewTemplate(templates: { [number]: Model }, templateConfig: any): Model
	return templates[templateConfig[1]]:Clone()
end

local function getTemplate(templates: { [number]: Model }, templateConfig: any): Model
	local pool = availableTemplates[templates]
	if not pool then
		availableTemplates[templates] = { [templateConfig[1]] = {} }
		return getNewTemplate(templates, templateConfig)
	end

	local available = pool[templateConfig[1]]
	if available == nil then
		pool[templateConfig[1]] = {}
		available = pool[templateConfig[1]]
	end

	if #available == 0 then
		return getNewTemplate(templates, templateConfig)
	end

	-- get size test
	local size = 0
	for _, p in pairs(availableTemplates) do
		for _ = 1, #p do
			size += 1
		end
	end
	print("template pool size is: " .. tostring(size))

	return table.remove(available, 1)
end
local function destroyTemplate(templates: { [number]: Model }, model: Model, templateConfig: any)
	local pool = availableTemplates[templates]
	-- don't care checking for edge cases like pool being nil because getTemplate always creates it
	local available = pool[templateConfig[1]]

	if #available <= MAX_POOL_PER_TEMPLATE then
		table.insert(available, model)
		model.Parent = nil
		return
	end

	for k in pairs(templateConfig) do
		templateConfig[k] = nil
	end

	model:Destroy()
end

--

local function addFront(scene: types.Scene, templateConfig: any)
	local front = scene.created.front
	local previous = front[#front] or scene.created.center
	local target = previous[1]:GetPivot()

	local template = getTemplate(scene.templates, templateConfig)
	template.Name = "front"

	template.PrimaryPart = template:FindFirstChild("End") -- attaching back of this to front of previous
	template:PivotTo(target)

	template.Parent = sceneParent
	table.insert(scene.created.front, { template, templateConfig })
end

local function addBack(scene: types.Scene, templateConfig: any)
	local back = scene.created.back
	local previous = back[#back] or scene.created.center
	local target = previous[1]:FindFirstChild("End").CFrame

	local template = getTemplate(scene.templates, templateConfig)
	template.Name = "back"

	template:PivotTo(target)

	if templateConfig[3] and templateConfig[3].center then
		scene.centering = {
			id = templateConfig[2],
			slowingDistance = templateConfig[3].slowingDistance or 100,
		}
	end

	template.Parent = sceneParent
	table.insert(scene.created.back, { template, templateConfig })
end

local function destroyFirst(scene: types.Scene)
	local front = scene.created.front
	destroyTemplate(scene.templates, unpack(table.remove(front, #front)))
end

local function shiftTemplates(scene: types.Scene)
	local created = scene.created
	if #created.back == 0 then -- can't shift without a center
		return
	end

	table.insert(created.front, 1, created.center)
	created.center = created.back[1]
	-- created.center[1]:PivotTo(scene.origin) -- resync
	table.remove(created.back, 1)
end

local function getSceneTemplateById(scene: types.Scene, id: number)
	local all = { unpack(scene.created.front), scene.created.center, unpack(scene.created.back) }
	for _, sceneTemplate in all do
		if sceneTemplate[2] and sceneTemplate[2][2] == id then
			return sceneTemplate[1]
		end
	end
end

local function updateScene(scene: types.Scene, onCreate: boolean?)
	if onCreate then
		if scene.order.center == nil then
			return warn("huh no center?? how")
		end

		local center = getTemplate(scene.templates, scene.order.center)
		center:PivotTo(scene.origin)
		center.Parent = sceneParent
		scene.created.center = { center, scene.order.center }

		for _, id in scene.order.front do
			addFront(scene, id)
		end

		for _, id in scene.order.back do
			addBack(scene, id)
		end

		return
	end

	shiftTemplates(scene)
	destroyFirst(scene)
end

local function progressScene(scene: types.Scene, dt: number)
	local created = scene.created

	local center = created.center[1]
	local pivot = center:GetPivot()
	local cf = center:FindFirstChild("End").CFrame
	local dir = (pivot.Position - cf.Position).Unit

	local centering = scene.centering

	local speed = scene.speed._value

	if centering then
		--[[
			 speed *= centerPointOnScene / slowinDistance
		--]]
		local model: Model = getSceneTemplateById(scene, centering.id)
		if model then
			local front: Part, back: Part = model:FindFirstChild("Front"), model:FindFirstChild("End")
			local centerPoint = (front.Position + back.Position) / 2
			local distance = (centerPoint - scene.origin.Position).Magnitude
			-- print(centering)
			speed = distance / centering.slowingDistance * scene.speed._value
			if speed < 2 then
				speed = 0
			end
		end
	end

	local progress = dt * speed
	center:PivotTo(pivot + dir * progress)

	for i, current in created.back do
		local previous = created.back[i - 1] and created.back[i - 1][1] or center
		local target = previous:FindFirstChild("End").CFrame
		local model = current[1]

		model.PrimaryPart = model:FindFirstChild("Front")
		model:PivotTo(target)
	end

	for i, current in created.front do
		local previous = created.front[i - 1] and created.front[i - 1][1] or center
		local target = previous:FindFirstChild("Front").CFrame
		local model = current[1]

		model.PrimaryPart = model:FindFirstChild("End")
		model:PivotTo(target)
	end
end

--

local function establishScene(data)
	local scene: types.Scene = {
		origin = data.origin,
		order = data.order,
		templates = data.templates,
		speed = data.speed,
		created = { front = {}, back = {}, center = {} },
	}

	updateScene(scene, true)
	scenes[data.sceneNumber] = scene
end

local function addBackWrapped(sceneNumber: number, templateId: number)
	local scene = scenes[sceneNumber]
	if not scene then
		warn("no scene??")
		return
	end

	updateScene(scene, false)
	addBack(scene, templateId)
end

local function setSceneSpeed(sceneNumber: number, speed: types.Speed, fadeIn: number?)
	local scene = scenes[sceneNumber]
	if not scene then
		warn("no scene??")
		return
	end

	if scene.speed._value == speed._value and scene.speed._interval == speed._interval then
		return
	end

	if not fadeIn then
		scene.speed = speed
		return
	end

	scene.speed._interval = speed._interval
	addTween(tweenClass.new(fadeIn, scene.speed, { _value = speed._value }, "outQuad"))
end

local function release(sceneNumber: number, fadeTime: number)
	local scene = scenes[sceneNumber]
	if not scene then
		warn("no scene??")
		return
	end

	if not scene.centering then
		return
	end

	local originalSpeed = scene.speed._value
	scene.speed._value = 0
	scene.centering = nil
	addTween(tweenClass.new(fadeTime, scene.speed, { _value = originalSpeed }, "inQuad"))
end

remotes.listenEvent(sceneRemote, function(type, ...)
	if type == "establishScene" then
		establishScene(...)
	elseif type == "addBack" then
		addBackWrapped(...)
	elseif type == "setSceneSpeed" then
		setSceneSpeed(...)
	elseif type == "release" then
		release(...)
	end
end)

remotes.fireEvent(sceneRemote, "getScenes")

return function(dt: number)
	debug.profilebegin("scene movement")
	for _, scene in scenes do
		progressScene(scene, dt)
	end
	updateTweens(dt)
	debug.profileend()
end
