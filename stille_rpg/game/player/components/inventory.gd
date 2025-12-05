extends Node

var inventory_list : Array = []
var max_inventory_items : int = 27
var parent : CharacterBody2D
var selected_slots : Array[TextureButton] = []

func _ready():
	parent = get_parent()
	# Connect to the UI node to detect clicks
	parent.get_node("UI").gui_input.connect(_on_ui_input)
	
func _on_ui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var summary_panel = parent.get_node("UI/ContextPanelBackground/InventoryPanel/ItemSummaryPanel")
		
		# Only check if summary is visible
		if summary_panel.visible:
			# Get mouse position relative to summary panel
			var mouse_pos = summary_panel.get_local_mouse_position()
			var panel_rect = Rect2(Vector2.ZERO, summary_panel.size)
			
			# If click is outside the panel, deselect
			if not panel_rect.has_point(mouse_pos):
				deselect_all_slots()
				
func ensure_all_slots_connected() -> void:
	var inventory_grid = parent.get_node("UI/ContextPanelBackground/InventoryPanel/ScrollContainer/InventoryGrid")
	for slot in inventory_grid.get_children():
		if not slot.slot_selected.is_connected(_on_slot_selected):
			slot.slot_selected.connect(_on_slot_selected)
		if not slot.slot_deselected.is_connected(_on_slot_deselected):
			slot.slot_deselected.connect(_on_slot_deselected)
			
			
func add_item(item_data: Dictionary) -> bool:
	deselect_all_slots()
	
	var remaining_amount = item_data.stack_size
	
	for existing_item in inventory_list:
		if items_match(existing_item, item_data):
			var space_available = existing_item.max_stack - existing_item.stack_size
			
			if space_available > 0:
				var amount_to_add = min(remaining_amount, space_available)
				existing_item.stack_size += amount_to_add
				remaining_amount -= amount_to_add
				
				update_inventory_slot(existing_item)
				
				if remaining_amount <= 0:
					return true
	
	while remaining_amount > 0:
		# Check if inventory is full
		if len(inventory_list) >= max_inventory_items:
			return false
		
		# Create a new stack with remaining items (up to max_stack)
		var new_stack_size = min(remaining_amount, item_data.max_stack)
		
		# Create a copy of item_data for the new slot
		var new_item_data = item_data.duplicate()
		new_item_data.stack_size = new_stack_size
		
		# Add to inventory list
		inventory_list.append(new_item_data)
		
		# Get the inventory grid
		var inventory_grid = parent.get_node("UI/ContextPanelBackground/InventoryPanel/ScrollContainer/InventoryGrid")
		var inventory_slot_scene = preload("res://game/scenes/gui/player/inventory_slot.tscn")
		
		# Create new inventory slot
		var inventory_slot = inventory_slot_scene.instantiate()
		inventory_slot.item_data = new_item_data
		
		# Add slot to inventory grid
		inventory_grid.add_child(inventory_slot)
		
		inventory_slot.slot_selected.connect(_on_slot_selected)
		inventory_slot.slot_deselected.connect(_on_slot_deselected)
		
		# Reduce remaining amount
		remaining_amount -= new_stack_size
	
	return true
	
func remove_item_slot(slot: TextureButton) -> void:
	# Remove from inventory_list
	for i in range(inventory_list.size() - 1, -1, -1):
		if inventory_list[i] == slot.item_data:
			inventory_list.remove_at(i)
			break
	
	# Remove from selected_slots if selected
	if slot in selected_slots:
		selected_slots.erase(slot)
	
	# Free the slot
	slot.queue_free()
	
func _on_slot_selected(slot: TextureButton) -> void:
	if slot in selected_slots:
		return
	
	deselect_all_slots()
	
	if slot not in selected_slots:
		selected_slots.append(slot)
	
	# Show and position the summary panel
	show_summary_for_slot(slot)

func show_summary_for_slot(slot: TextureButton) -> void:
	var summary_panel = parent.get_node("UI/ContextPanelBackground/InventoryPanel/ItemSummaryPanel")
	
	# Use global positions and convert back to local
	var slot_global_rect = slot.get_global_rect()
	var inventory_panel = summary_panel.get_parent()
	
	# Convert global position to local position within InventoryPanel
	var local_pos = inventory_panel.get_global_transform().affine_inverse() * slot_global_rect.position
	
	# Position at bottom-left of the slot
	summary_panel.position = local_pos + Vector2(0, slot_global_rect.size.y - 1)
	summary_panel.show()
	

func _on_slot_deselected(slot: TextureButton) -> void:
	# Hide the summary before removing from array
	if slot.has_node("SelectedItemSummary"):
		slot.get_node("SelectedItemSummary").hide()
	
	if slot in selected_slots:
		selected_slots.erase(slot)
		
	var summary_panel = parent.get_node("UI/ContextPanelBackground/InventoryPanel/ItemSummaryPanel")
	summary_panel.hide()
	
func deselect_all_slots() -> void:
	for slot in selected_slots:
		slot.deselect()
	
	selected_slots.clear()
	
	# Hide the summary panel
	var summary_panel = parent.get_node("UI/ContextPanelBackground/InventoryPanel/ItemSummaryPanel")
	summary_panel.hide()

func update_selected_item_summary_visibility() -> void:
	if len(selected_slots) == 0:
		return
	else:
		if selected_slots[0].has_node("SelectedItemSummary"):
			selected_slots[0].get_node("SelectedItemSummary").show()
	
	
func items_match(item1: Dictionary, item2: Dictionary) -> bool:
	# Compare all fields except stack_size
	if item1.id != item2.id:
		return false
	if item1.name != item2.name:
		return false
	if item1.description != item2.description:
		return false
	if item1.tags != item2.tags:
		return false
	if item1.max_stack != item2.max_stack:
		return false
	if item1.value != item2.value:
		return false
	if item1.scene_path != item2.scene_path:
		return false
	if item1.has("data") and item2.has("data") and item1.data != item2.data:
		return false
	if item1.has("metadata") and item2.has("metadata") and item1.metadata != item2.metadata:
		return false
	
	return true

func update_inventory_slot(item_data: Dictionary):
	var inventory_grid = parent.get_node("UI/ContextPanelBackground/InventoryPanel/ScrollContainer/InventoryGrid")
	for slot in inventory_grid.get_children():
		if slot.item_data == item_data:
			slot.update_display()
			break
