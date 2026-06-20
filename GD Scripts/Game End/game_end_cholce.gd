extends Control

# =================================================================
# FINQUEST GAME CONCLUSION & MASTER RESET ENGINE
# =================================================================

# --- NODE REFERENCES ---
@onready var restart_btn = $menu_button_container/restartbtn
@onready var main_menu_btn = $menu_button_container/mainmenubtn
@onready var menu_button_container = $menu_button_container

# 🏅 FIXED REFERENCE: Re-added your ending label node reference
@onready var ending_label = $ending_label

# A clean script flag to block inputs without breaking textures
var is_transitioning: bool = false

func _ready() -> void:
	is_transitioning = false
	
	# 1. Instantly strip away the black transition screen as soon as this menu initializes
	if TransitionManager.has_method("fade_from_black_instant"):
		TransitionManager.fade_from_black_instant()
	elif TransitionManager.has_method("fade_from_black"):
		TransitionManager.fade_from_black()
		
	# --- RESET VISIBILITY STATES ON LOAD ---
	if menu_button_container:
		menu_button_container.show()
		menu_button_container.modulate.a = 1.0
		menu_button_container.mouse_filter = Control.MOUSE_FILTER_STOP
		
	# 🏅 FIXED ACTION: Updates display text using explicit tracking tokens
	_update_ending_label_text()
		
	# 2. Connect button signals manually
	if restart_btn and not restart_btn.pressed.is_connected(_on_restart_btn_pressed):
		restart_btn.pressed.connect(_on_restart_btn_pressed)
		
	if main_menu_btn and not main_menu_btn.pressed.is_connected(_on_main_menu_btn_pressed):
		main_menu_btn.pressed.connect(_on_main_menu_btn_pressed)


# --- VARIABLE CONDITION EVALUATOR ---
func _update_ending_label_text() -> void:
	if not ending_label: return
	
	var ending_text: String = "ENDING"
	
	# 1. PRIMARY CONDITION: Check explicit global variable type markers
	if "ending_type" in Global and Global.ending_type != "":
		match Global.ending_type:
			"good_cafe":
				ending_text = "GOOD ENDING CAFE OWNER"
			"good_clerk":
				ending_text = "GOOD ENDING STORE OWNER"
			"mid":
				ending_text = "MID ENDING"
			"bankrupt":
				ending_text = "BANKRUPT ENDING"
			"dropout":
				ending_text = "DROPOUT ENDING"
			"bad":
				ending_text = "BAD ENDING"
				
	# 2. AUTOMATIC FALLBACK: If tracking token is missing, read stored scene data string
	if ending_text == "ENDING":
		var automated_path: String = ""
		if "current_scene" in GameManager and GameManager.current_scene != "":
			automated_path = GameManager.current_scene.to_lower()
		elif "current_chapter_description" in GameManager:
			automated_path = GameManager.current_chapter_description.to_lower()
			
		if automated_path != "":
			if "good_ending_cafe" in automated_path:
				ending_text = "GOOD ENDING CAFE OWNER"
			elif "good_ending_clerk" in automated_path:
				ending_text = "GOOD ENDING STORE OWNER"
			elif "mid_ending" in automated_path:
				ending_text = "MID ENDING"
			elif "bankrupt_ending" in automated_path:
				ending_text = "BANKRUPT ENDING"
			elif "dropout_ending" in automated_path:
				ending_text = "DROPOUT ENDING"
			elif "bad_ending" in automated_path:
				ending_text = "BAD ENDING"

	ending_label.text = ending_text


