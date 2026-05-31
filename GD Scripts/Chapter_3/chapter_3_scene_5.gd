extends Control

# --- SIGNALS ---
signal result_clicked

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var saving_screen = $SavingScreen
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var stats_screen = $StatsScreen
@onready var stats_panel = $StatsScreen/Panel 

@onready var next_button = $StatsScreen/Chapter4_btn 
@onready var main_menu_button = $StatsScreen/MainMenu_btn

@onready var total_label = $StatsScreen/Panel/TotalName/TotalLabel
@onready var feedback_label = $StatsScreen/Panel/FeedbackLabel

var currency_hud
var active_dialogue_box 

# --- INTERACTION LOCKS ---
var waiting_for_click: bool = false
var can_click_result: bool = false # 5-second lock

var is_transitioning: bool = false

func _ready() -> void:
	# Keep background ambient exploration tracks flowing into evaluations steadily
	AudioManager.play_chapter_music()

	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	
	if currency_hud.has_method("show"):
		currency_hud.show()
	
	# Sync visual display layers instantly
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	if jane_thinking: jane_thinking.modulate.a = 0.0
	
	if stats_screen: 
		stats_screen.hide()
		stats_screen.modulate.a = 0.0
		
	if next_button: 
		next_button.hide()
		next_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if main_menu_button:
		main_menu_button.hide()
		main_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	await get_tree().process_frame
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_sequence()


# --- INPUT DETECTION FOR CLICKS ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if waiting_for_click and can_click_result:
			waiting_for_click = false
			can_click_result = false
			result_clicked.emit() 


