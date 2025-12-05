extends Node

var inventory_page : Node
var inventory_grid : Node

var inventory_list : Array = []

var parent

func _ready() -> void:
	parent = get_parent()
	
	inventory_page = get_parent().get_node("UI").get_node("InventoryPage")
	inventory_grid = inventory_page.get_node("InventoryGrid").get_node("Container")
	
	parent.item_picked_up.connect(_on_item_picked_up)
	
func _on_item_picked_up(item) -> void:
	if(item.state == ItemState.ItemState.INVENTORY or is_inventory_full()):
		return
		
	var first_empty = get_first_empty_slot()
	
	for child in inventory_grid.get_children():
		if(item == child):
			return

	item.hide()
	item.state = ItemState.ItemState.INVENTORY
			
	first_empty.item = item
	
	item.reparent.call_deferred(parent)
		
func get_first_empty_slot() -> Node:
	for child in inventory_grid.get_children():
		if(child.item == null):
			return child

	return null

func is_inventory_full() -> bool:
	var full = true
	
	for child in inventory_grid.get_children():
		if(child.item == null):
			full = false
			
	return full
			
