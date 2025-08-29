extends Node2D  # This should be your parent node that holds all pens

# Array to keep track of all pen nodes
var pens = []
var active_pen = null

func _ready():
	# Find all pen nodes (assuming they're direct children)
	for child in get_children():
		if child.has_signal("pen_clicked"):  # Check if it's a pen
			pens.append(child)
			# Connect the signal from each pen
			child.connect("pen_clicked", Callable(self, "_on_pen_clicked"))
	
	print("Found ", pens.size(), " pens")

# Function to handle when a pen is clicked
func _on_pen_clicked(clicked_pen):
	if active_pen != null and active_pen != clicked_pen:
		# Release the previously active pen
		active_pen.release()
	
	# Set the new active pen
	active_pen = clicked_pen

# Function to release all pens (optional)
func release_all_pens():
	for pen in pens:
		pen.release()
	active_pen = null
