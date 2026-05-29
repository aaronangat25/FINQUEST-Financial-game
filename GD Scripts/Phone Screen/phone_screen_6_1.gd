extends Control

# --- SIGNALS ---
signal chat_closed 

# --- NODE REFERENCES ---
@onready var scroll_container = $PhoneScreen/ScrollContainer
@onready var chat_container = $PhoneScreen/ScrollContainer/VBoxContainer

@onready var back_texture_button = $PhoneScreen/BackTextureButton
@onready var back_button_child = $PhoneScreen/BackTextureButton/BackButton

const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

var chat_messages = [
	{"sender": "Mami", "text": "Anak, okay ka lang ba?"},
	{"sender": "Jane", "text": "Hindi ko po na-manage nang maayos…"}
]

func _ready() -> void:
	if scroll_container and scroll_container.get_v_scroll_bar():
		scroll_container.get_v_scroll_bar().modulate.a = 0.0 
	
	if chat_container:
		for child in chat_container.get_children():
			child.queue_free()
	
	if back_texture_button:
		back_texture_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not back_texture_button.pressed.is_connected(_on_back_pressed):
			back_texture_button.pressed.connect(_on_back_pressed)
			
	if back_button_child:
		back_button_child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not back_button_child.pressed.is_connected(_on_back_pressed):
			back_button_child.pressed.connect(_on_back_pressed)
		
	_play_chat_sequence()

func _play_chat_sequence() -> void:
	for msg in chat_messages:
		await get_tree().create_timer(4.0).timeout
		_spawn_chat_bubble(msg["text"], msg["sender"] == "Jane")
		await get_tree().create_timer(0.1).timeout
		
		if scroll_container:
			var scrollbar = scroll_container.get_v_scroll_bar()
			if scrollbar:
				var tween = create_tween()
				tween.tween_property(scroll_container, "scroll_vertical", scrollbar.max_value, 0.3)

	if back_texture_button: back_texture_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if back_button_child: back_button_child.mouse_filter = Control.MOUSE_FILTER_STOP
	print("Chat finished! Back button is now clickable.")

func _on_back_pressed() -> void:
	print("BACK BUTTON CLICKED! Direct execution on parent engine initialized...")
	emit_signal("chat_closed")
	
	# --- THE FIX: Call the direct parent function to hide the elements ---
	var main_scene = get_parent()
	if main_scene and main_scene.has_method("hide_elements_for_narration"):
		main_scene.hide_elements_for_narration()
	else:
		# Double-check fallback up the tree stack if instantiated as a nested canvas item
		var main_scene_fallback = get_tree().current_scene
		if main_scene_fallback and main_scene_fallback.has_method("hide_elements_for_narration"):
			main_scene_fallback.hide_elements_for_narration()
	
	# Hide phone view interface instantly
	self.hide()
	self.visible = false
	
	# Trigger narrator text block sequence
	_play_end_narration()

# --- NARRATION ENGINE (FIXED TRANSITION) ---
func _play_end_narration() -> void:
	var active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	
	if "is_fading" in active_dialogue_box:
		active_dialogue_box.is_fading = false
		
	get_parent().add_child(active_dialogue_box)
	
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		active_dialogue_box.show()
		box_visual.modulate.a = 1.0 
	
	var name_panel = active_dialogue_box.find_child("Panel", true, false)
	var name_label = active_dialogue_box.find_child("NameLabel", true, false)
	
	if name_panel:
		name_panel.hide()
		name_panel.visible = false
		name_panel.modulate.a = 0.0
		
	if name_label:
		name_label.hide()
		name_label.visible = false
		name_label.text = ""
		
	var narration_data = [
		{"speaker": "", "text": "Without proper budgeting and financial discipline, even small expenses became overwhelming."},
		{"speaker": "", "text": "Every peso counts. Saving early matters."}
	]
	
	active_dialogue_box.start_dialogue(narration_data)
	await active_dialogue_box.dialogue_finished
	
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 1.0)
		await t_box_out.finished
		
	active_dialogue_box.queue_free()
	
	# 1. Count 2 seconds exactly after text disappears
	await get_tree().create_timer(2.0).timeout
	
	# 2. Smoothly fade into black screen overlay
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	print("Transitioning cleanly to End Choice screen...")
	
	# 3. Switch scene over to game_end_choice.tscn
	var next_scene_path = "res://Scenes/Game End/game_end_cholce.tscn"
	get_tree().change_scene_to_file(next_scene_path)
	
	# --- FIX: We remove the get_tree().root block to prevent the null instance crash! ---
	# The new scene will automatically load with the black screen removed instantly or via its own ready block.
	if TransitionManager.has_method("fade_from_black_instant"):
		TransitionManager.fade_from_black_instant()
	
	queue_free()

func _spawn_chat_bubble(text_content: String, is_jane: bool) -> void:
	if not chat_container: return

	var panel = PanelContainer.new()
	var label = Label.new()
	label.text = text_content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(40, 0) 
	label.add_theme_font_size_override("font_size", 2) 
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.add_theme_constant_override("line_spacing", -2)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_top", 1)
	margin.add_theme_constant_override("margin_bottom", 1)
	margin.add_child(label)
	panel.add_child(margin)
	
	var style = StyleBoxFlat.new()
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	
	if is_jane:
		style.bg_color = Color("a5d68d") 
	else:
		style.bg_color = Color("d3c7a3") 
		
	panel.add_theme_stylebox_override("panel", style)
	
	var wrapper = HBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var stretchy_spacer = Control.new()
	stretchy_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if is_jane:
		wrapper.add_child(stretchy_spacer) 
		wrapper.add_child(panel)
	else:
		wrapper.add_child(panel)
		wrapper.add_child(stretchy_spacer) 
	
	chat_container.add_child(wrapper)
	
	wrapper.pivot_offset = wrapper.size / 2.0
	wrapper.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(wrapper, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
