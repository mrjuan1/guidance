class_name ChainPlacementNode
extends Node3D

@export var camera_controller: CameraController
@export var _min_chains: int = 5
@export var _placement_colour: Color = Color(0.0, 0.617, 1.0, 0.831)
@export var _error_colour: Color = Color(1.0, 0.4, 0.4, 0.831)

var target: Node3D:
	get:
		if camera_controller.camera_ray_cast.is_colliding():
			var collider: Object = camera_controller.camera_ray_cast.get_collider()
			if collider is ChainLinkInteraction:
				var chain_link_interaction: ChainLinkInteraction = collider
				var parent: Node3D = chain_link_interaction.get_parent_node_3d()
				if parent is ChainLink:
					var chain_link: ChainLink = parent
					parent = chain_link.get_parent_node_3d()
					if parent is LightBeacon or parent is Override:
						return parent

			if collider is LightBeacon or collider is Override:
				return collider

		return null
	set(_value):
		pass

var can_place: bool:
	get:
		if _chain_link_count < _min_chains:
			_chain_pin.visible = false
			return false

		if target:
			_chain_pin.visible = false
			return true

		if not _chain_ray_cast.is_colliding():
			_chain_pin.visible = true
			return true

		_chain_pin.visible = false
		return false
	set(_value):
		pass

@onready var _chain_link: Node3D = $ChainLink
@onready var _chain_link_mesh: MeshInstance3D = _chain_link.find_child("ChainLinkMesh")
@onready var _chain_link_material: StandardMaterial3D = _chain_link_mesh.get_active_material(0).duplicate()
@onready var _chain_links: Array[Node3D] = [_chain_link]
@onready var _chain_link_count: int = len(_chain_links)
@onready var _chain_pin: ChainPin = $ChainPin
@onready var _chain_ray_cast: RayCast3D = $ChainRayCast

func _ready() -> void:
	_chain_link.rotation.x = ChainPlacement.QUARTER_PI
	_chain_link_mesh.set_surface_override_material(0, _chain_link_material)
	_chain_link_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_chain_link_material.no_depth_test = true
	_chain_link_material.albedo_color = _placement_colour

	_chain_pin.position.y = -0.5
	_chain_pin.collision_layer = 0

func _input(event: InputEvent) -> void:
	if camera_controller.camera_ray_cast.is_colliding():
		if event is InputEventMouseMotion:
			var start: Vector3 = global_position

			var end: Vector3
			var target_node: Node3D = target
			if target_node is LightBeacon:
				var chain_link: ChainLink = target_node.find_child("ChainLinkStatic")
				end = chain_link.global_position
			elif target_node is Override:
				var override: Override = target_node
				if not override.input1:
					var chain_link_in1: ChainLink = override.find_child("ChainLinkIn1")
					end = chain_link_in1.global_position
				elif not override.input2:
					var chain_link_in2: ChainLink = override.find_child("ChainLinkIn2")
					end = chain_link_in2.global_position
			else:
				end = camera_controller.camera_ray_cast.get_collision_point()

			var direction: Vector3 = end - start
			var distance: float = direction.length()

			_update_chain_links(start, direction, distance)
			_update_chain_collision(start, end, distance)

			if can_place:
				_chain_link_material.albedo_color = _placement_colour
			else:
				_chain_link_material.albedo_color = _error_colour

			_chain_pin.global_position = end
			_chain_pin.global_position.y = 0.0
		elif event is InputEventMouseButton and camera_controller.still:
			var input_event: InputEventMouseButton = event
			if input_event.is_action_released("interact"):
				ChainPlacement.end(true)
			elif input_event.is_action_released("cancel"):
				ChainPlacement.end(false)

func _update_chain_links(start: Vector3, direction: Vector3, distance: float) -> void:
	var chain_links: int = maxi(int(distance / ChainPlacement.CHAIN_LINK_LENGTH), 1)

	if chain_links > _chain_link_count:
		var links_to_add: int = chain_links - _chain_link_count
		for i: int in links_to_add:
			var chain_link: Node3D = _chain_link.duplicate()
			add_child(chain_link)
			_chain_links.push_back(chain_link)
	elif chain_links < _chain_link_count:
		var links_to_remove: int = _chain_link_count - chain_links
		for i: int in links_to_remove:
			var chain_link: Node3D = _chain_links.pop_back()
			chain_link.queue_free()
	_chain_link_count = len(_chain_links)

	for i: int in _chain_link_count:
		var chain_link: Node3D = _chain_links[i]

		var link_position: Vector3 = start + (direction * (float(i) / float(_chain_link_count)))
		chain_link.global_position = link_position
		chain_link.global_position.y = 0.5

		if i % 2 == 0:
			chain_link.rotation.x = ChainPlacement.QUARTER_PI
		else:
			chain_link.rotation.x = -ChainPlacement.QUARTER_PI
		chain_link.rotation.y = atan2(direction.x, direction.z) + ChainPlacement.HALF_PI
		chain_link.rotation.z = 0.0

func _update_chain_collision(start: Vector3, end: Vector3, distance: float) -> void:
	_chain_ray_cast.look_at_from_position(start, end)
	_chain_ray_cast.target_position.z = -distance
