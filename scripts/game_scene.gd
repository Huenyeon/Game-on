extends Node2D

@onready var paper = $paper
@onready var student_paper = $"student paper"
@onready var paper_text: RichTextLabel = $paper/MarginContainer/Text
@onready var stamp: Sprite2D = $stamp
@onready var stamp_options: Node2D = $stamp/StampOptions

# =======================
# Variables
# =======================
var paper_open = false
var rng := RandomNumberGenerator.new()

var articles := [
	"""BrightFuture Daily
	
“New Solar Panel Paint Can Charge Phones in Sunlight ”

On August 21, 2025, BrightFuture Daily reported that scientists at SunTech Academy developed a paint that can act like a solar panel. The article claimed that “any wall covered in the paint can charge a phone directly.”""",

	"""NextWave Newsroom

“Students in Riverdale Town Can Graduate Early by Planting 100 Trees ”

On August 19, 2025, NextWave Newsroom reported that Riverdale High would allow 
students to graduate one year earlier if they planted 100 trees. 
The article included student testimonials but no official school statement.""",

	""" Knowledge Spark Gazette

“Homework-Free Fridays Become Law in Greenfield City”

On August 17, 2025, Knowledge Spark Gazette published that the city council of 
Greenfield passed a law banning homework on Fridays for all students.

Date Published: May 2, 2023"""
]



func _ready() -> void:
	rng.randomize()
	paper.visible = false
	student_paper.visible = true
	paper_open = false 
	stamp_options.visible = false


# =======================
# When the player clicks on the student paper
# =======================
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		paper_open = true
		paper.visible = true
		student_paper.visible = false
		
		#show text 
		var idx := rng.randi_range(0, articles.size() - 1)
		paper_text.text = articles[idx]


func _on_stamp_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		stamp_options.visible = not stamp_options.visible
		
		
func _unhandled_input(event: InputEvent) -> void:
	if paper_open and event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_viewport().get_mouse_position()
		
		var tex_size = paper.texture.get_size()*paper.scale
		var top_left = paper.global_position - (tex_size * 0.5)
		var paper_rect = Rect2(top_left, tex_size)
		
		if not paper_rect.has_point(mouse_pos):
			paper_open = false
			paper.visible = false
			student_paper.visible = true

	# Hide stamp options when clicking elsewhere
	if event is InputEventMouseButton and event.pressed:
		if stamp_options.visible:
			var mouse_pos2 = get_viewport().get_mouse_position()
			var options_top_left := stamp.global_position + Vector2(40, -20)
			var options_rect := Rect2(options_top_left, Vector2(96, 48))
			if not options_rect.has_point(mouse_pos2):
				stamp_options.visible = false
		
