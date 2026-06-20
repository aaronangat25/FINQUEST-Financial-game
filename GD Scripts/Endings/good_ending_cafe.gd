extends Control

# --- PRELOADED SCENES & ASSETS ---
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const CAFE_INDOOR_BG = preload("res://Assets/Backgrounds/Endings/cafeindoorbg.png")

# --- NODE REFERENCES ---
@onready var janecafebg = $janecafebg
@onready var jane_barista = $Jane2DBaristaAnchor/jane2d_barista
@onready var kylie = $KylieDialogueAnchor/kylie2d

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
	
	AudioManager.play_coffee_shop_music()
	# 1. Initialize character elements to completely hidden
	if jane_barista:
		jane_barista.hide()
		jane_barista.modulate.a = 0.0
		
	if kylie:
		kylie.hide()
		kylie.modulate.a = 0.0

	await get_tree().process_frame
	
	# 2. Run the complex double title card sequence
	await _run_double_title_sequence()
	
	if initial_black_screen:
		var fade_tween = create_tween()
		fade_tween.tween_property(initial_black_screen, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_tween.finished
		initial_black_screen.queue_free()
	
	# 3. Fade away the storefront black transition screen smoothly
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	# 4. Count 2 seconds exactly after the black screen disappears
	await get_tree().create_timer(2.0).timeout
	
	# 5. Cinematic cut to inside the cafe storefront layout
	await _transition_to_indoor_cafe()
	
	# 🏅 ACHIEVEMENT INTEGRATION: Pop the correct database key for the Good Ending!
	GameManager.unlock_achievement("GOOD_ENDING")
	
	# 6. Play the ultimate good ending script sequence
	_play_good_ending_sequence()


# --- DOUBLE TITLE CARD TIMING SEQUENCER ---
func _run_double_title_sequence() -> void:
	if TransitionManager.has_method("fade_to_black_instant"):
		TransitionManager.fade_to_black_instant()
		
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.modulate.a = 0.0
		title_label.show()
		await get_tree().create_timer(1.0).timeout
		
		# --- TITLE CARD 1: AFTER GRADUATION ---
		title_label.text = "AFTER\nGRADUATION"
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		
		await get_tree().create_timer(0.5).timeout
		
		# --- TITLE CARD 2: AT JANE'S BREW CAFE ---
		title_label.text = "At\nJane’s\nBrew\nCafe"
		var t3 = create_tween()
		t3.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t3.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t4 = create_tween()
		t4.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t4.finished
		
		title_label.hide()
		await get_tree().create_timer(1.0).timeout


# --- INDOOR BACKGROUND CUT TRANSITION ---
func _transition_to_indoor_cafe() -> void:
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	if janecafebg and CAFE_INDOOR_BG:
		var new_stylebox = StyleBoxTexture.new()
		new_stylebox.texture = CAFE_INDOOR_BG
		janecafebg.add_theme_stylebox_override("panel", new_stylebox)
		
	await get_tree().create_timer(2.0).timeout
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	await get_tree().create_timer(2.0).timeout


# --- GOOD ENDING CINEMATIC SEQUENCE ---
func _play_good_ending_sequence() -> void:
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		var t_box_in = create_tween()
		t_box_in.tween_property(box_visual, "modulate:a", 1.0, 1.0)
		await t_box_in.finished
		
	if jane_barista:
		jane_barista.modulate.a = 0.0
		jane_barista.show()
		if jane_barista.has_method("appear"):
			jane_barista.appear("idle", false)
			
	if kylie:
		kylie.modulate.a = 0.0
		kylie.show()
		if kylie.has_method("appear"):
			kylie.appear("idle", false)
			
	await get_tree().create_timer(0.5).timeout

	var choice_text = "cafe"
	if "choice_printing" in Global and Global.choice_printing != "":
		choice_text = Global.choice_printing 
		
	var dialogue_data = [
		{"speaker": "Kylie", "text": "Grabe… from struggling student to " + choice_text + " owner?"},
		{"speaker": "Jane", "text": "Lahat nagsimula sa tamang paghawak ng maliiit na allowance."}
	]
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(dialogue_data)
	await active_dialogue_box.dialogue_finished
	
	if jane_barista and jane_barista.has_method("exit"):
		jane_barista.exit(true)
	if kylie and kylie.has_method("exit"):
		kylie.exit(true)
		
	await get_tree().create_timer(0.5).timeout
	
	if jane_barista: jane_barista.hide()
	if kylie: kylie.hide()
		
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	
	await get_tree().create_timer(1.5).timeout
	
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
		{"speaker": "", "text": "Because of discipline, smart risks, and financial wiisdom, Jane built not just income—but her dream."},
		{"speaker": "", "text": "Financial freedom starts wiith small smart choices."}
	]
	active_dialogue_box.start_dialogue(final_narration)
	await active_dialogue_box.dialogue_finished
	
	if box_visual:
		var t_box_final = create_tween()
		t_box_final.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_final.finished
	active_dialogue_box.queue_free()
	
	await get_tree().create_timer(3.0).timeout
	
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	# 💾 DATABASE FLUSH: Commits "GOOD_ENDING" to the persistent SQLite tables cleanly before changing scenes
	GameManager.flush_buffer_to_database()
	Global.ending_type = "good_cafe"	
	get_tree().change_scene_to_file("res://Scenes/Game End/game_end_cholce.tscn")
