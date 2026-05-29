extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const CASHIER_INDOOR_BG = preload("res://Assets/Backgrounds/Chapter 1/cashier/cashierbg.png")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn") 

# --- TUTORIAL ASSETS ---
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_TUTORIAL_SCENE = preload("res://Scenes/Phone/phone_cashier_tutorial.tscn") 

# --- CUSTOM SIGNAL ---
signal receipt_clicked 

# --- NODE REFERENCES ---
@onready var background = $cashiermarketbg 

# --- CHARACTER ANCHORS ---
@onready var kylie = $KylieDialogueAnchor/kylie2d
@onready var bea_dialogue = $BeaDialogueAnchor/bea2d
@onready var student_dialogue = $StudentDialogueAnchor/student2d
@onready var jane_big = $JaneBigAnchor/jane2dbig 

# --- UI CONTROLS ---
@onready var receipt_control = $ReceiptControl
@onready var choose_control_4 = $ChooseControl4
@onready var btn_30a = $"ChooseControl4/ChoicesContainer4/30A_btn"
@onready var btn_40b = $"ChooseControl4/ChoicesContainer4/40B_btn"
@onready var btn_50c = $"ChooseControl4/ChoicesContainer4/50C_btn"

var currency_hud
var active_dialogue_box

# --- OVERLAY VARIABLES ---
var active_gray_screen
var active_tutorial

# --- FIX: NEW VARIABLE FOR BULLETPROOF CLICKS ---
var is_waiting_for_receipt: bool = false

func _ready() -> void:
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	# Force characters to be invisible
	kylie.modulate.a = 0.0
	bea_dialogue.modulate.a = 0.0
	student_dialogue.modulate.a = 0.0
	if jane_big: jane_big.modulate.a = 0.0 
	
	# Hide UI overlays at the start
	receipt_control.modulate.a = 0.0
	receipt_control.hide()
	
	choose_control_4.modulate.a = 0.0
	choose_control_4.hide()
	
	# Connect the buttons (Only 50C gets the 120 reward!)
	# FIXED: Appended GameManager database log hooks to match structural selections
	btn_30a.pressed.connect(func(): 
		GameManager.log_choice("chap1_cashier_change", "A")
		_on_cashier_choice_made(0)
	)
	btn_40b.pressed.connect(func(): 
		GameManager.log_choice("chap1_cashier_change", "B")
		_on_cashier_choice_made(0)
	)
	btn_50c.pressed.connect(func(): 
		GameManager.log_choice("chap1_cashier_change", "C")
		_on_cashier_choice_made(120)
	)
	
	# Disable buttons initially
	_set_choice_buttons_disabled(true)
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.transition_finished
		
	_play_cashier_sequence()

