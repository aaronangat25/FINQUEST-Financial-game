extends CanvasLayer

# =========================================
# FINQUEST REUSABLE PAUSE UTILITY (FIXED)
# =========================================

# NODE PATHS BASED ON YOUR EXACT TREE
@onready var pause_button : Button = $pause_btn
@onready var menu_panel : Panel = $Panel
@onready var resume_btn : Button = $Panel/menu_button_container/resume_btn
@onready var mainmenu_btn : Button = $Panel/menu_button_container/mainmenu_btn

# =========================================
# GODOT READY
# =========================================
func _ready():
	# FORCE MAXIMUM OVERLAP PRIORITY
	layer = 10

	# 1. Ensure the overlay menu is hidden when the chapter first boots up
	if menu_panel:
		menu_panel.visible = false
		
	# 2. Wire up all button press interactions safely
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	if resume_btn:
		resume_btn.pressed.connect(_on_resume_pressed)
	if mainmenu_btn:
		mainmenu_btn.pressed.connect(_on_main_menu_pressed)

# =========================================
# DYNAMIC RUNTIME PERFORMANCE MONITOR
# =========================================
func _process(_delta: float) -> void:
	# Keep tracking the root tree scene to see if SavingScreen or transitions are active
	var current_scene_root = get_tree().current_scene
	if current_scene_root:
		var saving_overlay = current_scene_root.get_node_or_null("SavingScreen")
		
		# Hide pause button completely if saving or transitions are busy
		if (saving_overlay and saving_overlay.visible) or TransitionManager.is_transitioning:
			hide()
		else:
			show()

# =========================================
# OPEN PAUSE OVERLAY
# =========================================
func _on_pause_button_pressed():
	# DOUBLE CHECK SAFETY LOCK:
	var current_scene_root = get_tree().current_scene
	if current_scene_root:
		var saving_overlay = current_scene_root.get_node_or_null("SavingScreen")
		if saving_overlay and saving_overlay.visible:
			print("[SYSTEM] Pause blocked: Saving screen is currently active.")
			return
			
	# Intercept and block layout actions if transition animations are processing
	if TransitionManager.is_transitioning:
		print("[SYSTEM] Pause blocked: Scene transition in progress.")
		return

	print("[SYSTEM] Game paused.")
	
	# Freeze all background logic processing safely
	get_tree().paused = true
	
	# Show the beautiful grey panel overlay options
	if menu_panel:
		menu_panel.visible = true

# =========================================
# RESUME GAMEPLAY ACTION
# =========================================
func _on_resume_pressed():
	print("[SYSTEM] Game resumed.")
	
	# Hide the pause overlay panel
	if menu_panel:
		menu_panel.visible = false
		
	# Unfreeze the game tree so dialogue and actions start moving again
	get_tree().paused = false

# =========================================
# QUIT TO MAIN MENU ROUTING
# =========================================
func _on_main_menu_pressed():
	print("[SYSTEM] Quitting to Main Menu. Processing sandbox clean sweep...")
	
	# 1. Unpause the engine FIRST so code can process out-of-scene logic cleanup frames safely
	get_tree().paused = false
	
	# 2. Wipe all choice selection memory tracking arrays and hard-reset the runtime variables
	GameManager.clear_temporary_buffer()
	
	# 3. Synchronize the local manager explicitly with your baseline SQLite records
	GameManager.load_player_stats()
	
	# 4. Direct path back to your landing scene
	get_tree().change_scene_to_file("res://Scenes/Main Screen/main_screen.tscn")
