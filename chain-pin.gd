class_name ChainPin
extends StaticBody3D

@export var camera: Camera3D
@export var camera_ray_cast: RayCast3D
@export var _active_colour: Color = Color(1.0, 0.9, 0.0)
@export var _inactive_colour: Color = Color(0.32, 0.133, 0.0)

const _HALF_PI = PI / 2.0
const _QUARTER_PI = _HALF_PI / 2.0

var input_chain: Chain
var _chain_placement_instance: ChainPlacement
var _chain1: Chain
var _chain2: Chain
var _active: bool = false

@onready var _chain_placement: PackedScene = load("res://chain-placement.tscn")
@onready var _chain_link: PackedScene = load("res://chain-link.tscn")
@onready var _chain_pin: PackedScene = load("res://chain-pin.tscn")
@onready var _chain_pin_mesh: MeshInstance3D = $ChainPinMesh
@onready var _material: StandardMaterial3D = _chain_pin_mesh.get_active_material(0).duplicate()
@onready var _inactive_light: OmniLight3D = $InactiveLight
@onready var _active_light: OmniLight3D = $ActiveLight

func _ready() -> void:
	_chain_pin_mesh.set_surface_override_material(0, _material)

func interact(interacting: bool) -> void:
	if interacting and not GlobalStates.linking and (not _chain1 or not _chain2):
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
		unlink(true)

func set_active(active: bool) -> void:
	_active = active
	if _active:
		_material.emission = _active_colour
		_inactive_light.visible = false
		_active_light.visible = true
	else:
		_material.emission = _inactive_colour
		_inactive_light.visible = true
		_active_light.visible = false

	if _chain1:
		for link: ChainLink in _chain1.get_children():
			link.set_active(_active)
		if _chain1.destination:
			_chain1.destination.call("set_active", _active)

	if _chain2:
		for link: ChainLink in _chain2.get_children():
			link.set_active(_active)
		if _chain2.destination:
			_chain2.destination.call("set_active", _active)

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

	var chain: Chain = Chain.new()
	chain.position = position - (direction * (0.75 / float(links)))
	chain.source = self

	var extra_chains: int = 1
	if target and target.name == "ChainLink" or target is LightBeaconIn:
		extra_chains -= 1

	for i: int in links + extra_chains:
		var link_instance: Node3D = _chain_link.instantiate()
		link_instance.position = direction * (float(i) / float(links))
		link_instance.position.y = 0.5
		link_instance.rotation.y = atan2(direction.x, direction.z) + _HALF_PI
		if i % 2 == 0:
			link_instance.rotation.x = _QUARTER_PI
		else:
			link_instance.rotation.x = -_QUARTER_PI

		chain.add_child(link_instance)

	var root: Node3D = get_parent_node_3d()
	var parents_parent: Node3D = root.get_parent_node_3d()
	while parents_parent:
		root = parents_parent
		parents_parent = parents_parent.get_parent_node_3d()
	root.add_child(chain)

	for link: ChainLink in chain.get_children():
		link.set_active(_active)

	if target:
		if target.name == "ChainLink" or target is LightBeaconIn:
			var light_beacon: LightBeacon = target.get_parent_node_3d()
			light_beacon.input_chain = chain
			light_beacon.input_chain.destination = light_beacon
			light_beacon.set_active(_active)
		if target is LongBoxIn:
			var long_box_chain_link: Node3D = target.get_parent_node_3d()
			var long_box: LongBox = long_box_chain_link.get_parent_node_3d()
			if long_box_chain_link.name == "LongBoxChainLinkIn1":
				long_box.input_chain1 = chain
				long_box.input_chain1.destination = long_box
			elif long_box_chain_link.name == "LongBoxChainLinkIn2":
				long_box.input_chain2 = chain
				long_box.input_chain2.destination = long_box
			long_box.set_active()
		elif target.name == "LongBoxChainLinkIn1":
			var long_box: LongBox = target.get_parent()
			long_box.input_chain1 = chain
			long_box.input_chain1.destination = long_box
			long_box.set_active()
		elif target.name == "LongBoxChainLinkIn2":
			var long_box: LongBox = target.get_parent()
			long_box.input_chain2 = chain
			long_box.input_chain2.destination = long_box
			long_box.set_active()
		else:
			print("Unknown target: ", target)
	else:
		var chain_pin: ChainPin = _chain_pin.instantiate()
		chain_pin.global_position = end
		chain_pin.camera = camera
		chain_pin.camera_ray_cast = camera_ray_cast
		chain_pin.input_chain = chain
		root.add_child(chain_pin)

		chain.destination = chain_pin
		chain_pin.set_active(_active)

	if not _chain1:
		_chain1 = chain
	elif not _chain2:
		_chain2 = chain

func unlink(keep_source: bool = false) -> void:
	if _chain1:
		if _chain1.destination:
			_chain1.source = null
			if _chain1.destination.has_method("unlink"):
				_chain1.destination.call("unlink")
		_chain1.queue_free()

	if _chain2:
		if _chain2.destination:
			_chain2.source = null
			if not _chain1 and _chain2.destination.has_method("unlink"):
				_chain2.destination.call("unlink")
		_chain2.queue_free()

	if not keep_source:
		if input_chain and input_chain.source:
			input_chain.destination = null
			if input_chain.source.has_method("unlink"):
				input_chain.source.call("unlink")
			input_chain.queue_free()

		queue_free()
