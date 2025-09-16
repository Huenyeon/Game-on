extends Node2D
class_name DesktopWindow

# Dragging variables
var window_index := -1

# Reference to main scene (will be set when window is created)
var main_scene: Node = null

func setup_window(index: int, main_scene_ref: Node, report_data: Dictionary):
	window_index = index
	main_scene = main_scene_ref
	
	# Fill in report data - use the correct nested paths
	$NewsWindow/HeadlineLabel.text = report_data["headline"]
	$NewsWindow/BodyLabel.text = report_data["body"]
	$NewsWindow/PublisherLabel.text = "Publisher: " + report_data["publisher"]
	$NewsWindow/DateLabel.text = "Date: " + report_data["published_date"]


func start_dragging(event):

	# Bring to front when clicked
	if main_scene and main_scene.has_method("bring_window_to_front"):
		main_scene.bring_window_to_front(self)
