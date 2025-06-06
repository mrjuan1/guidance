extends StaticBody3D

signal output_selected

func interact() -> void:
	output_selected.emit()
