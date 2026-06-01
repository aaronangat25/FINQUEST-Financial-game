extends Control

# =========================================
# FINQUEST CHAPTER SELECTION SCREEN (FIXED)
# =========================================

const LOGO_LOCKED = "res://Assets/Logo/logo finquest.png"
const THUMB_PROLOGUE = "res://Assets/Backgrounds/Chapter Selection/prologuethumbnail.png"
const THUMB_CHAPTER_1 = "res://Assets/Backgrounds/Chapter Selection/chapter1thumbnail.png"
const THUMB_CHAPTER_2 = "res://Assets/Backgrounds/Chapter Selection/chapter2thumbnail.png"
const THUMB_CHAPTER_3 = "res://Assets/Backgrounds/Chapter Selection/chapter3thumbnail.png"
const THUMB_CHAPTER_4 = "res://Assets/Backgrounds/Chapter Selection/chapter4thumbnail.png"
const THUMB_CHAPTER_5 = "res://Assets/Backgrounds/Chapter Selection/chapter5thumbnail.png"
const THUMB_ENDING = "res://Assets/Backgrounds/Chapter Selection/endingthumbnail.png"

# =========================================
# NODE PATHS MATCHING YOUR EXACT TREE
# =========================================
@onready var back_menu_btn : Button = $chapter_selection_bg/back_menu_btn
@onready var chapter_thumbnail : Panel = $chapter_selection_bg/chapter_container/chapter_thumbnail
@onready var chapter_label : Label = $chapter_selection_bg/chapter_container/chapter_thumbnail/chapter_label
@onready var play_btn : Button = $chapter_selection_bg/play_container/play_btn
@onready var next_arrow : Button = $chapter_selection_bg/next_chapter_btn
@onready var back_arrow : Button = $chapter_selection_bg/back_chapter_btn

# TRACKING STATE (Local view index matches visual navigation cards 1 to 7)
var current_view_index : int = 1

# =========================================
# GODOT READY
# =========================================
func _ready():
	next_arrow.pressed.connect(_on_next_arrow_pressed)
	back_arrow.pressed.connect(_on_back_arrow_pressed)
	if play_btn:
		play_btn.pressed.connect(_on_play_btn_pressed)
	
	# Connect the new back to menu navigation asset safely
	if back_menu_btn:
		back_menu_btn.pressed.connect(_on_back_menu_btn_pressed)
	
	update_selection_ui()

# =========================================
# UI CORE UPDATE LOGIC
# =========================================
func update_selection_ui():
	# --- FRESH LOAD RECENT SQL SAVE ---
	GameManager.load_player_stats() 
	
	print("[DEBUG] Chapter Selection screen checking unlocks for Player ID: ", GameManager.player_id)
	
	var title_text : String = ""
	var target_thumbnail_path : String = ""
	var is_chapter_unlocked : bool = false
	var is_chapter_completed : bool = false
	
	# Fetch database progress trackers from SQLite
	var unlocked_list = GameManager.get_unlocked_chapters()
	
	# DEVELOPER SAFETY FALLBACK GUARD
	if unlocked_list.size() == 0 and GameManager.player_id == 1:
		print("[DEVELOPER SAFETY] No data entries found for Player 1. Injecting clean default testing tracks...")
		DatabaseManager.create_default_chapter_progress(1)
		unlocked_list = GameManager.get_unlocked_chapters()
		
	print("[DEBUG] Unlocked Chapters Array returned from SQLite: ", unlocked_list)
	
	# FIXED: Map visual UI scene index selections to their explicit database tracking IDs cleanly
	var target_db_chapter_number = current_view_index
	
	# Kumuha ng buong status ng current chapter view mula sa database table
	DatabaseManager.db.query_with_bindings("""
		SELECT is_unlocked, is_completed 
		FROM chapter_progress 
		WHERE player_id = ? AND chapter_number = ?;
	""", [GameManager.player_id, target_db_chapter_number])
	
	if DatabaseManager.db.query_result.size() > 0:
		var record = DatabaseManager.db.query_result[0]
		is_chapter_unlocked = int(record["is_unlocked"]) == 1
		is_chapter_completed = int(record["is_completed"]) == 1
	else:
		if current_view_index == 1:
			is_chapter_unlocked = true

	# EVALUATE CONTENT DATA MAPS BASED ON TRACKING INDEX
	match current_view_index:
		1:
			title_text = "PROLOGUE"
			target_thumbnail_path = THUMB_PROLOGUE
		2:
			title_text = "CHAPTER 1"
			target_thumbnail_path = THUMB_CHAPTER_1
		3:
			title_text = "CHAPTER 2"
			target_thumbnail_path = THUMB_CHAPTER_2
		4:
			title_text = "CHAPTER 3"
			target_thumbnail_path = THUMB_CHAPTER_3
		5:
			title_text = "CHAPTER 4"
			target_thumbnail_path = THUMB_CHAPTER_4
		6:
			title_text = "CHAPTER 5"
			target_thumbnail_path = THUMB_CHAPTER_5
		7:
			title_text = "EPILOGUE"
			target_thumbnail_path = THUMB_ENDING

	# BOUNDARY HIDING CONTROLS
	back_arrow.visible = (current_view_index > 1)
	next_arrow.visible = (current_view_index < 7)

	# INSTANT VISUAL ASSIGNMENT
	chapter_label.text = title_text
	set_panel_image(target_thumbnail_path if is_chapter_unlocked else LOGO_LOCKED)
	
	# IPASA ANG STATUS PARA SA BAGONG COMPLETED/FINISHED CONFIGURATIONS
	adjust_play_button_state(is_chapter_unlocked, is_chapter_completed)

