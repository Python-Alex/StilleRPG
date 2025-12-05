extends Node

var world_items : Array[ItemBase] = [] # list of items currently in the world
var player_node : CharacterBody2D = null

# Culling manager (optional - will be created if it doesn't exist)
var culling_manager : ItemCullingManager = null

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
	
	# Check if we have a culling manager as a child
	for child in get_children():
		if child is ItemCullingManager:
			culling_manager = child
			break
	
	# If no culling manager exists, create one with default settings
	if culling_manager == null:
		culling_manager = ItemCullingManager.new()
		culling_manager.culling_method = ItemCullingManager.CullingMethod.SPATIAL_HASHING
		culling_manager.culling_update_rate = 0.1
		culling_manager.culling_margin = 100.0
		culling_manager.spatial_cell_size = 256
		add_child(culling_manager)
		print("[WorldItemManager] Created default ItemCullingManager")

func _update_player_signals() -> void:
	if player_node == null:
		return
	
	for item in world_items:
		if item and not item.item_picked_up.is_connected(_player_item_pickup):
			item.item_picked_up.connect(_player_item_pickup)

func _player_item_pickup(item_data: Dictionary, item_instance: ItemBase) -> void:
	# Add to player inventory
	if player_node and player_node.inventory:
		player_node.inventory.add_item(item_data)
	
	# Unregister from culling manager BEFORE the item is freed
	if culling_manager and is_instance_valid(item_instance):
		culling_manager.unregister_item(item_instance)
	
	# Remove from world_items list
	if item_instance in world_items:
		world_items.erase(item_instance)
	
	# Clean up any invalid items while we're at it
	for i in range(world_items.size() - 1, -1, -1):
		if world_items[i] == null or not is_instance_valid(world_items[i]):
			world_items.remove_at(i)

func _player_item_drop(item_data: Dictionary, drop_position: Vector2) -> void:
	"""
	Handles dropping an item from the player's inventory into the world.
	Creates the item instance, sets it up properly, and adds it to the world.
	"""
	if not player_node:
		print("Error: Player node not set in WorldItemManager")
		return
	
	# Check if item is droppable
	if not item_data.get("is_droppable", false):
		print("Cannot drop this item!")
		return
	
	# Check if we have a scene for this item
	if not __item_scene_ref.has(item_data.id):
		print("Error: No scene found for item ID ", item_data.id)
		return
	
	# Create the item instance
	var scene = __item_scene_ref[item_data.id]
	var instance = scene.instantiate()
	
	# Add to world items list and scene tree FIRST
	# This ensures the node is fully initialized before we set data
	world_items.append(instance)
	add_child(instance)
	
	# Wait a frame to ensure the node is fully ready
	await get_tree().process_frame
	
	# Now set the item data (sprite nodes should be ready now)
	instance.set_item_data(item_data)
	
	# Drop it at the specified position (activates cooldown)
	instance.drop(drop_position)
	
	# Connect the pickup signal
	if not instance.item_picked_up.is_connected(_player_item_pickup):
		instance.item_picked_up.connect(_player_item_pickup)
	
	# Register with culling manager
	if culling_manager:
		culling_manager.register_item(instance)
	
	print("Dropped item: ", item_data.name, " at position: ", drop_position)

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
			
		# Register with culling manager
		if culling_manager:
			culling_manager.register_item(item)
	else:
		print("Player not set yet, will connect via timer")

# =============================================================================
# CULLING CONTROL - Convenience Functions
# =============================================================================

func switch_culling_method(method: int) -> void:
	"""
	Switch culling method at runtime
	Parameters:
		method: 0 = NONE, 1 = SIMPLE, 2 = SPATIAL_HASHING
	"""
	if culling_manager:
		culling_manager.set_culling_method(method)
	else:
		push_warning("[WorldItemManager] No culling manager available")

func set_culling_update_rate(rate: float) -> void:
	"""Change how often culling updates (in seconds)"""
	if culling_manager:
		culling_manager.set_update_rate(rate)

func set_culling_margin(margin: float) -> void:
	"""Change the margin around screen to keep items loaded"""
	if culling_manager:
		culling_manager.set_margin(margin)

func set_spatial_cell_size(size: int) -> void:
	"""Change spatial grid cell size (only for SPATIAL_HASHING method)"""
	if culling_manager:
		culling_manager.set_cell_size(size)

func get_culling_stats() -> Dictionary:
	"""Get current culling statistics"""
	if culling_manager:
		return culling_manager.get_stats()
	return {}

func print_culling_stats() -> void:
	"""Print culling statistics to console"""
	if culling_manager:
		culling_manager.print_stats()
	else:
		print("[WorldItemManager] No culling manager available")

func get_item_counts() -> Dictionary:
	"""
	Get comprehensive item counts including culling info.
	Returns: {
		"world_items_total": int,
		"culled_visible": int,
		"culled_hidden": int,
		"culled_percent_visible": float
	}
	"""
	var world_total = world_items.size()
	
	var counts = {
		"world_items_total": world_total,
		"culled_visible": 0,
		"culled_hidden": 0,
		"culled_percent_visible": 0.0
	}
	
	if culling_manager:
		var culling_counts = culling_manager.get_item_counts()
		counts["culled_visible"] = culling_counts.visible
		counts["culled_hidden"] = culling_counts.hidden
		counts["culled_percent_visible"] = culling_counts.visible_percent
	
	return counts

func print_item_counts() -> void:
	"""Print detailed item count information"""
	var counts = get_item_counts()
	
	print("[WorldItemManager] === ITEM COUNTS ===")
	print("  Total World Items: ", counts.world_items_total)
	
	if culling_manager:
		print("  --- Culling Info ---")
		print("  Visible: ", counts.culled_visible, " (", "%.1f" % counts.culled_percent_visible, "%)")
		print("  Hidden: ", counts.culled_hidden)
	else:
		print("  Culling: Disabled")
	
	print("==========================")

func get_visible_item_count() -> int:
	"""Get count of visible items"""
	if culling_manager:
		return culling_manager.get_visible_item_count()
	return world_items.size()  # All visible if no culling

func get_hidden_item_count() -> int:
	"""Get count of hidden items"""
	if culling_manager:
		return culling_manager.get_hidden_item_count()
	return 0  # None hidden if no culling
