@tool
class_name ChainPin
extends StaticBody3D

@export var active: bool = false:
	set(value):
		active = value
		if _chain_pin_model:
			_update_active()

@export var _lerp_speed: float = 15.0:
	set(value):
		_lerp_speed = value
		_update_lerp_speed()

@export var _active_colour: Color = Color(1.0, 0.8, 0.0)
@export var _inactive_colour: Color = Color(0.498, 0.231, 0.0)

var _colour: Color

var input: Chain
var outputs: Array[Chain] = []

@onready var _chain_pin_model: Node3D = $ChainPinModel
@onready var _chain_pin_mesh: MeshInstance3D = _chain_pin_model.find_child("ChainPinMesh")
@onready var _chain_pin_material: StandardMaterial3D = _chain_pin_mesh.get_active_material(0).duplicate()
@onready var _chain_pin_light: Light = $ChainPinLight

func _ready() -> void:
	_chain_pin_mesh.set_surface_override_material(0, _chain_pin_material)
	_update_active()
	_update_lerp_speed()

func _process(delta: float) -> void:
	_chain_pin_material.emission = _chain_pin_material.emission.lerp(_colour, _lerp_speed * delta)

func _update_active() -> void:
	if active:
		_colour = _active_colour
	else:
		_colour = _inactive_colour

	_chain_pin_light.active = active

func _update_lerp_speed() -> void:
	_chain_pin_light.lerp_speed = _lerp_speed

func select_handler(interacting: bool) -> void:
	if interacting:
		ChainPlacement.start(self)
	else:
		queue_free()
