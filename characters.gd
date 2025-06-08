extends Node

const MIN_ADD_CHARACTERS: int = 5
const MAX_ADD_CHARACTERS: int = 10
const SPAWN_DISTANCE: float = 7.0

var _character_scene: PackedScene = preload("res://character.tscn")

var characters: Array[Character] = []
var target_position: Vector3

func add_characters() -> void:
	if not target_position:
		push_warning("No target position specified for characters, cannot spawn")
		return

	var amount: int = randi_range(MIN_ADD_CHARACTERS, MAX_ADD_CHARACTERS)
	for i: int in amount:
		var character: Character = _character_scene.instantiate()

		var direction: float = randf_range(0.0, TAU)
		character.position.x = target_position.x + (cos(direction) * SPAWN_DISTANCE)
		character.position.z = target_position.z + (sin(direction) * SPAWN_DISTANCE)

		characters.push_back(character)
