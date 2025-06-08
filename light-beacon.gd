class_name LightBeacon
extends StaticBody3D

@onready var _inactive_face_colour: Color = Color(0.26, 0.108, 0.0)
@onready var _active_face_colour: Color = Color(1.0, 0.9, 0.0)

var _active: bool = false
var input_chain: Chain

@onready var _faces_mesh: MeshInstance3D = $BoxFaces
@onready var _faces_material: StandardMaterial3D = _faces_mesh.get_active_material(0).duplicate()
@onready var _chain_link_mesh: MeshInstance3D = %ChainLinkMesh
@onready var _link_material: StandardMaterial3D = _chain_link_mesh.get_active_material(0).duplicate()
@onready var _inactive_light: OmniLight3D = $InactiveLight
@onready var _active_light: OmniLight3D = $ActiveLight

func _ready() -> void:
	_faces_mesh.set_surface_override_material(0, _faces_material)
	_chain_link_mesh.set_surface_override_material(0, _link_material)

func interact(interacting: bool) -> void:
	if not interacting:
		unlink()

func set_active(active: bool) -> void:
	_active = active
	if _active:
		_faces_material.emission = _active_face_colour
		_link_material.emission = _active_face_colour
		_inactive_light.visible = false
		_active_light.visible = true
		_attract_characters()
	else:
		_faces_material.emission = _inactive_face_colour
		_link_material.emission = _inactive_face_colour
		_inactive_light.visible = true
		_active_light.visible = false
		_repel_characters()

func _on_light_beacon_in_input_selected(interacting: bool) -> void:
	interact(interacting)

func unlink(_keep_source: bool = false) -> void:
	if input_chain:
		if input_chain.source:
			input_chain.destination = null
			if input_chain.source.has_method("unlink"):
				input_chain.source.call("unlink", true)
		input_chain.queue_free()

	set_active(false)

func _attract_characters() -> void:
	Characters.target_position = position
	for character: Character in Characters.characters:
		character.move()

func _repel_characters() -> void:
	var root: Node3D = get_parent_node_3d()
	var parent: Node3D = root.get_parent_node_3d()
	while parent:
		root = parent
		parent = parent.get_parent_node_3d()
	var navigation_region: NavigationRegion3D = root.find_child("NavigationRegion")

	var power_source: Node3D = navigation_region.find_child("PowerSource")
	if power_source.get("_active"):
		Characters.target_position = power_source.position
	else:
		var far: Node3D = navigation_region.find_child("Far")
		Characters.target_position = far.position

	for character: Character in Characters.characters:
		character.move()
