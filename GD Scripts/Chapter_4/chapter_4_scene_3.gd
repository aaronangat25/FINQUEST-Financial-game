extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var saving_screen = $SavingScreen
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var stat_screen = $StatsScreen

# Using find_child grabs if deep inside Panels
@onready var meeting_label = stat_screen.find_child("MeetingResultLabel", true, false)
@onready var printing_label = stat_screen.find_child("PrintingLabel", true, false)
@onready var feedback_label = stat_screen.find_child("FeedbackLabel", true, false)
@onready var grade_label = stat_screen.find_child("GradeLabel", true, false)
@onready var chapter5_btn = stat_screen.find_child("Chapter5_btn", true, false)
@onready var main_menu_btn = stat_screen.find_child("MainMenu_btn", true, false)

var currency_hud
var active_dialogue_box
var is_transitioning: bool = false

func _ready() -> void:
	# Keep background music loops moving smoothly into final score assessment cards
	AudioManager.play_chapter_music()

	# 🟢 FIXED: Instantiate directly to the scene tree to avoid thread lag
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if stat_screen: stat_screen.hide()
	if chapter5_btn: chapter5_btn.hide()
	if main_menu_btn: main_menu_btn.hide()
	
	await get_tree().process_frame
	
	# Force visual ledger totals sync on evaluation card load
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
	
	await get_tree().create_timer(2.0).timeout
	_play_intro_sequence()


# --- USER INTERACTION SECTION ---
func _play_intro_sequence() -> void:
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
	
	if jane_thinking:
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished
		jane_thinking.exit(true)
		
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
	active_dialogue_box.queue_free()
	_calculate_and_show_results()


# --- CALCULATIONS AREA ---
func _calculate_and_show_results() -> void:
	var meeting = Global.choice_meeting 
	var printing = Global.choice_printing 
	
	var final_feedback = ""
	var jane_reaction = ""
	
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
	
	var end_grade = 2.0
	
	# 🟢 TIER 1: Outstanding Defense (1.0) -> Choices: (A, A)
	if meeting == "A" and printing == "A":
		end_grade = 1.00
		final_feedback = "RESULT: OUTSTANDING DEFENSE (1.00)"
		jane_reaction = "Worth it lahat ng pagod… napasa ko!"
		if feedback_label: feedback_label.add_theme_color_override("font_color", color_green)
		
		# 🏅 ACHIEVEMENT INTEGRATION
		GameManager.unlock_achievement("MAGNA_CUM_BUDGET")
		
	# 🟢 TIER 2: Struggled Defense (3.0) -> Choices: (B, C)
	elif meeting == "B" and printing == "C":
		end_grade = 3.00
		final_feedback = "RESULT: STRUGGLED DEFENSE (3.00)"
		# Updated dialogue based on image_8b755f.png
		jane_reaction = "Nakaraos… pero sobrang hirap. Babawi nalang ako next time."
		if feedback_label: feedback_label.add_theme_color_override("font_color", color_red)
		
	# 🟢 TIER 3: Passed Defense (2.0) -> Covers: (A, B) // (B, A) // (A, C)
	else:
		end_grade = 2.00
		final_feedback = "RESULT: PASSED DEFENSE (2.00)"
		jane_reaction = "Kinaya ko… pero ang dami ko pang pwedeng i-improve."
		if feedback_label: feedback_label.add_theme_color_override("font_color", color_green)

	if feedback_label:
		feedback_label.text = final_feedback
		
	if grade_label:
		grade_label.text = str(end_grade)

	if feedback_label:
		feedback_label.text = final_feedback
		
	if grade_label:
		grade_label.text = str(end_grade)

	stat_screen.show()
	stat_screen.modulate.a = 0.0
	var t_stat = create_tween()
	t_stat.tween_property(stat_screen, "modulate:a", 1.0, 1.0)
	await t_stat.finished

	_play_result_dialogue(jane_reaction, end_grade)


