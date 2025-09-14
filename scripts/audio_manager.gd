extends Node

var background_music_player: AudioStreamPlayer
var is_music_enabled: bool = true

func _ready():
	# Create the background music player
	background_music_player = AudioStreamPlayer.new()
	background_music_player.name = "BackgroundMusicPlayer"
	add_child(background_music_player)
	
	# Load the background music
	var music_stream = load("res://assets/Sounds/BG_Music.mp3")
	if music_stream:
		background_music_player.stream = music_stream
		background_music_player.autoplay = false
		background_music_player.volume_db = -10.0  # Adjust volume as needed
		# Enable looping
		background_music_player.finished.connect(_on_music_finished)
	else:
		print("Warning: Could not load BG_Music.mp3")

func _on_music_finished():
	# Restart the music when it finishes to create seamless looping
	if is_music_enabled and background_music_player.stream:
		background_music_player.play()

func play_background_music():
	if is_music_enabled and background_music_player and not background_music_player.playing:
		background_music_player.play()

func stop_background_music():
	if background_music_player and background_music_player.playing:
		background_music_player.stop()

func pause_background_music():
	if background_music_player and background_music_player.playing:
		background_music_player.stream_paused = true

func resume_background_music():
	if background_music_player and is_music_enabled:
		background_music_player.stream_paused = false

func set_music_volume(volume_db: float):
	if background_music_player:
		background_music_player.volume_db = volume_db

func toggle_music():
	is_music_enabled = !is_music_enabled
	if is_music_enabled:
		play_background_music()
	else:
		stop_background_music()
