local ReplicatedStorage = game.ReplicatedStorage

local common = ReplicatedStorage.Common
local types = require(common.types)

export type TemplateConfig = {
	center: boolean?,
	dampening: number?,
}
export type SceneBuilderConfig = {
	templates: { [number]: Model },
	speed: types.Speed,
	origin: CFrame,

	getTemplate: any,
}
export type SceneBuilder = {
	sceneNumber: number,
	_templates: { [number]: Model },
	_speed: types.Speed,
	_origin: CFrame,
	_running: boolean,
	_getTemplate: any,
	_thread: thread,
	_data: any,
	_templateCounter: number,
	_templateConfigs: { [number]: TemplateConfig },
	_idTracking: { front: { any }, back: { any }, center: any },
}

return nil
