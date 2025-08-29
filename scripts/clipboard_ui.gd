extends Node2D

@onready var checkbox_container = $CheckboxContainer

func _ready():
	hide() 

func open():
	show()

func close():
	hide()
