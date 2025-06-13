@tool
class_name ChainLink
extends Node3D

@export var active: bool = false:
	set(value):
		active = value
		if _chain_link_resource:
			_set_colour()

@export var _active_colour: Color = Color(1.0, 0.8, 0.0)
@export var _inactive_colour: Color = Color(0.498, 0.231, 0.0)

@export var colour_lerp_speed: float = 15.0:
	set(value):
		colour_lerp_speed = value
		_update_lerp_speed()

@onready var _chain_link_resource: ChainLinkResource = %ChainLinkResource

func _ready() -> void:
	_set_colour()
	_update_lerp_speed()

func _set_colour() -> void:
	if active:
		_chain_link_resource.emission_colour = _active_colour
	else:
		_chain_link_resource.emission_colour = _inactive_colour

func _update_lerp_speed() -> void:
	_chain_link_resource.emission_lerp_speed = colour_lerp_speed
