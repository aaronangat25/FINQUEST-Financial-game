extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var jen_clerk = $JenDialogueAnchor/jen2d 
@onready var choose_control = $ChooseControl10

var currency_hud
var active_dialogue_box

func _ready() -> void:
	# 1. Spawn Currency HUD
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	currency_hud.show()
	
	# 2. Hide initially
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jen_clerk: jen_clerk.modulate.a = 0.0
	
	if choose_control:
		choose_control.hide()
		choose_control.modulate.a = 0.0
			
	await get_tree().process_frame
	
	# 3. Fade in from Black Screen
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	# 4. Wait 1 second before starting
	await get_tree().create_timer(1.0).timeout
	
	_play_intro_sequence()


func _play_intro_sequence() -> void:
	
	# 1. Dialogue Box Fades in FIRST (1.0 duration fade)
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
		
	# 2. Jane Fades in SECOND (1.0 duration fade)
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished
		
	# Line 1 Jane
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Kailangan na namin magpa-print ng proposal."}])
	await active_dialogue_box.dialogue_finished
	
	
	# Swap Jane to Jen
	if jane_thinking: jane_thinking.hide()
	if jen_clerk:
		jen_clerk.show()
		jen_clerk.modulate.a = 1.0 # Force fully visible instantly
		if jen_clerk.has_method("appear"): jen_clerk.appear("idle", false)
		
	
	active_dialogue_box.queue_free()
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = false # NO FADE!
	box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual: box_visual.modulate.a = 1.0
	
	# Line 2 Clerk
	active_dialogue_box.start_dialogue([{"speaker": "Clerk", "text": "P10 per page po."}])
	await active_dialogue_box.dialogue_finished
	
	
	# Swap Jen to Jane
	if jen_clerk: jen_clerk.hide()
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 1.0 
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)

	
	active_dialogue_box.queue_free()
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = false # NO FADE!
	box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual: box_visual.modulate.a = 1.0
	
	# Line 3 jane
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Ang dami nito… mahal din pala."}])
	await active_dialogue_box.dialogue_finished
	
	
	# Fade out Jane FIRST (1.0 duration fade)
	if jane_thinking: 
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished
		jane_thinking.exit(true)
	
	# Fade out Dialogue Box SECOND (1.0 duration fade)
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	
	_show_choices()

	# Choices Logic
func _show_choices() -> void:
	if choose_control:
		choose_control.modulate.a = 0.0
		choose_control.show()
		var t_choice_in = create_tween()
		t_choice_in.tween_property(choose_control, "modulate:a", 1.0, 1.0)
		await t_choice_in.finished
		
		# Connect the three buttons
		var btn_a = choose_control.find_child("coloredA_btn", true, false)
		var btn_b = choose_control.find_child("blackandwhiteB_btn", true, false)
		var btn_c = choose_control.find_child("digitalC_btn", true, false)
		
		if btn_a and not btn_a.pressed.is_connected(_on_choice_a_pressed): 
			btn_a.pressed.connect(_on_choice_a_pressed)
		if btn_b and not btn_b.pressed.is_connected(_on_choice_b_pressed): 
			btn_b.pressed.connect(_on_choice_b_pressed)
		if btn_c and not btn_c.pressed.is_connected(_on_choice_c_pressed): 
			btn_c.pressed.connect(_on_choice_c_pressed)


func _on_choice_a_pressed() -> void:
	Global.choice_printing = "A" 
	_handle_choice_reaction(200, "Maganda yung output… sana worth it.")

func _on_choice_b_pressed() -> void:
	Global.choice_printing = "B" 
	_handle_choice_reaction(120, "Okay na ‘to… basta malinaw.")
	
func _on_choice_c_pressed() -> void:
	Global.choice_printing = "C" 
	_handle_choice_reaction(0, "Tipid… pero baka makaapekto sa evaluation.")


func _handle_choice_reaction(deduction_amount: int, choice_text: String) -> void:
	# 1. Fade out ChooseControl10 (1.0 duration)
	if choose_control:
		var t_choice_out = create_tween()
		t_choice_out.tween_property(choose_control, "modulate:a", 0.0, 1.0)
		await t_choice_out.finished
		choose_control.hide()
		
	# 2. STRICT CURRENCY MECHANIC
	if deduction_amount > 0 and currency_hud:
		var amount_to_change = -deduction_amount 
		
		# We check for common names. If yours is different, replace "deduct_money" with your exact name!
		if currency_hud.has_method("deduct_money"):
			currency_hud.deduct_money(deduction_amount)
			print("DEBUG: Successfully deducted ", deduction_amount)
			
		elif currency_hud.has_method("subtract_money"):
			currency_hud.subtract_money(deduction_amount)
			print("DEBUG: Successfully subtracted ", deduction_amount)
			
		elif currency_hud.has_method("add_money"):
			currency_hud.add_money(amount_to_change) 
			print("DEBUG: Successfully added negative ", amount_to_change)
			
		elif currency_hud.has_method("update_money"):
			currency_hud.update_money(amount_to_change)
			print("DEBUG: Successfully updated money by ", amount_to_change)
			
		else:
			print("ERROR: Godot cannot find your money function! Check currency_hud.gd for the exact name.")

	# 3. Fade IN Dialogue Box FIRST (1.0 duration fade)
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
		
	# 4. Fade IN Thinking Jane SECOND (1.0 duration fade)
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished # WAIT for Jane
	
	# 5. Play Reaction Text
	active_dialogue_box.is_fading = false
	var reaction_convo = [{"speaker": "Jane", "text": choice_text}]
	active_dialogue_box.start_dialogue(reaction_convo)
	await active_dialogue_box.dialogue_finished
	
	# 6. Fade OUT Jane FIRST (1.0 duration fade)
	if jane_thinking: 
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished
		jane_thinking.exit(true)
		
	# 7. Fade OUT Dialogue Box SECOND (1.0 duration fade)
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	
	_transition_to_scene_3()


func _transition_to_scene_3() -> void:
	# Wait 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	# Fade to Black
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	# Show "THESIS DEFENSE DAY" Title
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label:
		title_label.text = "THESIS\nDEFENSE\nDAY"
		title_label.modulate.a = 0.0
		title_label.show()
		
		var t_title_in = create_tween()
		t_title_in.tween_property(title_label, "modulate:a", 1.0, 1.0)
		await t_title_in.finished
		
		await get_tree().create_timer(3.0).timeout
		
		var t_title_out = create_tween()
		t_title_out.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t_title_out.finished
		title_label.hide()
		
	print("Chapter 4 Scene 2 Complete! Transitioning to Scene 3...")
	
	# Change Scene to Scene 3
	var next_scene_path = "res://Scenes/Chapter 4/chapter_4_scene_3.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
