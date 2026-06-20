extends Control

# --- PRELOADED SCENES ---
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_office = $Jane2DOfficeAnchor/jane2d_office
@onready var jen_dialogue = $JenDialogueAnchor/jen2d

var active_dialogue_box

var initial_black_screen: ColorRect

func _ready() -> void:
	# --- FIXED: SPAWN AN INSTANT BLACK BLANKET ON FRAME ONE ---
	initial_black_screen = ColorRect.new()
	initial_black_screen.name = "InitialBlackScreen"
	initial_black_screen.color = Color(0, 0, 0, 1)
	initial_black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	initial_black_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(initial_black_screen)
	
	for child in get_tree().root.get_children():
		if child.has_method("refresh_display") and child.has_method("update_ui"):
			child.hide()
	
	AudioManager.play_chapter_music()
	# 1. Start completely invisible via native node settings
	if jane_office:
		jane_office.hide()
		jane_office.modulate.a = 0.0
		
	if jen_dialogue:
		jen_dialogue.hide()
		jen_dialogue.modulate.a = 0.0

	await get_tree().process_frame
	
	# 2. Run the "AFTER GRADUATION" Title Card Sequence
	await _run_title_sequence()
	
	if initial_black_screen:
		var fade_tween = create_tween()
		fade_tween.tween_property(initial_black_screen, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_tween.finished
		initial_black_screen.queue_free()
	
	# 3. Fade away the black transition screen smoothly
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	# 4. Count 2 seconds exactly after the black screen disappears
	await get_tree().create_timer(2.0).timeout
	
	# 5. Play the mid ending narrative cutscene sequence
	_play_mid_ending_sequence()


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


# --- MID ENDING CINEMATIC SEQUENCE ---
func _play_mid_ending_sequence() -> void:
	# Instantiate Dialogue Box as hidden base asset
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	
	# =========================================================
	# === SEQUENTIAL RULE STEP 1: DIALOGUE BOX FADES IN FIRST ===
	# =========================================================
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		var t_box_in = create_tween()
		t_box_in.tween_property(box_visual, "modulate:a", 1.0, 1.0)
		await t_box_in.finished
		
	# =========================================================
	# === SEQUENTIAL RULE STEP 2: CHARACTER LAYOUTS FADE IN SAME TIMING ===
	# =========================================================
	if jane_office:
		jane_office.show()
		jane_office.appear("idle", false)
	
	if jen_dialogue:
		jen_dialogue.show()
		if jen_dialogue.has_method("appear"):
			jen_dialogue.appear("idle", false)
			
	await get_tree().create_timer(0.5).timeout

	# 🏅 ACHIEVEMENT INTEGRATION: Pop the correct database key for the Corporate Ladder Climber Ending!
	GameManager.unlock_achievement("MID_ENDING")

	# Present dialogue lines
	var dialogue_data = [
		{"speaker": "Boss", "text": "Welcome to your first day, Jane."},
		{"speaker": "Jane", "text": "Thank you po."},
		{"speaker": "Jane", "text": "Hindi man madali… pero stable. Step by step, I’m building my future."}
	]
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(dialogue_data)
	await active_dialogue_box.dialogue_finished
	
	# =========================================================
	# === SEQUENTIAL RULE STEP 3: CHARACTER LAYOUTS FADE OUT FIRST ===
	# =========================================================
	if jane_office and jane_office.has_method("exit"):
		jane_office.exit(true)
		
	if jen_dialogue and jen_dialogue.has_method("exit"):
		jen_dialogue.exit(true)
		
	await get_tree().create_timer(0.5).timeout
	
	if jen_dialogue: jen_dialogue.hide()
	if jane_office: jane_office.hide()
		
	# =========================================================
	# === SEQUENTIAL RULE STEP 4: DIALOGUE BOX FADES OUT SECOND ===
	# =========================================================
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
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
		
	var name_panel = active_dialogue_box.find_child("Panel", true, false)
	var name_label = active_dialogue_box.find_child("NameLabel", true, false)
	if name_panel: name_panel.hide(); name_panel.modulate.a = 0.0
	if name_label: name_label.hide(); name_label.text = ""
	
	var final_narration = [
		{"speaker": "", "text": "Smart budgeting and responsible choices led Jane to a stable and secure life."},
		{"speaker": "", "text": "Consistency creates stability."}
	]
	active_dialogue_box.start_dialogue(final_narration)
	await active_dialogue_box.dialogue_finished
	
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
		
	# 💾 DATABASE FLUSH: Securely saves the unlocked "MID_ENDING" achievement data to the SQLite backend
	GameManager.flush_buffer_to_database()
	Global.ending_type = "mid"	
	get_tree().change_scene_to_file("res://Scenes/Game End/game_end_cholce.tscn")
