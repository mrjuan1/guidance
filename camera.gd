extends Node3D

@export var _camera: Camera3D
@export var _initial_position: Vector3 = Vector3.ZERO
@export var _initial_rotation: Vector3 = Vector3(-40.0, -20.0, 0.0)
@export var _initial_zoom: float = 4.0

@export_group("Movement")
@export var _movement_input_speed: float = 20.0
@export var _movement_lerp_speed: float = 5.0

@export_group("Rotation")
@export var _rotation_input_speed: float = 5.0
@export var _rotation_lerp_speed: float = 5.0
@export var _min_tilt: float = -70.0
@export var _max_tilt: float = -10.0

@export_group("Zoom")
@export var _zoom_lerp_speed: float = 5.0
@export var _min_zoom: float = 2.0
@export var _max_zoom: float = 8.0

var _input_velocity: Vector2 = Vector2.ZERO

var _moving: bool = false
var _rotating: bool = false

@onready var _target_pos: Vector3 = _initial_position
@onready var _target_dir: Vector3 = _initial_rotation
@onready var _target_zoom: float = _initial_zoom

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_input_velocity = event.relative

func _process(delta: float) -> void:
	if Input.is_action_pressed("interact"):
		if abs(_input_velocity) > Vector2.ZERO:
			_moving = true
	elif Input.is_action_just_released("interact"):
		_moving = false
	elif Input.is_action_pressed("cancel"):
		if abs(_input_velocity) > Vector2.ZERO:
			_rotating = true
	elif Input.is_action_just_released("cancel"):
		_rotating = false
	elif Input.is_action_just_pressed("zoom_in"):
		_target_zoom = clampf(_target_zoom - 1.0, _min_zoom, _max_zoom)
	elif Input.is_action_just_pressed("zoom_out"):
		_target_zoom = clampf(_target_zoom + 1.0, _min_zoom, _max_zoom)
	elif Input.is_action_just_pressed("reset_cam"):
		_target_dir = _initial_rotation
		_target_zoom = _initial_zoom

	if _moving:
		var movement_direction: Vector3 = (transform.basis * Vector3(_input_velocity.x, 0.0, _input_velocity.y)).normalized()
		var movement_speed = _movement_input_speed * delta
		_target_pos.x -= movement_direction.x * movement_speed
		_target_pos.z -= movement_direction.z * movement_speed
	elif _rotating:
		var rotation_speed: float = _rotation_input_speed * delta
		_target_dir.x = clampf(_target_dir.x - (_input_velocity.y * rotation_speed), _min_tilt, _max_tilt)
		_target_dir.y -= _input_velocity.x * rotation_speed

	_input_velocity = Vector2.ZERO

	position = lerp(position, _target_pos, _movement_lerp_speed * delta)

	var target_dir_radians: Vector3 = Vector3(
		deg_to_rad(_target_dir.x),
		deg_to_rad(_target_dir.y),
		deg_to_rad(_target_dir.z)
	)
	rotation = lerp(rotation, target_dir_radians, _rotation_lerp_speed * delta)

	_camera.position.z = lerp(_camera.position.z, _target_zoom, _zoom_lerp_speed * delta)
