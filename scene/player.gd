extends CharacterBody2D

const SPEED = 150.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var checklist_ui: Node2D

# States
enum State { ENTERING, STOPPED }
var state = State.ENTERING

# Target position for the middle of the table
var target_x = 350 # Adjust based on your table's position
var stop_distance = 5  # Distance threshold before stopping

signal reached_middle

func _ready() -> void:
	state = State.ENTERING
	# Connect input event to handle clicks
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Close checklist if it's open
		if checklist_ui and checklist_ui.visible:
			checklist_ui.visible = false

func set_checklist_ui(ui: Node2D) -> void:
	checklist_ui = ui

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
		emit_signal("reached_middle") # Notify main scene
