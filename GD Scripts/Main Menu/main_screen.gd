extends Control

const NEXT_SCENE = "res://Scenes/Chapter Selection/chapter_selection.tscn"

@onready var play_btn = $main_menu_bg/menu_button_container/playbtn

func _ready():
	# --- AUDIO INITIALIZATION ---
	# Starts menu background music looping instantly on game startup
	AudioManager.play_menu_music()
	
	# --- GLOBAL TRANSITION FALLBACK SAFETY ---
	if TransitionManager.has_method("fade_from_black"):
		TransitionManager.fade_from_black()
	
	# 1. Spawn a black screen that starts completely opaque 
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1) 
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.z_index = 100 # Keep it on top of everything
	
	# 2. Block clicks while the screen is still fading in
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	add_child(fade_rect)
	
	# 3. Create the Tween to fade the black screen to transparent 
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	
	# 4. Delete the black screen when the fade finishes
	tween.finished.connect(fade_rect.queue_free)

func _on_playbtn_pressed():
	TransitionManager.transition_to(NEXT_SCENE)

func _change_scene():
	get_tree().change_scene_to_file(NEXT_SCENE)
