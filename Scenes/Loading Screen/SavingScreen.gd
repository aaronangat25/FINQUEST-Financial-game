extends CanvasLayer

# =========================================
# FINQUEST GLOBAL SAVING OVERLAY 
# =========================================

func _ready():
	# Completely deactivate and hide this layer the moment the scene starts
	hide()
	process_mode = PROCESS_MODE_DISABLED

func trigger_save_sequence(next_scene_path: String):
	# 1. Wake up the processing layer and bring it to full view
	process_mode = PROCESS_MODE_ALWAYS
	show()
	
	# 2. Fire database updates
	GameManager.complete_current_chapter(100.0)
	print("[DATABASE] Progression saved smoothly.")
	
	# 3. Wait 2 seconds for the immersive save screen effect
	await get_tree().create_timer(2.0).timeout
	
	# 4. Change scene directly through the engine core tree
	get_tree().change_scene_to_file(next_scene_path)
