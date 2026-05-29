extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_LOCK_SCREEN_2 = preload("res://Scenes/Phone/phone_lock_screen_2.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES MATCHING YOUR SCENE TREE EXACTLY ---
@onready var saving_screen = $SavingScreen
@onready var jane_big = $JaneBigAnchor/jane2d
@onready var phone_mini = $PhoneMini 
@onready var kylie = $KylieDialogueAnchor/kylie2d 
@onready var jane_smile_notif = $Janesmilenotif 
@onready var jane_2d_big = $JaneBigAnchor2/jane2d

var currency_hud
var active_gray_screen
var active_lock_screen
var active_dialogue_box 

# BULLETPROOF CLICK VARIABLE
var is_phone_clickable: bool = false

func _ready() -> void:
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	if phone_mini:
		phone_mini.phone_clicked.connect(_open_phone_lock_screen)
	
	# Hide all necessary elements initially
	if jane_big: jane_big.modulate.a = 0.0
	if kylie: kylie.modulate.a = 0.0
	if jane_smile_notif: jane_smile_notif.modulate.a = 0.0
	if jane_2d_big: jane_2d_big.modulate.a = 0.0

	await TransitionManager.fade_from_black()
	_play_end_sequence()

func _play_end_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	
	if jane_big:
		jane_big.appear("idle")
		
	await get_tree().create_timer(1.0).timeout
	
	if phone_mini:
		phone_mini.appear()
		
	await get_tree().create_timer(1.5).timeout
	
	if phone_mini:
		phone_mini.trigger_notification()
		
	is_phone_clickable = true


# RESTRICTED CLICK DETECTION (CANVASLAYER SAFE)
func _input(event: InputEvent) -> void:
	if is_phone_clickable and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# Look inside the CanvasLayer to find the actual UI control
		if phone_mini and phone_mini.get_child_count() > 0:
			var phone_ui = phone_mini.get_child(0)
			
			if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
				_open_phone_lock_screen()


func _open_phone_lock_screen() -> void:
	if active_lock_screen != null: return
		
	is_phone_clickable = false
		
	if phone_mini: phone_mini.visible = false
		
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_lock_screen = PHONE_LOCK_SCREEN_2.instantiate()
	add_child(active_lock_screen)
	
	var padlock_btn = active_lock_screen.get_node_or_null("PhoneLockScreenControl/phonelockscreen/padlocktexturebutton/padlockbutton")
	
	if padlock_btn:
		padlock_btn.pressed.connect(_on_padlock_pressed)

func _on_padlock_pressed() -> void:
	if active_gray_screen: active_gray_screen.queue_free()
	if active_lock_screen: active_lock_screen.queue_free()
	if jane_big: jane_big.hide()
	
	await get_tree().create_timer(0.5).timeout
	
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
	
	if kylie:
		kylie.appear("idle", false) 
	await get_tree().create_timer(0.6).timeout
	
	var closing_conversation = [
		{"speaker": "Kylie", "text": "Good job today. See? Kaya mo naman pala mag-manage ng sarili mong pera."},
		{"speaker": "Kylie", "text": "Welcome to Manila life."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(closing_conversation)
	
	await active_dialogue_box.dialogue_finished
	
	if kylie:
		kylie.exit(true) 
		
	await get_tree().create_timer(0.6).timeout
		
	if box_visual:
		var tween_out = create_tween()
		tween_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_out.finished 
		
	active_dialogue_box.queue_free()
	
	# --- ENDING SEQUENCE TRANSITION ---
	
	if jane_smile_notif:
		jane_smile_notif.show()
		var tween_notif = create_tween()
		tween_notif.tween_property(jane_smile_notif, "modulate:a", 1.0, 0.5)
		
	if jane_2d_big:
		if jane_2d_big.has_method("appear"):
			jane_2d_big.appear("idle")
		else:
			var tween_big = create_tween()
			tween_big.tween_property(jane_2d_big, "modulate:a", 1.0, 0.5)
			
	await get_tree().create_timer(3.5).timeout
	
	# =================================================================
	# STEP 1: TRIGGER SAVING OVERLAY 
	# =================================================================
	if currency_hud:
		currency_hud.hide()
		
	print("[SYSTEM] Running database save sequence for Chapter 1.")
	
	# 1. Flush the choices and balances FIRST
	GameManager.flush_buffer_to_database()
	
	# 2. Wake up save overlay graphic
	saving_screen.process_mode = PROCESS_MODE_ALWAYS
	saving_screen.show()
	
	# 3. Mark Chapter 1 as complete, unlock Chapter 2 row, and advance tracker to 3
	GameManager.complete_current_chapter(100.0) 
	await get_tree().create_timer(2.0).timeout
	
	# =================================================================
	# STEP 2: GLOBAL BLACKOUT TRANSITION (MAINTAINED OVER SCENE LOADING)
	# =================================================================
	# We force the global visual manager overlay to drop down. This guarantees
	# that the screen stays black even when this scene is destroyed!
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	
	saving_screen.hide()
	saving_screen.process_mode = PROCESS_MODE_DISABLED
	
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "CHAPTER 2"
		title_label.modulate.a = 0.0
		title_label.show()
		
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		
		await get_tree().create_timer(2.0).timeout
		
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		
		title_label.text = "2 MONTHS\nAFTER"
		
		var t3 = create_tween()
		t3.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t3.finished
		
		await get_tree().create_timer(2.0).timeout
		
		var t4 = create_tween()
		t4.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t4.finished
		
		title_label.hide()
	
	# Transition seamlessly with the black curtain held high by global nodes
	get_tree().change_scene_to_file("res://Scenes/Chapter 2/chapter_2_scene_1.tscn")
