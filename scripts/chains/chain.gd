class_name Chain
extends Node3D

var active: bool:
	set(value):
		active = value
		var chain_links: Array[Node] = get_children()
		for chain_link: ChainLink in chain_links:
			chain_link.active = active

var input: Node3D
var output: Node3D
