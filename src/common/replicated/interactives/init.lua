-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local client = Players.LocalPlayer
local mousey = client:GetMouse()

-- local common = ReplicatedStorage:WaitForChild("Common")
-- local mouse = require(common:WaitForChild("mouse"))

local defaultDistance = 6

local interactives = {}
for _, interactive in script:GetChildren() do
	interactives[interactive.Name] = require(interactive)
end

local function checkDistance(part: Instance, distance: number): boolean
	local character = client.Character
	if not character then
		return false
	end

	local pos = part.CFrame.Position
	local myPos = character:GetPivot().Position

	return (pos - myPos).Magnitude <= distance
end

local function checkTarget(part: Instance)
	if not part:GetAttribute("IsInteractive") then
		return
	end

	local interactiveName = part:GetAttribute("InteractiveType")
	if not interactiveName then
		return
	end

	local interactive = interactives[interactiveName]
	if not interactive then
		return
	end

	if interactive.check then
		if not interactive:check(part) then
			return
		end
	else
		local distance = part:GetAttribute("InteractiveDistance") or interactive.distance or defaultDistance
		if not checkDistance(part, distance) then
			return
		end
	end

	interactive.interact(part)
end

local function handleInput(_, state: Enum.UserInputState)
	if state == Enum.UserInputState.Begin then
		local hit = mousey.Target

		if hit then
			checkTarget(hit)
		end
	end

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	"Clicker",
	handleInput,
	false,
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.Touch
)

return nil
