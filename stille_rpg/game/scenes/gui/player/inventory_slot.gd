extends TextureButton

var item_data : Dictionary = {}
var selected : bool = false
signal slot_selected(slot: TextureButton)
signal slot_deselected(slot: TextureButton)

func _ready() -> void:
	pressed.connect(_on_pressed)
	update_display()
	
	# Hide summary by default
	if has_node("SelectedItemSummary"):
		$SelectedItemSummary.hide()

func _gui_input(event: InputEvent) -> void:
	# If summary is visible, don't process input on the parent button
	if has_node("SelectedItemSummary") and $SelectedItemSummary.visible:
		if event is InputEventMouseButton:
			accept_event()  # Consume the event so it doesn't trigger pressed signal
		
func _on_pressed() -> void:
	if selected:
		selected = false
		update_selection_visual()
		slot_deselected.emit(self)
	else:
		selected = true
		update_selection_visual()
		slot_selected.emit(self)

func update_display() -> void:
	# Set up the slot visuals based on item data
	if item_data.has("icon") and item_data.icon:
		$ItemTexture.texture = item_data.icon
	
	# Set up tooltip or label
	if item_data.has("name"):
		tooltip_text = item_data.name
		if item_data.has("description"):
			tooltip_text += "\n" + item_data.description
	
	if item_data.has("stack_size"):
		$Label.text = "%d" % [item_data.stack_size]
	
	show()
	$ItemTexture.show()
	$Label.show()
	
	# Update selection visual when display updates
	update_selection_visual()

func update_selection_visual() -> void:
	if selected:
		$HoverIcon.visible = true
	else:
		$HoverIcon.visible = false

func deselect() -> void:
	selected = false
	update_selection_visual()
	
	# Hide summary when deselected
	if has_node("SelectedItemSummary"):
		$SelectedItemSummary.hide()

func _on_mouse_entered() -> void:
	if not selected:  # Only show hover if not selected
		$HoverIcon.visible = true

func _on_mouse_exited() -> void:
	if not selected:  # Only hide hover if not selected
		$HoverIcon.visible = false

func clear_slot() -> void:
	# Clear item data
	item_data = {}
	
	# Clear texture
	if has_node("ItemTexture"):
		$ItemTexture.texture = null
	
	# Clear label
	if has_node("Label"):
		$Label.text = ""
	
	# Hide elements
	if has_node("ItemTexture"):
		$ItemTexture.hide()
	if has_node("Label"):
		$Label.hide()
	if has_node("HoverIcon"):
		$HoverIcon.hide()
	if has_node("SelectedItemSummary"):
		$SelectedItemSummary.hide()
	
	# Reset selection state
	selected = false
	
	# Clear tooltip
	tooltip_text = ""
	
	# Keep the root TextureButton visible
	show()
