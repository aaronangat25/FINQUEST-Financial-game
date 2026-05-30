extends Control

# PRELOADED SCENES & ASSETS
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const CAFE_INDOOR_BG = preload("res://Assets/Backgrounds/Chapter 1/barista/cafeindoorbg.png")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn") 

# TUTORIAL & DORM ASSETS
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_TUTORIAL_SCENE = preload("res://Scenes/Phone/phone_barista_tutorial.tscn")

@onready var background = $cafebg

# CHARACTER ANCHORS
@onready var leo_table = $LeoTableAnchor/leo2d
@onready var leo_dialogue = $LeoDialogueAnchor/leo2d
@onready var kylie = $KylieDialogueAnchor/kylie2d

var currency_hud
var active_dialogue_box

# OVERLAY VARIABLES
var active_gray_screen
var active_tutorial

func _ready() -> void:
	# --- AUDIO INITIALIZATION ---
	# Seamlessly drops the general/menu music and changes to the coffee shop vibe
	AudioManager.play_coffee_shop_music()
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	leo_table.modulate.a = 0.0
	leo_dialogue.modulate.a = 0.0
	kylie.modulate.a = 0.0
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.transition_finished
		
	_play_barista_sequence()

func _play_barista_sequence() -> void:
	await get_tree().create_timer(2.0).timeout
	await TransitionManager.fade_to_black()
	
	var new_style = StyleBoxTexture.new()
	new_style.texture = CAFE_INDOOR_BG
	background.add_theme_stylebox_override("panel", new_style)
	
	leo_table.appear("idle", true)
	
	await get_tree().create_timer(0.5).timeout
	await TransitionManager.fade_from_black()
	
	await get_tree().create_timer(1.0).timeout
	leo_table.exit(true)
	await get_tree().create_timer(0.6).timeout
	
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
	
	kylie.appear()
	await get_tree().create_timer(0.6).timeout
	
	var cafe_conversation = [
		{"speaker": "Kylie", "text": "Hello! My friend here wants to work here, she's a freshman."},
		{"speaker": "Leo", "text": "Looking for a part-time job? Perfect timing."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(cafe_conversation)
	
	await active_dialogue_box.dialogue_finished
	
	leo_dialogue.exit(false)
	active_dialogue_box.queue_free()
	
	# --- OPEN PHONE INTERFACE TUTORIAL ---
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_tutorial = PHONE_TUTORIAL_SCENE.instantiate()
	add_child(active_tutorial)
	
	var back_btn = active_tutorial.get_node("phonebaristatutorialcontrol/phonebarsitatutorial/BackTextureButton/BackButton")
	if not back_btn:
		back_btn = active_tutorial.get_node("phonebaristatutorialcontrol/phonebarsitatutorial/BackTextureButton")
		
	if back_btn:
		back_btn.pressed.connect(_on_tutorial_back_pressed)
	else:
		print("ERROR: Could not find BackButton in tutorial screen!")


func _on_tutorial_back_pressed() -> void:
	if active_gray_screen: active_gray_screen.queue_free()
	if active_tutorial: active_tutorial.queue_free()
	
	await get_tree().create_timer(0.5).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	if box_visual:
		box_visual.modulate.a = 0.0
		active_dialogue_box.show() 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
		
	await get_tree().create_timer(0.2).timeout
	
	leo_dialogue.appear("idle", false) 
	await get_tree().create_timer(0.6).timeout
	
	var final_conversation = [
		{"speaker": "Leo", "text": "You learn fast. Come back if you want shifts."}
	]
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(final_conversation)
	await active_dialogue_box.dialogue_finished
	
	leo_dialogue.exit(true) 
	await get_tree().create_timer(0.6).timeout
	
	if box_visual:
		var tween_out = create_tween()
		tween_out.tween_property(box_visual, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
		await tween_out.finished
	active_dialogue_box.queue_free()
	
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
	
	# --- RESTORE GENERAL BACKGROUND EXPLORATION THEME ---
	AudioManager.play_chapter_music()
	
	get_tree().change_scene_to_file("res://Scenes/Chapter 1/chapter_1_end.tscn")

func _on_dialogue_line_started(line_data: Dictionary) -> void:
	var speaker = line_data.get("speaker", "")
	if speaker == "Kylie":
		kylie.appear("idle", true) 
		leo_dialogue.exit(false)   
	elif speaker == "Leo":
		leo_dialogue.appear("idle", true)
		kylie.exit(false)
