extends Node
class_name ItemCullingManager

# =============================================================================
# ITEM CULLING MANAGER - Configurable Visibility Culling System
# =============================================================================
# Separate node that manages visibility culling for world items
# Can be attached to WorldItemManager or run independently

# =============================================================================
# CONFIGURATION
# =============================================================================

## Culling method to use
enum CullingMethod {
	NONE,              # No culling (all items always visible)
	SIMPLE,            # Simple rectangle check - good for <1000 items
	SPATIAL_HASHING    # Spatial grid - excellent for 10,000+ items
}

@export var culling_method : CullingMethod = CullingMethod.SPATIAL_HASHING
@export var culling_update_rate : float = 0.1  # How often to update culling (seconds)
@export var culling_margin : float = 100.0      # Extra pixels beyond screen to keep items visible
@export var spatial_cell_size : int = 256       # Size of spatial grid cells (only for SPATIAL_HASHING)

# =============================================================================
# CORE VARIABLES
# =============================================================================

var viewport : Viewport = null
var viewport_size : Vector2 = Vector2.ZERO
var items_to_cull : Array[Node2D] = []  # Items to manage culling for

# =============================================================================
# SPATIAL HASHING VARIABLES (only used if culling_method = SPATIAL_HASHING)
# =============================================================================

var spatial_grid : Dictionary = {}       # Key: Vector2i (cell coords), Value: Array[Node2D]
var items_to_cells : Dictionary = {}    # Maps item -> current cell for fast updates

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Get viewport
	viewport = get_viewport()
	viewport_size = viewport.get_visible_rect().size
	
	var window_size = DisplayServer.window_get_size()
	
	# Set up culling timer (if culling is enabled)
	if culling_method != CullingMethod.NONE:
		var culling_timer = Timer.new()
		culling_timer.wait_time = culling_update_rate
		culling_timer.one_shot = false
		culling_timer.timeout.connect(_update_culling)
		add_child(culling_timer)
		culling_timer.start()
		
		print("[ItemCullingManager] Initialized with method: ", CullingMethod.keys()[culling_method])
		print("[ItemCullingManager] Update rate: ", culling_update_rate, "s")
		print("[ItemCullingManager] Window size: ", window_size)
		print("[ItemCullingManager] Viewport size: ", viewport_size)
		if culling_method == CullingMethod.SPATIAL_HASHING:
			print("[ItemCullingManager] Spatial cell size: ", spatial_cell_size, "px")

# =============================================================================
# PUBLIC API
# =============================================================================

func register_item(item: Node2D) -> void:
	"""Register an item to be culled"""
	if item not in items_to_cull:
		items_to_cull.append(item)
		
		if culling_method == CullingMethod.SPATIAL_HASHING:
			_add_item_to_spatial_grid(item)

func unregister_item(item: Node2D) -> void:
	"""Unregister an item from culling"""
	if item in items_to_cull:
		items_to_cull.erase(item)
		
		if culling_method == CullingMethod.SPATIAL_HASHING:
			_remove_item_from_spatial_grid(item)

func clear_all_items() -> void:
	"""Clear all registered items"""
	items_to_cull.clear()
	spatial_grid.clear()
	items_to_cells.clear()

# =============================================================================
# CULLING SYSTEM
# =============================================================================

func _update_culling() -> void:
	"""Main culling update function - dispatches to appropriate method"""
	if viewport == null or items_to_cull.is_empty():
		return
	
	match culling_method:
		CullingMethod.NONE:
			return
		CullingMethod.SIMPLE:
			_update_culling_simple()
		CullingMethod.SPATIAL_HASHING:
			_update_culling_spatial()

func _get_culling_rect() -> Rect2:
	"""Calculate the visible rectangle from viewport perspective"""
	# Get the canvas transform to find what world coordinates are visible
	var canvas_transform = viewport.get_canvas_transform()
	
	# Use the actual window size (display resolution)
	var window_size = DisplayServer.window_get_size()
	
	# The viewport rect in canvas (world) coordinates using full window size
	var viewport_rect = Rect2(Vector2.ZERO, window_size)
	
	# Transform viewport rect to world coordinates
	var world_rect = canvas_transform.affine_inverse() * viewport_rect
	
	# Add margin for smoother transitions
	world_rect = world_rect.grow(culling_margin)
	
	return world_rect

func _update_culling_simple() -> void:
	"""
	Simple culling method - checks every item against camera rect.
	Performance: O(n) where n = total items
	Good for: < 1000 items
	"""
	var culling_rect = _get_culling_rect()
	
	for item in items_to_cull:
		if not is_instance_valid(item):
			continue
		
		# Check if item is within culling rect
		var item_in_view = culling_rect.has_point(item.global_position)
		
		# Only update visibility if it changed (prevents unnecessary updates)
		if item.visible != item_in_view:
			item.visible = item_in_view
			
			# Also disable collision processing for hidden items
			_set_collision_enabled(item, item_in_view)

