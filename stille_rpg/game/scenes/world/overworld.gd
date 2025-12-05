extends Node2D

func _ready():
	for i in range(72):
		var scene = preload("res://game/item/items/grass_seed.tscn")
		var instance = scene.instantiate()
		
		WorldItemManager.add_item_to_world(instance)
		
		instance.position = Vector2(randi_range(-100, 100), randi_range(-100, 100))

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed("open_context_menu")):
		print("?H")
		WorldItemManager.player_node.toggle_ui_visibility()
