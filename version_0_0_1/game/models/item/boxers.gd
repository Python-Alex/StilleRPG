extends TextureRect

var item_name = "Boxers"
var item_id = 1
var item_description = "A pair of boxers"
var item_texture = load("res://assets/Items/item_boxers.png")

const __scene_path = "res://game/models/item/boxers.tscn"

var data : Dictionary = {
	
}

var state : ItemState.ItemState

var metadata : Dictionary = {
	"can_pickup": false,
	"can_equip": true,
	"can_hold": true,
}

func _ready() -> void:
	texture = item_texture
