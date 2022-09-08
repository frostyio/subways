local userInputService = game:GetService("UserInputService")

local camera = workspace.CurrentCamera
local defaultDistance = 999

local mouse = {}

local function GetResult(length: number?, params: RaycastParams?): RaycastResult
	local pos = userInputService:GetMouseLocation()
	local unit = camera:ViewportPointToRay(pos.X, pos.Y)
	local dir = unit.Direction * (length or defaultDistance)
	return workspace:Raycast(unit.Origin, dir, params), unit, dir, pos
end

function mouse:GetTarget(length: number?, params: RaycastParams?): BasePart?
	local result = GetResult(length, params)

	if result then
		return result.Instance
	end
end

function mouse:GetHit(length: number?, params: RaycastParams?): CFrame
	local result, unit, dir = GetResult(length, params)

	if result then
		return CFrame.new(result.Position, unit.Direction)
	else
		return CFrame.new(unit.Origin + dir, unit.Direction)
	end
end

return mouse
