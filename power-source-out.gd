extends StaticBody3D

signal output_selected(interacting: bool)

func interact(interacting: bool) -> void:
	output_selected.emit(interacting)
