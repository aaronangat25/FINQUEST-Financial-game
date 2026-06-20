extends Control

# --- PRELOADED SCENE TARGET ---
const MAIN_SCREEN_SCENE_PATH = "res://Scenes/Main Screen/main_screen.tscn"

# --- NODE REFERENCES ---
# Safe fetching via recursive searching down the tree to grab the logo
@onready var hbdvon_logo: AnimatedSprite2D = $hbdvonanchor/hbdvon_logo

func _ready() -> void:
	# 1. Instantly hide the logo at scene launch
	if hbdvon_logo:
		hbdvon_logo.hide()
		hbdvon_logo.stop()
		hbdvon_logo.modulate.a = 0.0
	
	# Start our sequenced intro engine pipeline
	_run_intro_sequence()


func _run_intro_sequence() -> void:
	# 2. Count 3 seconds instantly
	await get_tree().create_timer(3.0).timeout
	
	# 3. Fade in slowly (1.5 seconds)
	if hbdvon_logo:
		hbdvon_logo.show()
		hbdvon_logo.play("idle") # Begin playing loop state
		
		var fade_in_tween = create_tween()
		fade_in_tween.tween_property(hbdvon_logo, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
		await fade_in_tween.finished
		
	# 4. Let the looping idle animation play cleanly on screen for 3.5 seconds
	await get_tree().create_timer(3.5).timeout
	
	# 5. Fade out slowly (adjusting to matching 1.5s curve)
	if hbdvon_logo:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(hbdvon_logo, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE)
		await fade_out_tween.finished
		hbdvon_logo.hide()
		
	# 6. Count 1.5 seconds flat of empty black space buffer
	await get_tree().create_timer(1.5).timeout
	
	# 7. Execute smooth jump switch to the main screen file
	print("Intro complete! Passing scene focus to Main Screen...")
	get_tree().change_scene_to_file(MAIN_SCREEN_SCENE_PATH)
