class_name CameraController
extends Node3D

@export var _ray_cast_length: float = 20.0

@export_group("Movement")
@export var _min_position: Vector2 = Vector2(-50.0, -50.0)
@export var _max_position: Vector2 = Vector2(50.0, 50.0)
@export var _movement_speed: float = 1.0
@export var _movement_lerp_speed: float = 5.0

@export_group("Rotation")
@export var _min_tilt: float = -80.0:
	set(value):
		_min_tilt = value
		_min_tilt_radians = deg_to_rad(_min_tilt)
@export var _max_tilt: float = -20.0:
	set(value):
		_max_tilt = value
		_max_tilt_radians = deg_to_rad(_max_tilt)
@export var _rotation_speed: float = 0.25
@export var _rotation_lerp_speed: float = 5.0

@export_group("Zooming")
@export var _min_zoom: float = 2.0:
	set(value):
		_min_zoom = value
		_zoom_range_length = _max_zoom - _min_zoom
@export var _max_zoom: float = 10.0:
	set(value):
		_max_zoom = value
		_zoom_range_length = _max_zoom - _min_zoom
@export var _zoom_lerp_speed: float = 5.0

var _moving: bool = false
var _rotating: bool = false
var _was_moving_or_rotating: bool = false
var _input_relative: Vector2 = Vector2.ZERO

var _min_tilt_radians: float = deg_to_rad(_min_tilt)
var _max_tilt_radians: float = deg_to_rad(_max_tilt)
var _zoom_range_length: float = _max_zoom - _min_zoom

var still: bool:
	get:
		return _input_relative.is_zero_approx()
	set(_value):
		pass

@onready var _camera: Camera3D = $Camera
@onready var camera_ray_cast: RayCast3D = $CameraRayCast

@onready var _initial_position: Vector2 = Vector2(position.x, position.y)
@onready var _initial_rotation: Vector2 = Vector2(rotation.x, rotation.y)
@onready var _initial_zoom: float = _camera.position.z

@onready var _target_position: Vector2 = _initial_position
@onready var _target_rotation: Vector2 = _initial_rotation
@onready var _target_zoom: float = _initial_zoom

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var input_event: InputEventMouseButton = event
		var interact_released: bool = input_event.is_action_released("interact")
		var cancel_released: bool = input_event.is_action_released("cancel")
		_update_camera_ray_cast(input_event.position)

		if interact_released or cancel_released:
			if interact_released:
				_moving = false
			elif cancel_released:
				_rotating = false

			if _was_moving_or_rotating:
				_was_moving_or_rotating = false
			elif not _was_moving_or_rotating and camera_ray_cast.is_colliding():
				var collider: Object = camera_ray_cast.get_collider()
				if collider.has_method("select_handler"):
					collider.call("select_handler", interact_released)

		elif event.is_action("zoom_in"):
			_target_zoom = clampf(_target_zoom - 1.0, _min_zoom, _max_zoom)
		elif event.is_action("zoom_out"):
			_target_zoom = clampf(_target_zoom + 1.0, _min_zoom, _max_zoom)
		elif event.is_action_pressed("reset_camera"):
			if input_event.double_click:
				_target_position = _initial_position
			else:
				_target_rotation = _initial_rotation
				_target_zoom = _initial_zoom
		elif still:
			if event.is_action_pressed("interact"):
				_moving = true
			elif event.is_action_pressed("cancel"):
				_rotating = true
	elif event is InputEventMouseMotion:
		var input_event: InputEventMouseMotion = event
		_input_relative = input_event.relative

		if (_moving or _rotating) and not still:
			_was_moving_or_rotating = true

		_update_camera_ray_cast(input_event.position)

func _physics_process(delta: float) -> void:
	if _moving:
		var movement_direction: Vector3 = transform.basis * Vector3(_input_relative.x, 0.0, _input_relative.y)
		var movement_scaled: Vector2 = Vector2(movement_direction.x, movement_direction.z) * (_target_zoom / _zoom_range_length)
		var movement_speed: Vector2 = movement_scaled * _movement_speed * delta
		_target_position.x = clampf(_target_position.x - movement_speed.x, _min_position.x, _max_position.x)
		_target_position.y = clampf(_target_position.y - movement_speed.y, _min_position.y, _max_position.y)
	elif _rotating:
		var rotation_speed: Vector2 = _input_relative * _rotation_speed * delta
		_target_rotation.x = clampf(_target_rotation.x - rotation_speed.y, _min_tilt_radians, _max_tilt_radians)
		_target_rotation.y -= rotation_speed.x

	_input_relative = Vector2.ZERO

func _process(delta: float) -> void:
	var movement_speed: float = _movement_lerp_speed * delta
	position.x = lerpf(position.x, _target_position.x, movement_speed)
	position.z = lerpf(position.z, _target_position.y, movement_speed)

	var rotation_lerp_speed: float = _rotation_lerp_speed * delta
	rotation.x = lerpf(rotation.x, _target_rotation.x, rotation_lerp_speed)
	rotation.y = lerp_angle(rotation.y, _target_rotation.y, rotation_lerp_speed)

	_camera.position.z = lerpf(_camera.position.z, _target_zoom, _zoom_lerp_speed * delta)

func _update_camera_ray_cast(input_position: Vector2) -> void:
	var from: Vector3 = _camera.project_ray_origin(input_position)
	var to: Vector3 = from + (_camera.project_ray_normal(input_position) * _ray_cast_length)
	camera_ray_cast.look_at_from_position(from, to)
