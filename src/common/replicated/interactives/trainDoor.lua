local DOOR_OPEN_TIME = 1.2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local common = ReplicatedStorage:WaitForChild("Common")
local tweenModule = require(common:WaitForChild("tween"))
local audiomodule = require(common:WaitForChild("audio"))

type Tween = {
	tween: any,
	callback: any,
}
local activeTweens: { Tween } = {}

local function updateTweens(dt: number)
	for i, tween in activeTweens do
		local tw, cb = tween.tween, tween.callback
		tw:update(dt)
		cb()

		if tw.clock >= tw.duration then
			table.remove(activeTweens, i)
		end
	end
end

local tweenThread = coroutine.create(function()
	while true do
		if #activeTweens == 0 then
			coroutine.yield()
		end

		local dt = RunService.RenderStepped:Wait()
		updateTweens(dt)
	end
end)

local function createTween(duration: number, subject: any, target: any, easing: string, callback: any)
	table.insert(activeTweens, {
		tween = tweenModule.new(duration, subject, target, easing),
		callback = callback,
	})
	if #activeTweens == 1 then
		coroutine.resume(tweenThread)
	end
end

type Door = {
	leftOrigin: CFrame,
	rightOrigin: CFrame,
	isTweening: boolean,
}

local openedDoors: { [Model]: Door } = {}

local function openDoor(leftHalf: Model, rightHalf: Model)
	local leftCf, rightCf = leftHalf:GetPivot(), rightHalf:GetPivot()
	local leftBounding, rightBounding = select(2, leftHalf:GetBoundingBox()), select(2, rightHalf:GetBoundingBox())

	local leftGoal, rightGoal = leftCf * CFrame.new(leftBounding.X, 0, 0), rightCf * CFrame.new(-rightBounding.X, 0, 0)
	local state = { value = 0 }

	audiomodule.playAudio("doors", true, 0.8)

	createTween(DOOR_OPEN_TIME, state, { value = 0.83 }, "linear", function()
		leftHalf:PivotTo(leftCf:Lerp(leftGoal, state.value))
		rightHalf:PivotTo(rightCf:Lerp(rightGoal, state.value))
	end)

	return leftCf, rightCf, DOOR_OPEN_TIME
end

local function closeDoor(door: Door, leftHalf: Model, rightHalf: Model)
	local leftCf, rightCf = leftHalf:GetPivot(), rightHalf:GetPivot()
	local leftO, rightO = door.leftOrigin, door.rightOrigin

	local state = { value = 0 }

	audiomodule.playAudio("doors", true, 0.8)

	createTween(DOOR_OPEN_TIME, state, { value = 1 }, "linear", function()
		leftHalf:PivotTo(leftCf:Lerp(leftO, state.value))
		rightHalf:PivotTo(rightCf:Lerp(rightO, state.value))
	end)

	return DOOR_OPEN_TIME
end

local function toggleDoor(doorModel: Model, leftHalf: Model, rightHalf: Model)
	local door = openedDoors[doorModel]
	if door and door.isTweening then
		return
	end

	if door == nil then -- if door is closed, open
		local l, r, delay = openDoor(leftHalf, rightHalf)
		openedDoors[doorModel] = {
			leftOrigin = l,
			rightOrigin = r,
			isTweening = true,
		}

		task.delay(delay, function()
			if openedDoors[doorModel] then
				openedDoors[doorModel].isTweening = false
			end
		end)
	else -- if door is open, close
		door.isTweening = true
		task.delay(closeDoor(door, leftHalf, rightHalf), function()
			openedDoors[doorModel] = nil
		end)
	end
end

local function interact(part: Instance)
	local door: Model = part.Parent
	local leftHalf: Model = door:FindFirstChild("DoorHalfLeft")
	local rightHalf: Model = door:FindFirstChild("DoorHalfRight")

	toggleDoor(door, leftHalf, rightHalf)
end

return {
	interact = interact,
}
