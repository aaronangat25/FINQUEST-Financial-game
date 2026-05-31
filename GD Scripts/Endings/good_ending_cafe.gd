extends Control

# --- PRELOADED SCENES & ASSETS ---
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const CAFE_INDOOR_BG = preload("res://Assets/Backgrounds/Endings/cafeindoorbg.png") # Matches your file tree in image_96b005.png

# --- NODE REFERENCES ---
# Matching your scene tree hierarchy from image_96b005.png precisely
@onready var janecafebg = $janecafebg
@onready var jane_barista = $Jane2DBaristaAnchor/jane2d_barista# Adjusted spelling if "Jane2DBaristaAnchor" is used
@onready var kylie = $KylieDialogueAnchor/kylie2d

var active_dialogue_box

func _ready() -> void:
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
	
	# 3. Fade away the storefront black transition screen smoothly
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	# 4. Count 2 seconds exactly after the black screen disappears
	await get_tree().create_timer(2.0).timeout
	
	# 5. Cinematic cut to inside the cafe storefront layout
	await _transition_to_indoor_cafe()
	
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
		
		await get_tree().create_timer(3.0).timeout # Count 3sec
		
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished # Fadeout
		
		await get_tree().create_timer(0.5).timeout
		
		# --- TITLE CARD 2: AT JANE'S BREW CAFE ---
		title_label.text = "At\nJane’s\nBrew\nCafe"
		var t3 = create_tween()
		t3.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t3.finished
		
		await get_tree().create_timer(3.0).timeout # Count 3sec
		
		var t4 = create_tween()
		t4.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t4.finished # Fadeout
		
		title_label.hide()
		await get_tree().create_timer(1.0).timeout # Count 1sec follow up


# --- INDOOR BACKGROUND CUT TRANSITION ---
func _transition_to_indoor_cafe() -> void:
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	# --- THE FIX FOR PANEL NODES ---
	if janecafebg and CAFE_INDOOR_BG:
		# Create a new StyleBoxTexture to hold your indoor image asset cleanly
		var new_stylebox = StyleBoxTexture.new()
		new_stylebox.texture = CAFE_INDOOR_BG
		
		# Assign it to the panel node theme override slot
		janecafebg.add_theme_stylebox_override("panel", new_stylebox)
		
	await get_tree().create_timer(2.0).timeout
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	await get_tree().create_timer(2.0).timeout


# --- GOOD ENDING CINEMATIC SEQUENCE ---
func _play_good_ending_sequence() -> void:
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
	# === SEQUENTIAL RULE STEP 2: CHARACTERS FADE IN (ANTI-BLINK FIX) ===
	# =========================================================
	# We force their initial visibility states to stay hidden, 
	# then let their own native appear() functions reveal them smoothly.
	if jane_barista:
		jane_barista.modulate.a = 0.0
		jane_barista.show()
		if jane_barista.has_method("appear"):
			jane_barista.appear("idle", false) # Let its own internal tween handle the fade seamlessly!
			
	if kylie:
		kylie.modulate.a = 0.0
		kylie.show()
		if kylie.has_method("appear"):
			kylie.appear("idle", false) # Let its own internal tween handle the fade seamlessly!
			
	# Wait 0.5 seconds for their internal character animations to finish fading in cleanly
	await get_tree().create_timer(0.5).timeout

	# Present final dialogue tracking script options
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
	
	# =========================================================
	# === SEQUENTIAL RULE STEP 3: CHARACTERS FADE OUT FIRST ===
	# =========================================================
	if jane_barista and jane_barista.has_method("exit"):
		jane_barista.exit(true)
	if kylie and kylie.has_method("exit"):
		kylie.exit(true)
		
	# Wait for their internal exit fades (0.5 seconds) to finish cleanly
	await get_tree().create_timer(0.5).timeout
	
	if jane_barista: jane_barista.hide()
	if kylie: kylie.hide()
		
	# =========================================================
	# === SEQUENTIAL RULE STEP 4: DIALOGUE BOX FADES OUT SECOND ===
	# =========================================================
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	
	# 7. Count 1.5 seconds narration structural gap
	await get_tree().create_timer(1.5).timeout
	
	# 8. Fade in Dialogue Box only (Nameless Narration Block)
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
	
	# Fade out narration display container
	if box_visual:
		var t_box_final = create_tween()
		t_box_final.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_final.finished
	active_dialogue_box.queue_free()
	
	# 9. Count 3 seconds exactly
	await get_tree().create_timer(3.0).timeout
	
	# 10. Fade into black overlay screen and switch over to game_end_choice.tscn
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	get_tree().change_scene_to_file("res://Scenes/Game End/game_end_cholce.tscn")
