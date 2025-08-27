extends Node2D

@onready var marker = $Marker2D  # tip of the pen
@onready var sprite = $red # assuming you have a sprite for the pen

var sticking := false
var start_pos: Vector2

func _ready():
	start_pos = global_position
	set_process(false)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not sticking:
			# Check if click is near the pen tip
			var mouse_pos = get_global_mouse_position()
			var tip_pos = $CollisionShape2D.global_position
			if tip_pos.distance_to(mouse_pos) < 10:  # Adjust threshold as needed
				sticking = true
				set_process(true)
				# Make pen follow mouse
				global_position = mouse_pos - marker.position
		else:
			# Single click anywhere to return the pen
			sticking = false
			set_process(false)
			return_to_start()

func _process(_delta):
	if sticking:
		# Keep the tip on the cursor while dragging
		global_position = get_global_mouse_position() - marker.position

func return_to_start():
	# Create a simple animation without tween
	var duration = 0.5
	var elapsed = 0.0
	var initial_pos = global_position
	
	while elapsed < duration:
		elapsed += get_process_delta_time()
		var t = elapsed / duration
		# Smooth easing function
		t = t * t * (3.0 - 2.0 * t)
		global_position = initial_pos.lerp(start_pos, t)
		await get_tree().process_frame
	
	global_position = start_pos
	print("Pen returned to start position")
