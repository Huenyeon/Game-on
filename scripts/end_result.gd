extends Node2D

@onready var result_sprite: Sprite2D = $Panel/ResultSprite
@onready var info_label: Label = $Panel/VBox/InfoLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueButton

@export var tex_ok: Texture2D = preload("res://assets/images/Win.png")
@export var tex_bad: Texture2D = preload("res://assets/images/Lose.png")
@export var result_scale: float = 0.25
@export var target_result_height: float = 300.0
@export var match_to_lose_size: bool = true
@export var reference_scale: float = 1.0
@export var win_position_offset: Vector2 = Vector2(0, -20)

var _base_result_position: Vector2

func _ready() -> void:
	# Stop background music for end scene
	AudioManager.stop_background_music()
	
	# Ensure consistent centering and baseline scale for the result image
	result_sprite.centered = true
	result_sprite.scale = Vector2.ONE * result_scale
	_base_result_position = result_sprite.position
	# Safe read of the last stamp info
	var info = null
	if "last_stamp" in Global:
		info = Global.last_stamp
	if info == null:
		info_label.text = "Time's up! Let's go again."
		result_sprite.texture = tex_bad
		return

	var stamp_type: String = info.get("type", "")
	var report = info.get("report", null)

	# Determine whether the student's report matches any computer report (by headline)
	var matched := false
	if report != null:
		for r in Global.active_reports:
			if r.has("headline") and r["headline"] == report.get("headline", ""):
				matched = true
				break

	# Normal correctness: matched & approved OR not matched & denied
	var normal_correct := (matched and stamp_type == "approved") or (not matched and stamp_type == "denied")
	var correct_decision := normal_correct
	# Apply invert flag if present
	if "end_result_inverted" in Global and Global.end_result_inverted:
		correct_decision = not normal_correct

	# Show result image and message
	if correct_decision:
		_apply_result_texture(tex_ok)
		info_label.text = "Great job scanning the paper!"
	else:
		_apply_result_texture(tex_bad)
		info_label.text = "It looks like the scan didn't come out quite right."

func _apply_result_texture(texture: Texture2D) -> void:
	# Apply texture and normalize its on-screen size so Win/Lose appear identically positioned and sized
	result_sprite.texture = texture
	if texture == null:
		return
	var tex_size: Vector2 = texture.get_size()
	if tex_size.y <= 0.0:
		return
	# Determine target height: either fixed or based on Lose image to match sizes
	var desired_height: float = target_result_height
	if match_to_lose_size and tex_bad != null:
		var lose_h := tex_bad.get_size().y
		if lose_h > 0.0:
			desired_height = lose_h * reference_scale
	# Compute scale to reach the target height (maintains aspect ratio), then apply user multiplier
	var scale_factor: float = desired_height / tex_size.y
	var final_scale: float = scale_factor * result_scale
	result_sprite.scale = Vector2.ONE * final_scale

	# Apply per-result positional offset: move only Win upward, keep Lose at base
	if texture == tex_ok:
		result_sprite.position = _base_result_position + win_position_offset
	else:
		result_sprite.position = _base_result_position

func _on_continue_pressed() -> void:
	# Clear last stamp
	if "last_stamp" in Global:
		Global.last_stamp = null

	# Clear current student report
	Global.current_student_report = null
	# Return to main menu
	get_tree().change_scene_to_file("res://scene/menu.tscn")

func _on_back_to_menu_pressed() -> void:
	# Clear last stamp
	if "last_stamp" in Global:
		Global.last_stamp = null

	# Clear current student report
	Global.current_student_report = null
	# Return to main menu
	get_tree().change_scene_to_file("res://scene/menu.tscn")
	
