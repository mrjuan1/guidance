extends Node

var _scene_node: Node3D

func _physics_process(_delta: float) -> void:
	if not _scene_node:
		_find_scene_node()
		if not _scene_node:
			printerr("Could not find scene node")
			return

	if _clean_scene():
		_update()

func _find_scene_node() -> void:
	var root_children: Array[Node] = get_tree().root.get_children()
	for child: Node in root_children:
		if child.find_child("CameraController"):
			_scene_node = child
			return

func _clean_scene() -> bool:
	var children: Array[Node] = _scene_node.get_children()
	for child: Node in children:
		if child is NavigationRegion3D:
			var navigation_region_children: Array[Node] = child.get_children()
			for navigation_region_child: Node in navigation_region_children:
				if navigation_region_child is ChainPin:
					var chain_pin: ChainPin = navigation_region_child
					if not chain_pin.input:
						chain_pin.queue_free()
						return false
				elif navigation_region_child is LightBeacon:
					var light_beacon: LightBeacon = navigation_region_child
					if not light_beacon.input:
						light_beacon.active = false
		elif child is Chain:
			var chain: Chain = child
			if not chain.input or not chain.output:
				chain.queue_free()
				return false

	return true

func _process_node(node: Node3D) -> void:
	if node is ChainPin:
		var chain_pin: ChainPin = node
		for chain_pin_output: Chain in chain_pin.outputs:
			if chain_pin_output:
				chain_pin_output.active = chain_pin.active
				_process_node(chain_pin_output)
	else:
		if node is PowerSource:
			var power_source: PowerSource = node
			if power_source.output:
				var chain: Chain = power_source.output
				chain.active = power_source.active
				_process_node(chain)
		elif node is Chain:
			var chain: Chain = node
			chain.output.set("active", chain.active)
			_process_node(chain.output)
		elif node is LightBeacon:
			var light_beacon: LightBeacon = node
			if light_beacon.input:
				var chain: Chain = light_beacon.input
				light_beacon.active = chain.active
			else:
				light_beacon.active = false

func _update() -> void:
	var navigation_region: NavigationRegion3D = _scene_node.find_child("NavigationRegion")
	var children: Array[Node] = navigation_region.get_children()
	for child: Node in children:
		if child is PowerSource:
			var power_source: PowerSource = child
			_process_node(power_source)
