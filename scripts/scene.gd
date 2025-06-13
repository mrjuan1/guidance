class_name Scene

var _root_node: Node3D
var _camera_controller: CameraController

var root_node: Node3D:
	get:
		return _root_node
	set(_value):
		pass

var camera_controller: CameraController:
	get:
		return _camera_controller
	set(_value):
		pass

func _init(root_node_value: Node3D, camera_controller_value: CameraController) -> void:
	_root_node = root_node_value
	_camera_controller = camera_controller_value
