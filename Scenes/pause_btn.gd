extends CanvasLayer

# =========================================
# FINQUEST REUSABLE PAUSE UTILITY
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
	# Setting this layer index high guarantees it renders over all other nodes!
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
	# Keep tracking the root tree scene to see if SavingScreen is currently running
	var current_scene_root = get_tree().current_scene
	if current_scene_root:
		var saving_overlay = current_scene_root.get_node_or_null("SavingScreen")
		
		if saving_overlay and saving_overlay.visible:
			# If saving screen is running, hide this entire layer from view instantly
			hide()
		else:
			# If no saving screen is running, make sure the pause button is visible
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
	print("[SYSTEM] Quitting to Main Menu.")
	
	# CRITICAL FIX: Always unpause the engine BEFORE changing scenes!
	# If you leave it paused, your Main Menu will freeze up completely.
	get_tree().paused = false
	
	# Direct path back to your landing scene
	get_tree().change_scene_to_file("res://Scenes/Main Screen/main_screen.tscn")
