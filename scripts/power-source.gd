@tool
class_name PowerSource
extends StaticBody3D

@export var active: bool = false:
	set(value):
		active = value
		if _box:
			_update_active()

@export var _lerp_speed: float = 15.0:
	set(value):
		_lerp_speed = value
		_update_lerp_speed()

@onready var _box: Box = $Box
@onready var _box_light: BoxLight = $BoxLight
@onready var _chain_link_static: ChainLink = $ChainLinkStatic
@onready var _power_source_light: PowerSourceLight = $PowerSourceLight

func _ready() -> void:
	_update_active()
	_update_lerp_speed()

func _update_active() -> void:
	_box.active = active
	_box_light.active = active
	_chain_link_static.active = active
	_power_source_light.active = active

func _update_lerp_speed() -> void:
	_box.colour_lerp_speed = _lerp_speed
	_box_light.colour_lerp_speed = _lerp_speed
	_chain_link_static.colour_lerp_speed = _lerp_speed
	_power_source_light.lerp_speed = _lerp_speed

func select_handler(interacting: bool) -> void:
	if interacting:
		active = !active
		# spawn and/or attract characters if active
		# transfer state
