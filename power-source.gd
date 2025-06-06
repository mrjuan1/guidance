extends StaticBody3D

signal state_toggled(active: bool)
signal output_selected(power_source: StaticBody3D)

const _INACTIVE_COLOUR: String = "blue"
const _ACTIVE_COLOUR: String = "yellow"

var _active: bool = false

@onready var mesh: MeshInstance3D = $Mesh
@onready var _material: StandardMaterial3D = (mesh.get_active_material(0) as StandardMaterial3D)
@onready var _inactive_texture: Texture2D = load(_material.albedo_texture.resource_path)
@onready var _active_texture: Texture2D = load(_material.albedo_texture.resource_path.replace(_INACTIVE_COLOUR, _ACTIVE_COLOUR))

func interact() -> void:
	_active = !_active
	if _active:
		_material.albedo_texture = _active_texture
	else:
		_material.albedo_texture = _inactive_texture

	state_toggled.emit(_active)

func _on_power_source_out_output_selected() -> void:
	output_selected.emit(self)
