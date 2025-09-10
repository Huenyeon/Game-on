extends Panel

@onready var timer: Timer = $TimerLabel/GameTimer
@onready var label: Label = $TimerLabel

func _ready():
	# Start the timer (set wait_time = 90 in the Inspector)
	timer.start()
	label.text = str(int(timer.wait_time))

func _process(_delta):
	if timer.time_left > 0:
		# Always update label with remaining time
		label.text = str(int(timer.time_left))
