class_name ChainLinkInteraction
extends StaticBody3D

func select_handler(interacting: bool) -> void:
	var parent: Node3D = get_parent_node_3d()
	if parent is ChainLink:
		parent = parent.get_parent_node_3d()

	if interacting:
		if parent is PowerSource:
			ChainPlacement.start(self)
		elif parent is LightBeacon:
			print("light beacon chain link")
		elif parent is Override:
			print("override chain link")
	else:
		if parent is PowerSource:
			var power_source: PowerSource = parent
			if power_source.output:
				power_source.output.queue_free()
		elif parent is LightBeacon:
			var light_beacon: LightBeacon = parent
			if light_beacon.input:
				light_beacon.input.queue_free()
		elif parent is Override:
			var override: Override = parent
			var chain_link: ChainLink = get_parent_node_3d()
			if chain_link.name == "ChainLinkIn1" and override.input1:
				override.input1.queue_free()
			elif chain_link.name == "ChainLinkIn2" and override.input2:
				override.input2.queue_free()
			elif chain_link.name == "ChainLinkOut" and override.output:
				override.output.queue_free()
