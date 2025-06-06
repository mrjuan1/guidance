extends CSGBox3D

signal _state_toggled

const _INACTIVE_COLOUR: String = "blue"
const _ACTIVE_COLOUR: String = "yellow"

var _active: bool = false

@onready var _material: StandardMaterial3D = (material as StandardMaterial3D)
@onready var _inactive_texture: Texture2D = load(_material.albedo_texture.resource_path)
@onready var _active_texture: Texture2D = load(_material.albedo_texture.resource_path.replace(_INACTIVE_COLOUR, _ACTIVE_COLOUR))

func interact() -> void:
	_active = !_active
	if _active:
		_material.albedo_texture = _active_texture
	else:
		_material.albedo_texture = _inactive_texture

	_state_toggled.emit(_active)
