class_name LongBoxIn
extends StaticBody3D

signal input_selected(interacting: bool)

func interact(interacting: bool) -> void:
	input_selected.emit(interacting)
