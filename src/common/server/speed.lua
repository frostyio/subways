local ReplicatedStorage = game.ReplicatedStorage

local common = ReplicatedStorage.Common
local types = require(common.types)

local module = {}

do
	local seconds = {}

	function seconds.fromStuds(n: types.Studs): types.Speed
		return {
			_interval = 1,
			_value = n,
		}
	end

	module.seconds = seconds
end

return module