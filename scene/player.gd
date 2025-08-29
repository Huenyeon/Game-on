extends CharacterBody2D

const SPEED = 150.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# States
enum State { ENTERING, STOPPED }
var state = State.ENTERING

# Target position for the middle of the table
var target_x = 350 # Adjust based on your table's position
var stop_distance = 5  # Distance threshold before stopping

signal reached_middle

func _ready() -> void:
	# Check if player has already reached middle in a previous session
	if Global.player_has_reached_middle:
		state = State.STOPPED
		position.x = target_x  # Set position directly to middle
		emit_signal("reached_middle") # Emit signal to notify other nodes
	else:
		state = State.ENTERING

func _physics_process(delta: float) -> void:
	if state == State.ENTERING:
		_auto_move_to_middle()
	else:
		velocity.x = 0

	# Apply gravity (in case floor is sloped)
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

func _auto_move_to_middle() -> void:
	if abs(position.x - target_x) > stop_distance:
		var dir = sign(target_x - position.x)
		velocity.x = dir * SPEED
	else:
		velocity.x = 0
		state = State.STOPPED
		Global.player_has_reached_middle = true  # Set the global flag
		emit_signal("reached_middle") # Notify main scene
