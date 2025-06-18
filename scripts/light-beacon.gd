@tool
class_name LightBeacon
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

var input: Chain

@onready var _box: Box = $Box
@onready var _chain_link_static: ChainLink = $ChainLinkStatic
@onready var _light_beacon_light: Light = $LightBeaconLight

func _ready() -> void:
	_update_active()
	_update_lerp_speed()

func _update_active() -> void:
	_box.active = active
	_chain_link_static.active = active
	_light_beacon_light.active = active

func _update_lerp_speed() -> void:
	_box.colour_lerp_speed = _lerp_speed
	_chain_link_static.colour_lerp_speed = _lerp_speed
	_light_beacon_light.lerp_speed = _lerp_speed