func _update_culling_spatial() -> void:
	"""
	Spatial hashing method - only checks items in visible cells.
	Performance: O(items_in_visible_cells)
	Excellent for: 10,000+ items
	"""
	var culling_rect = _get_culling_rect()
	
	# Get all cells that intersect with the visible area
	var visible_cells = _get_cells_in_rect(culling_rect)
	
	# Track which items we've processed this frame
	var processed_items : Dictionary = {}
	
	# Show items in visible cells
	for cell in visible_cells:
		if not spatial_grid.has(cell):
			continue
		
		for item in spatial_grid[cell]:
			if not is_instance_valid(item):
				continue
			
			processed_items[item] = true
			
			# Double-check with actual rectangle (items on cell borders)
			var item_in_view = culling_rect.has_point(item.global_position)
			
			if item.visible != item_in_view:
				item.visible = item_in_view
				_set_collision_enabled(item, item_in_view)
	
	# Hide items not in visible cells
	for cell in spatial_grid.keys():
		if cell in visible_cells:
			continue  # Already processed
		
		for item in spatial_grid[cell]:
			if not is_instance_valid(item) or processed_items.has(item):
				continue
			
			if item.visible:
				item.visible = false
				_set_collision_enabled(item, false)

func _set_collision_enabled(item: Node2D, enabled: bool) -> void:
	"""Helper to disable/enable collision for an item"""
	if item.has_node("CollisionShape2D"):
		item.get_node("CollisionShape2D").set_deferred("disabled", not enabled)
	elif item.has_node("CollisionPolygon2D"):
		item.get_node("CollisionPolygon2D").set_deferred("disabled", not enabled)

# =============================================================================
# SPATIAL HASHING IMPLEMENTATION
# =============================================================================

func _get_cell_coords(pos: Vector2) -> Vector2i:
	"""Convert world position to grid cell coordinates"""
	return Vector2i(
		int(floor(pos.x / spatial_cell_size)),
		int(floor(pos.y / spatial_cell_size))
	)

func _add_item_to_spatial_grid(item: Node2D) -> void:
	"""Add item to the spatial hash grid"""
	if not is_instance_valid(item):
		return
		
	var cell = _get_cell_coords(item.global_position)
	
	if not spatial_grid.has(cell):
		spatial_grid[cell] = []
	
	if item not in spatial_grid[cell]:
		spatial_grid[cell].append(item)
	
	items_to_cells[item] = cell

func _remove_item_from_spatial_grid(item: Node2D) -> void:
	"""Remove item from the spatial hash grid"""
	if not items_to_cells.has(item):
		return
	
	var cell = items_to_cells[item]
	
	if spatial_grid.has(cell):
		spatial_grid[cell].erase(item)
		# Clean up empty cells
		if spatial_grid[cell].is_empty():
			spatial_grid.erase(cell)
	
	items_to_cells.erase(item)

func _update_item_spatial_position(item: Node2D) -> void:
	"""Update item's position in spatial grid if it moved to a different cell"""
	if not is_instance_valid(item):
		return
		
	if not items_to_cells.has(item):
		_add_item_to_spatial_grid(item)
		return
	
	var old_cell = items_to_cells[item]
	var new_cell = _get_cell_coords(item.global_position)
	
	if old_cell != new_cell:
		# Item moved to a different cell, update it
		if spatial_grid.has(old_cell):
			spatial_grid[old_cell].erase(item)
			if spatial_grid[old_cell].is_empty():
				spatial_grid.erase(old_cell)
		
		if not spatial_grid.has(new_cell):
			spatial_grid[new_cell] = []
		
		spatial_grid[new_cell].append(item)
		items_to_cells[item] = new_cell

func _get_cells_in_rect(rect: Rect2) -> Array[Vector2i]:
	"""Get all grid cells that intersect with the given rectangle"""
	var cells : Array[Vector2i] = []
	
	var min_cell = _get_cell_coords(rect.position)
	var max_cell = _get_cell_coords(rect.position + rect.size)
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			cells.append(Vector2i(x, y))
	
	return cells

func rebuild_spatial_grid() -> void:
	"""Rebuild the entire spatial grid (call after changing cell_size or adding many items)"""
	spatial_grid.clear()
	items_to_cells.clear()
	
	for item in items_to_cull:
		if is_instance_valid(item):
			_add_item_to_spatial_grid(item)
	
	print("[ItemCullingManager] Rebuilt spatial grid with ", spatial_grid.size(), " cells")

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

