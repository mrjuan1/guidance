@tool
class_name BoxLight
extends Node3D

@export var active: bool = false:
	set(value):
		active = value
		_set_colour()

@export var _active_colour: Color = Color(0.0, 1.0, 0.0)
@export var _inactive_colour: Color = Color(1.0, 0.0, 0.0)
@export var colour_lerp_speed: float = 15.0

var _colour: Color

@onready var _mesh: MeshInstance3D = $LightMesh
@onready var _material: StandardMaterial3D = _mesh.get_active_material(0).duplicate()

func _ready() -> void:
	_mesh.set_surface_override_material(0, _material)
	_set_colour()

func _process(delta: float) -> void:
	_material.emission = lerp(_material.emission, _colour, colour_lerp_speed * delta)

func _set_colour() -> void:
	if active:
		_colour = _active_colour
	else:
		_colour = _inactive_colour