# --- SCORING EVALUATION LAYOUT ---
func _play_result_dialogue(reaction_text: String, earned_grade: float) -> void:
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
	
	var t_fade_final = create_tween().set_parallel(true)
	if jane_thinking: t_fade_final.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
	if box_visual: t_fade_final.tween_property(box_visual, "modulate:a", 0.0, 1.0)
	await t_fade_final.finished
	
	if jane_thinking: jane_thinking.exit(true)
	active_dialogue_box.queue_free()
	
	var t_ui = create_tween().set_parallel(true)
	
	for child in stat_screen.get_children():
		if child != chapter5_btn and child != main_menu_btn:
			t_ui.tween_property(child, "modulate:a", 0.0, 1.0)
			
	await t_ui.finished
	
	var t_show_buttons = create_tween().set_parallel(true)
	
	if chapter5_btn:
		chapter5_btn.show()
		chapter5_btn.modulate.a = 0.0
		t_show_buttons.tween_property(chapter5_btn, "modulate:a", 1.0, 1.0)
		if not chapter5_btn.pressed.is_connected(_on_chapter_5_btn_pressed.bind(earned_grade)):
			chapter5_btn.pressed.connect(_on_chapter_5_btn_pressed.bind(earned_grade))
			
	if main_menu_btn:
		main_menu_btn.show()
		main_menu_btn.modulate.a = 0.0
		t_show_buttons.tween_property(main_menu_btn, "modulate:a", 1.0, 1.0)
		if not main_menu_btn.pressed.is_connected(_on_main_menu_pressed.bind(earned_grade)):
			main_menu_btn.pressed.connect(_on_main_menu_pressed.bind(earned_grade))


# --- CONTINUE BUTTON EVENT ---
func _on_chapter_5_btn_pressed(final_grade: float) -> void:
	if is_transitioning: return
	is_transitioning = true
	
	# 🟢 FIXED: Disable pause controls instantly before calculations begin
	_hide_pause_button_completely()
	
	if chapter5_btn: chapter5_btn.disabled = true
	if main_menu_btn: main_menu_btn.disabled = true
	
	if currency_hud: currency_hud.hide()
	if stat_screen: stat_screen.hide()
	
	GameManager.current_chapter = 5
	
	var next_scene_path = "res://Scenes/Chapter 5/chapter_5_scene_1.tscn"
	_execute_save_and_transition(next_scene_path, true, final_grade)


# --- MAIN MENU BUTTON EVENT ---
func _on_main_menu_pressed(final_grade: float) -> void:
	if is_transitioning: return
	is_transitioning = true
	
	# 🟢 FIXED: Disable pause controls instantly before calculations begin
	_hide_pause_button_completely()
	
	if chapter5_btn: chapter5_btn.disabled = true
	if main_menu_btn: main_menu_btn.disabled = true
	
	if currency_hud: currency_hud.hide()
	if stat_screen: stat_screen.hide()
	
	GameManager.current_chapter = 5
	
	var main_menu_path = "res://Scenes/Main Screen/main_screen.tscn"
	_execute_save_and_transition(main_menu_path, false, final_grade)


# --- REUSABLE SYSTEM TRANSACTION HANDLER ---
func _execute_save_and_transition(destination_path: String, run_chapter_card: bool, grade_scored: float) -> void:
	GameManager.flush_buffer_to_database()
	
	if saving_screen:
		saving_screen.process_mode = PROCESS_MODE_ALWAYS
		saving_screen.show()
		
	GameManager.complete_current_chapter(grade_scored)
	print("[DATABASE] Chapter 4 Progression committed smoothly.")
	
	await get_tree().create_timer(3.0).timeout
	
	var local_black_screen = ColorRect.new()
	local_black_screen.color = Color(0, 0, 0, 1)
	local_black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(local_black_screen)
	
	if saving_screen:
		saving_screen.hide()
		saving_screen.process_mode = PROCESS_MODE_DISABLED
		
	if run_chapter_card:
		if TransitionManager.has_method("fade_to_black"):
			await TransitionManager.fade_to_black()
			
		AudioManager.restart_general_music()
			
		var title_label = TransitionManager.get_node_or_null("TitleLabel")
		if title_label:
			title_label.modulate.a = 0.0
			title_label.show()
			
			title_label.text = "CHAPTER 5"
			var t1 = create_tween()
			t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
			await t1.finished
			
			await get_tree().create_timer(2.0).timeout
			
			var t2 = create_tween()
			t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
			await t2.finished
			
			title_label.text = "GRADUATION"
			var t3 = create_tween()
			t3.tween_property(title_label, "modulate:a", 1.0, 1.0)
			await t3.finished
			
			await get_tree().create_timer(2.0).timeout
			
			var t4 = create_tween()
			t4.tween_property(title_label, "modulate:a", 0.0, 1.0)
			await t4.finished
			title_label.hide()
			
			await get_tree().create_timer(1.0).timeout
			
		get_tree().change_scene_to_file(destination_path)
	else:
		get_tree().change_scene_to_file(destination_path)


# 🛡️ UNIFIED CLEAN PAUSE KILLER UTILITY
func _hide_pause_button_completely() -> void:
	if is_instance_valid(currency_hud):
		var hud_withdraw_btn = currency_hud.find_child("withdraw_btn", true, false)
		if hud_withdraw_btn:
			hud_withdraw_btn.hide()
			
	var active_pause = find_child("pause_btn", true, false)
	if active_pause:
		active_pause.hide()
		active_pause.process_mode = PROCESS_MODE_DISABLED
