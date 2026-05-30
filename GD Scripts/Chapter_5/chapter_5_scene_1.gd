extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const PHONE_LOCK_SCREEN_5_SCENE = preload("res://Scenes/Phone/phone_lock_screen_6.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jane_talking = $JaneDialogueAnchor/jane2d
@onready var jane_big_anchor = $JaneBigAnchor
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var kylie = $JaneBigAnchor/KylieDialogueAnchor/kylie2d
@onready var phone_mini = $PhoneMini

var currency_hud
var active_dialogue_box

# Phone UI Trackers
var active_gray_screen 
var active_lock_screen

var is_phone_clickable: bool = false

func _ready() -> void:
	# --- AUDIO INITIALIZATION ---
	# Ensures the main ambient exploration track flows steadily into Chapter 5's opening
	AudioManager.play_chapter_music()

	# --- MASTER DATABASE SYNCHRONIZATION ---
	GameManager.load_player_stats()
	Global.player_money = GameManager.on_hand_cash
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	currency_hud.show()
	
	# Initial clean state layout resets
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jane_talking: jane_talking.modulate.a = 0.0
	if jane_big_anchor: jane_big_anchor.hide()
	if jane_big: jane_big.hide()
	if kylie: kylie.hide()
	if phone_mini: phone_mini.hide()
			
	await get_tree().process_frame
	
	# Force display layout sync immediately so HUD accurately parses previous chapter state
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_sequence()


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
		{"speaker": "Jane", "text": "Ang bilis ng panahon…"},
		{"speaker": "Jane", "text": "parang kailan lang, first day ko lang sa dorm."}
	]
	
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(intro_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: jane_thinking.exit(true)
	await get_tree().create_timer(0.5).timeout
	
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await t_box_out.finished
	active_dialogue_box.queue_free()
	
	_play_phone_sequence()


# --- PHONE APPEARS SEQUENCE ---
func _play_phone_sequence() -> void:
	await get_tree().create_timer(0.5).timeout
	
	if jane_big_anchor:
		jane_big_anchor.show()
		
	if jane_big:
		jane_big.modulate.a = 0.0
		jane_big.show()
		if jane_big.has_method("appear"):
			jane_big.appear()
			
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_big, "modulate:a", 1.0, 1.0)
			
	await get_tree().create_timer(0.5).timeout
	
	if phone_mini:
		if "layer" in phone_mini:
			phone_mini.layer = 5 
			
		phone_mini.show()
		if phone_mini.has_method("appear"):
			phone_mini.appear()
		
	await get_tree().create_timer(1.0).timeout
	
	if phone_mini and phone_mini.has_method("trigger_notification"):
		# Trigger your push notification one-shot sound alert
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
					_open_lock_screen_5()


# --- PHONE SYSTEM CONTROLS ---
func _open_lock_screen_5() -> void:
	is_phone_clickable = false
	if phone_mini: phone_mini.hide()
	
	if jane_big and jane_big.visible:
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_big, "modulate:a", 0.0, 0.4)
		await t_jane_out.finished
		jane_big.hide()
	
	if jane_big_anchor:
		jane_big_anchor.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_lock_screen = PHONE_LOCK_SCREEN_5_SCENE.instantiate()
	add_child(active_lock_screen)
	
	var close_btn = active_lock_screen.find_child("X_button", true, false)
	if not close_btn:
		close_btn = active_lock_screen.find_child("padlockbutton", true, false)
		
	if close_btn:
		if not close_btn.pressed.is_connected(_on_close_btn_pressed):
			close_btn.pressed.connect(_on_close_btn_pressed)


func _on_close_btn_pressed() -> void:
	if active_lock_screen:
		active_lock_screen.queue_free()
		
	if active_gray_screen:
		active_gray_screen.queue_free()
	
	_play_kylie_conversation()


# --- IN-ROOM KYLIE CONVERSATION SEQUENCE ---
func _play_kylie_conversation() -> void:
	if jane_big_anchor:
		jane_big_anchor.show()
	if jane_big:
		jane_big.hide()
		jane_big.modulate.a = 0.0

	# =====================================================================
	# --- PIECE 1: Kylie Speaks First ---
	# =====================================================================
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.show()
	
	if kylie:
		kylie.show()
		kylie.modulate.a = 0.0
		if kylie.has_method("appear"): kylie.appear("idle", false)
		await create_tween().tween_property(kylie, "modulate:a", 1.0, 0.4).finished

	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Kylie", "text": "Bestie!! Ready ka na ba magiing officially unemployed?"}])
	await active_dialogue_box.dialogue_finished

	if kylie:
		await create_tween().tween_property(kylie, "modulate:a", 0.0, 0.3).finished
		kylie.hide()
	active_dialogue_box.queue_free()
	await get_tree().process_frame

	# =====================================================================
	# --- PIECE 2: Jane Replies ---
	# =====================================================================
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.show()

	if jane_talking:
		jane_talking.show()
		jane_talking.modulate.a = 0.0
		if jane_talking.has_method("appear"): jane_talking.appear("idle", false)
		await create_tween().tween_property(jane_talking, "modulate:a", 1.0, 0.4).finished

	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "HAHA grabe ka. Pero honestly… kinakabahan ako."}])
	await active_dialogue_box.dialogue_finished

	if jane_talking:
		await create_tween().tween_property(jane_talking, "modulate:a", 0.0, 0.3).finished
		jane_talking.hide()
	active_dialogue_box.queue_free()
	await get_tree().process_frame

	# =====================================================================
	# --- PIECE 3: Kylie Responds ---
	# =====================================================================
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.show()

	if kylie:
		kylie.show()
		kylie.modulate.a = 0.0
		if kylie.has_method("appear"): kylie.appear("idle", false)
		await create_tween().tween_property(kylie, "modulate:a", 1.0, 0.4).finished

	active_dialogue_box.is_fading = true
	active_dialogue_box.start_dialogue([{"speaker": "Kylie", "text": "Normal lang ‘yan. After graduation, real life na talaga."}])
	
	if active_dialogue_box.has_signal("text_finished"):
		await active_dialogue_box.text_finished
	else:
		await get_tree().create_timer(1.5).timeout 
		
	var input_clicked: bool = false
	while not input_clicked:
		if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			input_clicked = true
		await get_tree().process_frame

	await get_tree().create_timer(1.0).timeout

	if kylie:
		var t_kylie_out = create_tween()
		t_kylie_out.tween_property(kylie, "modulate:a", 0.0, 0.4)
		await t_kylie_out.finished
		kylie.hide()

	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await t_box_out.finished
	
	if jane_big_anchor: jane_big_anchor.hide()
	active_dialogue_box.queue_free()

	_play_final_jane_dialogue()

# --- FINAL JANE DIALOGUE REFLECTION ---
func _play_final_jane_dialogue() -> void:
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
		{"speaker": "Jane", "text": "Hindi lang pala grades ang importante…"},
		{"speaker": "Jane", "text": "pati kung paano mo hinandle ang pera mo buong college life."}
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
	
	await get_tree().create_timer(1.5).timeout
	
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	var next_scene_path = "res://Scenes/Chapter 5/chapter_5_scene_2.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