# --- INTRO SEQUENCE ---
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
		
	if jane_thinking: 
		jane_thinking.show()
		if jane_thinking.has_method("appear"):
			jane_thinking.appear("idle", false)
	await get_tree().create_timer(0.6).timeout
	
	var intro_convo = [
		{"speaker": "Jane", "text": "Let’s see kung paano ko nahandle yung gastos ko this month."}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(intro_convo)
	await active_dialogue_box.dialogue_finished
	
	if jane_thinking: jane_thinking.exit(true)
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await tween_box_out.finished 
	active_dialogue_box.queue_free()
	
	_show_evaluation_stats()


# --- STATS SCREEN EVALUATION ---
func _show_evaluation_stats() -> void:
	await get_tree().create_timer(0.5).timeout
	
	# Read her true accumulated expenses out of our safe RAM staging registers
	var true_expenses = abs(GameManager.buffered_on_hand_change)
	
	var jane_reaction_text = "" 
	
	if total_label:
		total_label.text = "P" + str(true_expenses)
		
	if feedback_label:
		# COMBINED INFLATION CARD TARGET BOUNDARIES
		# Meal (0 to 90) + Groceries (100 to 250)
		if true_expenses <= 150: 
			feedback_label.text = "RESULT: EXCELLENT BUDGETING"
			feedback_label.add_theme_color_override("font_color", Color("a5d68d")) 
			jane_reaction_text = "Buti na lang nag-adjust ako kahit may inflation."
			
			# 🏅 ACHIEVEMENT INTEGRATION: Unlocks when securing the highest monthly budget result tier
			GameManager.unlock_achievement("INFLATION_FIGHTER")
			
		elif true_expenses <= 250: 
			feedback_label.text = "RESULT: GOOD BUDGETING"
			feedback_label.add_theme_color_override("font_color", Color("78dfb7ff")) 
			jane_reaction_text = "Okay naman... pero pwede ko pa pagbutihin."
			
		else: 
			feedback_label.text = "RESULT: NEEDS IMPROVEMENT"
			feedback_label.add_theme_color_override("font_color", Color("d95763")) 
			jane_reaction_text = "Ang bilis maubos ng pera ko... kailangan kong mag-budget better next time."
	
	# 1. Show only the Stats Panel (Yellow Box)
	if stats_screen:
		stats_screen.show()
		if stats_panel: stats_panel.show()
		
		var tween = create_tween()
		tween.tween_property(stats_screen, "modulate:a", 1.0, 1.0)
		await tween.finished 
		
	# 2. PAUSE FOR 5 SECONDS
	waiting_for_click = true
	can_click_result = false
	
	await get_tree().create_timer(5.0).timeout
	can_click_result = true
	
	await self.result_clicked
	
	# 3. Instantly hide ONLY the Yellow Box result panel upon click
	if stats_panel:
		stats_panel.hide()
		
	# 4. Spawn Dialogue Box for Jane's reaction
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
		
	if jane_thinking: 
		jane_thinking.show()
		if jane_thinking.has_method("appear"):
			jane_thinking.appear("idle", false)
	await get_tree().create_timer(0.6).timeout
	
	var reaction_convo = [
		{"speaker": "Jane", "text": jane_reaction_text}
	]
	
	active_dialogue_box.is_fading = false 
	active_dialogue_box.start_dialogue(reaction_convo)
	await active_dialogue_box.dialogue_finished
	
	# 5. Cleanup the dialogue and Jane
	if jane_thinking: jane_thinking.exit(true)
	await get_tree().create_timer(0.6).timeout
			
	if box_visual:
		var tween_box_out = create_tween()
		tween_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await tween_box_out.finished 
	active_dialogue_box.queue_free()
		
	# 6. FINALLY: Show BOTH the Chapter 4 and Main Menu Navigation Buttons!
	if stats_screen: stats_screen.show() 
	
	# Setup Chapter 4 Continue Button
	if next_button:
		next_button.show()
		next_button.mouse_filter = Control.MOUSE_FILTER_STOP
		next_button.modulate.a = 0.0
		var btn_tween = create_tween()
		btn_tween.tween_property(next_button, "modulate:a", 1.0, 0.5)
		
		if not next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.connect(_on_next_pressed)

	# Setup Exit to Main Menu Button
	if main_menu_button:
		main_menu_button.show()
		main_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
		main_menu_button.modulate.a = 0.0
		var menu_btn_tween = create_tween()
		menu_btn_tween.tween_property(main_menu_button, "modulate:a", 1.0, 0.5)
		
		if not main_menu_button.pressed.is_connected(_on_main_menu_pressed):
			main_menu_button.pressed.connect(_on_main_menu_pressed)

# --- CONTINUE TO CHAPTER 4 BUTTON CLICKED ---
func _on_next_pressed() -> void:
	if is_transitioning: return
	is_transitioning = true 
	
	if next_button: next_button.disabled = true
	if main_menu_button: main_menu_button.disabled = true
	
	print("Chapter 3 Complete! Preparing 3-second database save sequence...")
	
	if currency_hud: currency_hud.hide()
	if stats_screen: stats_screen.hide()
	
	# Force tracker safely to Chapter 4 (Row 5 inside SQLite chapter_progress table)
	GameManager.current_chapter = 4
	
	var next_scene_path = "res://Scenes/Chapter 4/chapter_4_scene_1.tscn" 
	_execute_save_and_blackout(next_scene_path, true)


# --- QUIT TO MAIN MENU BUTTON CLICKED ---
func _on_main_menu_pressed() -> void:
	if is_transitioning: return
	is_transitioning = true 
	
	if next_button: next_button.disabled = true
	if main_menu_button: main_menu_button.disabled = true
	
	print("Quitting to Main Menu. Running database save sequence first...")
	
	if currency_hud: currency_hud.hide()
	if stats_screen: stats_screen.hide()
	
	# Force tracker safely to Chapter 4 (Row 5 inside SQLite chapter_progress table)
	GameManager.current_chapter = 4
	
	var main_screen_path = "res://Scenes/Main Screen/main_screen.tscn"
	_execute_save_and_blackout(main_screen_path, false)


# --- ENCAPSULATED SAVE OVERLAY RUNTIME CARRIER ---
func _execute_save_and_blackout(destination_path: String, play_cinematic_card: bool) -> void:
	# Safely commits Chapter 3 choice sets and budget log arrays right before shifting scenes!
	GameManager.flush_buffer_to_database()
	
	# 1. Fire up the saving overlay asset node
	saving_screen.process_mode = PROCESS_MODE_ALWAYS
	saving_screen.show()
	GameManager.complete_current_chapter(100.0)
	
	await get_tree().create_timer(3.0).timeout
	
	# 2. Drop the local solid black background cover block
	var local_black_screen = ColorRect.new()
	local_black_screen.color = Color(0, 0, 0, 1)
	local_black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(local_black_screen)
	
	saving_screen.hide()
	saving_screen.process_mode = PROCESS_MODE_DISABLED
	
	# 3. Handle specific level banner tweens if continuing forward
	if play_cinematic_card:
		# Clear track locks and restart the default background score loop from zero for Chapter 4
		AudioManager.restart_general_music()

		var title_label = TransitionManager.get_node_or_null("TitleLabel")
		if title_label:
			title_label.text = "CHAPTER 4"
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
			
		ResourceLoader.load_threaded_request(destination_path)
		var load_status = ResourceLoader.load_threaded_get_status(destination_path)
		
		while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().create_timer(0.1).timeout 
			load_status = ResourceLoader.load_threaded_get_status(destination_path)
			
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			var new_scene = ResourceLoader.load_threaded_get(destination_path)
			get_tree().change_scene_to_packed(new_scene)
	else:
		get_tree().change_scene_to_file(destination_path)