# --- RESTART BUTTON LOGIC (FULL MASTER FACTORY RESET) ---
func _on_restart_btn_pressed() -> void:
	if is_transitioning: return
	is_transitioning = true
	
	print("[MASTER RESET] Restart button clicked! Wiping database states for a true fresh run...")
	
	if menu_button_container:
		menu_button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# =================================================================
	# 1. RUNTIME RAM & STATS RESYNC (With Achievement Preservation)
	# =================================================================
	var saved_achievements = {}
	if "unlocked_achievements" in GameManager:
		saved_achievements = GameManager.unlocked_achievements.duplicate()

	if "money" in Global: Global.money = 0
	if "currency" in Global: Global.currency = 0
	if "choice_meeting" in Global: Global.choice_meeting = ""
	if "choice_printing" in Global: Global.choice_printing = ""
	if "ending_type" in Global: Global.ending_type = "" # Clear global variable tracking state

	if "on_hand_cash" in GameManager: GameManager.on_hand_cash = 0
	if "bank_cash" in GameManager: GameManager.bank_cash = 0
	if "total_expenses" in GameManager: GameManager.total_expenses = 0
	if "total_income" in GameManager: GameManager.total_income = 0
	if "financial_wisdom_points" in GameManager: GameManager.financial_wisdom_points = 0
	if "grades" in GameManager: GameManager.grades = 0.0
	if "current_chapter" in GameManager: GameManager.current_chapter = 1
	if "current_scene" in GameManager: GameManager.current_scene = ""
	
	if "buffered_choices" in GameManager: GameManager.buffered_choices.clear()
	if "buffered_bank_change" in GameManager: GameManager.buffered_bank_change = 0
	if "buffered_on_hand_change" in GameManager: GameManager.buffered_on_hand_change = 0
	if "current_chapter_description" in GameManager: GameManager.current_chapter_description = ""

	if "unlocked_achievements" in GameManager:
		GameManager.unlocked_achievements = saved_achievements

	# =================================================================
	# 2. DATABASE PROGRESSION RESET PIPELINE (Customized Selective Clear)
	# =================================================================
	DatabaseManager.db.query_with_bindings("""
		UPDATE chapter_progress 
		SET is_unlocked = 0, is_completed = 0 
		WHERE player_id = ? AND chapter_number > 1;
	""", [GameManager.player_id])
	
	DatabaseManager.db.query_with_bindings("""
		UPDATE chapter_progress 
		SET is_unlocked = 1, is_completed = 0 
		WHERE player_id = ? AND chapter_number = 1;
	""", [GameManager.player_id])
	
	DatabaseManager.db.query_with_bindings("""
		DELETE FROM player_choices WHERE player_id = ?;
	""", [GameManager.player_id])
	
	DatabaseManager.db.query_with_bindings("""
		DELETE FROM transactions WHERE player_id = ?;
	""", [GameManager.player_id])
	
	DatabaseManager.db.query_with_bindings("""
		DELETE FROM minigame_progress WHERE player_id = ?;
	""", [GameManager.player_id])
	
	DatabaseManager.db.query_with_bindings("""
		UPDATE player_stats
		SET bank_cash = 3000, 
			on_hand_cash = 0, 
			financial_wisdom_points = 0, 
			grades = 0.0, 
			current_chapter = 1,
			total_income = 0,
			total_expenses = 0
		WHERE player_id = ?;
	""", [GameManager.player_id])
	
	if GameManager.has_method("flush_buffer_to_database"):
		GameManager.flush_buffer_to_database()
	
	print("[DATABASE] SQLite parameters synchronized. Stored achievements kept untouched for QA metrics.")

	# =================================================================
	# 3. VISUAL TRANSITION SEQUENCING
	# =================================================================
	if menu_button_container:
		var t_menu = create_tween()
		t_menu.tween_property(menu_button_container, "modulate:a", 0.0, 0.5)
		await t_menu.finished
		menu_button_container.hide()

	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	if AudioManager.has_method("play_chapter_music"):
		AudioManager.play_chapter_music()
		
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "Chapter 1"
		title_label.modulate.a = 0.0
		title_label.show()
		
		var t_text = create_tween()
		t_text.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t_text.finished
		
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Chapter 1/chapter_1.tscn")


# --- MAIN MENU BUTTON LOGIC ---
func _on_main_menu_btn_pressed() -> void:
	if is_transitioning: return
	is_transitioning = true
	
	print("Main Menu button clicked! Leaving game over screen...")
	
	if menu_button_container:
		menu_button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	else:
		await get_tree().create_timer(0.5).timeout
		
	get_tree().change_scene_to_file("res://Scenes/Main Screen/main_screen.tscn")


# =================================================================
# ANDROID HARDWARE / OS GESTURE BACK INTERCEPTOR
# =================================================================
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_android_back_button()

func _handle_android_back_button() -> void:
	print("[MOBILE SAFETY LOCK] User pressed Android back on choices panel. Request ignored safely.")
