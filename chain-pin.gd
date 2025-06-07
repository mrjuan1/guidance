class_name ChainPin
extends StaticBody3D

@export var camera: Camera3D
@export var camera_ray_cast: RayCast3D

const _HALF_PI = PI / 2.0
const _QUARTER_PI = _HALF_PI / 2.0

var input_chain: Chain
var _chain_placement_instance: ChainPlacement
var _linked: bool = false
var _chain: Chain

@onready var _chain_placement: PackedScene = load("res://chain-placement.tscn")
@onready var _chain_link: PackedScene = load("res://chain-link.tscn")
@onready var _chain_pin: PackedScene = load("res://chain-pin.tscn")

func interact(interacting: bool) -> void:
	if interacting and not GlobalStates.linking and not _linked:
		_chain_placement_instance = _chain_placement.instantiate()
		_chain_placement_instance.position = position
		_chain_placement_instance.position.y = 0.5

		_chain_placement_instance.camera = camera
		_chain_placement_instance.camera_ray_cast = camera_ray_cast
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
	_chain.position = position - (direction * (0.75 / float(links)))
	_chain.source = self

	for i: int in links + 1:
		var link_instance: Node3D = _chain_link.instantiate()
		link_instance.position = direction * (float(i) / float(links))
		link_instance.position.y = 0.25
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
	chain_pin.camera = camera
	chain_pin.camera_ray_cast = camera_ray_cast
	chain_pin.input_chain = _chain
	root.add_child(chain_pin)

	_chain.destination = chain_pin

func unlink() -> void:
	if _linked:
		if _chain.destination:
			_chain.source = null
			if _chain.destination.has_method("unlink"):
				_chain.destination.call("unlink")
		_chain.queue_free()
		_linked = false

	if input_chain and input_chain.source:
		input_chain.destination = null
		if input_chain.source.has_method("unlink"):
			input_chain.source.call("unlink")
		input_chain.queue_free()

	queue_free()
