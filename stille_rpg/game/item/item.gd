extends Area2D
class_name ItemBase

var timer : Timer
var is_control_visible : bool = false

# Item properties
@export var item_id : int = 0
@export var item_name: String = "Item"
@export var item_description: String = "A basic item"
@export var item_tags: Array[GameTypes.ItemTag] = []
@export var stack_size: int = 1
@export var max_stack: int = 99
@export var item_weight : float = 0.01
@export var item_value: int = 10
@export var item_icon: Texture2D
@export var scene_path: String

@export var data : Dictionary = {}
@export var metadata : Dictionary = {}

# Core item type flags
@export var is_equippable: bool = false
@export var is_consumable: bool = false
@export var is_stackable: bool = false
@export var is_tradeable: bool = false
@export var is_droppable: bool = false
@export var is_questitem: bool = false

@export var equipment_slot: GameTypes.EquipmentSlot  # "head", "chest", "legs", "weapon", "shield", etc.
@export var equipment_type: GameTypes.EquipmentType  # "armor", "weapon", "accessory"
@export var required_level: int = 1
@export var required_stats: Dictionary[GameTypes.SkillTypes, int] = {}  # {"strength": 10, "dexterity": 5}

@export var consumable_type: GameTypes.ConsumableType  # "potion", "food", "scroll", "elixir"
@export var use_effect: GameTypes.UseEffect  # "heal", "buff", "restore_mana"
@export var effect_value: int = 0
@export var effect_duration: float = 0.0
@export var cooldown_time: float = 0.0

@export var damage: int = 0
@export var damage_type : GameTypes.DamageType
@export var defense: int = 0
@export var attack_speed: float = 1.0
@export var critical_chance: float = 0.0
@export var stat_modifiers: Dictionary = {}  # {"strength": 5, "health": 20}

@export var rarity: GameTypes.ItemRarity  # "common", "uncommon", "rare", "epic", "legendary"
@export var quality: int = 100  # Durability/condition
@export var max_quality: int = 100

@export var is_usable_in_combat: bool = true
@export var is_usable_outside_combat: bool = true
@export var required_class: String = ""  # "warrior", "mage", "rogue"
@export var required_race: String = ""

@export var is_cursed: bool = false
@export var is_magical: bool = false
@export var is_soulbound: bool = false
@export var enchantment_slots: int = 0
@export var current_enchantments: Array = []

@export var is_craftable: bool = false
@export var is_material: bool = false
@export var crafting_ingredients: Array = []

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var control_node: Control = $Control

signal item_picked_up(item_data: Dictionary)

func _ready():
	
	# Set up collision layers
	collision_layer = 4  # Item layer
	collision_mask = 1   # Player layer
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	# Set sprite if icon is assigned
	if item_icon:
		sprite.texture = item_icon
	
	if scene_path == "":
		scene_path = scene_file_path
		
	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = 0.01
	timer.timeout.connect(_on_update)
	timer.autostart = true
	
	add_child(timer)
	
	# Hide control node initially
	if control_node:
		control_node.visible = false
		control_node.mouse_entered.connect(_on_control_mouse_entered)
		control_node.mouse_exited.connect(_on_control_mouse_exited)
		
func _on_update() -> void:
	$Label.text = "%d" % [stack_size]

func _on_body_entered(body):
	if(body.name == "Player"):
		pickup(body)

func pickup(_player):
	# Create item data dictionary
	var item_data = get_item_data()
	
	# Emit signal with item data
	item_picked_up.emit(item_data)
	
	# You can add pickup effects here (sound, particle, etc.)
	queue_free()

func get_item_data() -> Dictionary:
	return {
		"id": item_id,
		"name": item_name,
		"description": item_description,
		"tags": item_tags,
		"stack_size": stack_size,
		"max_stack": max_stack,
		"weight": item_weight,
		"value": item_value,
		"icon": item_icon,
		"scene_path": scene_path,
		"data": data,
		"metadata": metadata,
		
		# Core item type flags
		"is_equippable": is_equippable,
		"is_consumable": is_consumable,
		"is_stackable": is_stackable,
		"is_tradeable": is_tradeable,
		"is_droppable": is_droppable,
		"is_questitem": is_questitem,
		
		# Equipment specific
		"equipment_slot": equipment_slot,
		"equipment_type": equipment_type,
		"required_level": required_level,
		"required_stats": required_stats,
		
		# Consumable specific
		"consumable_type": consumable_type,
		"use_effect": use_effect,
		"effect_value": effect_value,
		"effect_duration": effect_duration,
		"cooldown_time": cooldown_time,
		
		# Combat/Stats
		"damage": damage,
		"defense": defense,
		"attack_speed": attack_speed,
		"critical_chance": critical_chance,
		"stat_modifiers": stat_modifiers,
		
		# Rarity/Quality
		"rarity": rarity,
		"quality": quality,
		"max_quality": max_quality,
		
		# Usage restrictions
		"is_usable_in_combat": is_usable_in_combat,
		"is_usable_outside_combat": is_usable_outside_combat,
		"required_class": required_class,
		"required_race": required_race,
		
		# Special properties
		"is_cursed": is_cursed,
		"is_magical": is_magical,
		"is_soulbound": is_soulbound,
		"enchantment_slots": enchantment_slots,
		"current_enchantments": current_enchantments,
		
		# Crafting
		"is_craftable": is_craftable,
		"is_material": is_material,
		"crafting_ingredients": crafting_ingredients
	}
	
