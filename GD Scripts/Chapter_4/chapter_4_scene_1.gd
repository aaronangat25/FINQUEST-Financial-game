extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const PHONE_LOCK_SCREEN_5_SCENE = preload("res://Scenes/Phone/phone_lock_screen_5.tscn")
const PHONE_SCREEN_4_SCENE = preload("res://Scenes/Phone Screen/phone_screen_4.tscn")
const PHONE_SCREEN_5_1_SCENE = preload("res://Scenes/Phone Screen/phone_screen_5_1.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var phone_mini = $PhoneMini
@onready var choose_control = $ChooseControl9
@onready var pause_btn = $pause_btn

var currency_hud
var active_dialogue_box

# Phone UI Trackers
var active_gray_screen 
var active_lock_screen
var active_phone_screen
var active_phone_screen_5_1

var is_phone_clickable: bool = false
var phone_state: int = 0

func _ready() -> void:
	# --- AUDIO INITIALIZATION ---
	# Ensures the main exploration track plays smoothly on chapter startup
	AudioManager.play_chapter_music()

	# --- MASTER DATABASE SYNCHRONIZATION ---
	GameManager.load_player_stats()
	Global.player_money = GameManager.on_hand_cash
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	
	# Force the HUD to render her actual carried pocket balance immediately
	await get_tree().process_frame
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	# 🛡️ THE STARTUP LOCKOUT FIX: Force hide both elements instantly before titles run
	if pause_btn:
		pause_btn.hide()
		pause_btn.process_mode = PROCESS_MODE_DISABLED
		
	if is_instance_valid(currency_hud):
		var hud_withdraw_btn = currency_hud.find_child("withdraw_btn", true, false)
		if hud_withdraw_btn:
			hud_withdraw_btn.hide()

	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jane_big: jane_big.hide()
	if phone_mini: phone_mini.hide()
	
	if choose_control:
		choose_control.hide()
		choose_control.modulate.a = 0.0
			
	await get_tree().process_frame
	
	# Block execution here while the black screens show "CHAPTER 4" -> "START OF THESIS SEMESTER"
	await _run_title_sequence()
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	# 🟢 RE-REVEAL HUD & CONTROLS: Title sequences finished, now safe to interact!
	if pause_btn:
		pause_btn.show()
		pause_btn.process_mode = PROCESS_MODE_INHERIT
		
	if is_instance_valid(currency_hud):
		var hud_withdraw_btn = currency_hud.find_child("withdraw_btn", true, false)
		if hud_withdraw_btn:
			hud_withdraw_btn.show()
		
	_play_intro_sequence()


# --- TWO-STEP TITLE ANIMATION ---
func _run_title_sequence() -> void:
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "CHAPTER 4"
		title_label.modulate.a = 0.0
		title_label.show()
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		
		title_label.text = "START OF\nTHESIS\nSEMESTER"
		title_label.modulate.a = 0.0
		var t3 = create_tween()
		t3.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t3.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t4 = create_tween()
		t4.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t4.finished
		title_label.hide()


# --- INTRO DIALOGUE SEQUENCE ---
func _play_intro_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	
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
		jane_thinking.modulate.a = 1.0
		if jane_thinking.has_method("appear"):
			jane_thinking.appear("idle", false)
	
	var intro_convo = [
		{"speaker": "Jane", "text": "Ito na… thesis na. Parang ito na yung pinakamahirap na part ng college."}
	]
	
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(intro_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: jane_thinking.exit(true)
	
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
	active_dialogue_box.queue_free()
	
	_play_phone_sequence()


# --- PHONE APPEARS SEQUENCE ---
func _play_phone_sequence() -> void:
	await get_tree().create_timer(0.5).timeout
	
	if jane_big:
		jane_big.modulate.a = 0.0
		jane_big.show()
		if jane_big.has_method("appear"):
			jane_big.appear()
			
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_big, "modulate:a", 1.0, 1.0)
			
	await get_tree().create_timer(1.0).timeout
	
	if phone_mini:
		phone_mini.show()
		if phone_mini.has_method("appear"):
			phone_mini.appear()
		
	await get_tree().create_timer(1.5).timeout
	
	if phone_mini and phone_mini.has_method("trigger_notification"):
		# Trigger your crisp incoming chat alert notification chime sound effect
		AudioManager.play_sfx("NOTIFICATION")
		phone_mini.trigger_notification()
		
	is_phone_clickable = true


# --- PHONE CLICK DETECTION ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_phone_clickable:
			if phone_mini and phone_mini.get_child_count() > 0:
				var phone_ui = phone_mini.get_child(0)
				if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
					
					if phone_state == 0:
						_open_lock_screen_5()
					elif phone_state == 1:
						_open_phone_screen_4()


# Phone Logic

func _open_lock_screen_5() -> void:
	is_phone_clickable = false
	if phone_mini: phone_mini.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_lock_screen = PHONE_LOCK_SCREEN_5_SCENE.instantiate()
	add_child(active_lock_screen)
	
	var padlock = active_lock_screen.find_child("padlockbutton", true, false)
	if padlock:
		if not padlock.pressed.is_connected(_on_padlock_pressed):
			padlock.pressed.connect(_on_padlock_pressed)

func _on_padlock_pressed() -> void:
	if active_lock_screen:
		active_lock_screen.queue_free()
		
	if active_gray_screen:
		active_gray_screen.queue_free()
		
	phone_mini.show()
	if phone_mini.has_method("trigger_notification"):
		# Trigger follow-up notification chime as home screen returns
		AudioManager.play_sfx("NOTIFICATION")
		phone_mini.trigger_notification()
		
	phone_state = 1
	is_phone_clickable = true

func _open_phone_screen_4() -> void:
	is_phone_clickable = false
	phone_mini.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_phone_screen = PHONE_SCREEN_4_SCENE.instantiate()
	add_child(active_phone_screen)
	
	var contacts_btn = active_phone_screen.find_child("contactsbutton", true, false)
	var contacts_tex_btn = active_phone_screen.find_child("ContactsTextureButton", true, false)
	
	if contacts_btn and not contacts_btn.pressed.is_connected(_on_contacts_pressed):
		contacts_btn.pressed.connect(_on_contacts_pressed)
	if contacts_tex_btn and not contacts_tex_btn.pressed.is_connected(_on_contacts_pressed):
		contacts_tex_btn.pressed.connect(_on_contacts_pressed)
		
	var sis_btn = active_phone_screen.find_child("SISbutton", true, false)
	var sis_tex_btn = active_phone_screen.find_child("SISbuttexturebutton", true, false)
	
	if sis_btn and not sis_btn.pressed.is_connected(_on_sis_pressed):
		sis_btn.pressed.connect(_on_sis_pressed)
	if sis_tex_btn and not sis_tex_btn.pressed.is_connected(_on_sis_pressed):
		sis_tex_btn.pressed.connect(_on_sis_pressed)


func _on_contacts_pressed() -> void:
	print("DEBUG: Contacts button clicked! Spawning chat screen...")
	
	if active_phone_screen:
		active_phone_screen.hide()
		
	active_phone_screen_5_1 = PHONE_SCREEN_5_1_SCENE.instantiate()
	add_child(active_phone_screen_5_1)
	
	active_phone_screen_5_1.visible = true
	if active_phone_screen_5_1.has_method("show"):
		active_phone_screen_5_1.show()
	
	# --- SAFE RAM CHOICE STAGING ---
	GameManager.log_choice("chap4_view_group_chat", "Viewed")
	
	var back_btn = active_phone_screen_5_1.find_child("BackButton", true, false)
	if not back_btn:
		back_btn = active_phone_screen_5_1.find_child("*Back*", true, false)
		
	if back_btn:
		print("DEBUG: Back button found inside phone 5_1.")
		if not back_btn.pressed.is_connected(_on_phone_5_1_back_pressed):
			back_btn.pressed.connect(_on_phone_5_1_back_pressed)
	else:
		print("ERROR: Back button NOT found in phone 5_1!")

func _on_sis_pressed() -> void:
	if not active_phone_screen: return
	
	var warning_panel = active_phone_screen.find_child("WarningPanel", true, false)
	var warning_label = active_phone_screen.find_child("WarningLabel", true, false)
	
	var contacts_btn = active_phone_screen.find_child("ContactsTextureButton", true, false)
	var sis_btn = active_phone_screen.find_child("SISbuttexturebutton", true, false)
		
	if warning_panel:
		if contacts_btn: contacts_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sis_btn: sis_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Trigger systemic login lockout error buzzer chime
		AudioManager.play_sfx("ERROR")
		
		warning_panel.show()
		warning_panel.visible = true
		warning_panel.modulate.a = 0.0
		if warning_label: 
			warning_label.show()
			warning_label.visible = true
			warning_label.modulate.a = 1.0
		
		var t_in = create_tween()
		t_in.tween_property(warning_panel, "modulate:a", 1.0, 0.5)
		await t_in.finished
		
		await get_tree().create_timer(1.5).timeout
		
		if is_instance_valid(warning_panel):
			var t_out = create_tween()
			t_out.tween_property(warning_panel, "modulate:a", 0.0, 0.5)
			await t_out.finished
			warning_panel.hide()
			
			if contacts_btn: contacts_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			if sis_btn: sis_btn.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_phone_5_1_back_pressed() -> void:
	if active_phone_screen_5_1:
		active_phone_screen_5_1.queue_free()
	if active_phone_screen:
		active_phone_screen.queue_free()
	if active_gray_screen:
		active_gray_screen.queue_free()
		
	_play_final_jane_dialogue()


# Final Dialogue and Choices

func _play_final_jane_dialogue() -> void:
	if jane_big and jane_big.visible:
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_big, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished
		jane_big.hide()

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
		if jane_thinking.has_method("appear"):
			jane_thinking.appear("idle", false)
			
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished
		
	var final_convo = [
		{"speaker": "Jane", "text": "Ang dami ko pang gastos… tapos kailangan din ng oras at effort."},
		{"speaker": "Jane", "text": "Paano ko pagsasabayin ‘to? Time, energy… at pera?"}
	]
	
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(final_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: 
		jane_thinking.exit(true)
		await get_tree().create_timer(1.0).timeout
		
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	
	if choose_control:
		choose_control.modulate.a = 0.0
		choose_control.show()
		var t_choice_in = create_tween()
		t_choice_in.tween_property(choose_control, "modulate:a", 1.0, 1.0)
		await t_choice_in.finished
		
		var btn_a = choose_control.find_child("face2faceA_btn", true, false)
		var btn_b = choose_control.find_child("olcmeetingB_btn", true, false)
		
		if btn_a:
			if not btn_a.pressed.is_connected(_on_choice_a_pressed): 
				btn_a.pressed.connect(_on_choice_a_pressed)
			
		if btn_b:
			if not btn_b.pressed.is_connected(_on_choice_b_pressed): 
				btn_b.pressed.connect(_on_choice_b_pressed)


# CHOICE BRANCHES
func _on_choice_a_pressed() -> void:
	Global.choice_meeting = "A"
	# Trigger your cash deduction wallet swipe sound effect for transit costs
	AudioManager.play_sfx("DEDUCT")
	
	# Hide pause controls instantly upon clicking choice card
	_hide_pause_button_completely()
	_handle_choice_reaction("A", "Medyo magastos… pero ang bilis namin naka-progress")

func _on_choice_b_pressed() -> void:
	Global.choice_meeting = "B"
	
	# Hide pause controls instantly upon clicking choice card
	_hide_pause_button_completely()
	_handle_choice_reaction("B", "Tipid nga… pero ang damiing interruptions.")

func _handle_choice_reaction(choice_id: String, choice_text: String) -> void:
	if choose_control:
		var t_choice_out = create_tween()
		t_choice_out.tween_property(choose_control, "modulate:a", 0.0, 1.0)
		await t_choice_out.finished
		choose_control.hide()
		
	# --- SAFE RAM STAGING REDIRECTION ---
	GameManager.log_choice("chap4_meeting_preference", choice_id)
	if choice_id == "A":
		GameManager.request_expense_payment(120, "Commuter travel fare for physical group thesis session")

	# Pull fresh metrics into the HUD display layer instantly
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()

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
	var reaction_convo = [{"speaker": "Jane", "text": choice_text}]
	active_dialogue_box.start_dialogue(reaction_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: 
		jane_thinking.exit(true)
		await get_tree().create_timer(1.0).timeout
		
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	
	await get_tree().create_timer(2.0).timeout
	
	# Force clean lockdown again before firing black title cards
	_hide_pause_button_completely()

	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "AT A\nPRINTING\nSHOP"
		title_label.modulate.a = 0.0
		title_label.show()
		
		var t_title_in = create_tween()
		t_title_in.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t_title_in.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t_title_out = create_tween()
		t_title_out.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t_title_out.finished
		title_label.hide()
		
	print("Chapter 4 Scene 1 Complete! Transitioning to Scene 2...")
	
	if is_instance_valid(currency_hud): currency_hud.hide()

	var next_scene_path = "res://Scenes/Chapter 4/chapter_4_scene_2.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)


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