func _play_cashier_sequence() -> void:
	await get_tree().create_timer(2.0).timeout
	await TransitionManager.fade_to_black()
	
	var new_style = StyleBoxTexture.new()
	new_style.texture = CASHIER_INDOOR_BG
	background.add_theme_stylebox_override("panel", new_style)
	
	await get_tree().create_timer(0.5).timeout
	await TransitionManager.fade_from_black()
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	
	active_dialogue_box.line_started.connect(_on_dialogue_line_started)
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
	
	kylie.appear("idle", false) 
	await get_tree().create_timer(0.6).timeout
	
	var cashier_conversation = [
		{"speaker": "Kylie", "text": "Hello! My friend here wants to work here. She’s a freshman."},
		{"speaker": "Bea", "text": "Gusto mo mag-cashier? Dapat mabiilis at marunong sa pera."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(cashier_conversation)
	
	await active_dialogue_box.dialogue_finished
	
	bea_dialogue.exit(false) 
	kylie.exit(false) 
	active_dialogue_box.queue_free()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_tutorial = PHONE_TUTORIAL_SCENE.instantiate()
	add_child(active_tutorial)
	
	var back_btn = active_tutorial.get_node("cashiertutorialcontrol/cashiertutorial/BackTextureButton/BackButton")
	if not back_btn:
		back_btn = active_tutorial.get_node("cashiertutorialcontrol/cashiertutorial/BackTextureButton/BackButton")
		
	if back_btn:
		back_btn.pressed.connect(_on_tutorial_back_pressed)


# --- TRIGGERED WHEN THE PLAYER CLICKS THE BACK BUTTON ---
func _on_tutorial_back_pressed() -> void:
	if active_gray_screen: active_gray_screen.queue_free()
	if active_tutorial: active_tutorial.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	
	active_dialogue_box.line_started.connect(_on_dialogue_line_started)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		var name_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel/NameLabel")
		if name_label: name_label.text = "Student" 
		
		box_visual.modulate.a = 0.0
		active_dialogue_box.show() 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	await get_tree().create_timer(0.2).timeout
	
	student_dialogue.appear("idle", false) 
	await get_tree().create_timer(0.6).timeout
	
	var final_conversation = [
		{"speaker": "Student", "text": "I’m ready to pay for these."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(final_conversation)
	
	await active_dialogue_box.dialogue_finished
	
	# Instantly hide student and dialogue box
	student_dialogue.exit(false) 
	active_dialogue_box.queue_free() 
	
	# --- PHASE 1: RECEIPT SEQUENCE (BULLETPROOF CLICKS) ---
	receipt_control.show()
	
	var tween_receipt_in = create_tween()
	tween_receipt_in.tween_property(receipt_control, "modulate:a", 1.0, 0.5)
	await tween_receipt_in.finished
	
	# Tell Godot we are now waiting for ANY screen click
	is_waiting_for_receipt = true 
	
	# Wait for the player to click anywhere
	await receipt_clicked 
	
	# Stop listening for clicks
	is_waiting_for_receipt = false 
	
	var tween_receipt_out = create_tween()
	tween_receipt_out.tween_property(receipt_control, "modulate:a", 0.0, 0.5)
	await tween_receipt_out.finished
	receipt_control.hide()
	
	# --- PHASE 2: CHOICES & JANE SEQUENCE ---
	choose_control_4.show()
	_set_choice_buttons_disabled(true) # Disable choice buttons during fade
	
	var tween_choice = create_tween()
	tween_choice.tween_property(choose_control_4, "modulate:a", 1.0, 0.5)
	
	if jane_big:
		jane_big.appear() # Jane fades in alongside the choices!
		
	await tween_choice.finished
	
	# Re-enable the choice buttons now that fading is done!
	_set_choice_buttons_disabled(false)


# --- FIX: GLOBAL CLICK DETECTION (BYPASSES ALL UI BLOCKING) ---
func _input(event: InputEvent) -> void:
	if is_waiting_for_receipt and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		receipt_clicked.emit()


# --- HELPER: TOGGLE BUTTON STATES ---
func _set_choice_buttons_disabled(is_disabled: bool) -> void:
	var filter = Control.MOUSE_FILTER_IGNORE if is_disabled else Control.MOUSE_FILTER_STOP
	
	btn_30a.mouse_filter = filter
	btn_40b.mouse_filter = filter
	btn_50c.mouse_filter = filter

# --- HANDLING THE CASHIER CHOICE ---
func _on_cashier_choice_made(reward: int) -> void:
	_set_choice_buttons_disabled(true) 
	
	if reward > 0:
		currency_hud.add_money(reward)
		
	# FIXED: Stage the sandbox pocket money increase directly inside your memory tracking buffers
	GameManager.stage_finance_change(0, reward, "Chapter 1 Cashier Part-Time Training Reward")
	
	# Fade out Choices and Jane together
	var tween_fade = create_tween()
	tween_fade.tween_property(choose_control_4, "modulate:a", 0.0, 0.5)
	
	if jane_big:
		var jane_tween = create_tween()
		jane_tween.tween_property(jane_big, "modulate:a", 0.0, 0.5)
		
	await tween_fade.finished
	choose_control_4.hide()
	
	await get_tree().create_timer(2.0).timeout
	
	_trigger_shift_end_transition()

func _trigger_shift_end_transition() -> void:
	await TransitionManager.fade_to_black()
	
	var title_label = TransitionManager.get_node("TitleLabel")
	if title_label:
		title_label.text = "SHIFT HAS\nENDED"
		title_label.modulate.a = 0.0
		title_label.show()
		
		var text_tween = create_tween()
		text_tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await text_tween.finished
		
		await get_tree().create_timer(2.0).timeout
		
		var text_out = create_tween()
		text_out.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await text_out.finished
		title_label.hide()
	
		get_tree().change_scene_to_file("res://Scenes/Chapter 1/chapter_1_end.tscn")

# --- INSTANT CHARACTER SWAP ---
func _on_dialogue_line_started(line_data: Dictionary) -> void:
	var speaker = line_data.get("speaker", "")
	
	if speaker == "Kylie":
		kylie.appear("idle", true) 
		bea_dialogue.exit(false)   
		if student_dialogue: student_dialogue.exit(false)
	elif speaker == "Bea":
		bea_dialogue.appear("idle", true)
		kylie.exit(false)
		if student_dialogue: student_dialogue.exit(false)
	elif speaker == "Student":
		student_dialogue.appear("idle", true)
		kylie.exit(false)
		bea_dialogue.exit(false)