func set_item_data(item_data: Dictionary) -> void:
	# Basic properties
	item_id = item_data.get("id", 0)
	item_name = item_data.get("name", "Item")
	item_description = item_data.get("description", "")
	item_tags = item_data.get("tags", [])
	stack_size = item_data.get("stack_size", 1)
	max_stack = item_data.get("max_stack", 99)
	item_weight = item_data.get("weight", 0.01)
	item_value = item_data.get("value", 10)
	item_icon = item_data.get("icon", null)
	data = item_data.get("data", {})
	metadata = item_data.get("metadata", {})
	
	# Core item type flags
	is_equippable = item_data.get("is_equippable", false)
	is_consumable = item_data.get("is_consumable", false)
	is_stackable = item_data.get("is_stackable", false)
	is_tradeable = item_data.get("is_tradeable", false)
	is_droppable = item_data.get("is_droppable", false)
	is_questitem = item_data.get("is_questitem", false)
	
	# Equipment specific
	equipment_slot = item_data.get("equipment_slot", "")
	equipment_type = item_data.get("equipment_type", "")
	required_level = item_data.get("required_level", 1)
	required_stats = item_data.get("required_stats", {})
	
	# Consumable specific
	consumable_type = item_data.get("consumable_type", "")
	use_effect = item_data.get("use_effect", "")
	effect_value = item_data.get("effect_value", 0)
	effect_duration = item_data.get("effect_duration", 0.0)
	cooldown_time = item_data.get("cooldown_time", 0.0)
	
	# Combat/Stats
	damage = item_data.get("damage", 0)
	defense = item_data.get("defense", 0)
	attack_speed = item_data.get("attack_speed", 1.0)
	critical_chance = item_data.get("critical_chance", 0.0)
	stat_modifiers = item_data.get("stat_modifiers", {})
	
	# Rarity/Quality
	rarity = item_data.get("rarity", "common")
	quality = item_data.get("quality", 100)
	max_quality = item_data.get("max_quality", 100)
	
	# Usage restrictions
	is_usable_in_combat = item_data.get("is_usable_in_combat", true)
	is_usable_outside_combat = item_data.get("is_usable_outside_combat", true)
	required_class = item_data.get("required_class", "")
	required_race = item_data.get("required_race", "")
	
	# Special properties
	is_cursed = item_data.get("is_cursed", false)
	is_magical = item_data.get("is_magical", false)
	is_soulbound = item_data.get("is_soulbound", false)
	enchantment_slots = item_data.get("enchantment_slots", 0)
	current_enchantments = item_data.get("current_enchantments", [])
	
	# Crafting
	is_craftable = item_data.get("is_craftable", false)
	is_material = item_data.get("is_material", false)
	crafting_ingredients = item_data.get("crafting_ingredients", [])
	
	# Update sprite if icon changed
	if item_icon:
		sprite.texture = item_icon
	
	_on_update()

# Show control when mouse enters the item sprite/area
func _on_mouse_entered():
	sprite.modulate = Color(1.2, 1.2, 1.2)
	if control_node:
		control_node.visible = true
		is_control_visible = true

# Don't hide immediately when mouse exits item - let control handle it
func _on_mouse_exited():
	sprite.modulate = Color(1, 1, 1)
	# Only hide if mouse isn't over the control node
	if control_node and not control_node.get_global_rect().has_point(get_global_mouse_position()):
		control_node.visible = false
		is_control_visible = false

# Keep control visible when mouse is over it
func _on_control_mouse_entered():
	if control_node:
		is_control_visible = true

# Hide control when mouse leaves it
func _on_control_mouse_exited():
	if control_node:
		control_node.visible = false
		is_control_visible = false
