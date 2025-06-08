class_name Character
extends CharacterBody3D

enum CharacterAnimation {
	IDLE,
	MOVE
}

@export var _movement_speed: float = 2.0
@export var _rotation_speed: float = 10.0

var _animation: CharacterAnimation
var _last_animation: CharacterAnimation
var _target_rotation: float = rotation.y

@onready var _character_animation: AnimationPlayer = $CharacterAnimation
@onready var _character_navigation: NavigationAgent3D = $CharacterNavigation
@onready var _idle_timer: Timer = $IdleTimer

func _ready() -> void:
	move()

func _physics_process(delta: float) -> void:
	if _animation == CharacterAnimation.MOVE:
		var next_position: Vector3 = _character_navigation.get_next_path_position()
		next_position.y = 0.0
		var movement_velocity: Vector3 = position.direction_to(next_position) * _movement_speed
		movement_velocity.y = velocity.y
		_character_navigation.velocity = movement_velocity

		var direction: Vector3 = next_position - position
		_target_rotation = atan2(direction.x, direction.z)
		rotation.x = 0.0

	move_and_slide()

func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, _target_rotation, _rotation_speed * delta)

func _play_animation(animation: CharacterAnimation) -> void:
	_animation = animation

	if _animation != _last_animation:
		var name: String
		match _animation:
			CharacterAnimation.IDLE:
				name = "Character/Idle"
				_character_animation.speed_scale = 1.5
				_idle_timer.wait_time = randf_range(2.0, 5.0)
				_idle_timer.start()
			CharacterAnimation.MOVE:
				name = "Character/Move"
				_character_animation.speed_scale = 4.0
				_idle_timer.stop()
				_retarget()
		_character_animation.play(name)

		var start_position: float = randf_range(0.0, _character_animation.current_animation_length)
		_character_animation.seek(start_position, true)

		_last_animation = _animation

func _retarget() -> void:
	var target_position: Vector3 = Characters.target_position
	var direction: float = randf_range(0.0, TAU)
	target_position.x += cos(direction) * randf_range(2.0, 3.0)
	target_position.z += sin(direction) * randf_range(2.0, 3.0)
	_character_navigation.target_position = target_position

func _on_character_navigation_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity

func _on_character_navigation_target_reached() -> void:
	_play_animation(CharacterAnimation.IDLE)

func _on_idle_timer_timeout() -> void:
	_retarget()
	_play_animation(CharacterAnimation.MOVE)
	_idle_timer.wait_time = randf_range(2.0, 5.0)

func move() -> void:
	_last_animation = CharacterAnimation.IDLE
	_play_animation(CharacterAnimation.MOVE)
