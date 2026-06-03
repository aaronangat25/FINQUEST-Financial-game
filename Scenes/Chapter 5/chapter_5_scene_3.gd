extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_big_anchor = $JaneBigAnchor
@onready var jane_big_anchor2 = $JaneBigAnchor2
@onready var jane_big_anchor3 = $JaneBigAnchor3
@onready var jane_talking = $JaneDialogueAnchor/jane2d
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking

# Choice Layout Engine Nodes
@onready var choose_control = $ChooseControl11
@onready var choice_appears_banner = $ChooseControl11/ChoiceAppears
@onready var choices_container = $ChooseControl11/ChoicesContainer10

# Button Interaction Targets
@onready var new_outfit_btn = $ChooseControl11/ChoicesContainer10/newOutfit_btn
@onready var simple_outfit_btn = $ChooseControl11/ChoicesContainer10/simpleOutfit_btn
@onready var borrow_outfit_btn = $ChooseControl11/ChoicesContainer10/borrowOutfit_btn

var currency_hud
var active_dialogue_box

var graduation_choice: String = ""

func _ready() -> void:
	# Keep baseline loops processing travel settings steadily
	AudioManager.play_chapter_music()

	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	currency_hud.show()
	
	# Strict Scene Layer Visibility Defaults Reset
	if jane_big_anchor: jane_big_anchor.hide()
	if jane_big_anchor2: jane_big_anchor2.hide()
	if jane_big_anchor3: jane_big_anchor3.hide()
	if jane_talking: jane_talking.hide()
	
	if jane_thinking:
		jane_thinking.hide()
		jane_thinking.modulate.a = 0.0
		
	if choose_control:
		choose_control.hide()
		choose_control.modulate.a = 0.0
	if choice_appears_banner: choice_appears_banner.hide()
	if choices_container: choices_container.hide()
			
	await get_tree().process_frame
	
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
		
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_sequence()


# --- STEP 1: INITIAL REFLECTION ---
func _play_intro_sequence() -> void:
	await get_tree().create_timer(0.5).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		await create_tween().tween_property(box_visual, "modulate:a", 1.0, 0.5).finished
		
	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"):
			jane_thinking.appear("idle", false)
		await create_tween().tween_property(jane_thinking, "modulate:a", 1.0, 0.5).finished
	
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "May graduation pa… syempre may gastos ulit."}])
	await active_dialogue_box.dialogue_finished
	
	var t_clear = create_tween().set_parallel(true)
	if jane_thinking: t_clear.tween_property(jane_thinking, "modulate:a", 0.0, 0.4)
	if box_visual: t_clear.tween_property(box_visual, "modulate:a", 0.0, 0.4)
	await t_clear.finished
	
	if jane_thinking: jane_thinking.hide()
	active_dialogue_box.queue_free()
	_show_graduation_choices()


# --- STEP 2: SHOW INTERACTIVE CHOICE MENU ---
func _show_graduation_choices() -> void:
	if choose_control:
		choose_control.show()
		choose_control.modulate.a = 0.0
		
		if choice_appears_banner: choice_appears_banner.show()
		if choices_container: choices_container.show()
		
		var t_menu = create_tween()
		t_menu.tween_property(choose_control, "modulate:a", 1.0, 0.5)
		await t_menu.finished
		
	if new_outfit_btn and not new_outfit_btn.pressed.is_connected(_on_choice_a_selected):
		new_outfit_btn.pressed.connect(_on_choice_a_selected)
		
	if simple_outfit_btn and not simple_outfit_btn.pressed.is_connected(_on_choice_b_selected):
		simple_outfit_btn.pressed.connect(_on_choice_b_selected)
		
	if borrow_outfit_btn and not borrow_outfit_btn.pressed.is_connected(_on_choice_c_selected):
		borrow_outfit_btn.pressed.connect(_on_choice_c_selected)


# --- STEP 3: CHOICE BUTTON CALLBACKS ---
func _on_choice_a_selected() -> void:
	_disable_all_buttons()
	graduation_choice = "A"
	
	# Trigger transaction sound profile for outfit purchase
	AudioManager.play_sfx("DEDUCT")
	GameManager.log_choice("chap5_graduation_outfit", "A")
	GameManager.request_expense_payment(2500, "Purchased a premium brand-new graduation dress outfit")
	
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
		
	_handle_immediate_reflection(jane_big_anchor, "Deserve ko rin naman siguro ito…")

func _on_choice_b_selected() -> void:
	_disable_all_buttons()
	graduation_choice = "B"
	
	# Trigger transaction sound profile for simple outfit purchase
	AudioManager.play_sfx("DEDUCT")
	GameManager.log_choice("chap5_graduation_outfit", "B")
	GameManager.request_expense_payment(1500, "Purchased a standard simple graduation outfit")
	
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
		
	_handle_immediate_reflection(jane_big_anchor2, "Simple pero memorable pa rin.")

func _on_choice_c_selected() -> void:
	_disable_all_buttons()
	graduation_choice = "C"
	
	# Trigger transaction sound profile for outfit rental dry-cleaning
	AudioManager.play_sfx("DEDUCT")
	GameManager.log_choice("chap5_graduation_outfit", "C")
	GameManager.request_expense_payment(1000, "Paid rental and dry cleaning for a borrowed graduation outfit")
	
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
		
	_handle_immediate_reflection(jane_big_anchor3, "Mas importante ang future kaysa isang araw lang ng gastos.")


# --- STEP 4: DIRECT SELECTION REFLECTION ---
func _handle_immediate_reflection(target_anchor: Control, jane_reflection: String) -> void:
	if choose_control:
		var t_out = create_tween()
		t_out.tween_property(choose_control, "modulate:a", 0.0, 0.4)
		await t_out.finished
		choose_control.hide()

	if target_anchor:
		target_anchor.show()
		target_anchor.modulate.a = 1.0

	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	active_dialogue_box.show()
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		box_visual.modulate.a = 0.0
		await create_tween().tween_property(box_visual, "modulate:a", 1.0, 0.4).finished

	if jane_thinking:
		jane_thinking.show()
		jane_thinking.modulate.a = 0.0
		if jane_thinking.has_method("appear"): 
			jane_thinking.appear("idle", false)
		await create_tween().tween_property(jane_thinking, "modulate:a", 1.0, 0.4).finished

	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": jane_reflection}])
	await active_dialogue_box.dialogue_finished

	var t_clear = create_tween().set_parallel(true)
	if jane_thinking: t_clear.tween_property(jane_thinking, "modulate:a", 0.0, 0.4)
	if box_visual: t_clear.tween_property(box_visual, "modulate:a", 0.0, 0.4)
	if target_anchor: t_clear.tween_property(target_anchor, "modulate:a", 0.0, 0.4)
	await t_clear.finished
	
	if jane_thinking: jane_thinking.hide()
	if target_anchor: target_anchor.hide()
	active_dialogue_box.queue_free()
	_transition_to_ending()


# --- HELPER UTILITIES ---
func _disable_all_buttons() -> void:
	var buttons = [new_outfit_btn, simple_outfit_btn, borrow_outfit_btn]
	for btn in buttons:
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _transition_to_ending() -> void:
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	print("Chapter 5 Finished! Progressing engine pipeline to summary matrices...")
	get_tree().change_scene_to_file("res://Scenes/Chapter 5/chapter_5_scene_4.tscn")
