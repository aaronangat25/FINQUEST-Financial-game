extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")
const CLERK_BG_TEXTURE = preload("res://Assets/Backgrounds/Chapter_3/clerkbg.png")

# --- NODE REFERENCES ---
@onready var background = $clerkmarketbg
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jen_dialogue = $JenDialogueAnchor/jen2d

@onready var choose_control_8 = $ChooseControl8
@onready var choose_response_8 = $ChooseControl8/ChooseResponse8 
@onready var choices_container_8 = $ChooseControl8/ChoicesContainer8
@onready var branded_btn = $ChooseControl8/ChoicesContainer8/brandedA_btn
@onready var generic_btn = $ChooseControl8/ChoicesContainer8/genericB_btn
@onready var essentials_btn = $ChooseControl8/ChoicesContainer8/essentialsC_btn
@onready var jane_big_2 = $JaneBigAnchor2/jane2dbig

var currency_hud
var active_dialogue_box 

func _ready() -> void:
	
	AudioManager.play_convenience_store_music()
	# 1. Setup Currency HUD
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	# 2. Hide characters & UI initially
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jen_dialogue: jen_dialogue.modulate.a = 0.0
	if jane_big_2: jane_big_2.modulate.a = 0.0
	
	if choose_control_8:
		choose_control_8.modulate.a = 0.0
		choose_control_8.hide()
		
		# Connect Buttons
		if branded_btn: branded_btn.pressed.connect(_on_grocery_choice_pressed.bind("A"))
		if generic_btn: generic_btn.pressed.connect(_on_grocery_choice_pressed.bind("B"))
		if essentials_btn: essentials_btn.pressed.connect(_on_grocery_choice_pressed.bind("C"))
	
	# 3. Fade from black
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_sequence()


# --- PART 1: OUTSIDE THE STORE ---
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
		
	# Fade in thinking Jane
	if jane_thinking: jane_thinking.appear("idle", false)
	await get_tree().create_timer(0.6).timeout
	
	var intro_convo = [
		{"speaker": "Jane", "text": "Bibili sana ako ng groceries for the week."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(intro_convo)
	await active_dialogue_box.dialogue_finished
	
	# Clean up sequence 1
	if jane_thinking: jane_thinking.exit(true)
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await tween_box_out.finished 
	active_dialogue_box.queue_free()
	
	# Transition to inside the store
	_play_background_transition()


# --- BACKGROUND SWAP ---
func _play_background_transition() -> void:
	await TransitionManager.fade_to_black()
	
	# Swap the image to the inside of the clerk store
	if background:
		var new_stylebox = StyleBoxTexture.new()
		new_stylebox.texture = CLERK_BG_TEXTURE
		background.add_theme_stylebox_override("panel", new_stylebox)
		
	await get_tree().create_timer(0.5).timeout
	await TransitionManager.fade_from_black()
	
	# --- AUDIO LAYER INJECTION ---
	# Play the convenience store entrance chime sound effect profile as Jane enters
	AudioManager.play_sfx("DOORBELL")
	
	_play_clerk_sequence()


# --- PART 2: INSIDE THE STORE ---
func _play_clerk_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	
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
	if jen_dialogue: jen_dialogue.appear("idle", false)
	await get_tree().create_timer(0.6).timeout
	
	var clerk_convo = [
		{"speaker": "Jane", "text": "Wait... bakit P120 na ‘tong noodles? Dati P90 lang."},
		{"speaker": "Store Clerk", "text": "Tumaas po presyo dahil sa inflation."},
		{"speaker": "Jane", "text": "So ganito pala epekto ng inflation."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(clerk_convo)
	await active_dialogue_box.dialogue_finished
	
	# Exit animations
	if jane_thinking: jane_thinking.exit(true)
	if jen_dialogue: jen_dialogue.exit(true)
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await tween_box_out.finished 
	active_dialogue_box.queue_free()
	
	_play_choice_sequence()


# --- PART 3: GROCERY CHOICE ---
func _play_choice_sequence() -> void:
	if jane_big_2:
		jane_big_2.show()
		var tween_j = create_tween()
		tween_j.tween_property(jane_big_2, "modulate:a", 1.0, 0.5)
			
	await get_tree().create_timer(0.6).timeout
	
	if choose_control_8:
		choose_control_8.show()
		if choose_response_8: choose_response_8.show()
		if choices_container_8: choices_container_8.show()
		
		var tween_choice = create_tween()
		tween_choice.tween_property(choose_control_8, "modulate:a", 1.0, 0.5)

func _on_grocery_choice_pressed(choice: String) -> void:
	if branded_btn: branded_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if generic_btn: generic_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if essentials_btn: essentials_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# --- SAFE RAM STAGING REDIRECTION ---
	# Pass choice tracking and financial adjustments into the memory staging buffers
	GameManager.log_choice("chap3_grocery_choice", choice)
	
	# Trigger the transaction cash deduction sound feedback profile
	AudioManager.play_sfx("DEDUCT")
	
	if choice == "A": 
		GameManager.stage_finance_change(0, -250, "Purchased branded grocery items")
	elif choice == "B": 
		GameManager.stage_finance_change(0, -150, "Purchased generic grocery items")
	elif choice == "C": 
		GameManager.stage_finance_change(0, -100, "Purchased strictly essential groceries")
	
	# Refresh UI visually using our memory synchronization method
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	# Fade out UI
	var tween_out = create_tween().set_parallel(true)
	if choose_control_8: tween_out.tween_property(choose_control_8, "modulate:a", 0.0, 0.5)
	if jane_big_2: tween_out.tween_property(jane_big_2, "modulate:a", 0.0, 0.5)
	await tween_out.finished
	
	_transition_to_scene_4()


# --- PART 4: MOBILE SAFE TRANSITION ---
func _transition_to_scene_4() -> void:
	await TransitionManager.fade_to_black()
	AudioManager.play_chapter_music()
	
	await get_tree().create_timer(1.0).timeout
	
	var next_scene_path = "res://Scenes/Chapter 3/chapter_3_scene_4.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		print("Loading Chapter 3 Scene 4...")
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		print("Successfully loaded! Switching scenes now.")
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
	else:
		print("CRITICAL ERROR: Scene failed to load completely.")
