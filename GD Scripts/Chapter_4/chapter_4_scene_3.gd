extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var stat_screen = $StatsScreen

# Using find_child grabs if deep inside Panels
@onready var meeting_label = stat_screen.find_child("MeetingResultLabel", true, false)
@onready var printing_label = stat_screen.find_child("PrintingLabel", true, false)
@onready var feedback_label = stat_screen.find_child("FeedbackLabel", true, false)
@onready var chapter5_btn = stat_screen.find_child("Chapter5_btn", true, false)

var currency_hud
var active_dialogue_box

func _ready() -> void:
	# 1. Spawn Currency HUD
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	
	# 2. Setup Initial State
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if stat_screen: stat_screen.hide()
	if chapter5_btn: chapter5_btn.hide()
	
	await get_tree().process_frame
	
	# 3. Transition: Fade out black screen
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
	
	# 4. Wait 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	_play_intro_sequence()

# STEP 1: INTRO DIALOGUE
func _play_intro_sequence() -> void:
	# Rule 1.0: Box FIRST
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
	
	# Rule 1.0: Jane SECOND
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished

	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Ito na ‘yon… lahat ng pagod, gastos, at effort—dito magbubunga."}])
	await active_dialogue_box.dialogue_finished
	
	# Rule 1.0: Fade out Jane FIRST
	if jane_thinking:
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished
		jane_thinking.exit(true)
		
	# Rule 1.0: Fade out Box SECOND
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
	active_dialogue_box.queue_free()
	
	_calculate_and_show_results()

# STEP 2: LOGIC & STAT SCREEN
func _calculate_and_show_results() -> void:
	# PULL CHOICES FROM GLOBAL SCRIPT
	var meeting = Global.choice_meeting 
	var printing = Global.choice_printing 
	
	var final_feedback = ""
	var jane_reaction = ""
	
	# Format text with just "=" to prevent doubling
	if meeting_label:
		if meeting == "A": meeting_label.text = "= Face-to-Face"
		elif meeting == "B": meeting_label.text = "= Online Meeting"
		else: meeting_label.text = "= No Data"
		
	if printing_label:
		if printing == "A": printing_label.text = "= Full Colored"
		elif printing == "B": printing_label.text = "= Black & White"
		elif printing == "C": printing_label.text = "= Digital Copy"
		else: printing_label.text = "= No Data"


	var color_green = Color("2ecc71") 
	var color_red = Color("e74c3c")   
	
	if meeting == "A" and printing == "A":
		final_feedback = "RESULT: OUTSTANDING DEFENSE (1.0)"
		jane_reaction = "Worth it lahat ng pagod… napasa ko!"
		if feedback_label: feedback_label.add_theme_color_override("font_color", color_green)
		
	elif printing == "C":
		final_feedback = "RESULT: STRUGGLED DEFENSE (1.50)"
		jane_reaction = "Nakaraos… pero sobrang hirap. Kailangan ko pang bumawi."
		if feedback_label: feedback_label.add_theme_color_override("font_color", color_red)
		
	else:
		final_feedback = "RESULT: PASSED DEFENSE (1.25)"
		jane_reaction = "Kinaya ko… pero ang dami ko pang pwedeng i-improve."
		if feedback_label: feedback_label.add_theme_color_override("font_color", color_green)

	if feedback_label:
		feedback_label.text = final_feedback

	# Show Stat Screen
	stat_screen.show()
	stat_screen.modulate.a = 0.0
	var t_stat = create_tween()
	t_stat.tween_property(stat_screen, "modulate:a", 1.0, 1.0)
	await t_stat.finished

	_play_result_dialogue(jane_reaction)

# STEP 3: REACTION & BUTTON 
func _play_result_dialogue(reaction_text: String) -> void:
	# Rule 1.0: Box FIRST
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		var t_in = create_tween()
		t_in.tween_property(box_visual, "modulate:a", 1.0, 1.0)
		await t_in.finished
		
	# Rule 1.0: Jane SECOND
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished

	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": reaction_text}])
	await active_dialogue_box.dialogue_finished
	
	# Rule 1.0: Fade out Jane and Box
	var t_fade_final = create_tween().set_parallel(true)
	if jane_thinking: t_fade_final.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
	if box_visual: t_fade_final.tween_property(box_visual, "modulate:a", 0.0, 1.0)
	await t_fade_final.finished
	
	if jane_thinking: jane_thinking.exit(true)
	active_dialogue_box.queue_free()
	
	
	var t_ui = create_tween().set_parallel(true)
	
	# Loop through all items inside StatScreen (Panel, Labels, etc.)
	for child in stat_screen.get_children():
		# If the item is NOT the Chapter 5 button, fade it to 0
		if child != chapter5_btn:
			t_ui.tween_property(child, "modulate:a", 0.0, 1.0)
			
	await t_ui.finished
	
	
	if chapter5_btn:
		chapter5_btn.show()
		chapter5_btn.modulate.a = 0.0
		var t_btn = create_tween()
		t_btn.tween_property(chapter5_btn, "modulate:a", 1.0, 1.0)
		
		if not chapter5_btn.pressed.is_connected(_on_chapter_5_btn_pressed):
			chapter5_btn.pressed.connect(_on_chapter_5_btn_pressed)


# --- SEQUENTIAL TITLE TRANSITION ---
func _on_chapter_5_btn_pressed() -> void:
	print("Proceeding to Chapter 5!")
	
	# 1. Fade to Black
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.modulate.a = 0.0
		title_label.show()
		
		# 2. Fade IN "CHAPTER 5" (1.0 duration)
		title_label.text = "CHAPTER 5"
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		
		# Wait while player reads it
		await get_tree().create_timer(2.0).timeout
		
		# 3. Fade OUT "CHAPTER 5" (1.0 duration)
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		
		# 4. Change text while invisible, then Fade IN "GRADUATION" (1.0 duration)
		title_label.text = "GRADUATION"
		var t3 = create_tween()
		t3.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t3.finished
		
		# Wait while player reads it
		await get_tree().create_timer(2.0).timeout
		
		# 5. Fade OUT "GRADUATION" (1.0 duration)
		var t4 = create_tween()
		t4.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t4.finished
		title_label.hide()
		
		# 6. Final Wait before Scene Change
		await get_tree().create_timer(1.0).timeout
	
	# 7. Change Scene
	get_tree().change_scene_to_file("res://Scenes/Chapter 5/chapter_5_scene_1.tscn")
