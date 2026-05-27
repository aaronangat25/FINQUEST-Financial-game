extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const CLERK_INDOOR_BG = preload("res://Assets/Backgrounds/Chapter 1/store clerk/clerkbg.png")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn") 

# --- TUTORIAL ASSETS ---
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_TUTORIAL_SCENE = preload("res://Scenes/Phone/phone_clerk_tutorial.tscn") 

# --- NODE REFERENCES ---
@onready var background = $clerkmarketbg 

# --- CHARACTER ANCHORS ---
@onready var jen_dialogue = $JenDialogueAnchor/jen2d
@onready var kylie = $KylieDialogueAnchor/kylie2d
@onready var student_dialogue = $StudentDialogueAnchor/student2d
@onready var jane_big = $JaneBigAnchor/jane2dbig

@onready var choose_control_3 = $ChooseControl3
@onready var aisle_btn = $ChooseControl3/ChoicesContainer3/Aisle1A_btn
@onready var storage_btn = $ChooseControl3/ChoicesContainer3/StorageB_btn
@onready var cashier_btn = $ChooseControl3/ChoicesContainer3/CashierC_btn

var currency_hud
var active_dialogue_box

# --- OVERLAY VARIABLES ---
var active_gray_screen
var active_tutorial

func _ready() -> void:
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	# Force characters to be invisible before the scene starts
	jen_dialogue.modulate.a = 0.0
	kylie.modulate.a = 0.0
	student_dialogue.modulate.a = 0.0
	jane_big.modulate.a = 0.0 # <-- HIDE JANE INITIALLY
	
	choose_control_3.modulate.a = 0.0
	choose_control_3.hide()
	
	aisle_btn.pressed.connect(func(): _on_store_choice_made(100))
	storage_btn.pressed.connect(func(): _on_store_choice_made(0))
	cashier_btn.pressed.connect(func(): _on_store_choice_made(0))
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.transition_finished
		
	_play_storeclerk_sequence()

func _play_storeclerk_sequence() -> void:
	await get_tree().create_timer(2.0).timeout
	await TransitionManager.fade_to_black()
	
	var new_style = StyleBoxTexture.new()
	new_style.texture = CLERK_INDOOR_BG
	background.add_theme_stylebox_override("panel", new_style)
	
	await get_tree().create_timer(0.5).timeout
	await TransitionManager.fade_from_black()
	
	# 1. DIALOGUE BOX FADES IN FIRST
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
	
	# 2. KYLIE FADES IN FIRST
	kylie.appear("idle", false) 
	await get_tree().create_timer(0.6).timeout
	
	# 3. START THE CONVERSATION
	var clerk_conversation = [
		{"speaker": "Kylie", "text": "Hello! My friend here wants to work here, she's a freshman."},
		{"speaker": "Jen", "text": "Madali lang dito. mostly restocking and assisting customers."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(clerk_conversation)
	await active_dialogue_box.dialogue_finished
	
	# 4. INSTANTLY REMOVE CHARACTERS BEFORE TUTORIAL
	jen_dialogue.exit(false) 
	kylie.exit(false) 
	active_dialogue_box.queue_free()
	
	# 5. SHOW THE TUTORIAL PHONE INSTANTLY
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_tutorial = PHONE_TUTORIAL_SCENE.instantiate()
	add_child(active_tutorial)
	
	var back_btn = active_tutorial.get_node("phoneclerktutorialcontrol/phoneclerktutorial/BackTextureButton/BackButton")
	if not back_btn:
		back_btn = active_tutorial.get_node("phoneclerktutorialcontrol/phoneclerktutorial/BackTextureButton")
		
	if back_btn:
		back_btn.pressed.connect(_on_tutorial_back_pressed)
	else:
		print("ERROR: Could not find BackButton in tutorial screen!")


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
		# Pre-fill name tag to prevent stretching bug
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
		{"speaker": "Student", "text": "Miss, saan po yung ballpen worth P15?"}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(final_conversation)
	
	await active_dialogue_box.dialogue_finished
	
	student_dialogue.exit(true) 
	await get_tree().create_timer(0.6).timeout 
	
	if box_visual:
		var tween_out = create_tween()
		tween_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_out.finished 
		
	active_dialogue_box.queue_free()
	
	# --- JANE AND CHOICES FADE IN TOGETHER ---
	choose_control_3.show()
	var tween_choice = create_tween()
	tween_choice.tween_property(choose_control_3, "modulate:a", 1.0, 0.5)
	jane_big.appear() # <- Jane fades in at the exact same time!

# --- HANDLING THE STORE CHOICE ---
func _on_store_choice_made(reward: int) -> void:
	if reward > 0:
		currency_hud.add_money(reward)
	
	# --- JANE AND CHOICES FADE OUT TOGETHER ---
	# We use a direct tween here because Big Jane doesn't have an exit() function!
	var jane_tween = create_tween()
	jane_tween.tween_property(jane_big, "modulate:a", 0.0, 0.5)
	
	var tween_fade = create_tween()
	tween_fade.tween_property(choose_control_3, "modulate:a", 0.0, 0.5)
	
	# Wait for both tweens to finish
	await tween_fade.finished
	choose_control_3.hide()
	
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
		jen_dialogue.exit(false)   
		if student_dialogue: student_dialogue.exit(false)
	elif speaker == "Jen":
		jen_dialogue.appear("idle", true)
		kylie.exit(false)
		if student_dialogue: student_dialogue.exit(false)
	elif speaker == "Student":
		student_dialogue.appear("idle", true)
		kylie.exit(false)
		jen_dialogue.exit(false)
