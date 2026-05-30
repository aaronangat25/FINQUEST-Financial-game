extends Control

const NEXT_SCENE = "res://Scenes/Chapter Selection/chapter_selection.tscn"

# --- NODE REFERENCES ---
@onready var play_btn = $main_menu_bg/menu_button_container/playbtn
@onready var option_btn = $main_menu_bg/menu_button_container/optionbtn

# Direct path traversing through the CanvasLayer to the yellow OptionPanel container
@onready var option_panel = $Option

func _ready():
	# Instantly hide the options panel at game frame zero
	if option_panel:
		option_panel.hide()
	else:
		print("[ERROR] main_screen.gd cannot find the OptionPanel node! Check your hierarchy paths.")

	# --- SIGNAL CONNECTIONS ---
	if play_btn and not play_btn.pressed.is_connected(_on_playbtn_pressed):
		play_btn.pressed.connect(_on_playbtn_pressed)
		
	if option_btn and not option_btn.pressed.is_connected(_on_option_btn_pressed):
		option_btn.pressed.connect(_on_option_btn_pressed)

	# --- AUDIO INITIALIZATION ---
	AudioManager.play_menu_music()
	
	# --- GLOBAL TRANSITION FALLBACK SAFETY ---
	if TransitionManager.has_method("fade_from_black"):
		TransitionManager.fade_from_black()
	
	# --- VISUAL FADE-IN SEQUENCE ---
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1) 
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.z_index = 100 
	
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	add_child(fade_rect)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.0)
	tween.finished.connect(fade_rect.queue_free)


# --- BUTTON CLICK HANDLERS ---

func _on_playbtn_pressed():
	TransitionManager.transition_to(NEXT_SCENE)

func _on_option_btn_pressed():
	if option_panel:
		option_panel.show()
		print("[MAIN SCREEN] Option Panel overlay opened.")

func _change_scene():
	get_tree().change_scene_to_file(NEXT_SCENE)
