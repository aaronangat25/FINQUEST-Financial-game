extends Node

# =========================================
# FINQUEST AUDIO MANAGER
# =========================================

# FILE PATHS
var click_sfx_path : String = "res://Assets/Audio/SFX/Menu Selection Click.wav"
var menu_music_path : String = "res://Assets/Audio/Music/FINQUEST MAIN MENU.mp3"
var general_music_path : String = "res://Assets/Audio/Music/GENERAL MUSIC.mp3"
var coffeeshop_music_path : String = "res://Assets/Audio/Music/COFFEE SHOP POSSBLE 3.mp3"

# AUDIO PLAYERS
var bgm_player : AudioStreamPlayer
var current_track_path : String = ""

func _ready() -> void:
	# Initialize background music player channel
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.bus = "Master"
	
	print("[AUDIO] Global input click and multi-scene music engine active.")

# =========================================
# CAPTURE MOUSE CLICKS GLOBALLY
# =========================================
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			play_click_sfx()

# =========================================
# PLAY ONE-SHOT CLICK SFX
# =========================================
func play_click_sfx():
	var sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	sfx_player.stream = load(click_sfx_path)
	sfx_player.volume_db = -5.0
	sfx_player.play()
	
	sfx_player.finished.connect(sfx_player.queue_free)

# =========================================
# MUSIC CONTROL SYSTEM
# =========================================

# Call this on your Main Menu setup
func play_menu_music():
	_change_bgm_track(menu_music_path, -6.0)

# Call this inside your Gameplay Chapter scripts
func play_chapter_music():
	_change_bgm_track(general_music_path, -8.0)

# Call this whenever the player enters the coffee shop scene location
func play_coffeeshop_music():
	_change_bgm_track(coffeeshop_music_path, -7.0) # Balanced for cozy dialogue ambience

# Internal helper method to handle loading, volume-resetting, and playing tracks safely
func _change_bgm_track(target_path : String, target_volume : float):
	# If the requested track is already active and playing, leave it alone
	if bgm_player.playing and current_track_path == target_path:
		return
		
	var stream = load(target_path)
	if stream:
		bgm_player.stop() # Instant cutoff of any old tracking properties
		bgm_player.stream = stream
		bgm_player.volume_db = target_volume # RESET volume step from potential previous fade-outs
		bgm_player.play()
		current_track_path = target_path
		print("[AUDIO] Now playing music track: ", target_path.get_file())
	else:
		print("[AUDIO ERROR] Track file not found at path: ", target_path)

# Call this if you want to transition out of any scene track using a smooth 1-second fade
func fade_out_music():
	if not bgm_player.playing:
		return
		
	print("[AUDIO] Initiating 1-second fade out loop structure...")
	var fade_tween = create_tween()
	fade_tween.tween_property(bgm_player, "volume_db", -80.0, 1.0)
	fade_tween.finished.connect(func():
		bgm_player.stop()
		current_track_path = ""
		print("[AUDIO] Fade out complete. Audio channel parked.")
	)
