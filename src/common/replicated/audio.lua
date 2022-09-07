local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local resources = ReplicatedStorage:WaitForChild("Resources")
local sounds = resources:WaitForChild("Sounds")

local client = Players.LocalPlayer
local clientGui = client:WaitForChild("PlayerGui")

local function playAudio(name: string, deleteOnFinish: boolean?, fadeAt: number?): Sound
	local sound = sounds:FindFirstChild(name)
	if not sound then
		return warn(name, "was not found in sounds.")
	end

	local clone: Sound = sound:Clone()
	clone.Parent = clientGui
	clone:Play()

	if deleteOnFinish then
		-- should clean up the connection on destroy
		clone.Ended:Connect(function() 
			clone:Destroy()
		end)
	end

	if fadeAt then
		local remaining = (1 - fadeAt) * clone.TimeLength
		local startAt = fadeAt * clone.TimeLength
		task.delay(startAt, function() 
			TweenService:Create(clone, TweenInfo.new(remaining, Enum.EasingStyle.Linear), { Volume = 0 }):Play()
		end)
	end

	return sound
end

local module = {}
module.playAudio = playAudio

return module