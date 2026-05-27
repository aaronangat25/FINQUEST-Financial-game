extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_graduation_anchor = $JaneGraduationAnchor
@onready var jane_graduation_sprite = $JaneGraduationAnchor/JaneGraduation

# Choice Menu UI Display Blocks
@onready var choose_control = $ChooseControl11
@onready var choice_appears_banner = $ChooseControl11/ChoiceAppears
@onready var choices_container = $ChooseControl11/ChoicesContainer10

# Interactive Selection Buttons
@onready var apply_corporate_btn = $ChooseControl11/ChoicesContainer10/applyCorporate_btn
@onready var start_business_btn = $ChooseControl11/ChoicesContainer10/startBusiness_btn
@onready var stop_first_btn = $ChooseControl11/ChoicesContainer10/stopFirst_btn

# Summary Evaluation Overlay Panel
@onready var stats_screen = $StatsScreen
@onready var chapter_5_btn = $StatsScreen/Chapter5_btn

var currency_hud
var active_dialogue_box

# Localized tracking state variable
var career_choice: String = ""

func _ready() -> void:
	# 1. Instantiate Core Currency Hud Element
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	currency_hud.show()
	
	# 2. Strict Runtime Layout Visibility Defaults Reset
	if jane_graduation_anchor: jane_graduation_anchor.hide()
	if jane_graduation_sprite:
		jane_graduation_sprite.hide()
		jane_graduation_sprite.modulate.a = 0.0
		
	if choose_control:
		choose_control.hide()
		choose_control.modulate.a = 0.0
	if choice_appears_banner: choice_appears_banner.hide()
	if choices_container: choices_container.hide()
	
	# Keep stats panel matrix safe and invisible on launch
	if stats_screen:
		stats_screen.hide()
		stats_screen.modulate.a = 0.0
			
	await get_tree().process_frame
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_monologue()


# --- STEP 1: GRADUATION REFLECTION MONOLOGUE ---
func _play_intro_monologue() -> void:
	await get_tree().create_timer(0.5).timeout
	
	# Fade In Dialogue Box Container Frame FIRST
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		await create_tween().tween_property(box_visual, "modulate:a", 1.0, 0.5).finished
		
	# Fade In Jane Graduation Cap Sprite SECOND
	if jane_graduation_anchor: jane_graduation_anchor.show()
	if jane_graduation_sprite:
		jane_graduation_sprite.show()
		if jane_graduation_sprite.has_method("appear"):
			jane_graduation_sprite.appear("idle", false)
		await create_tween().tween_property(jane_graduation_sprite, "modulate:a", 1.0, 0.5).finished
	
	# Execute text typewriter block sequence
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Graduate na ako… pero ano na ang next step?"}])
	await active_dialogue_box.dialogue_finished
	
	# Clear out old overlay panels smoothly before displaying choice pathways
	var t_clear = create_tween().set_parallel(true)
	if box_visual: t_clear.tween_property(box_visual, "modulate:a", 0.0, 0.4)
	if jane_graduation_sprite: t_clear.tween_property(jane_graduation_sprite, "modulate:a", 0.0, 0.4)
	await t_clear.finished
	
	if jane_graduation_sprite: jane_graduation_sprite.hide()
	if jane_graduation_anchor: jane_graduation_anchor.hide()
	active_dialogue_box.queue_free()
	
	_show_graduation_choices()


# --- STEP 2: SHOW INTERACTIVE CAREER SELECTION MENU ---
func _show_graduation_choices() -> void:
	if choose_control:
		choose_control.show()
		choose_control.modulate.a = 0.0
		
		if choice_appears_banner: choice_appears_banner.show()
		if choices_container: choices_container.show()
		
		var t_menu = create_tween()
		t_menu.tween_property(choose_control, "modulate:a", 1.0, 0.5)
		await t_menu.finished
		
	# Connect Button Hooks Bulletproofly
	if apply_corporate_btn and not apply_corporate_btn.pressed.is_connected(_on_corporate_selected):
		apply_corporate_btn.pressed.connect(_on_corporate_selected)
		
	if start_business_btn and not start_business_btn.pressed.is_connected(_on_business_selected):
		start_business_btn.pressed.connect(_on_business_selected)
		
	if stop_first_btn and not stop_first_btn.pressed.is_connected(_on_stop_first_selected):
		stop_first_btn.pressed.connect(_on_stop_first_selected)


# --- STEP 3: INTERACTIVE BUTTON SELECTION ACTIONS ---
func _on_corporate_selected() -> void:
	_lock_all_inputs()
	career_choice = "Corporate"
	_show_stats_summary_screen()

func _on_business_selected() -> void:
	_lock_all_inputs()
	career_choice = "Business"
	_show_stats_summary_screen()

func _on_stop_first_selected() -> void:
	_lock_all_inputs()
	career_choice = "Stop"
	_show_stats_summary_screen()


# --- STEP 4: DISPLAY STATS SCREEN OVERLAY DIRECTLY ---
func _show_stats_summary_screen() -> void:
	# 1. Fade out choice menu selection block cleanly
	if choose_control:
		var t_out = create_tween()
		t_out.tween_property(choose_control, "modulate:a", 0.0, 0.4)
		await t_out.finished
		choose_control.hide()

	# 2. Bring up the StatsScreen overlay panel smoothly
	if stats_screen:
		stats_screen.show()
		var t_panel = create_tween()
		t_panel.tween_property(stats_screen, "modulate:a", 1.0, 0.5)
		await t_panel.finished
		
	# Connect the exit button handler inside the summary matrix
	if chapter_5_btn and not chapter_5_btn.pressed.is_connected(_on_final_chapter_exit_pressed):
		chapter_5_btn.pressed.connect(_on_final_chapter_exit_pressed)


# --- STEP 5: GAME CONCLUSION ROUTINE ---
func _on_final_chapter_exit_pressed() -> void:
	if chapter_5_btn:
		chapter_5_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	print("Chapter 5 Career Summary Complete. Returning to Main Game Summary Screen Matrix...")
	#get_tree().change_scene_to_file("res://Scenes/Menu/game_summary_screen.tscn")


# --- HELPER UTILITIES ---
func _lock_all_inputs() -> void:
	var option_buttons = [apply_corporate_btn, start_business_btn, stop_first_btn]
	for btn in option_buttons:
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
