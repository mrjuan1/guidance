extends StaticBody3D

@export var _camera: Camera3D
@export var _camera_ray_cast: RayCast3D

@export var _inactive_face_colour: Color = Color(1.0, 0.417, 0.0)
@export var _active_face_colour: Color = Color(1.0, 0.9, 0.0)
@export var _inactive_light_colour: Color = Color(1.0, 0.0, 0.0)
@export var _active_light_colour: Color = Color(0.0, 1.0, 0.0)

const _HALF_PI = PI / 2.0
const _QUARTER_PI = _HALF_PI / 2.0

var _active: bool = false
var _chain_placement_instance: ChainPlacement
var _linked: bool = false
var _chain: Chain
var _navigation_region: NavigationRegion3D

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

func _ready() -> void:
	var root: Node3D = get_parent_node_3d()
	var parents_parent: Node3D = root.get_parent_node_3d()
	while parents_parent:
		root = parents_parent
		parents_parent = parents_parent.get_parent_node_3d()
	_navigation_region = root.find_child("NavigationRegion")

func interact(interacting: bool) -> void:
	if interacting and not GlobalStates.linking:
		_active = !_active
		if _active:
			_faces_material.emission = _active_face_colour
			_light_material.emission = _active_light_colour
			_link_material.emission = _active_face_colour
			_inactive_light.visible = false
			_active_light.visible = true
			_attract_characters()
		else:
			_faces_material.emission = _inactive_face_colour
			_light_material.emission = _inactive_light_colour
			_link_material.emission = _inactive_face_colour
			_inactive_light.visible = true
			_active_light.visible = false
			_repel_characters()

		if _chain:
			for link: ChainLink in _chain.get_children():
				link.set_active(_active)
			if _chain.destination:
				_chain.destination.call("set_active", _active)

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
				if not actual_target.input_chain1:
					actual_target = actual_target.find_child("LongBoxChainLinkIn1")
				else:
					actual_target = actual_target.find_child("LongBoxChainLinkIn2")
			_place_chain(start, actual_target.global_position, actual_target)
		else:
			_place_chain(start, end)

		_linked = true

	_chain_placement_instance.chain_placed.disconnect(_on_chain_placed)
	_chain_placement_instance.queue_free()
	GlobalStates.linking = false

func _place_chain(start: Vector3, end: Vector3, target: Node3D = null) -> void:
	var direction: Vector3 = end - start
	var distance: float = direction.length()
	var links: int = max(1, int(distance / GlobalStates.CHAIN_LENGTH))

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

	_navigation_region.add_child(_chain)

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
		_navigation_region.add_child(chain_pin)

		_chain.destination = chain_pin
		chain_pin.set_active(_active)

func unlink(_keep_source: bool = false) -> void:
	if _linked:
		if _chain.destination:
			_chain.source = null
			if _chain.destination.has_method("unlink"):
				_chain.destination.call("unlink")

		_chain.queue_free()
		_linked = false

func _attract_characters() -> void:
	Characters.target_position = position

	if len(Characters.characters) == 0:
		Characters.add_characters()
		for character: Character in Characters.characters:
			_navigation_region.add_child(character)
	else:
		for character: Character in Characters.characters:
			character.move()

func _repel_characters() -> void:
	var far: Node3D = _navigation_region.find_child("Far")
	Characters.target_position = far.position

	for character: Character in Characters.characters:
		character.move()
