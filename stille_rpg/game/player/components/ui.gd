extends Control

@onready var __toggle_state_buttons = [
	$InventoryAction, $SkillsAction, $JournalAction, $MapAction, $SettingsAction
]

@onready var __toggle_link_panels = {
	$InventoryAction: $ContextPanelBackground/InventoryPanel,
	$SkillsAction: $ContextPanelBackground/SkillsPanel, 
	$JournalAction: null, 
	$MapAction: null, 
	$SettingsAction: null
}

var __current_action : TextureButton = null

const COLOR_ACTIVE = Color("#ffffffb6")
const COLOR_INACTIVE = Color("#595959b6")

func _ready():
	toggle_all_actions_off()
	# Make Inventory Active by default
	_activate_action($InventoryAction)

func toggle_all_actions_off(besides: Array[TextureButton] = []) -> void:
	for child in __toggle_state_buttons:
		if child in besides:
			continue
		child.button_pressed = false
		child.get_node("Label").add_theme_color_override("font_color", COLOR_INACTIVE)

func _activate_action(action: TextureButton) -> void:
	toggle_all_actions_off([action])
	action.button_pressed = true
	action.get_node("Label").add_theme_color_override("font_color", COLOR_ACTIVE)
	__current_action = action
	
	__toggle_link_panels[action].show()

func _deactivate_action(action: TextureButton) -> void:
	action.button_pressed = false
	action.get_node("Label").add_theme_color_override("font_color", COLOR_INACTIVE)
	__current_action = null
	
	__toggle_link_panels[action].hide()

func _on_inventory_action_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_action($InventoryAction)
		$OverheadLabelBackground/OverheadLabel.text = "Inventory"
	elif __current_action == $InventoryAction:
		_deactivate_action($InventoryAction)

func _on_skills_action_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_action($SkillsAction)
		$OverheadLabelBackground/OverheadLabel.text = "Skills"
	elif __current_action == $SkillsAction:
		_deactivate_action($SkillsAction)

func _on_journal_action_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_action($JournalAction)
		$OverheadLabelBackground/OverheadLabel.text = "Journal"
	elif __current_action == $JournalAction:
		_deactivate_action($JournalAction)

func _on_map_action_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_action($MapAction)
		$OverheadLabelBackground/OverheadLabel.text = "Map"
	elif __current_action == $MapAction:
		_deactivate_action($MapAction)

func _on_settings_action_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_activate_action($SettingsAction)
		$OverheadLabelBackground/OverheadLabel.text = "Settings"
	elif __current_action == $SettingsAction:
		_deactivate_action($SettingsAction)
