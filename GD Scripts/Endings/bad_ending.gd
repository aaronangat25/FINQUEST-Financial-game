extends Control

# --- PRELOADED SCENES ---
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
# Matching your scene tree hierarchy from image_9880e0.png precisely
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking

var active_dialogue_box

func _ready() -> void:
	
	AudioManager.play_bad_ending_music()
	# 1. Initialize elements to hidden so they don't flash on launch
	if jane_thinking:
		jane_thinking.hide()
		jane_thinking.modulate.a = 0.0

	await get_tree().process_frame
	
	# 2. Run the "AFTER GRADUATION" Title Card Sequence
	await _run_title_sequence()
	
	# 3. Fade away the black transition screen smoothly
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	# 4. Count 2 seconds exactly after the black screen disappears
	await get_tree().create_timer(2.0).timeout
	
	# 5. Play the bad ending narrative cutscene sequence
	_play_bad_ending_sequence()


# --- TIMED TITLE CARD SEQUENCE ---
func _run_title_sequence() -> void:
	if TransitionManager.has_method("fade_to_black_instant"):
		TransitionManager.fade_to_black_instant()
		
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.modulate.a = 0.0
		title_label.show()
		await get_tree().create_timer(1.0).timeout
		
		title_label.text = "AFTER\nGRADUATION"
		
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		
		title_label.hide()
		await get_tree().create_timer(1.0).timeout


# --- BAD ENDING CINEMATIC SEQUENCE ---
func _play_bad_ending_sequence() -> void:
	# Instantiate Dialogue Box as hidden base asset
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	
	# =========================================================
	# === SEQUENTIAL RULE: DIALOGUE BOX FADES IN FIRST ===
	# =========================================================
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		var t_box_in = create_tween()
		t_box_in.tween_property(box_visual, "modulate:a", 1.0, 1.0)
		await t_box_in.finished # Wait until dialogue box is completely visible
		
	# =========================================================
	# === SEQUENTIAL RULE: JANE THINKING FADES IN SECOND ===
	# =========================================================
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): 
			jane_thinking.appear("idle", false)
			
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished # Wait until Jane is completely visible

	# Present character lines
	var dialogue_data = [
		{"speaker": "Jane", "text": "Graduate na ako…"},
		{"speaker": "Jane", "text": "Pero bakit parang stuck pa rin ako? Weeks passed. No job offers. No savings."}
	]
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(dialogue_data)
	await active_dialogue_box.dialogue_finished
	
	# =========================================================
	# === SEQUENTIAL RULE: JANE THINKING FADES OUT FIRST ===
	# =========================================================
	if jane_thinking:
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished # Wait until Jane is completely hidden
		jane_thinking.hide()
		
	# =========================================================
	# === SEQUENTIAL RULE: DIALOGUE BOX FADES OUT SECOND ===
	# =========================================================
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished # Wait until dialogue box is completely hidden
		
	active_dialogue_box.queue_free()
	
	# 6. Count 1.5 seconds gap delay
	await get_tree().create_timer(1.5).timeout
	
	# 7. Fade in Dialogue Box only (Nameless Narration Block)
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	if "is_fading" in active_dialogue_box: 
		active_dialogue_box.is_fading = false
	add_child(active_dialogue_box)
	
	box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 1.0
		
	# Completely hide Name Labels panels to style it as narration
	var name_panel = active_dialogue_box.find_child("Panel", true, false)
	var name_label = active_dialogue_box.find_child("NameLabel", true, false)
	if name_panel: name_panel.hide(); name_panel.modulate.a = 0.0
	if name_label: name_label.hide(); name_label.text = ""
	
	var final_narration = [
		{"speaker": "", "text": "Graduation is not the finish line. It is the start of planning for the future."},
		{"speaker": "", "text": "Future planning is as significant as graduation itself."}
	]
	active_dialogue_box.start_dialogue(final_narration)
	await active_dialogue_box.dialogue_finished
	
	# Fade out narration box view
	if box_visual:
		var t_box_final = create_tween()
		t_box_final.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_final.finished
	active_dialogue_box.queue_free()
	
	# 8. Count 2 seconds exactly
	await get_tree().create_timer(2.0).timeout
	
	# 9. Fade into black overlay screen and switch over to game_end_choice.tscn
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	get_tree().change_scene_to_file("res://Scenes/Game End/game_end_cholce.tscn")
