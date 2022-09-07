export type Studs = number
export type Speed = {
	_interval: number,
	_value: number,
}
export type Scene = {
	origin: CFrame,
	order: any, -- like order but with numbers instead, cba to add generics
	templates: { [number]: Model },
	speed: Speed,
	created: any,
	centering: {
		id: number,
		slowingDistance: number,
	}?,
}
export type Train = {
	_origin: CFrame,
	_speed: Speed,
	_model: Model,
	_time: number,
}

return nil
