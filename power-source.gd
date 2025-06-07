extends StaticBody3D

@export var _camera: Camera3D
@export var _camera_ray_cast: RayCast3D

signal state_toggled(active: bool)

@onready var _inactive_face_colour: Color = Color(1.0, 0.417, 0.0)
@onready var _active_face_colour: Color = Color(1.0, 0.9, 0.0)
@onready var _inactive_light_colour: Color = Color(1.0, 0.0, 0.0)
@onready var _active_light_colour: Color = Color(0.0, 1.0, 0.0)

const _HALF_PI = PI / 2.0
const _QUARTER_PI = _HALF_PI / 2.0

var _active: bool = false
var _chain_placement_instance: ChainPlacement
var _linked: bool = false
var _chain: Chain

@onready var _faces_mesh: MeshInstance3D = $BoxFaces
@onready var _faces_material: StandardMaterial3D = _faces_mesh.get_active_material(0) as StandardMaterial3D
@onready var _light_mesh: MeshInstance3D = $Light
@onready var _light_material: StandardMaterial3D = _light_mesh.get_active_material(0) as StandardMaterial3D
@onready var _chain_link_mesh: MeshInstance3D = %ChainLinkMesh
@onready var _link_material: StandardMaterial3D = _chain_link_mesh.get_active_material(0) as StandardMaterial3D
@onready var _inactive_light: OmniLight3D = $InactiveLight
@onready var _active_light: OmniLight3D = $ActiveLight
@onready var _chain_placement: PackedScene = preload("res://chain-placement.tscn")
@onready var _chain_link: PackedScene = preload("res://chain-link.tscn")
@onready var _chain_pin: PackedScene = preload("res://chain-pin.tscn")

func interact(interacting: bool) -> void:
	if interacting and not GlobalStates.linking:
		_active = !_active
		if _active:
			_faces_material.emission = _active_face_colour
			_light_material.emission = _active_light_colour
			_link_material.emission = _active_face_colour
			_inactive_light.visible = false
			_active_light.visible = true
		else:
			_faces_material.emission = _inactive_face_colour
			_light_material.emission = _inactive_light_colour
			_link_material.emission = _inactive_face_colour
			_inactive_light.visible = true
			_active_light.visible = false

		if _chain:
			for link: ChainLink in _chain.get_children():
				link.set_active(_active)
			if _chain.destination:
				_chain.destination.call("set_active", _active)

		state_toggled.emit(_active)

func _on_power_source_out_output_selected(interacting: bool) -> void:
	if interacting and not GlobalStates.linking and not _linked:
		_chain_placement_instance = _chain_placement.instantiate()
		_chain_placement_instance.position = position
		_chain_placement_instance.position.x += 0.7

		_chain_placement_instance.camera = _camera
		_chain_placement_instance.camera_ray_cast = _camera_ray_cast
		_chain_placement_instance.chain_placed.connect(_on_chain_placed)

		var parent: Node3D = get_parent_node_3d()
		parent.add_child(_chain_placement_instance)

		GlobalStates.linking = true
	elif not interacting:
		unlink()

func _on_chain_placed(cancelled: bool, links: int = 0, direction: Vector3 = Vector3.ZERO, end_position: Vector3 = Vector3.ZERO) -> void:
	if not cancelled:
		_place_chain(links, direction, end_position)
		_linked = true

	_chain_placement_instance.chain_placed.disconnect(_on_chain_placed)
	_chain_placement_instance.queue_free()
	GlobalStates.linking = false

func _place_chain(links: int, direction: Vector3, end_position: Vector3) -> void:
	_chain = Chain.new()
	_chain.position = position
	_chain.position.x += 0.6
	_chain.source = self

	for i: int in links:
		var link_instance: ChainLink = _chain_link.instantiate()
		link_instance.position = direction * (float(i) / float(links))
		link_instance.position.y = 0.0
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

	var chain_pin: ChainPin = _chain_pin.instantiate()
	chain_pin.global_position = end_position
	chain_pin.camera = _camera
	chain_pin.camera_ray_cast = _camera_ray_cast
	chain_pin.input_chain = _chain
	root.add_child(chain_pin)

	_chain.destination = chain_pin

	for link: ChainLink in _chain.get_children():
		link.set_active(_active)
	chain_pin.set_active(_active)

func unlink() -> void:
	if _linked:
		if _chain.destination:
			_chain.source = null
			if _chain.destination.has_method("unlink"):
				_chain.destination.call("unlink")
		_chain.queue_free()
		_linked = false
