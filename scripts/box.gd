@tool
class_name Box
extends Node3D

@export var active: bool = false:
	set(value):
		active = value
		_set_colour()

@export var _active_colour: Color = Color(1.0, 0.8, 0.0)
@export var _inactive_colour: Color = Color(0.498, 0.231, 0.0)
@export var colour_lerp_speed: float = 15.0

var _meshes: Array = []
var _materials: Array
var _colour: Color

func _ready() -> void:
	_meshes.push_back(find_children("CornerFacesMesh"))
	_meshes.push_back(find_children("CenterFacesMesh"))
	_materials = _meshes.map(_map_material)
	_set_colour()

func _process(delta: float) -> void:
	for material: StandardMaterial3D in _materials:
		material.emission = lerp(material.emission, _colour, colour_lerp_speed * delta)

func _map_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var material: StandardMaterial3D = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	return material

func _set_colour() -> void:
	if active:
		_colour = _active_colour
	else:
		_colour = _inactive_colour
