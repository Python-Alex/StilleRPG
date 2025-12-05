extends Node2D

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var item_scene = preload("res://game/models/item/boxers.tscn")
			var item = item_scene.instantiate()
			
			var tile_pos = $InteriorLayer.local_to_map(get_global_mouse_position())
			var spawn_pos = $InteriorLayer.map_to_local(tile_pos)
			
			item.position = spawn_pos
			item.state = ItemState.ItemState.DROPPED
			add_child(item)
