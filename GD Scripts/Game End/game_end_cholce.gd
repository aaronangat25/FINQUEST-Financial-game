extends Control

# =================================================================
# FINQUEST GAME CONCLUSION & MASTER RESET ENGINE
# =================================================================

# --- NODE REFERENCES ---
@onready var restart_btn = $menu_button_container/restartbtn
@onready var main_menu_btn = $menu_button_container/mainmenubtn
@onready var menu_button_container = $menu_button_container

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
		
	# 2. Connect button signals manually
	if restart_btn and not restart_btn.pressed.is_connected(_on_restart_btn_pressed):
		restart_btn.pressed.connect(_on_restart_btn_pressed)
		
	if main_menu_btn and not main_menu_btn.pressed.is_connected(_on_main_menu_btn_pressed):
		main_menu_btn.pressed.connect(_on_main_menu_btn_pressed)


# --- RESTART BUTTON LOGIC (FULL MASTER FACTORY RESET) ---
func _on_restart_btn_pressed() -> void:
	if is_transitioning: return
	is_transitioning = true
	
	print("[MASTER RESET] Restart button clicked! Wiping database states for a true fresh run...")
	
	# Block interaction inputs directly on the layout container node level
	if menu_button_container:
		menu_button_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# =================================================================
	# 1. RUNTIME RAM & STATS RESYNC (Clearing GameManager First)
	# =================================================================
	# Drops cash to ₱3000/₱0, re-tracks chapter index back to 1, and clears buffers!
	if GameManager.has_method("execute_production_factory_reset"):
		GameManager.execute_production_factory_reset()

	# =================================================================
	# 2. DATABASE PROGRESSION RESET PIPELINE (SQLite Level Progress Wipe)
	# =================================================================
	# Force-relock all subsequent levels (Chapters 2-7 & Ending tracking slots) back to 0 state
	DatabaseManager.db.query_with_bindings("""
		UPDATE chapter_progress 
		SET is_unlocked = 0, is_completed = 0 
		WHERE player_id = ? AND chapter_number > 1;
	""", [GameManager.player_id])
	
	# Force reset Chapter 1 (Prologue) state back to unlocked but uncompleted
	DatabaseManager.db.query_with_bindings("""
		UPDATE chapter_progress 
		SET is_unlocked = 1, is_completed = 0 
		WHERE player_id = ? AND chapter_number = 1;
	""", [GameManager.player_id])
	
	# Revert structural currency states in Global script containers
	if "money" in Global: Global.money = 0
	if "currency" in Global: Global.currency = 0
	if "choice_meeting" in Global: Global.choice_meeting = ""
	if "choice_printing" in Global: Global.choice_printing = ""
	
	print("[DATABASE] SQLite chapter selection logs safely synchronized with GameManager resets.")

	# =================================================================
	# 3. VISUAL TRANSITION SEQUENCING
	# =================================================================
	# STEP 1: Fade the buttons out completely first (0.5 seconds duration)
	if menu_button_container:
		var t_menu = create_tween()
		t_menu.tween_property(menu_button_container, "modulate:a", 0.0, 0.5)
		await t_menu.finished
		menu_button_container.hide()

	# STEP 2: Fade the background curtain layer to black (1.0 second duration)
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	# Cross-fades out of the somber bad ending track and returns cleanly to general gameplay loops!
	if AudioManager.has_method("play_chapter_music"):
		AudioManager.play_chapter_music()
		
	# STEP 3: Now that the buttons are gone and it's pitch black, fade the "PROLOGUE" title IN
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "PROLOGUE"
		title_label.modulate.a = 0.0
		title_label.show()
		
		# Animate the text to fade IN over 1.0 second
		var t_text = create_tween()
		t_text.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t_text.finished
		
	# Hold on the completed title card for 1.5 seconds so the player can read it comfortably
	await get_tree().create_timer(1.5).timeout
		
	# Swap the scene over to the prologue blueprint file
	get_tree().change_scene_to_file("res://Scenes/Prologue/prologue.tscn")


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
