extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const PHONE_SCREEN_2_SCENE = preload("res://Scenes/Phone Screen/phone_screen_2.tscn") 
const PHONE_SCREEN_3_SCENE = preload("res://Scenes/Phone Screen/phone_screen_3.tscn") 
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_LOCK_SCREEN_3_SCENE = preload("res://Scenes/Phone/phone_lock_screen_3.tscn") 
const CLASSROOM_BG_TEXTURE = preload("res://Assets/Backgrounds/Chapter_2/classroom/classroom_bg.png") 

# --- NODE REFERENCES ---
@onready var saving_screen = $SavingScreen # Make sure to instantiate this in your scene tree!
@onready var background = $dormbg 
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var phone_mini = $PhoneMini 
@onready var feature_control = $FeatureCanvas/NewFeatureControl1 

@onready var jane_dialogue = $JaneDialogueAnchor/jane2d
@onready var kylie_dialogue = $KylieDialogueAnchor/kylie2d

@onready var choose_control_5 = $ChooseControl5
@onready var choose_response_5 = $ChooseControl5/ChooseResponse5 
@onready var study_cafe_btn = $ChooseControl5/ChoicesContainer5/studycafe_btn
@onready var study_lounge_btn = $ChooseControl5/ChoicesContainer5/studydormlounge_btn

@onready var choose_control_6 = $ChooseControl6
@onready var choose_response_6 = $ChooseControl6/ChooseResponse6 
@onready var ride_tricycle_btn = $ChooseControl6/ChoicesContainer6/ridetricylce_btn
@onready var walk_btn = $ChooseControl6/ChoicesContainer6/walk_btn
@onready var jane_big_2 = $JaneBigAnchor2/jane2dbig

@onready var exam_starts_control = $ExamStartsControl

var currency_hud
var active_dialogue_box 
var active_phone_screen_2
var active_phone_screen_3 
var active_gray_screen
var active_lock_screen_3
var active_money_ui
var active_padlock_btn 
var active_choice_shield 
var pause_button 

# --- TRACKING CHOICES FOR GRADES ---
var study_choice: String = ""
var travel_choice: String = ""

# --- BULLETPROOF CLICK VARIABLES ---
var is_phone_clickable: bool = false
var is_waiting_to_dismiss_phone: bool = false 
var is_phone_clickable_phase_2: bool = false
var is_waiting_to_dismiss_money: bool = false 
var is_phone_clickable_phase_3: bool = false 

func _ready() -> void:
	# --- AUDIO INITIALIZATION ---
	# Automatically ensures the general exploration music tracks loops smoothly on setup
	AudioManager.play_chapter_music()

	# 1. Pulls her exact hard-saved wallet values from SQLite rows
	GameManager.load_player_stats()
	
	# 2. Synchronize your Global tracking variable with the true database state
	Global.player_money = GameManager.on_hand_cash
	
	# 3. Instantiate the HUD 
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	# --- THE PAUSE BUTTON TRANSITION FIX ---
	pause_button = get_node_or_null("PauseButton")
	if not pause_button:
		pause_button = find_child("PauseButton", true, false)
		
	if pause_button:
		pause_button.hide() # Kill pause button visibility immediately on frame zero
	# ----------------------------------------
	
	if phone_mini: phone_mini.hide() 
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jane_big: jane_big.modulate.a = 0.0
	if feature_control: feature_control.modulate.a = 0.0
	
	if jane_dialogue: jane_dialogue.modulate.a = 0.0
	if kylie_dialogue: kylie_dialogue.modulate.a = 0.0
	
	if choose_control_5:
		choose_control_5.modulate.a = 0.0
		choose_control_5.hide()
		if choose_response_5: choose_response_5.hide() 
		
		if study_cafe_btn:
			study_cafe_btn.pressed.connect(_on_study_cafe_pressed)
		if study_lounge_btn:
			study_lounge_btn.pressed.connect(_on_study_lounge_pressed)
			
	if jane_big_2: jane_big_2.modulate.a = 0.0
	if choose_control_6:
		choose_control_6.modulate.a = 0.0
		choose_control_6.hide()
		if choose_response_6: choose_response_6.hide() 
		
		if ride_tricycle_btn:
			ride_tricycle_btn.pressed.connect(_on_ride_tricycle_pressed)
		if walk_btn:
			walk_btn.pressed.connect(_on_walk_pressed)
			
	if exam_starts_control:
		exam_starts_control.modulate.a = 0.0
		exam_starts_control.hide()
	
	# --- BULLETPROOF TRANSITION HOOK OVERRIDE ---
	if TransitionManager.color_rect:
		TransitionManager.color_rect.show()
		TransitionManager.color_rect.visible = true
		TransitionManager.color_rect.modulate.a = 1.0
	
	await get_tree().create_timer(0.5).timeout
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	if pause_button:
		pause_button.show()
	# ----------------------------------------------
		
	_play_intro_sequence()

