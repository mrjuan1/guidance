class_name ChainLinkInteraction
extends StaticBody3D

func select_handler(interacting: bool) -> void:
	if interacting:
		ChainPlacement.start(self)
