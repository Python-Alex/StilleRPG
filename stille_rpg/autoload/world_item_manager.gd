extends Node

var world_items : Array[ItemBase] = [] # list of items currently in the world
var player_node : CharacterBody2D = null

var __item_scene_ref = {
	0x200: preload("res://game/item/items/grass_seed.tscn")
}

func _ready() -> void:
	var _p_update_signal_timer = Timer.new()
	_p_update_signal_timer.wait_time = 0.01
	_p_update_signal_timer.one_shot = false
	_p_update_signal_timer.timeout.connect(_update_player_signals)
	add_child(_p_update_signal_timer)
	_p_update_signal_timer.start()

func _update_player_signals() -> void:
	if player_node == null:
		return
	
	for item in world_items:
		if item and not item.item_picked_up.is_connected(_player_item_pickup):
			item.item_picked_up.connect(_player_item_pickup)

func _player_item_pickup(item_data: Dictionary) -> void:
	# Add to player inventory
	if player_node and player_node.inventory:
		player_node.inventory.add_item(item_data)
	
	# Remove from world_items when picked up
	for i in range(world_items.size() - 1, -1, -1):
		if world_items[i] == null or not is_instance_valid(world_items[i]):
			world_items.remove_at(i)

func get_items_in_range(dplayer_node: CharacterBody2D, drange : float) -> Array[ItemBase]:
	var items : Array[ItemBase] = []
	for item in world_items:
		if dplayer_node.position.distance_to(item.position) <= drange:
			items.append(item)
	
	return items

func add_item_to_world(item: ItemBase) -> void:
	world_items.append(item)
	
	# Connect immediately if player exists
	if player_node:
		if not item.item_picked_up.is_connected(_player_item_pickup):
			item.item_picked_up.connect(_player_item_pickup)
	
		if not item in get_children():
			add_child(item)
	else:
		print("Player not set yet, will connect via timer")
		
	
