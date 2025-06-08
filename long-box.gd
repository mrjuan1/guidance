class_name LongBox
extends StaticBody3D

@export var _camera: Camera3D
@export var _camera_ray_cast: RayCast3D
@export var _inactive_face_colour: Color = Color(0.26, 0.108, 0.0)
@export var _active_face_colour: Color = Color(1.0, 0.9, 0.0)

const _HALF_PI = PI / 2.0
const _QUARTER_PI = _HALF_PI / 2.0

var _active: bool = false
var input_chain1: Chain
var input_chain2: Chain
var _chain_placement_instance: ChainPlacement
var _chain: Chain

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
@onready var _chain_placement: PackedScene = load("res://chain-placement.tscn")
@onready var _chain_link: PackedScene = load("res://chain-link.tscn")
@onready var _chain_pin: PackedScene = load("res://chain-pin.tscn")

func _ready() -> void:
	_faces_mesh.set_surface_override_material(0, _faces_material)
	_chain_link_in1_mesh.set_surface_override_material(0, _link_in1_material)
	_chain_link_in2_mesh.set_surface_override_material(0, _link_in2_material)
	_chain_link_out_mesh.set_surface_override_material(0, _link_out_material)
	set_active()

func interact(interacting: bool) -> void:
	if interacting and not GlobalStates.linking and not _chain:
		_chain_placement_instance = _chain_placement.instantiate()
		_chain_placement_instance.position = position
		_chain_placement_instance.position.y = 0.5
		_chain_placement_instance.position.z += 0.6

		_chain_placement_instance.camera = _camera
		_chain_placement_instance.camera_ray_cast = _camera_ray_cast
		_chain_placement_instance.chain_placed.connect(_on_chain_placed)

		var parent: Node3D = get_parent_node_3d()
		parent.add_child(_chain_placement_instance)

		GlobalStates.linking = true
	elif not interacting:
		unlink()

func set_active(__active: bool = false) -> void:
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

	if _chain:
		for link: ChainLink in _chain.get_children():
			link.set_active(_active)
		if _chain.destination:
			_chain.destination.call("set_active", _active)

func _on_chain_placed(
	cancelled: bool,
	start: Vector3 = Vector3.ZERO,
	end: Vector3 = Vector3.ZERO,
	target: Node3D = null
) -> void:
	if not cancelled:
		if target:
			var actual_target: Node3D = target
			if actual_target is LightBeacon:
				actual_target = actual_target.find_child("ChainLink")
			elif actual_target is LongBox:
				var long_box: LongBox = actual_target
				if not long_box.input_chain1:
					actual_target = actual_target.find_child("LongBoxChainLinkIn1")
				else:
					actual_target = actual_target.find_child("LongBoxChainLinkIn2")
			_place_chain(start, actual_target.global_position, actual_target)
		else:
			_place_chain(start, end)

	_chain_placement_instance.chain_placed.disconnect(_on_chain_placed)
	_chain_placement_instance.queue_free()
	GlobalStates.linking = false

func _place_chain(start: Vector3, end: Vector3, target: Node3D = null) -> void:
	var direction: Vector3 = end - start
	var distance: float = direction.length()
	var links: int = max(1, int(distance / GlobalStates.CHAIN_LENGTH))

	_chain = Chain.new()
	_chain.position = position - (direction * (0.75 / float(links)))
	_chain.source = self

	var extra_chains: int = 1
	if target and target.name == "ChainLink" or target is LightBeaconIn:
		extra_chains -= 1

	for i: int in links + extra_chains:
		if i > 0:
			var link_instance: Node3D = _chain_link.instantiate()
			link_instance.position = direction * (float(i) / float(links))
			link_instance.position.z += 0.6
			#link_instance.position.y = 0.5
			link_instance.rotation.y = atan2(direction.x, direction.z) + _HALF_PI
			if i % 2 == 0:
				link_instance.rotation.x = _QUARTER_PI
			else:
				link_instance.rotation.x = -_QUARTER_PI

			_chain.add_child(link_instance)

	var root: Node3D = get_parent_node_3d()
	var parents_parent: Node3D = root.get_parent_node_3d()
	while parents_parent:
		root = parents_parent
		parents_parent = parents_parent.get_parent_node_3d()
	root.add_child(_chain)

	for link: ChainLink in _chain.get_children():
		link.set_active(_active)

	if target:
		if target.name == "ChainLink" or target is LightBeaconIn:
			var light_beacon: LightBeacon = target.get_parent_node_3d()
			light_beacon.input_chain = _chain
			light_beacon.input_chain.destination = light_beacon
			light_beacon.set_active(_active)
		if target is LongBoxIn:
			var long_box_chain_link: Node3D = target.get_parent_node_3d()
			var long_box: LongBox = long_box_chain_link.get_parent_node_3d()
			if long_box_chain_link.name == "LongBoxChainLinkIn1":
				long_box.input_chain1 = _chain
				long_box.input_chain1.destination = long_box
			elif long_box_chain_link.name == "LongBoxChainLinkIn2":
				long_box.input_chain2 = _chain
				long_box.input_chain2.destination = long_box
			long_box.set_active()
		elif target.name == "LongBoxChainLinkIn1":
			var long_box: LongBox = target.get_parent()
			long_box.input_chain1 = _chain
			long_box.input_chain1.destination = long_box
			long_box.set_active()
		elif target.name == "LongBoxChainLinkIn2":
			var long_box: LongBox = target.get_parent()
			long_box.input_chain2 = _chain
			long_box.input_chain2.destination = long_box
			long_box.set_active()
		else:
			print("Unknown target: ", target)
	else:
		var chain_pin: ChainPin = _chain_pin.instantiate()
		chain_pin.global_position = end
		chain_pin.camera = _camera
		chain_pin.camera_ray_cast = _camera_ray_cast
		chain_pin.input_chain = _chain
		root.add_child(chain_pin)

		_chain.destination = chain_pin
		chain_pin.set_active(_active)

func unlink(_keep_source: bool = false) -> void:
	if _chain:
		if _chain.destination:
			_chain.source = null
			if _chain.destination.has_method("unlink"):
				_chain.destination.call("unlink")
		_chain.queue_free()

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
