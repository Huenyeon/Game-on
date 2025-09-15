extends Area2D

var dragging := false
var drag_offset := Vector2.ZERO

func _ready():
	#input_ray_pickable = true
	monitoring = true

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = true
			drag_offset = get_global_mouse_position() - get_parent().global_position
			# Call the bring_to_front function on the parent Window
			get_parent().bring_to_front()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false

func _process(delta):
	if dragging:
		get_parent().global_position = get_global_mouse_position() - drag_offset