func _play_intro_sequence() -> void:
	await get_tree().create_timer(1.5).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		var text_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/TextLabel")
		var name_panel = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel")
		if text_label: text_label.text = ""
		if name_panel: name_panel.hide()
		
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	await get_tree().create_timer(0.2).timeout
	
	if jane_thinking:
		jane_thinking.appear("idle", false)
			
	await get_tree().create_timer(0.6).timeout
	
	var thinking_convo = [
		{"speaker": "Jane", "text": "Midterms week na… dorm life really hits different."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(thinking_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking:
		jane_thinking.exit(true)
			
	await get_tree().create_timer(0.6).timeout
	
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_box_out.finished 
		
	active_dialogue_box.queue_free()
	_play_phone_sequence()

func _play_phone_sequence() -> void:
	await get_tree().create_timer(0.5).timeout
	
	if jane_big:
		if jane_big.has_method("appear"):
			if jane_big.get_method_argument_count("appear") == 0:
				jane_big.appear()
			else:
				jane_big.appear("idle", false)
			
	await get_tree().create_timer(1.0).timeout
	
	if phone_mini:
		phone_mini.show()
		phone_mini.appear()
		
	await get_tree().create_timer(1.5).timeout
	
	if phone_mini and phone_mini.has_method("trigger_notification"):
		# Trigger your incoming dialogue push notification alert sound effect ping
		AudioManager.play_sfx("NOTIFICATION")
		phone_mini.trigger_notification()
		
	is_phone_clickable = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		if is_phone_clickable:
			if phone_mini and phone_mini.get_child_count() > 0:
				var phone_ui = phone_mini.get_child(0)
				if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
					_open_phone_screen_2()
					
		elif is_waiting_to_dismiss_phone:
			_dismiss_phone_screen()
			
		elif is_phone_clickable_phase_2:
			if phone_mini and phone_mini.get_child_count() > 0:
				var phone_ui = phone_mini.get_child(0)
				if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
					_open_lock_screen_3()
					
		elif is_waiting_to_dismiss_money:
			_dismiss_money_ui()
			
		elif is_phone_clickable_phase_3:
			if phone_mini and phone_mini.get_child_count() > 0:
				var phone_ui = phone_mini.get_child(0)
				if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
					is_phone_clickable_phase_3 = false
					_open_phone_screen_3()

func _open_phone_screen_2() -> void:
	is_phone_clickable = false
	if phone_mini: phone_mini.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_phone_screen_2 = PHONE_SCREEN_2_SCENE.instantiate()
	add_child(active_phone_screen_2)
	
	var click_shield = ColorRect.new()
	click_shield.color = Color(0, 0, 0, 0)
	click_shield.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	active_phone_screen_2.add_child(click_shield)
	
	await get_tree().create_timer(1.0).timeout
	
	if feature_control:
		feature_control.show()
		var tween_feature_in = create_tween()
		tween_feature_in.tween_property(feature_control, "modulate:a", 1.0, 0.5)
		await tween_feature_in.finished
		
	await get_tree().create_timer(5.0).timeout
	
	if feature_control:
		var tween_feature_out = create_tween()
		tween_feature_out.tween_property(feature_control, "modulate:a", 0.0, 0.5)
		await tween_feature_out.finished
		feature_control.hide()
		
	is_waiting_to_dismiss_phone = true

func _dismiss_phone_screen() -> void:
	is_waiting_to_dismiss_phone = false
	
	if active_gray_screen: active_gray_screen.queue_free()
	if active_phone_screen_2: active_phone_screen_2.queue_free()
	if feature_control: feature_control.hide()
		
	if phone_mini:
		phone_mini.show()
		if phone_mini.has_method("appear"):
			phone_mini.appear() 
			
	await get_tree().create_timer(0.2).timeout
	is_phone_clickable_phase_2 = true

func _open_lock_screen_3() -> void:
	is_phone_clickable_phase_2 = false
	if phone_mini: phone_mini.hide()
		
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_lock_screen_3 = PHONE_LOCK_SCREEN_3_SCENE.instantiate()
	add_child(active_lock_screen_3)
	
	var padlock_btn = active_lock_screen_3.get_node_or_null("PhoneLockScreenControl/phonelockscreen/padlocktexturebutton/padlockbutton")
	
	if padlock_btn:
		padlock_btn.disabled = true
		active_padlock_btn = padlock_btn 
		padlock_btn.pressed.connect(_on_padlock_3_pressed)

	await get_tree().create_timer(3.0).timeout
	_show_money_ui() 

func _show_money_ui() -> void:
	var loaded_money_scene = load("res://Scenes/Money UI/money_ui.tscn")
	active_money_ui = loaded_money_scene.instantiate()
	add_child(active_money_ui)
	
	var base_allowance = 3000
	var job_salary = 0
	var job_display_name = "" 
	
	var chosen = Global.chapter_1_cafe_choice
	
	if chosen == "A": 
		job_salary = 2550
		job_display_name = "Cafe"
	elif chosen == "B": 
		job_salary = 1700
		job_display_name = "Clerk"
	elif chosen == "C": 
		job_salary = 2040
		job_display_name = "Cashier"
		
	# Trigger your confirmation deposit alert chime ("Withdraw or money increase")
	
		
	if active_money_ui.has_method("play_intro"):
		await active_money_ui.play_intro(job_display_name, job_salary)
	
	GameManager.stage_finance_change(0, base_allowance + job_salary, "Weekly Allowance & Part-Time Salary Payoff")
	
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
		
	await get_tree().create_timer(2.0).timeout
	is_waiting_to_dismiss_money = true

func _dismiss_money_ui() -> void:
	is_waiting_to_dismiss_money = false
	
	if active_money_ui and active_money_ui.has_method("play_outro"):
		await active_money_ui.play_outro()
		active_money_ui.queue_free()
		
	if active_padlock_btn:
		active_padlock_btn.disabled = false

func _on_padlock_3_pressed() -> void:
	if active_gray_screen: active_gray_screen.queue_free()
	if active_lock_screen_3: active_lock_screen_3.queue_free()
	if jane_big: jane_big.hide()
	
	_play_post_money_sequence()

func _play_post_money_sequence() -> void:
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		var text_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/TextLabel")
		var name_panel = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel")
		if text_label: text_label.text = ""
		if name_panel: name_panel.hide()
		
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	await get_tree().create_timer(0.2).timeout
	
	if jane_thinking:
		jane_thinking.appear("idle", false)
			
	await get_tree().create_timer(0.6).timeout
	
	var budget_convo = [
		{"speaker": "Jane", "text": "Kailangan ko talagang mag-budget ngayon."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(budget_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking:
		jane_thinking.exit(true)
		
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_box_out.finished 
		
	active_dialogue_box.queue_free()
	
	await get_tree().create_timer(1.0).timeout
	await TransitionManager.fade_to_black()
	await get_tree().create_timer(2.0).timeout
	await TransitionManager.fade_from_black()
	await get_tree().create_timer(1.0).timeout
	
	_play_kylie_conversation()

func _play_kylie_conversation() -> void:
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		var text_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/TextLabel")
		var name_panel = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel")
		if text_label: text_label.text = ""
		if name_panel: name_panel.hide()
		
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	await get_tree().create_timer(0.2).timeout
	
	if jane_dialogue:
		jane_dialogue.appear("idle", false)
	if kylie_dialogue:
		kylie_dialogue.appear("idle", false)
			
	await get_tree().create_timer(0.6).timeout
	
	var kylie_convo = [
		{"speaker": "Kylie", "text": "Uy, exam week mo rin ngayon? Hindi ako natulog kakareview."},
		{"speaker": "Jane", "text": "Same. Nag-iisip nga ako kung saan magre-review mamaya."},
		{"speaker": "Kylie", "text": "May study lounge sa baba, libre. Pero may café sa labas—may kape, pero magastos."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(kylie_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_dialogue:
		jane_dialogue.exit(true)
	if kylie_dialogue:
		kylie_dialogue.exit(true)
		
	await get_tree().create_timer(0.6).timeout
	
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_box_out.finished 
		
	active_dialogue_box.queue_free()
	_play_study_choice_sequence()

func _play_study_choice_sequence() -> void:
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		var text_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/TextLabel")
		var name_panel = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel")
		if text_label: text_label.text = ""
		if name_panel: name_panel.hide()
		
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	await get_tree().create_timer(0.2).timeout
	
	if jane_thinking:
		jane_thinking.appear("idle", false)
			
	await get_tree().create_timer(0.6).timeout
	
	var choice_convo = [
		{"speaker": "Jane", "text": "Comfort or savings?"}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(choice_convo)
	
	active_dialogue_box.propagate_call("set_process_input", [false])
	active_dialogue_box.propagate_call("set_process_unhandled_input", [false])
	
	if choose_control_5:
		if choose_response_5: choose_response_5.show()
		
		if study_cafe_btn: study_cafe_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		if study_lounge_btn: study_lounge_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		choose_control_5.move_to_front() 
		choose_control_5.show()
		var tween_choice = create_tween()
		tween_choice.tween_property(choose_control_5, "modulate:a", 1.0, 0.5)

func _on_study_cafe_pressed() -> void:
	_process_study_choice("Cafe")

func _on_study_lounge_pressed() -> void:
	_process_study_choice("Lounge")

func _process_study_choice(choice: String) -> void:
	if active_choice_shield:
		active_choice_shield.queue_free()
		
	if study_cafe_btn: study_cafe_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if study_lounge_btn: study_lounge_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if choice == "Cafe":
		study_choice = "A"
		# Trigger your cash deduction wallet sweep sound effect
		AudioManager.play_sfx("DEDUCT")
		GameManager.stage_finance_change(0, -150, "Purchased coffee at study cafe")
		GameManager.log_choice("chap2_study_location", "A")
	elif choice == "Lounge":
		study_choice = "B"
		GameManager.log_choice("chap2_study_location", "B")
	
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	if choose_control_5:
		var tween = create_tween()
		tween.tween_property(choose_control_5, "modulate:a", 0.0, 0.5)
		
	if jane_thinking:
		jane_thinking.exit(true)
		
	await get_tree().create_timer(0.6).timeout
	
	if active_dialogue_box:
		var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
		if box_visual:
			var tween_box_out = create_tween()
			tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
			await tween_box_out.finished 
		active_dialogue_box.queue_free()
	
	await get_tree().create_timer(1.0).timeout
	await TransitionManager.fade_to_black()
	await get_tree().create_timer(2.0).timeout
	await TransitionManager.fade_from_black()
	await get_tree().create_timer(1.0).timeout
	
	_play_morning_sequence()

func _play_morning_sequence() -> void:
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		var text_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/TextLabel")
		var name_panel = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel")
		if text_label: text_label.text = ""
		if name_panel: name_panel.hide()
		
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	await get_tree().create_timer(0.2).timeout
	
	if jane_thinking:
		jane_thinking.appear("idle", false)
			
	await get_tree().create_timer(0.6).timeout
	
	var morning_convo = [
		{"speaker": "Jane", "text": "Late na ako… I stayed up all night studying."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(morning_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking:
		jane_thinking.exit(true)
		
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_box_out.finished 
		
	active_dialogue_box.queue_free()
	_play_travel_choice_sequence()

func _play_travel_choice_sequence() -> void:
	if jane_big_2:
		jane_big_2.appear()
			
	await get_tree().create_timer(0.6).timeout
	
	if choose_control_6:
		if choose_response_6: choose_response_6.show()
		
		if ride_tricycle_btn: ride_tricycle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		if walk_btn: walk_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		choose_control_6.move_to_front() 
		choose_control_6.show()
		var tween_choice = create_tween()
		tween_choice.tween_property(choose_control_6, "modulate:a", 1.0, 0.5)

func _on_ride_tricycle_pressed() -> void:
	_process_travel_choice("Tricycle")

func _on_walk_pressed() -> void:
	_process_travel_choice("Walk")

func _process_travel_choice(choice: String) -> void:
	if ride_tricycle_btn: ride_tricycle_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if walk_btn: walk_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var is_tricycle = false
	if choice == "Tricycle":
		is_tricycle = true
		travel_choice = "A"
		AudioManager.play_sfx("DEDUCT")
		GameManager.stage_finance_change(0, -30, "Paid fare for tricycle ride to campus")
		GameManager.log_choice("chap2_travel_method", "A")
	elif choice == "Walk":
		travel_choice = "B"
		GameManager.log_choice("chap2_travel_method", "B")
			
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
			
	if choose_control_6:
		var tween = create_tween()
		tween.tween_property(choose_control_6, "modulate:a", 0.0, 0.5)
		
	if jane_big_2:
		var tween_jane = create_tween()
		tween_jane.tween_property(jane_big_2, "modulate:a", 0.0, 0.5)
		
	await get_tree().create_timer(0.6).timeout
	await get_tree().create_timer(1.0).timeout
	await TransitionManager.fade_to_black()
	
	# Cleanly play the loopable environment track channel if riding tricycle
	if is_tricycle:
		AudioManager.play_ambience("BUS", 0.5) # Reuses bus motor ambiance profile for travel text wrap
	
	await get_tree().create_timer(2.0).timeout
	
	# Smoothly fade out travel sounds before going inside the exam hall
	AudioManager.fade_out_ambience(1.0)
	
	if background:
		var new_stylebox = StyleBoxTexture.new()
		new_stylebox.texture = CLASSROOM_BG_TEXTURE
		background.add_theme_stylebox_override("panel", new_stylebox)
		
	await TransitionManager.fade_from_black()
	
	# Trigger your crisp high school bell sound effect on school arrival
	AudioManager.play_sfx("BELL", 2.0)
	
	if pause_button:
		pause_button.show()
	
	await get_tree().create_timer(1.0).timeout
	_play_exam_sequence()

func _play_exam_sequence() -> void:
	if exam_starts_control:
		exam_starts_control.show()
		var tween_exam_in = create_tween()
		tween_exam_in.tween_property(exam_starts_control, "modulate:a", 1.0, 0.5)
		await tween_exam_in.finished
		
	await get_tree().create_timer(3.0).timeout
	
	if pause_button: pause_button.hide()
	await TransitionManager.fade_to_black()
	await get_tree().create_timer(3.0).timeout
	
	if exam_starts_control:
		exam_starts_control.hide()
		
	await TransitionManager.fade_from_black()
	if pause_button: pause_button.show() 
	await get_tree().create_timer(1.0).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		var text_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/TextLabel")
		var name_panel = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel")
		if text_label: text_label.text = ""
		if name_panel: name_panel.hide()
		
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	await get_tree().create_timer(0.2).timeout
	
	if jane_dialogue:
		jane_dialogue.appear("idle", false)
			
	await get_tree().create_timer(0.6).timeout
	
	var post_exam_convo = [
		{"speaker": "Jane", "text": "Exams are finally over! Let's see our grades. I'm Nervous"}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(post_exam_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_dialogue:
		jane_dialogue.exit(true)
		
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_box_out.finished 
		
	active_dialogue_box.queue_free()
	await get_tree().create_timer(0.5).timeout
	
	if jane_big:
		jane_big.modulate.a = 0.0 
		jane_big.show() 
		
		if jane_big.has_method("appear"):
			if jane_big.get_method_argument_count("appear") == 0:
				jane_big.appear()
			else:
				jane_big.appear("idle", false)
				
		var tween_jane = create_tween()
		tween_jane.tween_property(jane_big, "modulate:a", 1.0, 0.5)
			
	await get_tree().create_timer(1.0).timeout
	
	if phone_mini:
		if phone_mini.get_child_count() > 0:
			phone_mini.get_child(0).modulate.a = 0.0
			
		phone_mini.show()
		if phone_mini.has_method("appear"):
			phone_mini.appear()
			
		if phone_mini.get_child_count() > 0:
			var tween_phone = create_tween()
			tween_phone.tween_property(phone_mini.get_child(0), "modulate:a", 1.0, 0.5)
		
	await get_tree().create_timer(1.5).timeout
	
	if phone_mini and phone_mini.has_method("trigger_notification"):
		# Trigger your smartphone grade alert push notification chime sound effect
		AudioManager.play_sfx("NOTIFICATION")
		phone_mini.trigger_notification()
		
	is_phone_clickable_phase_3 = true

func _open_phone_screen_3() -> void:
	if phone_mini: phone_mini.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_phone_screen_3 = PHONE_SCREEN_3_SCENE.instantiate()
	add_child(active_phone_screen_3)
	
	var sis_grade = active_phone_screen_3.find_child("SISgrade", true, false)
	var sis_text = active_phone_screen_3.find_child("SISgradetext", true, false)
	var back_tex_btn = active_phone_screen_3.find_child("BackTextureButton", true, false)
	var back_btn = active_phone_screen_3.find_child("BackButton", true, false)
	
	if back_tex_btn != null:
		if not back_tex_btn.pressed.is_connected(_on_phone_3_back_pressed):
			back_tex_btn.pressed.connect(_on_phone_3_back_pressed)
		back_tex_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if back_btn != null:
		if not back_btn.pressed.is_connected(_on_phone_3_back_pressed):
			back_btn.pressed.connect(_on_phone_3_back_pressed)
		back_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if sis_grade: sis_grade.hide()
	
	await get_tree().create_timer(3.0).timeout
	
	if sis_text:
		if study_choice == "A" and travel_choice == "A":
			sis_text.text = "1.0"
		elif study_choice == "B" and travel_choice == "B":
			sis_text.text = "1.50"
		else:
			sis_text.text = "1.25"
			
	if sis_grade: sis_grade.show()
	await get_tree().create_timer(3.0).timeout
	
	if back_tex_btn: back_tex_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	if back_btn: back_btn.mouse_filter = Control.MOUSE_FILTER_STOP

# =================================================================
# MASTER HANDOFF FIX FOR CHAPTER 2 END (STRICT PERSISTENCE)
# =================================================================
func _on_phone_3_back_pressed() -> void:
	print("YES! The _on_phone_3_back_pressed signal fired perfectly!")
	
	if pause_button: 
		pause_button.hide()
		pause_button.process_mode = PROCESS_MODE_DISABLED
	
	if active_phone_screen_3:
		var back_tex_btn = active_phone_screen_3.find_child("BackTextureButton", true, false)
		var back_btn = active_phone_screen_3.find_child("BackButton", true, false)
		if back_tex_btn: back_tex_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if back_btn: back_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if active_phone_screen_3: active_phone_screen_3.queue_free()
	if active_gray_screen: active_gray_screen.queue_free()
	if jane_big: jane_big.hide()
	
	await get_tree().create_timer(1.0).timeout
	
	if currency_hud:
		currency_hud.hide()
		
	GameManager.current_chapter = 3
	print("[SYSTEM] Running database save sequence for Chapter 2.")
	
	var end_grade = 1.25
	if study_choice == "A" and travel_choice == "A":
		end_grade = 1.0
	elif study_choice == "B" and travel_choice == "B":
		end_grade = 1.50
	
	GameManager.flush_buffer_to_database()
	
	saving_screen.process_mode = PROCESS_MODE_ALWAYS
	saving_screen.show()
	
	GameManager.complete_current_chapter(end_grade)
	
	var local_black_screen = ColorRect.new()
	local_black_screen.color = Color(0, 0, 0, 1) 
	local_black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	local_black_screen.z_index = 200 
	add_child(local_black_screen)
	
	await get_tree().create_timer(2.0).timeout
	
	saving_screen.hide()
	saving_screen.process_mode = PROCESS_MODE_DISABLED
	
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "CHAPTER 3"
		title_label.modulate.a = 0.0
		title_label.show()
		
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		
		await get_tree().create_timer(2.0).timeout
		
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		title_label.hide()
	
	# --- EXPLICIT MUSIC RESET FOR TRANSITION ---
	# Forces GENERAL MUSIC.mp3 to fade down and restart from 0.0 for Chapter 3
	AudioManager.restart_general_music()
		
	var next_scene_path = "res://Scenes/Chapter 3/chapter_3_scene_1.tscn"
	
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		print("Loading Chapter 3 Scene 1...")
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		print("Successfully loaded! Switching scenes now.")
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
	else:
		print("CRITICAL ERROR: Scene failed to load completely. Check your file paths!")
