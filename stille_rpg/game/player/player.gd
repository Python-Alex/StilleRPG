extends CharacterBody2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var collision : CollisionShape2D = $PlayerCollision
@onready var camera : Camera2D = $PlayerCamera
@onready var stats : Node = $Statistics
@onready var inventory = $Inventory

@export var speed : float = 200.0

var last_direction : Vector2 = Vector2.DOWN

func _ready():
	WorldItemManager.player_node = self

var current_input : Vector2 = Vector2.ZERO

func _physics_process(delta):
	handle_movement()
	handle_animation()
	move_and_slide()

func handle_movement():
	# Get input direction
	current_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Normalize diagonal movement so it doesn't move faster
	if current_input.length() > 0:
		current_input = current_input.normalized()
		last_direction = current_input
	
	# Apply movement
	velocity = current_input * speed

func handle_animation():
	# Check if moving based on input, not velocity
	var is_moving = current_input.length() > 0
	
	# Determine animation based on direction
	var anim_name = ""
	
	if is_moving:
		anim_name = "walking_" + get_direction_name(last_direction)
	else:
		anim_name = "idle_" + get_direction_name(last_direction)
	
	# Play animation if it's different from current
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func get_position_outside_player(area_size: float = 100.0, min_distance: float = 30.0) -> Vector2:
	var player_pos = global_position
	var random_pos = Vector2.ZERO
	
	# Keep generating until we find a valid position
	for i in range(100):
		random_pos = player_pos + Vector2(
			randf_range(-area_size / 2, area_size / 2),
			randf_range(-area_size / 2, area_size / 2)
		)
		
		if player_pos.distance_to(random_pos) >= min_distance:
			return random_pos
	
	# Fallback
	return player_pos + Vector2(min_distance, 0)

func get_direction_name(dir: Vector2) -> String:
	# Normalize direction for comparison
	var normalized = dir.normalized()
	
	# Define threshold for diagonal detection (45 degrees = 0.707)
	var diagonal_threshold = 0.5
	
	# Check for 8 directions
	# Pure cardinals first
	if abs(normalized.x) < diagonal_threshold:
		# Mostly vertical
		if normalized.y < 0:
			return "up"
		else:
			return "down"
	elif abs(normalized.y) < diagonal_threshold:
		# Mostly horizontal
		if normalized.x < 0:
			return "left"
		else:
			return "right"
	else:
		# Diagonals
		if normalized.y < 0:
			# Upper diagonals
			if normalized.x < 0:
				return "up_left"
			else:
				return "up_right"
		else:
			# Lower diagonals
			if normalized.x < 0:
				return "down_left"
			else:
				return "down_right"
	
	return "down"  # Default fallback


func toggle_ui_visibility() -> void:
	$UI/ContextPanelBackground.visible = not $UI/ContextPanelBackground.visible
	$UI/OverheadLabelBackground.visible = not $UI/OverheadLabelBackground.visible
	$UI/InventoryAction.visible = not $UI/InventoryAction.visible
	$UI/SkillsAction.visible = not $UI/SkillsAction.visible
	$UI/JournalAction.visible = not $UI/JournalAction.visible
	$UI/MapAction.visible = not $UI/MapAction.visible
	$UI/SettingsAction.visible = not $UI/SettingsAction.visible


func _on_item_summary_use_pressed() -> void:
	# Get the currently selected slot
	if inventory.selected_slots.size() == 0:
		return
	
	var selected_slot = inventory.selected_slots[0]
	var item_data = selected_slot.item_data
	
	# TODO: Implement use logic based on item type
	print("Used item: ", item_data.name)


func _on_item_summary_drop_pressed() -> void:
	# Get the currently selected slot
	if inventory.selected_slots.size() == 0:
		return
	
	var selected_slot = inventory.selected_slots[0]
	var item_data = selected_slot.item_data
	
	# Get a safe drop position outside player's interaction area
	var drop_position = get_position_outside_player(150.0, 50.0)
	
	# Use WorldItemManager to handle the drop
	await WorldItemManager._player_item_drop(item_data, drop_position)
	
	# Remove the slot from inventory after successful drop
	inventory.remove_item_slot(selected_slot)
	
	# Hide the item summary panel
	var summary_panel = $UI/ContextPanelBackground/InventoryPanel/ItemSummaryPanel
	if summary_panel:
		summary_panel.hide()


func _on_item_summary_equip_pressed() -> void:
	# Get the currently selected slot
	if inventory.selected_slots.size() == 0:
		return
	
	var selected_slot = inventory.selected_slots[0]
	var item_data = selected_slot.item_data
	
	# Check if item is equippable
	if not item_data.get("is_equippable", false):
		print("Cannot equip this item!")
		return
	
	# TODO: Implement equip logic
	print("Equipped item: ", item_data.name)
