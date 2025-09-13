extends Panel

@onready var timer: Timer = $TimerLabel/GameTimer
@onready var label: Label = $TimerLabel

func _ready():
	# Don't start the timer here - let game_scene control it
	# timer.start()  # Commented out - game_scene will control when to start
	label.text = str(int(timer.wait_time))

func _process(_delta):
	# Only update if timer is actually running
	if not timer.is_stopped() and timer.time_left > 0:
		# Always update label with remaining time
		label.text = str(int(timer.time_left))
