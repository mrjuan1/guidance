@tool
class_name PowerSourceLight
extends OmniLight3D

@export var active: bool = false:
	set(value):
		active = value
		_set_colour()

@export var lerp_speed: float = 15.0

@export_group("Active")
@export var _active_colour: Color = Color(1.0, 0.8, 0.0)
@export var _active_range: float = 5.0
@export var _active_shadow_opacity: float = 1.0

@export_group("Inactive")
@export var _inactive_colour: Color = Color(0.498, 0.231, 0.0)
@export var _inactive_range: float = 1.5
@export var _inactive_shadow_opacity: float = 0.0

var _colour: Color
var _range: float
var _shadow_opacity: float

func _ready() -> void:
	_set_colour()

func _process(delta: float) -> void:
	var scaled_lerp_speed: float = lerp_speed * delta
	light_color = lerp(light_color, _colour, scaled_lerp_speed)
	omni_range = lerpf(omni_range, _range, scaled_lerp_speed)
	shadow_opacity = lerpf(shadow_opacity, _shadow_opacity, scaled_lerp_speed)

func _set_colour() -> void:
	if active:
		_colour = _active_colour
		_range = _active_range
		_shadow_opacity = _active_shadow_opacity
	else:
		_colour = _inactive_colour
		_range = _inactive_range
		_shadow_opacity = _inactive_shadow_opacity
