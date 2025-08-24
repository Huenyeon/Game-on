extends Node2D

@onready var box_sprite: Sprite2D = $Box
@onready var checkmark: Sprite2D = $Checkmark
@onready var area: Area2D = $Area2D 

var checked: bool = false

func _ready() -> void:
	checkmark.visible = false
	area.input_event.connect(_on_area_input_event)

func _on_area_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		toggle()

func toggle() -> void:
	checked = !checked
	checkmark.visible = checked
