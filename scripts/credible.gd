extends  Label

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# Forward event to parent TextureButton
		get_parent()._gui_input(event)
