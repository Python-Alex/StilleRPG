extends Node2D

func _ready():
	pass

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("open_context_menu")):
		print("?H")
		WorldItemManager.player_node.toggle_ui_visibility()
