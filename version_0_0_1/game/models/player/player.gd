extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

var username : String = "Player"

var speed = 200.0
var sprint_bonus = 0.33
var last_direction = "down"

@onready var skills = $Skills
@onready var inventory = $Inventory

@onready var skill_cards = [
	$UI/SkillsPage/GridContainer/AttackSkillCard, $UI/SkillsPage/GridContainer/StrengthSkillCard,
	$UI/SkillsPage/GridContainer/DefenceSkillCard, $UI/SkillsPage/GridContainer/HitpointsSkillCard,
	$UI/SkillsPage/GridContainer/EnduranceSkillCard, $UI/SkillsPage/GridContainer/WoodcuttingSkillCard,
	$UI/SkillsPage/GridContainer/FarmingSkillCard, $UI/SkillsPage/GridContainer/CraftingSkillCard
]

signal item_picked_up(item)

func _ready():
	pass

func _physics_process(_delta):
	var input_direction = Vector2.ZERO
	
	# Get input
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1
	
	input_direction = input_direction.normalized()
	
	var current_speed = speed
	if Input.is_action_pressed("sprint"):
		current_speed = speed + (speed * sprint_bonus)
	
	velocity = input_direction * current_speed
	
	# Update animation
	if input_direction != Vector2.ZERO:
		var direction = get_8_direction_string(input_direction)
		last_direction = direction
		var anim_name = "move_" + direction
		animated_sprite.play(anim_name)
	else:
		animated_sprite.play("idle_" + last_direction)
	
	move_and_slide()

func get_8_direction_string(dir: Vector2) -> String:
	# Threshold for diagonal detection
	var threshold = 0.5
	
	# Pure cardinal directions
	if abs(dir.x) > abs(dir.y) * 2:  # Strongly horizontal
		return "right" if dir.x > 0 else "left"
	elif abs(dir.y) > abs(dir.x) * 2:  # Strongly vertical
		return "down" if dir.y > 0 else "up"
	
	# Diagonal directions
	if dir.x > 0 and dir.y > 0:
		return "down_right"
	elif dir.x < 0 and dir.y > 0:
		return "down_left"
	elif dir.x > 0 and dir.y < 0:
		return "up_right"
	elif dir.x < 0 and dir.y < 0:
		return "up_left"
	
	# Fallback
	return "down"

func _update_skill_cards() -> void:
	for skill_card in skill_cards:
		var skill_xp = skills._skill_structure[skill_card.skill_type]
		var current_level = ExperienceManager.get_level_from_experience(skill_xp)
		var current_level_xp = ExperienceManager.get_experience_for_level(current_level)
		var next_level_xp = ExperienceManager.get_experience_for_level(current_level + 1)
		
		var progress = skill_card.get_node("SkillProgress")
		var label = progress.get_node("SkillLevel")
		
		skill_card.tooltip_text = "Current Experience: %d\nNext Level: %d" % [
			skill_xp - current_level_xp, next_level_xp
		]
		
		progress.max_value = next_level_xp - current_level_xp
		progress.value = skill_xp - current_level_xp
		
		label.text = "%d" % [current_level]
		
func _process(_delta: float) -> void:
	if($UI/PlayerPage.visible):
		$UI/PlayerPage/Level.text = "Level: %d" % [ExperienceManager.get_level_from_experience(skills.experience)]
		# - MODIFY FOR SOMETHING ELSE [] $UI/PlayerPage/SkillPoints.text = "Skill Points: %d" % [skills.skill_points]
		$UI/PlayerPage/ProfileName.text = username

	if($UI/SkillsPage.visible):
		_update_skill_cards()
		
		$UI/SkillsPage/TotalExperience.text = "Total Experience : %s" % String.num(skills.get_total_experience(), 0)

func _on_player_page_pressed() -> void:
	$UI/PlayerPage.visible = not $UI/PlayerPage.visible

func _on_inventory_page_pressed() -> void:
	$UI/InventoryPage.visible = not $UI/InventoryPage.visible
	

func _on_interaction_area_area_entered(area: Area2D) -> void:
	if(area.name == "ItemPickupArea"):
		item_picked_up.emit(area.get_parent())
		
