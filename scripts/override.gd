@tool
class_name Override
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

var input1: Chain
var input2: Chain
var output: Chain

@onready var _box: Box = $Box
@onready var _chain_link_in1: ChainLink = $ChainLinkIn1
@onready var _chain_link_in2: ChainLink = $ChainLinkIn2
@onready var _chain_link_out: ChainLink = $ChainLinkOut
@onready var _override_light: Light = $OverrideLight

func _ready() -> void:
	_update_active()
	_update_lerp_speed()

func _update_active() -> void:
	_box.active = active
	_chain_link_in1.active = active
	_chain_link_in2.active = active
	_chain_link_out.active = active
	_override_light.active = active

func _update_lerp_speed() -> void:
	_box.colour_lerp_speed = _lerp_speed
	_chain_link_in1.colour_lerp_speed = _lerp_speed
	_chain_link_in2.colour_lerp_speed = _lerp_speed
	_chain_link_out.colour_lerp_speed = _lerp_speed
	_override_light.lerp_speed = _lerp_speed
