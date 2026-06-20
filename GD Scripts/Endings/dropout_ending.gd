extends Control

# --- PRELOADED SCENES ---
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_LOCK_SCREEN_7_SCENE = preload("res://Scenes/Phone/phone_lock_screen_7.tscn") # Adjust path to match your folder system

# --- NODE REFERENCES ---
@onready var phone_mini = $PhoneMini
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking

var active_dialogue_box
var active_gray_screen
var active_lock_screen

var is_phone_clickable: bool = false
var click_blocked_by_timer: bool = false

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
			
	AudioManager.play_bad_ending_music()
	# 1. Initialize everything to invisible so they don't blink on scene start
	if jane_big:
		jane_big.hide()
		jane_big.modulate.a = 0.0
		
	if jane_thinking:
		jane_thinking.hide()
		jane_thinking.modulate.a = 0.0
		
	if phone_mini:
		phone_mini.hide()
		if phone_mini.get_child_count() > 0:
			phone_mini.get_child(0).modulate.a = 0.0
		else:
			phone_mini.modulate.a = 0.0

	await get_tree().process_frame
	
	# 2. Run the "AFTER GRADUATION" Title Card Sequence
	await _run_title_sequence()
	
	if initial_black_screen:
		var fade_tween = create_tween()
		fade_tween.tween_property(initial_black_screen, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_tween.finished
		initial_black_screen.queue_free()
	
	# 3. Fade away the black curtain background layout smoothly
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	# 4. Count 2 seconds exactly after the black screen disappears
	await get_tree().create_timer(2.0).timeout
	
	# 5. Smoothly fade in Jane and the Phone mini layout interface
	_reveal_elements()


# --- TIMED TITLE CARD SEQUENCE ---
func _run_title_sequence() -> void:
	if TransitionManager.has_method("fade_to_black_instant"):
		TransitionManager.fade_to_black_instant()
		
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.modulate.a = 0.0
		title_label.show()
		await get_tree().create_timer(1.0).timeout
		
		title_label.text = "AT\nJANE'S\nDORM"
		
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		
		title_label.hide()
		await get_tree().create_timer(1.0).timeout


# --- FADE IN CHARACTERS & UI ---
func _reveal_elements() -> void:
	if jane_big:
		jane_big.show()
		if jane_big.has_method("appear"): 
			jane_big.appear()
		var t_jane = create_tween()
		t_jane.tween_property(jane_big, "modulate:a", 1.0, 1.0)
			
	await get_tree().create_timer(0.5).timeout
	
	if phone_mini:
		phone_mini.show()
		if phone_mini.has_method("appear"): 
			phone_mini.appear()
			
		var phone_target = phone_mini.get_child(0) if phone_mini.get_child_count() > 0 else phone_mini
		var t_phone = create_tween()
		t_phone.tween_property(phone_target, "modulate:a", 1.0, 1.0)
		await t_phone.finished
		
	await get_tree().create_timer(0.5).timeout
	if phone_mini and phone_mini.has_method("trigger_notification"):
		phone_mini.trigger_notification()
		
	is_phone_clickable = true


# --- PHONE CLICK DETECTION & OVERLAY GENERATOR ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if click_blocked_by_timer:
			get_viewport().set_input_as_handled() # Drop input completely
			return
			
		if is_phone_clickable and phone_mini and phone_mini.get_child_count() > 0:
			var phone_ui = phone_mini.get_child(0)
			if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
				_open_phone_lock_screen()


func _open_phone_lock_screen() -> void:
	is_phone_clickable = false
	click_blocked_by_timer = true # Lock all interactions
	
	if phone_mini: phone_mini.hide()
	
	# 1. Instantly display gray screen overlay
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	# 2. Instantly display phone lock screen 7 
	active_lock_screen = PHONE_LOCK_SCREEN_7_SCENE.instantiate()
	add_child(active_lock_screen)
	active_lock_screen.visible = true
	
	# Safely disable padlock buttons during the 5 second cooldown window
	var padlock_btn = active_lock_screen.find_child("padlockbutton", true, false)
	if padlock_btn: padlock_btn.disabled = true
	
	print("Lock screen opened! Input lock active for 5 seconds...")
	
	# 3. Count 5 seconds then restore input capabilities
	await get_tree().create_timer(5.0).timeout
	
	click_blocked_by_timer = false
	if padlock_btn:
		padlock_btn.disabled = false
		# Connect the padlock script to call our local sequence trigger when pressed
		padlock_btn.pressed.connect(_on_padlock_button_pressed)
		
	print("5 seconds complete. Padlock clicks enabled!")


# --- PADLOCK PROGRESSION SEQUENCE ---
func _on_padlock_button_pressed() -> void:
	print("Padlock clicked! Hiding layouts and initiating structured sequential transitions...")
	click_blocked_by_timer = true # Prevent multi-click glitches
	
	# 1. Hide phone layouts instantly
	if is_instance_valid(active_lock_screen): active_lock_screen.queue_free()
	if is_instance_valid(active_gray_screen): active_gray_screen.queue_free()
	if jane_big: jane_big.queue_free()
	if phone_mini: phone_mini.queue_free()
	
	# 2. Instantiate Dialogue Box first as hidden base asset
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	
	# =========================================================
	# === SEQUENTIAL STEP 1: DIALOGUE BOX FADES IN FIRST ===
	# =========================================================
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		var t_box_in = create_tween()
		t_box_in.tween_property(box_visual, "modulate:a", 1.0, 1.0)
		await t_box_in.finished # Wait for dialogue box to be fully visible
		
	# =========================================================
	# === SEQUENTIAL STEP 2: JANE THINKING FADES IN SECOND ===
	# =========================================================
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): 
			jane_thinking.appear("idle", false)
			
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished # Wait for Jane to be fully visible

	# 3. Present the line of text now that both elements are safely built on screen
	var line_1 = [{"speaker": "Jane", "text": "Malapit na sana…pero hindi ko kinaya."}]
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(line_1)
	await active_dialogue_box.dialogue_finished
	
	# =========================================================
	# === SEQUENTIAL STEP 3: JANE THINKING FADES OUT FIRST ===
	# =========================================================
	if jane_thinking:
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished # Wait for Jane to be fully gone from view
		jane_thinking.hide()
		
	# =========================================================
	# === SEQUENTIAL STEP 4: DIALOGUE BOX FADES OUT SECOND ===
	# =========================================================
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished # Wait for dialogue box to be completely gone
		
	active_dialogue_box.queue_free()
	
	# 4. Count 1.5 seconds narration gap break
	await get_tree().create_timer(1.5).timeout
	
	# 5. Fade in Dialogue box only (Nameless Narration Block)
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	if "is_fading" in active_dialogue_box: active_dialogue_box.is_fading = false
	add_child(active_dialogue_box)
	
	box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 1.0
		
	# Completely remove Name Labels
	var name_panel = active_dialogue_box.find_child("Panel", true, false)
	var name_label = active_dialogue_box.find_child("NameLabel", true, false)
	if name_panel: name_panel.hide(); name_panel.modulate.a = 0.0
	if name_label: name_label.hide(); name_label.text = ""
	
	var final_narration = [
		{"speaker": "", "text": "Poor planning and lack of financial preparation forced Jane to stop her studies."},
		{"speaker": "", "text": "Education needs both effort and financial planning."}
	]
	active_dialogue_box.start_dialogue(final_narration)
	await active_dialogue_box.dialogue_finished
	
	# Fade out narration box view
	if box_visual:
		var t_box_final = create_tween()
		t_box_final.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_final.finished
	active_dialogue_box.queue_free()
	
	# 6. Count 2 seconds exactly
	await get_tree().create_timer(2.0).timeout
	
	# 7. Fade into black overlay screen and shift cleanly to choices layout interface
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	Global.ending_type = "dropout"	
	get_tree().change_scene_to_file("res://Scenes/Game End/game_end_cholce.tscn")
