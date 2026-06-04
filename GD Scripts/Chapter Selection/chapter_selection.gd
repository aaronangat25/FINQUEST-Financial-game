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
	# Wait for database to be fully ready before doing anything
	while not DatabaseManager.is_ready:
		await get_tree().process_frame
	
	next_arrow.pressed.connect(_on_next_arrow_pressed)
	back_arrow.pressed.connect(_on_back_arrow_pressed)
	if play_btn:
		play_btn.pressed.connect(_on_play_btn_pressed)
	
	# Connect the new back to menu navigation asset safely
	if back_menu_btn:
		back_menu_btn.pressed.connect(_on_back_menu_btn_pressed)
	
	await update_selection_ui()

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
	
	# Map visual UI scene index selections to their explicit database tracking IDs cleanly
	var target_db_chapter_number = current_view_index
	
	# Kumuha ng buong status ng current chapter view mula sa database table
	await DatabaseManager.safe_query_with_bindings("""
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
	
	# ACADEMIC CHECK FOR CHAPTER 5 LOCKOUT
	var is_failing_gpa: bool = (GameManager.grades >= 2.75)
	
	if current_view_index == 6 and is_failing_gpa:
		print("[SYSTEM SELECTION] Player has dropped out (GPA: ", GameManager.grades, "). Hard-locking Chapter 5 layout.")
		set_panel_image(LOGO_LOCKED)
		adjust_play_button_state(false, false)
		
	# DYNAMIC EPILOGUE CHECKING LOGIC
	elif current_view_index == 7:
		# Check if they dropped out OR if they unlocked an entry in the player choices/ending table
		DatabaseManager.safe_query_with_bindings("""
			SELECT choice_value FROM player_choices 
			WHERE player_id = ? AND choice_key = 'chap5_career_pathway';
		""", [GameManager.player_id])
		
		var has_career_choice = DatabaseManager.db.query_result.size() > 0
		
		if is_failing_gpa or has_career_choice or is_chapter_unlocked:
			print("[SYSTEM SELECTION] Epilogue unlocked via branching path history.")
			set_panel_image(target_thumbnail_path)
			adjust_play_button_state(true, false) # Always allow replayability
		else:
			set_panel_image(LOGO_LOCKED)
			adjust_play_button_state(false, false)
	else:
		set_panel_image(target_thumbnail_path if is_chapter_unlocked else LOGO_LOCKED)
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
			play_btn.modulate = Color(0.5, 0.9, 0.5, 1.0)
			play_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif unlocked:
			play_btn.text = "PLAY"
			play_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			play_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			play_btn.text = "LOCKED"
			play_btn.modulate = Color(0.35, 0.35, 0.35, 1.0)
			play_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

# =========================================
# ARROW CLICK ROUTING EVENTS
# =========================================
func _on_next_arrow_pressed():
	if current_view_index < 7:
		current_view_index += 1
		await update_selection_ui()

func _on_back_arrow_pressed():
	if current_view_index > 1:
		current_view_index -= 1
		await update_selection_ui()

# =========================================
# MENU NAVIGATION ACTION (KEEP MUSIC ALIVE)
# =========================================
func _on_back_menu_btn_pressed():
	print("[SYSTEM] Returning to Main Menu. Keeping background streams looping smoothly.")
	get_tree().change_scene_to_file("res://Scenes/Main Screen/main_screen.tscn")

# =========================================
# MAIN PLAY ACTION ROUTING
# =========================================
func _on_play_btn_pressed():
	await get_tree().create_timer(0.1).timeout
	
	# Block Chapter 5 completely if they failed academically
	if current_view_index == 6 and GameManager.grades >= 2.75:
		print("[SYSTEM ACTION] Action aborted. Chapter 5 is structurally locked.")
		return
		
	# --- SMART EPILOGUE ROUTER (INDEX 7) ---
	if current_view_index == 7:
		AudioManager.stop_all_music()
		
		# Condition 1: Check low GPA for Dropout Ending
		if GameManager.grades >= 2.75:
			print("[ROUTER] Branching right into Dropout Ending Scene.")
			callable_deferred_transition("res://Scenes/Endings/dropout_ending.tscn", "EPILOGUE")
			return
			
		# Fetch career pathway selection history row from SQLite
		await DatabaseManager.safe_query_with_bindings("""
			SELECT choice_value FROM player_choices 
			WHERE player_id = ? AND choice_key = 'chap5_career_pathway' 
			ORDER BY created_at DESC LIMIT 1;
		""", [GameManager.player_id])
		
		if DatabaseManager.db.query_result.size() > 0:
			var path_taken = DatabaseManager.db.query_result[0]["choice_value"]
			
			# Condition 2: Corporate decision
			if path_taken == "Corporate":
				print("[ROUTER] Branching right into Mid Ending Corporate Scene.")
				callable_deferred_transition("res://Scenes/Endings/mid_ending.tscn", "EPILOGUE")
				return
				
			# Condition 3: Stop First decision with balance checking logic
			elif path_taken == "Stop":
				var total_player_money = GameManager.bank_cash + GameManager.on_hand_cash
				
				if total_player_money < 1000:
					print("[ROUTER] Historical records show Stop chosen with < 1000 funds. Routing to Bankrupt Ending.")
					callable_deferred_transition("res://Scenes/Endings/bankrupt_ending.tscn", "EPILOGUE")
				else:
					print("[ROUTER] Historical records show Stop chosen with valid funds. Routing to Bad Ending.")
					callable_deferred_transition("res://Scenes/Endings/bad_ending.tscn", "EPILOGUE")
				return
				
			# Condition 4: Business path chosen -> Look up explicit job_path column
			elif path_taken == "Business":
				print("[ROUTER] Business path chosen! Checking job_path row configuration from players...")
				
				await DatabaseManager.safe_query_with_bindings("""
					SELECT job_path 
					FROM players 
					WHERE id = ? 
					LIMIT 1;
				""", [GameManager.player_id])
				
				var target_good_ending = "res://Scenes/Endings/good_ending_clerk.tscn"
				
				if DatabaseManager.db.query_result.size() > 0:
					var active_job_path = DatabaseManager.db.query_result[0]["job_path"]
					if active_job_path == "Barista":
						target_good_ending = "res://Scenes/Endings/good_ending_cafe.tscn"
						print("[ROUTER] job_path is Barista. Routing to Good Ending (Cafe).")
					else:
						print("[ROUTER] job_path is ", active_job_path, ". Routing to Good Ending (Clerk).")
				else:
					print("[ROUTER] Player tracking missing. Defaulting to Clerk ending path context.")
					
				callable_deferred_transition(target_good_ending, "EPILOGUE")
				return
		
		# Condition 5: Default ultimate baseline fallback scene context tracker
		print("[ROUTER] Branching right into standard fallback Ending Scene.")
		callable_deferred_transition("res://Scenes/Ending/ending.tscn", "EPILOGUE")
		return
		
	var target_db_chapter_number = current_view_index

	await DatabaseManager.safe_query_with_bindings("""
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
		print("[SYSTEM] Chapter is locked or finished. Action aborted.")
		return 

	GameManager.current_chapter = current_view_index
	
	match current_view_index:
		1: callable_deferred_transition("res://Scenes/Prologue/prologue.tscn", "PROLOGUE")
		2: callable_deferred_transition("res://Scenes/Chapter 1/chapter_1.tscn", "CHAPTER 1")
		3: callable_deferred_transition("res://Scenes/Chapter 2/chapter_2_scene_1.tscn", "CHAPTER 2")
		4: callable_deferred_transition("res://Scenes/Chapter 3/chapter_3_scene_1.tscn", "CHAPTER 3")
		5: callable_deferred_transition("res://Scenes/Chapter 4/chapter_4_scene_1.tscn", "CHAPTER 4")
		6: callable_deferred_transition("res://Scenes/Chapter 5/chapter_5_scene_1.tscn", "CHAPTER 5")

# HELPER FUNCTION FOR DEFERRED SCENE SWAPS & RAM FLUSH
func callable_deferred_transition(scene_path: String, chapter_title: String) -> void:
	TransitionManager.call_deferred("transition_to", scene_path, chapter_title)
	call_deferred("force_memory_cleanup")

# FORCE MEMORY PURGE BEFORE NEW CHAPTER LOADS
func force_memory_cleanup() -> void:
	print("[MEMORY] Forcing full garbage collection and texture flush...")
	if chapter_thumbnail:
		chapter_thumbnail.remove_theme_stylebox_override("panel")
	OS.delay_msec(10)
	self.queue_free()
