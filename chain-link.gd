class_name ChainLink
extends RigidBody3D

@export var _active_colour: Color = Color(1.0, 0.9, 0.0)

var _active: bool = false

@onready var _chain_link_mesh: MeshInstance3D = $ChainLinkMesh
@onready var _material: StandardMaterial3D = _chain_link_mesh.get_active_material(0).duplicate()
@onready var _inactive_light: OmniLight3D = $InactiveLight
@onready var _active_light: OmniLight3D = $ActiveLight

func _ready() -> void:
	_chain_link_mesh.set_surface_override_material(0, _material)

func set_active(active: bool) -> void:
	_active = active
	if _active:
		_material.emission = _active_colour
		_inactive_light.visible = false
		_active_light.visible = true
	else:
		_material.emission = Color.BLACK
		_inactive_light.visible = true
		_active_light.visible = false
