extends TextureRect

var hovered : bool = false
var item = null
var selected : bool = false

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if(item != null and $ItemTexture.texture != item.item_texture):
		$ItemTexture.texture = item.item_texture


func _on_mouse_entered() -> void:
	if($ItemTexture.texture):
		$SelectedTexture.show()
		hovered = true

func _on_mouse_exited() -> void:
	$SelectedTexture.hide()
	hovered = false
