extends Control

# --- SIGNALS ---
signal result_clicked

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking
@onready var stats_screen = $StatsScreen
@onready var stats_panel = $StatsScreen/Panel 
@onready var next_button = $StatsScreen/Chapter4_btn 

@onready var total_label = $StatsScreen/Panel/TotalName/TotalLabel
@onready var feedback_label = $StatsScreen/Panel/FeedbackLabel

var currency_hud
var active_dialogue_box 

# --- INTERACTION LOCKS ---
var waiting_for_click: bool = false
var can_click_result: bool = false # 5-second lock

var is_transitioning: bool = false

func _ready() -> void:
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	currency_hud.show()
	
	if jane_thinking: jane_thinking.modulate.a = 0.0
	
	if stats_screen: 
		stats_screen.hide()
		stats_screen.modulate.a = 0.0
		
	if next_button: 
		next_button.hide()
		next_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	await get_tree().process_frame
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_intro_sequence()


# --- INPUT DETECTION FOR CLICKS ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# FIX: Only allow the click if 5 seconds have passed!
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
	
	# --- NO MORE INITIAL VARIABLES ---
	# Grab the exact expenses tracked perfectly by Global script
	var total_expenses = Global.total_expenses
	
	var jane_reaction_text = "" 
	
	if total_label:
		# Show the exact Total Expenses
		total_label.text = "P" + str(total_expenses)
		
	if feedback_label:
		# RESULT LOGIC
		if total_expenses <= 350: 
			# Excellent Budgeting (P185 - P350)
			feedback_label.text = "RESULT: EXCELLENT BUDGETING"
			feedback_label.add_theme_color_override("font_color", Color("a5d68d")) 
			jane_reaction_text = "Buti na lang nag-adjust ako kahit may inflation."
			
		elif total_expenses <= 520: 
			# Good Budgeting (P351 - P520)
			feedback_label.text = "RESULT: GOOD BUDGETING"
			feedback_label.add_theme_color_override("font_color", Color("78dfb7ff")) 
			jane_reaction_text = "Okay naman... pero pwede ko pa pagbutihin."
			
		else: 
			# Needs Improvement (P521+)
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
		
	# 6. FINALLY: Show the Chapter 4 Button!
	if stats_screen: stats_screen.show() 
	
	if next_button:
		next_button.show()
		next_button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		next_button.modulate.a = 0.0
		var btn_tween = create_tween()
		btn_tween.tween_property(next_button, "modulate:a", 1.0, 0.5)
		
		if not next_button.pressed.is_connected(_on_next_pressed):
			next_button.pressed.connect(_on_next_pressed)


func _on_next_pressed() -> void:
	# Use our secret lock instead of disabling the button, so it stays looking normal!
	if is_transitioning: return
	is_transitioning = true 
	
	print("Chapter 1-3 Summary Complete! Transitioning to Chapter 4...")
	
	# 1. Wait 2 seconds after clicking
	await get_tree().create_timer(2.0).timeout
	
	# 2. Fade to black
	await TransitionManager.fade_to_black()
	
	# 3. Transition to Chapter 4 Scene 1
	var next_scene_path = "res://Scenes/Chapter 4/chapter_4_scene_1.tscn" 
	
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
