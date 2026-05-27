extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")

const PHONE_SCREEN_4_SCENE = preload("res://Scenes/Phone Screen/phone_screen_4.tscn") 
const PHONE_SCREEN_4_1_SCENE = preload("res://Scenes/Phone Screen/phone_screen_4_1.tscn") 

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var phone_mini = $PhoneMini 

var currency_hud
var active_dialogue_box 
var active_gray_screen
var active_phone_screen_4
var active_phone_screen_4_1
var warning_label # To hold the "there is a msg" text

var is_phone_clickable: bool = false
var is_app_interacting: bool = false

func _ready() -> void:
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	# 2. Hide elements initially
	if phone_mini: phone_mini.hide() 
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jane_big: jane_big.modulate.a = 0.0
	
	# 3. Mobile Performance Breathing Timer
	await get_tree().create_timer(0.5).timeout
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_sequence()


# --- INTRO SEQUENCE ---
func _play_intro_sequence() -> void:
	await get_tree().create_timer(2.0).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6)
		await tween_in.finished
		
	if jane_thinking: jane_thinking.appear("idle", false)
	await get_tree().create_timer(0.6).timeout
	
	var intro_convo = [
		{"speaker": "Jane", "text": "Kung ganito kamahal lahat, baka kulangin allowance ko."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(intro_convo)
	await active_dialogue_box.dialogue_finished
	
	# --- EXIT SEQUENCE ---
	if jane_thinking: jane_thinking.exit(true)
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
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
					_open_phone_screen_4()


# --- PHONE SCREEN 4 SEQUENCE ---
func _open_phone_screen_4() -> void:
	is_phone_clickable = false
	if phone_mini: phone_mini.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_phone_screen_4 = PHONE_SCREEN_4_SCENE.instantiate()
	add_child(active_phone_screen_4)
	
	# Connect the app buttons using find_child
	var contacts_btn = active_phone_screen_4.find_child("contactsbutton", true, false)
	var contacts_tex_btn = active_phone_screen_4.find_child("ContactsTextureButton", true, false)
	var sis_btn = active_phone_screen_4.find_child("SISbutton", true, false)
	var sis_tex_btn = active_phone_screen_4.find_child("SISbuttexturebutton", true, false)
	
	if contacts_btn and not contacts_btn.pressed.is_connected(_on_contacts_pressed):
		contacts_btn.pressed.connect(_on_contacts_pressed)
	if contacts_tex_btn and not contacts_tex_btn.pressed.is_connected(_on_contacts_pressed):
		contacts_tex_btn.pressed.connect(_on_contacts_pressed)
		
	if sis_btn and not sis_btn.pressed.is_connected(_on_sis_pressed):
		sis_btn.pressed.connect(_on_sis_pressed)
	if sis_tex_btn and not sis_tex_btn.pressed.is_connected(_on_sis_pressed):
		sis_tex_btn.pressed.connect(_on_sis_pressed)


# --- APP BUTTON FUNCTIONS ---
func _on_contacts_pressed() -> void:
	if is_app_interacting: 
		return
		
	is_app_interacting = true
	
	if active_phone_screen_4: 
		active_phone_screen_4.queue_free()
		
	active_phone_screen_4_1 = PHONE_SCREEN_4_1_SCENE.instantiate()
	add_child(active_phone_screen_4_1)
	
	# --- FIX: Target the node that actually holds the script and signal! ---
	var phone_control_node = active_phone_screen_4_1.get_node_or_null("PhoneScreenControl")
	
	if phone_control_node:
		phone_control_node.chat_closed.connect(_on_chat_finished)
	else:
		print("ERROR: Could not find PhoneScreenControl to connect the signal!")


func _on_sis_pressed() -> void:
	if is_app_interacting: 
		return
		
	is_app_interacting = true
	
	if active_phone_screen_4:
		var warning_panel = active_phone_screen_4.find_child("WarningPanel", true, false)
		
		# Grab the buttons to disable their hover effects
		var contacts_btn = active_phone_screen_4.find_child("contactsbutton", true, false)
		var contacts_tex_btn = active_phone_screen_4.find_child("ContactsTextureButton", true, false)
		var sis_btn = active_phone_screen_4.find_child("SISbutton", true, false)
		var sis_tex_btn = active_phone_screen_4.find_child("SISbuttexturebutton", true, false)
		
		if warning_panel and not warning_panel.visible:
			warning_panel.show()
			
			# --- DISABLE ALL MOUSE INTERACTION (Kills the hover effect) ---
			if contacts_btn: contacts_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if contacts_tex_btn: contacts_tex_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if sis_btn: sis_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if sis_tex_btn: sis_tex_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Wait 3 seconds
			await get_tree().create_timer(3.0).timeout
			
			# Hide the panel
			if is_instance_valid(warning_panel):
				warning_panel.hide()
				
			# --- RESTORE MOUSE INTERACTION (Brings back hover and clicks) ---
			if is_instance_valid(active_phone_screen_4): # Just to be safe!
				if contacts_btn: contacts_btn.mouse_filter = Control.MOUSE_FILTER_STOP
				if contacts_tex_btn: contacts_tex_btn.mouse_filter = Control.MOUSE_FILTER_STOP
				if sis_btn: sis_btn.mouse_filter = Control.MOUSE_FILTER_STOP
				if sis_tex_btn: sis_tex_btn.mouse_filter = Control.MOUSE_FILTER_STOP
				
	is_app_interacting = false


# --- CLOSING SEQUENCE ---
func _on_chat_finished() -> void:
	# 1. Instantly destroy phone, gray background, and hide Big Jane
	if active_phone_screen_4_1: active_phone_screen_4_1.queue_free()
	if active_gray_screen: active_gray_screen.queue_free()
	
	# --- FIX: INSTANT HIDE (No tween, same millisecond as the phone) ---
	if jane_big:
		jane_big.hide()
		jane_big.modulate.a = 0.0
	
	# Give mobile a small 0.5s pause to breathe before the dialogue box pops up
	await get_tree().create_timer(0.5).timeout
	
	# 2. Spawn Dialogue Box
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6)
		await tween_in.finished
		
	# Fade in thinking Jane
	if jane_thinking: 
		jane_thinking.show()
		if jane_thinking.has_method("appear"):
			jane_thinking.appear("idle", false)
	await get_tree().create_timer(0.6).timeout
	
	# 3. Final Dialogue
	var final_convo = [
		{"speaker": "Jane", "text": "Tama si Mom… kailangan magiing practical."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(final_convo)
	await active_dialogue_box.dialogue_finished
	
	# 4. Exit Animations
	if jane_thinking: jane_thinking.exit(true)
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await tween_box_out.finished 
	active_dialogue_box.queue_free()
	
	# 5. Wait 2 seconds, fade to black
	await get_tree().create_timer(2.0).timeout
	await TransitionManager.fade_to_black()
	
	print("Chapter 3 Scene 4 complete! Ready for Scene 5.")
	
	# Transition to Scene 5
	var next_scene_path = "res://Scenes/Chapter 3/chapter_3_scene_5.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
