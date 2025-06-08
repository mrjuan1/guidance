extends Node3D

signal input_selected(interacting: bool)

func _on_long_box_in_input_selected(interacting: bool) -> void:
	input_selected.emit(interacting)
