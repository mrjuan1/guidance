class_name ChainPlacement
extends Node3D

signal chain_placed(cancelled: bool, start: Vector3, end: Vector3, target: Node3D)

@export var camera: Camera3D
@export var camera_ray_cast: RayCast3D
@export var _ray_length: float = 20.0
@export var _placement_colour: Color = Color(0.0, 0.5, 1.0, 0.792)
@export var _collision_colour: Color = Color(1.0, 0.388, 0.388, 0.682)

const _HALF_PI: float = PI / 2.0

var _input_relative: Vector2 = Vector2.ZERO
var _last_links: int = 0
var _link_instances: Array[Node3D] = []

@onready var _initial_position: Vector3 = position
@onready var _chain_link: PackedScene = preload("res://chain-link-temp.tscn")
@onready var _chain_placement_ray_cast: RayCast3D = $ChainPlacementRayCast
@onready var _chain_pin: StaticBody3D = $ChainPin

func _ready() -> void:
	_place_links(_initial_position, _initial_position, true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and camera and camera_ray_cast:
		var input_event: InputEventMouseMotion = event as InputEventMouseMotion
		_input_relative = input_event.relative

		var from: Vector3 = camera.project_ray_origin(input_event.position)
		var to: Vector3 = from + (camera.project_ray_normal(input_event.position) * _ray_length)

		camera_ray_cast.look_at_from_position(from, to, Vector3.UP)
		camera_ray_cast.force_raycast_update()

		if camera_ray_cast.is_colliding():
			var collision_position: Vector3 = camera_ray_cast.get_collision_point()
			var collider: Object = camera_ray_cast.get_collider()
			var is_pin = collider is not LightBeacon and collider is not LightBeaconIn
			_place_links(_initial_position, collision_position, is_pin)
	elif event is InputEventMouseButton:
		if event.is_action("interact") and _input_relative.is_zero_approx():
			var collision_position: Vector3 = camera_ray_cast.get_collision_point()
			var collider: Object = camera_ray_cast.get_collider()
			var is_pin = collider is not LightBeacon and collider is not LightBeaconIn

			var colliding: bool = _chain_placement_ray_cast.is_colliding()
			if colliding and not is_pin:
				chain_placed.emit(false, _initial_position, collision_position, collider)
			elif not colliding and is_pin:
				chain_placed.emit(false, _initial_position, collision_position)
		elif event.is_action("cancel"):
			chain_placed.emit(true)

		_input_relative = Vector2.ZERO

func _place_links(start: Vector3, end: Vector3, place_pin: bool) -> void:
	var direction: Vector3 = end - start
	var distance: float = direction.length()
	var links: int = max(1, int(distance / GlobalStates.CHAIN_LENGTH))

	if links != _last_links:
		if links > _last_links:
			var links_to_add: int = links - _last_links
			for i: int in links_to_add:
				var link_instance: Node3D = _chain_link.instantiate()
				add_child(link_instance)
				_link_instances.push_back(link_instance)
		elif links < _last_links:
			var links_to_remove: int = _last_links - links
			for i: int in links_to_remove:
				if len(_link_instances) > 1:
					var link_instance: Node3D = _link_instances.pop_back()
					link_instance.queue_free()
		_last_links = links

	_chain_placement_ray_cast.position = start - position
	_chain_placement_ray_cast.target_position = end - position
	_chain_placement_ray_cast.target_position.y = 0.0
	_chain_placement_ray_cast.force_raycast_update()

	var link_instances: int = len(_link_instances)
	for i: int in link_instances:
		var link_instance: Node3D = _link_instances[i]
		link_instance.position = direction * (float(i) / float(link_instances))
		link_instance.position.y = 0.0
		link_instance.rotation.y = atan2(direction.x, direction.z) + _HALF_PI

		if i % 2 == 0:
			link_instance.rotation.x = _HALF_PI

		var mesh: MeshInstance3D = link_instance.get_child(0) as MeshInstance3D
		var material: StandardMaterial3D = mesh.get_active_material(0) as StandardMaterial3D
		if _chain_placement_ray_cast.is_colliding() and place_pin:
			material.albedo_color = _collision_colour
		else:
			material.albedo_color = _placement_colour

	if place_pin:
		_chain_pin.global_position = end
		_chain_pin.global_position.y = 0.0
		_chain_pin.visible = true
	else:
		_chain_pin.visible = false
