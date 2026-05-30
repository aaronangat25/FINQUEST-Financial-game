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
	# Keep background music loop channels executing cleanly into printing tasks
	AudioManager.play_convenience_store_music()

	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	
	if jane_thinking: jane_thinking.modulate.a = 0.0
	if jen_clerk: jen_clerk.modulate.a = 0.0
	
	if choose_control:
		choose_control.hide()
		choose_control.modulate.a = 0.0
			
	await get_tree().process_frame
	
	# Force display layout sync on entry point
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
		
	await get_tree().create_timer(1.0).timeout
	_play_intro_sequence()


func _play_intro_sequence() -> void:
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
		
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished
		
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Kailangan na namin magpa-print ng proposal."}])
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: jane_thinking.hide()
	if jen_clerk:
		jen_clerk.show()
		jen_clerk.modulate.a = 1.0 
		if jen_clerk.has_method("appear"): jen_clerk.appear("idle", false)
		
	active_dialogue_box.queue_free()
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = false 
	box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual: box_visual.modulate.a = 1.0
	
	active_dialogue_box.start_dialogue([{"speaker": "Clerk", "text": "P10 per page po."}])
	await active_dialogue_box.dialogue_finished
	
	if jen_clerk: jen_clerk.hide()
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 1.0 
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)

	active_dialogue_box.queue_free()
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = false 
	box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual: box_visual.modulate.a = 1.0
	
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Ang dami nito… mahal din pala."}])
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: 
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished
		jane_thinking.exit(true)
	
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	_show_choices()


func _show_choices() -> void:
	if choose_control:
		choose_control.modulate.a = 0.0
		choose_control.show()
		var t_choice_in = create_tween()
		t_choice_in.tween_property(choose_control, "modulate:a", 1.0, 1.0)
		await t_choice_in.finished
		
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
	# Trigger deduction sound effect for colored copy purchase
	AudioManager.play_sfx("DEDUCT")
	_handle_choice_reaction(200, "Maganda yung output… sana worth it.")

func _on_choice_b_pressed() -> void:
	Global.choice_printing = "B" 
	# Trigger deduction sound effect for grayscale copy purchase
	AudioManager.play_sfx("DEDUCT")
	_handle_choice_reaction(120, "Okay na ‘to… basta malinaw.")
	
func _on_choice_c_pressed() -> void:
	Global.choice_printing = "C" 
	_handle_choice_reaction(0, "Tipid… pero baka makaapekto sa evaluation.")


func _handle_choice_reaction(deduction_amount: int, choice_text: String) -> void:
	if choose_control:
		var t_choice_out = create_tween()
		t_choice_out.tween_property(choose_control, "modulate:a", 0.0, 1.0)
		await t_choice_out.finished
		choose_control.hide()
		
	# --- SAFE RAM STAGING REDIRECTION ---
	GameManager.log_choice("chap4_printing_choice", Global.choice_printing)
	if deduction_amount > 0:
		GameManager.stage_finance_change(0, -deduction_amount, "Thesis document printing services expense")

	# Force visual layout update loop immediately
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()

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
		
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): jane_thinking.appear("idle", false)
		var t_jane_in = create_tween()
		t_jane_in.tween_property(jane_thinking, "modulate:a", 1.0, 1.0)
		await t_jane_in.finished
	
	active_dialogue_box.is_fading = false
	var reaction_convo = [{"speaker": "Jane", "text": choice_text}]
	active_dialogue_box.start_dialogue(reaction_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: 
		var t_jane_out = create_tween()
		t_jane_out.tween_property(jane_thinking, "modulate:a", 0.0, 1.0)
		await t_jane_out.finished
		jane_thinking.exit(true)
		
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	_transition_to_scene_3()


func _transition_to_scene_3() -> void:
	await get_tree().create_timer(2.0).timeout
	
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	AudioManager.play_chapter_music()
		
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
	
	var next_scene_path = "res://Scenes/Chapter 4/chapter_4_scene_3.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
