extends Panel

var is_hovered : bool = false


func _on_mouse_entered() -> void:
	$HoveredBorder.show()
	
	is_hovered = true


func _on_mouse_exited() -> void:
	$HoveredBorder.hide()

	is_hovered = false
