extends Node

const HALF_PI: float = PI * 0.5
const QUARTER_PI: float = HALF_PI * 0.5
const CHAIN_LINK_LENGTH: float = 0.28

const _PIN_ROTATION_RANGE: float = QUARTER_PI * 0.5

var _active: bool = false
var _source: Node3D
var _source_parent: Node3D
var _chain_placement_resource: PackedScene = preload("res://scenes/chains/chain-placement-node.tscn")
var _chain_placement_node: ChainPlacementNode
var _chain_link_resource: PackedScene = preload("res://scenes/chains/chain-link-rigid.tscn")
var _chain_pin_resource: PackedScene = preload("res://scenes/chains/chain-pin.tscn")

var active: bool:
	get:
		return _active
	set(_value):
		pass

func _get_current_scene() -> Scene:
	var root_nodes: Array[Node] = get_tree().root.get_children()
	for node: Node in root_nodes:
		var camera_controller: CameraController = node.find_child("CameraController")
		if camera_controller:
			var root_node: Node3D = node
			return Scene.new(root_node, camera_controller)

	return null

func start(node: Node3D) -> void:
	if active:
		push_warning("Already attempting to place a chain, cannot start another placement")
		return

	var scene: Scene = _get_current_scene()
	if not scene:
		printerr("Scene node could not be found")
		return

	_source = node

	var source_parent: Node3D
	if _source is ChainLinkInteraction:
		source_parent = _source.get_parent_node_3d()
		if source_parent is ChainLink:
			source_parent = source_parent.get_parent_node_3d()
			if source_parent is PowerSource:
				var power_source: PowerSource = source_parent
				if power_source.output:
					push_warning("Cannot link another chain from a source where only one chain is allowed")
					_source = null
					return
				else:
					_source_parent = power_source
	elif _source is ChainPin:
		var chain_pin: ChainPin = _source
		if len(chain_pin.outputs) >= 2:
			push_warning("Cannot link more than two chains from a chain pin")
			_source = null
			return

	_chain_placement_node = _chain_placement_resource.instantiate()
	_chain_placement_node.position = _source.global_position # Will test linking from future nodes
	_chain_placement_node.camera_controller = scene.camera_controller
	scene.root_node.add_child(_chain_placement_node)

	_active = true

func end(place_chain: bool) -> void:
	if not active:
		push_warning("Cannot end a non-existant chain placement")
		return

	if not place_chain:
		_chain_placement_node.queue_free()
		_source_parent = null
		_source = null
		_active = false
		return

	if not _chain_placement_node.can_place:
		return

	var scene: Scene = _get_current_scene()
	if not scene:
		printerr("Scene node could not be found")
		return

	var start_position: Vector3 = _source.global_position

	var end_position: Vector3
	var placement_node_target: Node3D = _chain_placement_node.target
	if placement_node_target is LightBeacon:
		var chain_link: ChainLink = placement_node_target.find_child("ChainLinkStatic")
		end_position = chain_link.global_position
	else:
		end_position = scene.camera_controller.camera_ray_cast.get_collision_point()

	_chain_placement_node.queue_free()

	if _source_parent is PowerSource or _source is ChainPin:
		var direction: Vector3 = (end_position - start_position).normalized()
		direction.y = 0.0

		var offset: Vector3 = direction * CHAIN_LINK_LENGTH
		if _source_parent is PowerSource:
			start_position += offset

		if placement_node_target is not LightBeacon:
			end_position += offset

		if _source is ChainPin:
			start_position.y = 0.5
			end_position.y = 0.5

	# Check for valid colliders, else place a chain pin (below is for placing a pin)
	var chain_pin: ChainPin
	if not placement_node_target:
		var chain_pin_position: Vector3 = scene.camera_controller.camera_ray_cast.get_collision_point()

		var scene_navigation_region: NavigationRegion3D = scene.root_node.find_child("NavigationRegion")
		if not scene_navigation_region:
			printerr("Scene has no navigation region")
			return

		chain_pin = _place_chain_pin(scene_navigation_region, chain_pin_position)
	# End of pin placement

	var chain: Chain = _place_chain(start_position, end_position)
	if _source_parent is PowerSource:
		chain.input = _source_parent
	elif _source is ChainPin:
		chain.input = _source
	if placement_node_target is LightBeacon:
		var light_beacon: LightBeacon = placement_node_target
		chain.output = light_beacon
		light_beacon.input = chain
	else:
		chain.output = chain_pin
		chain_pin.input = chain
	scene.root_node.add_child(chain)

	if _source_parent is PowerSource:
		var power_source: PowerSource = _source_parent
		power_source.output = chain
	elif _source is ChainPin:
		var source_chain_pin: ChainPin = _source
		source_chain_pin.outputs.push_back(chain)

	_source_parent = null
	_source = null
	_active = false

func _place_chain_pin(navigation_region: NavigationRegion3D, position: Vector3) -> ChainPin:
	var chain_pin: ChainPin = _chain_pin_resource.instantiate()

	var chain_pin_position: Vector3 = position
	chain_pin_position.y = -0.2 # Was 0.1
	chain_pin.global_position = chain_pin_position
	# Need to figure out a way to deal with this
	#chain_pin.rotation.x = randf_range(-_PIN_ROTATION_RANGE, _PIN_ROTATION_RANGE)
	#chain_pin.rotation.y = randf_range(-_PIN_ROTATION_RANGE, _PIN_ROTATION_RANGE)
	#chain_pin.rotation.z = randf_range(-_PIN_ROTATION_RANGE, _PIN_ROTATION_RANGE)

	navigation_region.add_child(chain_pin)
	navigation_region.bake_navigation_mesh()

	return chain_pin

func _place_chain(start_position: Vector3, end_position: Vector3) -> Chain:
	var direction: Vector3 = end_position - start_position
	var distance: float = direction.length()
	var chain_links: int = maxi(int(distance / CHAIN_LINK_LENGTH), 1)

	var chain: Chain = Chain.new()
	chain.global_position = start_position

	for i: int in chain_links:
		var chain_link: ChainLink = _chain_link_resource.instantiate()

		var link_position: Vector3 = direction * (float(i) / float(chain_links))
		chain_link.position = link_position
		chain_link.position.y = 0.0

		if i % 2 == 0:
			chain_link.rotation.x = QUARTER_PI
		else:
			chain_link.rotation.x = -QUARTER_PI
		chain_link.rotation.y = atan2(direction.x, direction.z) + HALF_PI
		chain_link.rotation.z = 0.0

		chain.add_child(chain_link)

	return chain