func set_culling_method(method: CullingMethod) -> void:
	"""Change culling method at runtime"""
	var old_method = culling_method
	culling_method = method
	
	print("[ItemCullingManager] Switching from ", CullingMethod.keys()[old_method], " to ", CullingMethod.keys()[method])
	
	# Handle transition from NONE - make sure all items are registered
	if old_method == CullingMethod.NONE:
		print("[ItemCullingManager] Re-enabling culling, registering all items")
	
	# Handle transition to SPATIAL_HASHING - build the grid
	if method == CullingMethod.SPATIAL_HASHING:
		if spatial_grid.is_empty() and not items_to_cull.is_empty():
			print("[ItemCullingManager] Building spatial grid...")
			rebuild_spatial_grid()
	
	# Handle transition to NONE - make all items visible
	elif method == CullingMethod.NONE:
		print("[ItemCullingManager] Disabling culling, showing all items")
		for item in items_to_cull:
			if is_instance_valid(item):
				item.visible = true
				_set_collision_enabled(item, true)
	
	# Handle transition to SIMPLE from SPATIAL_HASHING - clean up grid
	elif method == CullingMethod.SIMPLE and old_method == CullingMethod.SPATIAL_HASHING:
		print("[ItemCullingManager] Clearing spatial grid (switching to simple culling)")
		# Don't clear completely, but can rebuild later if needed
	
	print("[ItemCullingManager] Method switch complete")

func set_update_rate(rate: float) -> void:
	"""Change how often culling updates"""
	culling_update_rate = rate

func set_margin(margin: float) -> void:
	"""Change culling margin"""
	culling_margin = margin

func set_cell_size(size: int) -> void:
	"""Change spatial grid cell size and rebuild grid"""
	spatial_cell_size = size
	if culling_method == CullingMethod.SPATIAL_HASHING:
		rebuild_spatial_grid()

func get_visible_item_count() -> int:
	"""Get count of currently visible items"""
	var count = 0
	for item in items_to_cull:
		if is_instance_valid(item) and item.visible:
			count += 1
	return count

func get_hidden_item_count() -> int:
	"""Get count of currently hidden items"""
	var count = 0
	for item in items_to_cull:
		if is_instance_valid(item) and not item.visible:
			count += 1
	return count

func get_total_item_count() -> int:
	"""Get total count of registered items (visible + hidden)"""
	var count = 0
	for item in items_to_cull:
		if is_instance_valid(item):
			count += 1
	return count

func get_item_counts() -> Dictionary:
	"""
	Get detailed breakdown of item visibility counts.
	Returns: {
		"total": int,
		"visible": int, 
		"hidden": int,
		"visible_percent": float,
		"invalid": int
	}
	"""
	var total = 0
	var visible = 0
	var hidden = 0
	var invalid = 0
	
	for item in items_to_cull:
		if is_instance_valid(item):
			total += 1
			if item.visible:
				visible += 1
			else:
				hidden += 1
		else:
			invalid += 1
	
	var visible_percent = (float(visible) / float(total) * 100.0) if total > 0 else 0.0
	
	return {
		"total": total,
		"visible": visible,
		"hidden": hidden,
		"visible_percent": visible_percent,
		"invalid": invalid
	}

func print_item_counts() -> void:
	"""Print detailed item count information to console"""
	var counts = get_item_counts()
	print("[ItemCullingManager] === ITEM COUNTS ===")
	print("  Total Items: ", counts.total)
	print("  Visible: ", counts.visible, " (", "%.1f" % counts.visible_percent, "%)")
	print("  Hidden: ", counts.hidden)
	if counts.invalid > 0:
		print("  Invalid: ", counts.invalid, " (needs cleanup)")
	print("  Culling Method: ", CullingMethod.keys()[culling_method])

func get_stats() -> Dictionary:
	"""Get statistics about the culling system"""
	var stats = {
		"culling_method": CullingMethod.keys()[culling_method],
		"total_items": items_to_cull.size(),
		"visible_items": get_visible_item_count(),
		"update_rate": culling_update_rate,
		"margin": culling_margin
	}
	
	if culling_method == CullingMethod.SPATIAL_HASHING:
		stats["grid_cells"] = spatial_grid.size()
		stats["cell_size"] = spatial_cell_size
	
	return stats

func print_stats() -> void:
	"""Print culling statistics to console"""
	var stats = get_stats()
	print("[ItemCullingManager] === STATISTICS ===")
	for key in stats:
		print("  ", key, ": ", stats[key])
