class_name ChainPlacementNode
extends Node3D

const _HALF_PI: float = PI * 0.5
const _QUARTER_PI: float = _HALF_PI * 0.5

@export var _camera_controller: CameraController
@export var _chain_link_length: float = 0.28
@export var _placement_colour: Color = Color(0.0, 0.617, 1.0, 0.831)
@export var _error_colour: Color = Color(1.0, 0.4, 0.4, 0.831)

@onready var _camera_ray_cast: RayCast3D = _camera_controller.find_child("CameraRayCast")
@onready var _chain_link: Node3D = $ChainLink
@onready var _chain_link_mesh: MeshInstance3D = _chain_link.find_child("ChainLinkMesh")
@onready var _chain_link_material: StandardMaterial3D = _chain_link_mesh.get_active_material(0).duplicate()
@onready var _chain_links: Array[Node3D] = [_chain_link]
@onready var _chain_link_count: int = len(_chain_links)
@onready var _chain_ray_cast: RayCast3D = $ChainRayCast

func _ready() -> void:
	_chain_link.rotation.x = _QUARTER_PI
	_chain_link_mesh.set_surface_override_material(0, _chain_link_material)
	_chain_link_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_chain_link_material.no_depth_test = true
	_chain_link_material.albedo_color = _placement_colour

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _camera_ray_cast.is_colliding():
		var start: Vector3 = position
		var end: Vector3 = _camera_ray_cast.get_collision_point()
		var direction: Vector3 = end - start
		var distance: float = direction.length()
		var chain_links: int = maxi(int(distance / _chain_link_length), 1)

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

			var link_position: Vector3 = direction * (float(i) / float(_chain_link_count))
			link_position.y = 0.5
			chain_link.global_position = link_position

			chain_link.rotation.y = atan2(direction.x, direction.z) + _HALF_PI
			if i % 2 == 0:
				chain_link.rotation.x = _QUARTER_PI
			else:
				chain_link.rotation.x = -_QUARTER_PI

		_chain_ray_cast.global_position = start
		_chain_ray_cast.global_position.y = 0.5
		_chain_ray_cast.target_position = end + (direction.normalized() * 0.1)
		_chain_ray_cast.target_position.y = 0.0
		if _chain_ray_cast.is_colliding():
			_chain_link_material.albedo_color = _error_colour
		else:
			_chain_link_material.albedo_color = _placement_colour

func _update_chain_links() -> void:
	pass

func _update_chain_collision() -> void:
	pass
