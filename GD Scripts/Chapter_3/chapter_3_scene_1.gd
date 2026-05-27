extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_LOCK_SCREEN_4_SCENE = preload("res://Scenes/Phone/phone_lock_screen_4.tscn") 

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var phone_mini = $PhoneMini 

var currency_hud
var active_dialogue_box 
var active_gray_screen
var active_lock_screen_4

# --- BULLETPROOF CLICK VARIABLES ---
var is_phone_clickable: bool = false

func _ready() -> void:
	# 1. Setup Currency HUD
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	# 2. Hide elements initially
	if phone_mini: phone_mini.hide() 
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jane_big: jane_big.modulate.a = 0.0
	
	# 3. Mobile Performance Breathing Timer
	await get_tree().create_timer(1.5).timeout
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_sequence()


# --- INTRO SEQUENCE ---
func _play_intro_sequence() -> void:
	await get_tree().create_timer(2.0).timeout
	
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
	
	var intro_convo = [
		{"speaker": "Jane", "text": "Grabe… parang ang bilis maubos ng allowance ko lately."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(intro_convo)
	
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


# --- PHONE APPEARS SEQUENCE ---
func _play_phone_sequence() -> void:
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
		phone_mini.show()
		
		# --- FIX: Removed the manual tweens! Since this is a fresh scene, 
		# the built-in appear() will play perfectly without blinking. ---
		if phone_mini.has_method("appear"):
			phone_mini.appear()
		
	await get_tree().create_timer(1.5).timeout
	
	if phone_mini and phone_mini.has_method("trigger_notification"):
		phone_mini.trigger_notification()
		
	is_phone_clickable = true


# --- PHONE CLICK DETECTION ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		if is_phone_clickable:
			if phone_mini and phone_mini.get_child_count() > 0:
				var phone_ui = phone_mini.get_child(0)
				if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
					_open_lock_screen_4()


# --- LOCK SCREEN 4 SEQUENCE ---
func _open_lock_screen_4() -> void:
	is_phone_clickable = false
	if phone_mini: phone_mini.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_lock_screen_4 = PHONE_LOCK_SCREEN_4_SCENE.instantiate()
	add_child(active_lock_screen_4)
	
	var padlock_btn = active_lock_screen_4.find_child("padlockbutton", true, false)
	var padlock_tex_btn = active_lock_screen_4.find_child("padlocktexturebutton", true, false)
	
	if padlock_btn and not padlock_btn.pressed.is_connected(_on_padlock_4_pressed):
		padlock_btn.pressed.connect(_on_padlock_4_pressed)
	if padlock_tex_btn and not padlock_tex_btn.pressed.is_connected(_on_padlock_4_pressed):
		padlock_tex_btn.pressed.connect(_on_padlock_4_pressed)

	if padlock_btn: padlock_btn.disabled = true
	if padlock_tex_btn: padlock_tex_btn.disabled = true
	
	await get_tree().create_timer(3.0).timeout
	
	if padlock_btn: padlock_btn.disabled = false
	if padlock_tex_btn: padlock_tex_btn.disabled = false


func _on_padlock_4_pressed() -> void:
	if active_lock_screen_4:
		var padlock_btn = active_lock_screen_4.find_child("padlockbutton", true, false)
		if padlock_btn: padlock_btn.disabled = true
		
	if active_lock_screen_4: active_lock_screen_4.queue_free()
	if active_gray_screen: active_gray_screen.queue_free()
	if jane_big: jane_big.hide()
	
	_play_post_phone_sequence()


# --- POST PHONE SEQUENCE & TRANSITION ---
func _play_post_phone_sequence() -> void:
	await get_tree().create_timer(2.0).timeout
	
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
	
	# --- FIX: Updated Dialogue exact spelling ---
	var inflation_convo = [
		{"speaker": "Jane", "text": "Inflation? Kaya pala parang mas mahal lahat ngayon…"},
		{"speaker": "Jane", "text": "Kailangan ko na talagang magiing mas maiingat sa gastos."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(inflation_convo)
	
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking:
		jane_thinking.exit(true)
		
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_box_out.finished 
		
	active_dialogue_box.queue_free()
	
	await get_tree().create_timer(2.0).timeout
	
	await TransitionManager.fade_to_black()
	
	await get_tree().create_timer(1.0).timeout
	
	var next_scene_path = "res://Scenes/Chapter 3/chapter_3_scene_2.tscn"
	
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		print("Loading Chapter 3 Scene 2...")
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		print("Successfully loaded! Switching scenes now.")
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
	else:
		print("CRITICAL ERROR: Scene failed to load completely. Check your file paths!")
