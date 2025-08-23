extends Label


func _ready():
	$Headline.modulate.a = 0.0  # start invisible
	var tween = create_tween()
	tween.tween_property($Headline, "modulate:a", 1.0, 2.0) # fade in over 2s
	
