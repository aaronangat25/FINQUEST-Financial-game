extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var saving_screen = $SavingScreen
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
@onready var ending_btn = $StatsScreen/Ending_btn
@onready var main_menu_btn = $StatsScreen/MainMenu_btn

var currency_hud
var active_dialogue_box

var career_choice: String = ""
var is_transitioning: bool = false

func _ready() -> void:
	# Continuous ambient loops moving cleanly through final metrics
	AudioManager.play_chapter_music()
	
	Global.player_money = GameManager.on_hand_cash

	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	currency_hud.show()
	
	if jane_graduation_anchor: jane_graduation_anchor.hide()
	if jane_graduation_sprite:
		jane_graduation_sprite.hide()
		jane_graduation_sprite.modulate.a = 0.0
		
	if choose_control:
		choose_control.hide()
		choose_control.modulate.a = 0.0
	if choice_appears_banner: choice_appears_banner.hide()
	if choices_container: choices_container.hide()
	
	if stats_screen:
		stats_screen.hide()
		stats_screen.modulate.a = 0.0
		
	if ending_btn:
		ending_btn.hide()
		ending_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if main_menu_btn:
		main_menu_btn.hide()
		main_menu_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
	await get_tree().process_frame
	
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
		
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_monologue()


# --- STEP 1: GRADUATION REFLECTION MONOLOGUE ---
func _play_intro_monologue() -> void:
	await get_tree().create_timer(0.5).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 0.0
		await create_tween().tween_property(box_visual, "modulate:a", 1.0, 0.5).finished
		
	if jane_graduation_anchor: jane_graduation_anchor.show()
	if jane_graduation_sprite:
		jane_graduation_sprite.show()
		if jane_graduation_sprite.has_method("appear"):
			jane_graduation_sprite.appear("idle", false)
		await create_tween().tween_property(jane_graduation_sprite, "modulate:a", 1.0, 0.5).finished
	
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Graduate na ako… pero ano na ang next step?"}])
	await active_dialogue_box.dialogue_finished
	
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
	
	GameManager.log_choice("chap5_career_pathway", "Corporate")
	_show_stats_summary_screen()

func _on_business_selected() -> void:
	_lock_all_inputs()
	career_choice = "Business"
	
	GameManager.log_choice("chap5_career_pathway", "Business")
	_show_stats_summary_screen()

func _on_stop_first_selected() -> void:
	_lock_all_inputs()
	career_choice = "Stop"
	
	GameManager.log_choice("chap5_career_pathway", "Stop")
	_show_stats_summary_screen()


# --- STEP 4: DISPLAY STATS SCREEN OVERLAY DIRECTLY ---
func _show_stats_summary_screen() -> void:
	if choose_control:
		var t_out = create_tween()
		t_out.tween_property(choose_control, "modulate:a", 0.0, 0.4)
		await t_out.finished
		choose_control.hide()

	if stats_screen:
		stats_screen.show()
		var t_panel = create_tween()
		t_panel.tween_property(stats_screen, "modulate:a", 1.0, 0.5)
		await t_panel.finished
		
	var t_show_buttons = create_tween().set_parallel(true)
	
	if ending_btn:
		ending_btn.show()
		ending_btn.modulate.a = 0.0
		ending_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		t_show_buttons.tween_property(ending_btn, "modulate:a", 1.0, 0.5)
		if not ending_btn.pressed.is_connected(_on_final_chapter_exit_pressed):
			ending_btn.pressed.connect(_on_final_chapter_exit_pressed)
			
	if main_menu_btn:
		main_menu_btn.show()
		main_menu_btn.modulate.a = 0.0
		main_menu_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		t_show_buttons.tween_property(main_menu_btn, "modulate:a", 1.0, 0.5)
		if not main_menu_btn.pressed.is_connected(_on_main_menu_pressed):
			main_menu_btn.pressed.connect(_on_main_menu_pressed)


# --- STEP 5: GAME CONCLUSION ROUTINE (CONTINUE TO ENDING) ---
func _on_final_chapter_exit_pressed() -> void:
	if is_transitioning: return
	is_transitioning = true
	
	if ending_btn: ending_btn.disabled = true
	if main_menu_btn: main_menu_btn.disabled = true
	
	if currency_hud: currency_hud.hide()
	if stats_screen: stats_screen.hide()
	
	GameManager.current_chapter = 6
	var next_scene_path = "res://Scenes/Ending/ending.tscn"
	_execute_save_and_blackout(next_scene_path, true)


# --- MAIN MENU PRESSED EVENT ---
func _on_main_menu_pressed() -> void:
	if is_transitioning: return
	is_transitioning = true
	
	if ending_btn: ending_btn.disabled = true
	if main_menu_btn: main_menu_btn.disabled = true
	
	if currency_hud: currency_hud.hide()
	if stats_screen: stats_screen.hide()
	
	GameManager.current_chapter = 6
	var main_menu_path = "res://Scenes/Main Screen/main_screen.tscn"
	_execute_save_and_blackout(main_menu_path, false)


# --- ENCAPSULATED SAVE OVERLAY RUNTIME CARRIER ---
func _execute_save_and_blackout(destination_path: String, run_cinematic_card: bool) -> void:
	GameManager.flush_buffer_to_database()
	
	if saving_screen:
		saving_screen.process_mode = PROCESS_MODE_ALWAYS
		saving_screen.show()
		
	GameManager.complete_current_chapter(100.0)
	print("[DATABASE] Chapter 5 Progression committed smoothly.")
	
	await get_tree().create_timer(3.0).timeout
	
	var local_black_screen = ColorRect.new()
	local_black_screen.color = Color(0, 0, 0, 1)
	local_black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(local_black_screen)
	
	if saving_screen:
		saving_screen.hide()
		saving_screen.process_mode = PROCESS_MODE_DISABLED
	
	if run_cinematic_card:
		if TransitionManager.has_method("fade_to_black"):
			await TransitionManager.fade_to_black()
			
		# --- AUDIO STREAM THEME RESET ---
		# Clear existing track locks and restart the score head cleanly for the game's finale layout
		AudioManager.restart_general_music()
			
		var title_label = TransitionManager.get_node_or_null("TitleLabel")
		if title_label:
			title_label.modulate.a = 0.0
			title_label.show()
			
			title_label.text = "EPILOGUE"
			var t1 = create_tween()
			t1.tween_property(title_label, "modulate:a", 1.0, 1.0)
			await t1.finished
			
			await get_tree().create_timer(2.0).timeout
			
			var t2 = create_tween()
			t2.tween_property(title_label, "modulate:a", 0.0, 1.0)
			await t2.finished
			title_label.hide()
			
			await get_tree().create_timer(1.0).timeout
			
		get_tree().change_scene_to_file(destination_path)
	else:
		get_tree().change_scene_to_file(destination_path)


# --- HELPER UTILITIES ---
func _lock_all_inputs() -> void:
	var option_buttons = [apply_corporate_btn, start_business_btn, stop_first_btn]
	for btn in option_buttons:
		if btn:
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
