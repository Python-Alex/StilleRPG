extends FoldableContainer

func _ready() -> void:
	# Set highlighter FIRST
	var highlighter = CodeHighlighter.new()
	highlighter.add_keyword_color("Game", Color.LIME_GREEN)
	highlighter.add_keyword_color("Notification", Color.ROYAL_BLUE)
	highlighter.add_keyword_color("Alert", Color.YELLOW)
	highlighter.add_keyword_color("Error", Color.CRIMSON)
	
	$ScrollContainer/NinePatchRect/ChatOutput.syntax_highlighter = highlighter