# =========================================
# PANEL IMAGE HELPER
# =========================================
func set_panel_image(img_path: String):
	var new_stylebox = StyleBoxTexture.new()
	new_stylebox.texture = load(img_path)
	chapter_thumbnail.add_theme_stylebox_override("panel", new_stylebox)

# =========================================
# PLAY BUTTON VISUAL LOGIC
# =========================================
func adjust_play_button_state(unlocked : bool, completed : bool):
	if play_btn:
		play_btn.disabled = false 
		
		if completed:
			play_btn.text = "FINISHED"
			play_btn.modulate = Color(0.5, 0.9, 0.5, 1.0) # Light Green overlay modulation
			play_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif unlocked:
			play_btn.text = "PLAY"
			play_btn.modulate = Color(1.0, 1.0, 1.0, 1.0) # Native color style maps
			play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			play_btn.text = "LOCKED"
			play_btn.modulate = Color(0.35, 0.35, 0.35, 1.0) # Dark Grey overlay
			play_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

# =========================================
# ARROW CLICK ROUTING EVENTS
# =========================================
func _on_next_arrow_pressed():
	if current_view_index < 7:
		current_view_index += 1
		update_selection_ui()

func _on_back_arrow_pressed():
	if current_view_index > 1:
		current_view_index -= 1
		update_selection_ui()

# =========================================
# MENU NAVIGATION ACTION (KEEP MUSIC ALIVE)
# =========================================
func _on_back_menu_btn_pressed():
	print("[SYSTEM] Returning to Main Menu. Keeping background streams looping smoothly.")
	
	# Directly change the scene context to the main screen layout.
	# By bypassing AudioManager.stop_all_music(), your exploration theme stays persistent.
	get_tree().change_scene_to_file("res://Scenes/Main Screen/main_screen.tscn")

# =========================================
# MAIN PLAY ACTION ROUTING
# =========================================
func _on_play_btn_pressed():
	
	AudioManager.stop_all_music()
	var target_db_chapter_number = current_view_index

	# PREVENT ACCIDENTAL CLICKS ON LOCKED OR FINISHED LEVELS
	DatabaseManager.db.query_with_bindings("""
		SELECT is_unlocked, is_completed 
		FROM chapter_progress 
		WHERE player_id = ? AND chapter_number = ?;
	""", [GameManager.player_id, target_db_chapter_number])
	
	var can_play = false
	if DatabaseManager.db.query_result.size() > 0:
		var record = DatabaseManager.db.query_result[0]
		var unlocked = int(record["is_unlocked"]) == 1
		var completed = int(record["is_completed"]) == 1
		if unlocked and not completed:
			can_play = true
	else:
		if current_view_index == 1:
			can_play = true

	if not can_play:
		print("[SYSTEM] Chapter is currently locked or already finished. Action aborted.")
		return 

	# MATCH AND ASSIGN ACTIVE GAME STATE TRACKERS BEFORE ROUTING
	GameManager.current_chapter = current_view_index
	
	match current_view_index:
		1:
			TransitionManager.transition_to("res://Scenes/Prologue/prologue.tscn", "PROLOGUE")
		2:
			TransitionManager.transition_to("res://Scenes/Chapter 1/chapter_1.tscn", "CHAPTER 1")
		3:
			TransitionManager.transition_to("res://Scenes/Chapter 2/chapter_2_scene_1.tscn", "CHAPTER 2")
		4:
			TransitionManager.transition_to("res://Scenes/Chapter 3/chapter_3_scene_1.tscn", "CHAPTER 3")
		5:
			TransitionManager.transition_to("res://Scenes/Chapter 4/chapter_4_scene_1.tscn", "CHAPTER 4")
		6:
			TransitionManager.transition_to("res://Scenes/Chapter 5/chapter_5_scene_1.tscn", "CHAPTER 5")
		7:
			TransitionManager.transition_to("res://Scenes/Ending/ending.tscn", "EPILOGUE")
