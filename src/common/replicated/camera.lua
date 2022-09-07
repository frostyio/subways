local BASE_SENS = 0.7
local SPRING_SPEED = 40
local BASE_TILT = 1

local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local imports = ReplicatedStorage:WaitForChild("Imports")
local spring = require(imports:WaitForChild("spring"))

local module = {}
module.__index = module
export type Camera = typeof(module.new())

local activeCameras: { Camera } = {}
local currentCamera: Camera? -- for input grabbing
local updateThread: thread

local function resumeUpdateThread()
	if coroutine.status(updateThread) == "suspended" then
		coroutine.resume(updateThread)
	end
end

local function lerp(a, b, c)
	return a + (b - a) * c
end

local function input(_, state: Enum.UserInputState, object: InputObject)
	if not currentCamera then
		return
	end

	local angle: Vector2 = currentCamera._angle
	local delta = object.Delta * BASE_SENS

	if state == Enum.UserInputState.Change then
		local minBound, maxBound = currentCamera._angleBounds[1], currentCamera._angleBounds[2]

		local x = (angle.X - delta.X)
		local y = math.clamp((angle.Y - delta.Y), minBound, maxBound)

		currentCamera._angle = Vector2.new(x, y)

		if currentCamera._root then
			local current = currentCamera._root.CFrame
			local xr, _, zr = current:ToEulerAnglesYXZ()
			currentCamera._root.CFrame = CFrame.new(current.Position) * CFrame.Angles(xr, math.rad(-x), zr)
		end
	end
end

local function captureFocus(_, state: Enum.UserInputState, _)
	if state == Enum.UserInputState.Begin then
		ContextActionService:BindAction(
			"Input",
			input,
			false,
			Enum.UserInputType.MouseMovement,
			Enum.UserInputType.Touch
		)
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		currentCamera._camera.CameraType = Enum.CameraType.Scriptable
	end
end

function module.new(subject: BasePart?): Camera
	local self = setmetatable({}, module)

	self._subject = subject
	self._running = false
	self._root = nil
	self._humanoid = nil
	self._offset = Vector3.new()
	self._angle = Vector2.new(0, 0)
	self._angleBounds = { -74, 74 }
	self._useUserInput = false
	self._camera = nil
	self._tilt = 0
	self._spring = spring.new(Vector2.new())
	self._spring.Damper = 0.9
	self._spring.Speed = SPRING_SPEED
	self._callback = nil

	return self
end

function module.setCallback(self: Camera, callback: any)
	self._callback = callback
end

function module.setOffset(self: Camera, offset: Vector3)
	self._offset = offset
end

function module.setCharacter(self: Camera, character: Model)
	self._root = character:WaitForChild("HumanoidRootPart") :: BasePart
	self._humanoid = character:WaitForChild("Humanoid") :: Humanoid

	self._humanoid.AutoRotate = false
end

function module.setSubject(self: Camera, subject: BasePart)
	self._subject = subject
end

function module.run(self: Camera, useUserInput: boolean?)
	if self._running then
		return warn("Camera is already running")
	end

	self._running = true
	self._camera = workspace.CurrentCamera
	self._camera.CameraType = Enum.CameraType.Scriptable

	table.insert(activeCameras, self)
	resumeUpdateThread()

	if useUserInput or self._useUserInput then
		ContextActionService:UnbindAction("FocusControl")

		currentCamera = self
		ContextActionService:BindAction(
			"FocusControl",
			captureFocus,
			false,
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.Touch,
			Enum.UserInputType.Focus
		)
	end
end

function module.useUserInput(self: Camera, bool: boolean)
	self._useUserInput = bool
end

function module.stop(self: Camera)
	if not self._running then
		return warn("Camera is not running")
	end

	self._running = false
	table.remove(activeCameras, table.find(activeCameras, self))
end

function module._update(self: Camera, _dt: number)
	local subject = self._subject
	local subjectCf = subject and subject.CFrame or CFrame.new()
	local angle = self._angle
	local offset = self._offset

	local d = UserInputService:GetMouseDelta()
	local x = (-d * ((BASE_TILT / 100) * BASE_SENS)).X
	self._tilt = lerp(self._tilt, x, 0.05)

	self._spring.Target = angle
	local newAngle = self._spring.Position

	local cf = CFrame.new(subjectCf.Position + offset)
		* CFrame.Angles(0, math.rad(newAngle.X), 0)
		* CFrame.Angles(math.rad(newAngle.Y), 0, 0)

	if self._callback then
		cf = self._callback(cf) or cf
	end

	self._camera.CFrame = cf * CFrame.Angles(0, 0, self._tilt)
end

updateThread = coroutine.create(function()
	while true do
		if #activeCameras == 0 then
			coroutine.yield()
		end

		local dt = RunService.RenderStepped:Wait()

		for _, camera in activeCameras do
			camera:_update(dt)
		end
	end
end)

return module :: Camera
