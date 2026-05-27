extends Control

# --- SIGNALS ---
signal chat_closed 

# --- NODE REFERENCES ---
@onready var scroll_container = $PhoneScreen/ScrollContainer
@onready var chat_container = $PhoneScreen/ScrollContainer/VBoxContainer

@onready var back_texture_button = $PhoneScreen/BackTextureButton
@onready var back_button_child = $PhoneScreen/BackTextureButton/BackButton

var chat_messages = [
	{"sender": "Mom", "text": "Kamusta ka? Narinig ko tumataas presyo ng pagkain ngayon."},
	{"sender": "Jane", "text": "Oo nga po. Nag-aadjust na ako ng budget ko."},
	{"sender": "Mom", "text": "Good. Learning to manage money during inflation is important."}
]

func _ready() -> void:
	if scroll_container.get_v_scroll_bar():
		scroll_container.get_v_scroll_bar().modulate.a = 0.0 
	
	# Disable buttons initially
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
		
		var scrollbar = scroll_container.get_v_scroll_bar()
		if scrollbar:
			var tween = create_tween()
			tween.tween_property(scroll_container, "scroll_vertical", scrollbar.max_value, 0.3)

	# The chat is done! Unlock the buttons so they can be clicked
	if back_texture_button: back_texture_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if back_button_child: back_button_child.mouse_filter = Control.MOUSE_FILTER_STOP
	print("Chat finished! Back button is now clickable.")

func _on_back_pressed() -> void:
	# VISUAL CONFIRMATION: This will print in the Output panel!
	print("BACK BUTTON CLICKED! Sending signal to main scene...")
	chat_closed.emit()

# --- BUBBLE GENERATOR ---
func _spawn_chat_bubble(text_content: String, is_jane: bool) -> void:
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
	
	# --- NEW: ALIGNMENT FIX ---
	# We put the bubble in a horizontal box with a stretchy spacer
	var wrapper = HBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if is_jane:
		wrapper.add_child(spacer) # Spacer pushes Jane's bubble to the right
		wrapper.add_child(panel)
	else:
		wrapper.add_child(panel)
		wrapper.add_child(spacer) # Spacer pushes Mom's bubble to the left
	
	chat_container.add_child(wrapper)
	
	wrapper.scale = Vector2(0, 0)
	var tween = create_tween()
	tween.tween_property(wrapper, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
