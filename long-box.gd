class_name LongBox
extends StaticBody3D

@onready var _inactive_face_colour: Color = Color(0.26, 0.108, 0.0)
@onready var _active_face_colour: Color = Color(1.0, 0.9, 0.0)

var _active: bool = false
var input_chain1: Chain
var input_chain2: Chain

@onready var _faces_mesh: MeshInstance3D = $LongBoxFacesMesh
@onready var _faces_material: StandardMaterial3D = _faces_mesh.get_active_material(0).duplicate()
@onready var _chain_link_in1: Node3D = $LongBoxChainLinkIn1
@onready var _chain_link_in1_mesh: MeshInstance3D = _chain_link_in1.find_child("LongBoxChainLinkMesh", true)
@onready var _link_in1_material: StandardMaterial3D = _chain_link_in1_mesh.get_active_material(0).duplicate()
@onready var _chain_link_in2: Node3D = $LongBoxChainLinkIn2
@onready var _chain_link_in2_mesh: MeshInstance3D = _chain_link_in2.find_child("LongBoxChainLinkMesh", true)
@onready var _link_in2_material: StandardMaterial3D = _chain_link_in2_mesh.get_active_material(0).duplicate()
@onready var _chain_link_out: Node3D = $LongBoxChainLinkOut
@onready var _chain_link_out_mesh: MeshInstance3D = _chain_link_out.find_child("LongBoxChainLinkMesh", true)
@onready var _link_out_material: StandardMaterial3D = _chain_link_out_mesh.get_active_material(0).duplicate()
@onready var _inactive_light: OmniLight3D = $InactiveLight
@onready var _active_light: OmniLight3D = $ActiveLight

func _ready() -> void:
	_faces_mesh.set_surface_override_material(0, _faces_material)
	_chain_link_in1_mesh.set_surface_override_material(0, _link_in1_material)
	_chain_link_in2_mesh.set_surface_override_material(0, _link_in2_material)
	_chain_link_out_mesh.set_surface_override_material(0, _link_out_material)
	set_active()

func interact(interacting: bool) -> void:
	if not interacting:
		unlink()

func set_active(_active: bool = false) -> void:
	if input_chain1 and input_chain1.source and input_chain1.source.get("_active") and \
		input_chain2 and input_chain2.source and input_chain2.source.get("_active"):
		_active = false
	else:
		_active = true

	if _active:
		_faces_material.emission = _active_face_colour
		_link_in1_material.emission = _active_face_colour
		_link_in2_material.emission = _active_face_colour
		_link_out_material.emission = _active_face_colour
		_inactive_light.visible = false
		_active_light.visible = true
		_attract_characters()
	else:
		_faces_material.emission = _inactive_face_colour
		_link_in1_material.emission = _inactive_face_colour
		_link_in2_material.emission = _inactive_face_colour
		_link_out_material.emission = _inactive_face_colour
		_inactive_light.visible = true
		_active_light.visible = false
		_repel_characters()

func unlink(_keep_source: bool = false) -> void:
	if input_chain1:
		if input_chain1.source:
			input_chain1.destination = null
			if input_chain1.source.has_method("unlink"):
				input_chain1.source.call("unlink", true)
		input_chain1.queue_free()

	if input_chain2:
		if input_chain2.source:
			input_chain2.destination = null
			if not input_chain1 and input_chain2.source.has_method("unlink"):
				input_chain2.source.call("unlink", true)
		input_chain2.queue_free()

	set_active()

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

func _on_long_box_chain_link_in_1_input_selected(interacting: bool) -> void:
	interact(interacting)

func _on_long_box_chain_link_in_2_input_selected(interacting: bool) -> void:
	interact(interacting)

func _on_long_box_chain_link_out_input_selected(interacting: bool) -> void:
	interact(interacting)
