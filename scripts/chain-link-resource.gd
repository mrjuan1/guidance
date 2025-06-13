@tool
class_name ChainLinkResource
extends Node3D

@export var emission_enabled: bool = false:
	set(value):
		emission_enabled = value
		if material:
			_update_emission_state()

@export var emission_colour: Color
@export var emission_lerp_speed: float = 15.0

@onready var _mesh: MeshInstance3D = $ChainLinkMesh
@onready var material: StandardMaterial3D = _mesh.get_active_material(0).duplicate()

func _ready() -> void:
	_mesh.set_surface_override_material(0, material)
	_update_emission_state()

func _process(delta: float) -> void:
	if emission_enabled:
		material.emission = material.emission.lerp(emission_colour, emission_lerp_speed * delta)

func _update_emission_state() -> void:
	material.emission_enabled = emission_enabled
