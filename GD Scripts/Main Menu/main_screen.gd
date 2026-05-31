extends Control

const NEXT_SCENE = "res://Scenes/Chapter Selection/chapter_selection.tscn"

# --- NODE REFERENCES ---
@onready var play_btn = $main_menu_bg/menu_button_container/playbtn
@onready var option_btn = $main_menu_bg/menu_button_container/optionbtn

# 🏅 FIXED REFERENCE: Maps directly to the button inside your container path
@onready var achievement_btn = $main_menu_bg/menu_button_container/achievementbtn

# Direct paths traversing to your independent CanvasLayer overlay nodes
@onready var option_panel = $Option
@onready var achievement_panel = $AchievementList

func _ready():
	# Instantly hide overlays at game frame zero to clear the screen
	if option_panel:
		option_panel.hide()
	else:
		print("[ERROR] main_screen.gd cannot find the OptionPanel node!")

	if achievement_panel:
		achievement_panel.hide()
	else:
		print("[WARNING] main_screen.gd cannot find the AchievementList node!")

	# --- SIGNAL CONNECTIONS ---
	if play_btn and not play_btn.pressed.is_connected(_on_playbtn_pressed):
		play_btn.pressed.connect(_on_playbtn_pressed)
		
	if option_btn and not option_btn.pressed.is_connected(_on_option_btn_pressed):
		option_btn.pressed.connect(_on_option_btn_pressed)

	# 🏅 FIXED SIGNAL: Listen for clicks on your newly added achievement button
	if achievement_btn and not achievement_btn.pressed.is_connected(_on_achievement_btn_pressed):
		achievement_btn.pressed.connect(_on_achievement_btn_pressed)

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

# 🏅 FIXED ACTION: Safely synchronizes SQLite tables and reveals the panel
func _on_achievement_btn_pressed():
	if achievement_panel:
		if achievement_panel.has_method("sync_with_sqlite_database"):
			achievement_panel.sync_with_sqlite_database()
		
		achievement_panel.show()
		print("[MAIN SCREEN] Achievement list overlay opened and populated from DB.")

func _change_scene():
	get_tree().change_scene_to_file(NEXT_SCENE)
