extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jane_dialogue = $JaneDialogueAnchor/jane2d
@onready var kylie_dialogue = $KylieDialogueAnchor/kylie2d

@onready var choose_control_7 = $ChooseControl7
@onready var choose_response_7 = $ChooseControl7/ChooseResponse7 
@onready var choices_container_7 = $ChooseControl7/ChoicesContainer7
@onready var fullmeal_btn = $ChooseControl7/ChoicesContainer7/fullmealA_btn
@onready var budgetmeal_btn = $ChooseControl7/ChoicesContainer7/budgetmealB_btn
@onready var skipmeal_btn = $ChooseControl7/ChoicesContainer7/skipmealC_btn
@onready var jane_big_2 = $JaneBigAnchor2/jane2dbig

var currency_hud
var active_dialogue_box 

func _ready() -> void:
	# 1. Setup Currency HUD
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	# 2. Initialization
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jane_dialogue: jane_dialogue.modulate.a = 0.0
	if kylie_dialogue: kylie_dialogue.modulate.a = 0.0
	if jane_big_2: jane_big_2.modulate.a = 0.0
	
	if choose_control_7:
		choose_control_7.modulate.a = 0.0
		choose_control_7.hide()
		# Connect Buttons
		if fullmeal_btn: fullmeal_btn.pressed.connect(_on_meal_choice_pressed.bind("A"))
		if budgetmeal_btn: budgetmeal_btn.pressed.connect(_on_meal_choice_pressed.bind("B"))
		if skipmeal_btn: skipmeal_btn.pressed.connect(_on_meal_choice_pressed.bind("C"))
	
	# 3. Fade from black
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_canteen_sequence()

func _play_canteen_sequence() -> void:
	await get_tree().create_timer(2.0).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.line_started.connect(_on_dialogue_line_started)
	active_dialogue_box.is_fading = true 
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6)
		await tween_in.finished
		
	if jane_dialogue: jane_dialogue.appear("idle", false)
	if kylie_dialogue: kylie_dialogue.appear("idle", false)
	await get_tree().create_timer(0.6).timeout
	
	# --- FIX: Changed the speaker name back to "Jane" ---
	var canteen_convo = [
		{"speaker": "Kylie", "text": "Jane, napansin mo ba? Dati P50 lang ‘tong lunch ko, ngayon P70 na."},
		{"speaker": "Jane", "text": "Oo nga eh. Kahit pamasahe tumaas din."},
		{"speaker": "Kylie", "text": "That’s inflation daw sabi ng news."},
		{"speaker": "Jane", "text": "Inflation… meaning tumataas presyo ng mga bilihin?"},
		{"speaker": "Kylie", "text": "Yep. Kaya kailangan marunong tayong mag-adjust ng budget."},
		{"speaker": "Jane", "text": "Mukhang kailangan kong magtipiid ngayon."} 
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(canteen_convo)
	await active_dialogue_box.dialogue_finished
	
	# Exit animations
	if jane_thinking: jane_thinking.exit(true)
	if kylie_dialogue: kylie_dialogue.exit(true)
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await tween_box_out.finished 
	active_dialogue_box.queue_free()
	
	_play_choice_sequence()

# --- FIX: Use the 'in' keyword to bypass any hidden spaces! ---
func _on_dialogue_line_started(line_data: Dictionary) -> void:
	var text = line_data.get("text", "")
	
	# This checks if this specific phrase is ANYWHERE inside the text
	if "Mukhang kailangan kong magtipiid" in text:
		if jane_dialogue: 
			jane_dialogue.hide()
			jane_dialogue.modulate.a = 0.0
			
		if jane_thinking:
			jane_thinking.show()
			jane_thinking.modulate.a = 1.0
			if jane_thinking.has_method("appear"): 
				jane_thinking.appear("idle", true)

func _play_choice_sequence() -> void:
	if jane_big_2:
		jane_big_2.show()
		var tween_j = create_tween()
		tween_j.tween_property(jane_big_2, "modulate:a", 1.0, 0.5)
			
	await get_tree().create_timer(0.6).timeout
	
	if choose_control_7:
		choose_control_7.show()
		# Ensure both container and response (panel) are visible
		if choose_response_7: choose_response_7.show()
		if choices_container_7: choices_container_7.show()
		
		var tween_choice = create_tween()
		tween_choice.tween_property(choose_control_7, "modulate:a", 1.0, 0.5)

func _on_meal_choice_pressed(choice: String) -> void:
	# Disable buttons
	fullmeal_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	budgetmeal_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skipmeal_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# --- APPLY MONEY DEDUCTION (Inflation Prices) ---
	if currency_hud and currency_hud.has_method("add_money"):
		if choice == "A": currency_hud.add_money(-90) # Full Meal
		elif choice == "B": currency_hud.add_money(-50) # Budget Meal
	
	# Fade out
	var tween_out = create_tween().set_parallel(true)
	tween_out.tween_property(choose_control_7, "modulate:a", 0.0, 0.5)
	tween_out.tween_property(jane_big_2, "modulate:a", 0.0, 0.5)
	await tween_out.finished
	
	_transition_to_scene_3()

func _transition_to_scene_3() -> void:
	await TransitionManager.fade_to_black()
	
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "AFTER\nCLASS"
		title_label.modulate.a = 0.0
		title_label.show()
		var t1 = create_tween()
		t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t1.finished
		await get_tree().create_timer(2.0).timeout
		var t2 = create_tween()
		t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t2.finished
		title_label.hide()
		
	await get_tree().create_timer(0.5).timeout
	
	var next_scene_path = "res://Scenes/Chapter 3/chapter_3_scene_3.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
