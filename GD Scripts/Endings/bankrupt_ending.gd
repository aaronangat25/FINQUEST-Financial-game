extends Control

# --- PRELOADED SCENES ---
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const PHONE_SCREEN_4_SCENE = preload("res://Scenes/Phone Screen/phone_screen_4.tscn")
const PHONE_SCREEN_6_1_SCENE = preload("res://Scenes/Phone Screen/phone_screen_6_1.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var phone_mini = $PhoneMini

var active_dialogue_box
var active_gray_screen
var active_phone_screen
var active_phone_screen_6_1

var is_phone_clickable: bool = false

var initial_black_screen: ColorRect

func _ready() -> void:
	Global.ending_type = "bankrupt"
	# --- FIXED: SPAWN AN INSTANT BLACK BLANKET ON FRAME ONE ---
	initial_black_screen = ColorRect.new()
	initial_black_screen.name = "InitialBlackScreen"
	initial_black_screen.color = Color(0, 0, 0, 1)
	initial_black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	initial_black_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(initial_black_screen)
	# --- THE PERFECT TRACK FIX ---
	# Immediately boots up your specialized somber loop track for the bad ending state!
	if AudioManager.has_method("play_bad_ending_music"):
		AudioManager.play_bad_ending_music()

	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jane_big: jane_big.hide(); jane_big.modulate.a = 0.0
	if phone_mini: 
		phone_mini.visible = false
		phone_mini.hide()
	
	await get_tree().process_frame
	await _run_title_sequence()
	
	if initial_black_screen:
		var fade_tween = create_tween()
		fade_tween.tween_property(initial_black_screen, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_tween.finished
		initial_black_screen.queue_free()
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	await get_tree().create_timer(2.0).timeout
	_play_intro_sequence()


# --- TIMED TITLE SEQUENCE ---
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


# --- DIALOGUE PROCESSING ---
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
	
	var conversation = [
		{"speaker": "Jane", "text": "Hindi ko namalayan… paubos na pala lahat."},
		{"speaker": "Jane", "text": "Bills, pagkain, pamasahe… lahat naging problema."}
	]
	
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(conversation)
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
	_reveal_phone_and_jane()


# --- REVEAL PHONE AND JANE ---
func _reveal_phone_and_jane() -> void:
	await get_tree().create_timer(0.5).timeout
	if jane_big:
		jane_big.modulate.a = 0.0
		jane_big.show()
		if jane_big.has_method("appear"): jane_big.appear()
		var t_jane_big = create_tween()
		t_jane_big.tween_property(jane_big, "modulate:a", 1.0, 1.0)
			
	await get_tree().create_timer(1.0).timeout
	
	if phone_mini:
		phone_mini.visible = true
		phone_mini.show()
		if phone_mini.has_method("appear"): phone_mini.appear()
			
		var inner_panel = phone_mini.get_child(0) as Control
		if inner_panel:
			inner_panel.modulate.a = 0.0
			var t_phone = create_tween()
			t_phone.tween_property(inner_panel, "modulate:a", 1.0, 1.5)
			await t_phone.finished
		else:
			await get_tree().create_timer(1.5).timeout
		
	await get_tree().create_timer(0.5).timeout
	if phone_mini and phone_mini.has_method("trigger_notification"):
		# Trigger the smartphone text pop alert sound cleanly
		AudioManager.play_sfx("NOTIFICATION")
		phone_mini.trigger_notification()
		
	is_phone_clickable = true


# --- PHONE CLICK ROUTING ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_phone_clickable and phone_mini and phone_mini.get_child_count() > 0:
			var phone_ui = phone_mini.get_child(0)
			if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
				_open_phone_screen_4()


func _open_phone_screen_4() -> void:
	is_phone_clickable = false
	if phone_mini: phone_mini.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	active_gray_screen.name = "GrayScreen"
	add_child(active_gray_screen)
	
	active_phone_screen = PHONE_SCREEN_4_SCENE.instantiate()
	add_child(active_phone_screen)
	
	# Connect Apps
	var contacts_btn = active_phone_screen.find_child("contactsbutton", true, false)
	var contacts_tex = active_phone_screen.find_child("ContactsTextureButton", true, false)
	var sis_btn = active_phone_screen.find_child("SISbutton", true, false)
	var sis_tex = active_phone_screen.find_child("SISbuttexturebutton", true, false)
	
	if contacts_btn: contacts_btn.pressed.connect(_on_contacts_pressed)
	if contacts_tex: contacts_tex.pressed.connect(_on_contacts_pressed)
	if sis_btn: sis_btn.pressed.connect(_on_sis_pressed)
	if sis_tex: sis_tex.pressed.connect(_on_sis_pressed)


# --- SIS WARNING POPUP ---
func _on_sis_pressed() -> void:
	if not active_phone_screen: return
	var warning_panel = active_phone_screen.find_child("WarningPanel", true, false)
	var warning_label = active_phone_screen.find_child("WarningLabel", true, false)
	
	var contacts_btn = active_phone_screen.find_child("contactsbutton", true, false)
	var contacts_tex = active_phone_screen.find_child("ContactsTextureButton", true, false)
	var sis_btn = active_phone_screen.find_child("SISbutton", true, false)
	var sis_tex = active_phone_screen.find_child("SISbuttexturebutton", true, false)
	
	if warning_panel:
		if contacts_btn: contacts_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if contacts_tex: contacts_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sis_btn: sis_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if sis_tex: sis_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Trigger your systematic login lockout error buzzer chime sound effect
		AudioManager.play_sfx("ERROR")
		
		warning_panel.show(); warning_panel.modulate.a = 0.0
		if warning_label: warning_label.show()
		
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
			if contacts_tex: contacts_tex.mouse_filter = Control.MOUSE_FILTER_STOP
			if sis_btn: sis_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			if sis_tex: sis_tex.mouse_filter = Control.MOUSE_FILTER_STOP


# --- CONTACTS ROUTING TO 6_1 ---
func _on_contacts_pressed() -> void:
	if active_phone_screen: active_phone_screen.queue_free()
	
	active_phone_screen_6_1 = PHONE_SCREEN_6_1_SCENE.instantiate()
	add_child(active_phone_screen_6_1)
	active_phone_screen_6_1.visible = true


# --- NEW: ABSOLUTE METHOD TO HIDE EVERYTHING INSTANTLY ---
func hide_elements_for_narration() -> void:
	print("Parent command executed: Hiding GrayScreen and JaneBigAnchor nodes.")
	
	# 1. Hide GrayScreen instantly
	if is_instance_valid(active_gray_screen):
		active_gray_screen.hide()
		active_gray_screen.visible = false
	var fallback_gray = find_child("*GrayScreen*", true, false)
	if fallback_gray:
		fallback_gray.hide()
		fallback_gray.visible = false
		
	# 2. Hide JaneBigAnchor node layout instantly
	var jane_anchor = get_node_or_null("JaneBigAnchor")
	if jane_anchor:
		jane_anchor.hide()
		jane_anchor.visible = false
