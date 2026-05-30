extends CanvasLayer

signal line_started(line_data: Dictionary)
signal line_finished(line_data: Dictionary)
signal dialogue_finished

var current_line_data: Dictionary = {}

@onready var main_container = $MarginContainer
@onready var text_label = $MarginContainer/texturerectContainer/TextLabel
@onready var indicator = $MarginContainer/texturerectContainer/Indicator

@onready var name_box = $MarginContainer/texturerectContainer/Panel
@onready var name_label = $MarginContainer/texturerectContainer/Panel/NameLabel

var dialogue_queue: Array = []
var is_typing: bool = false
var active_tween: Tween
var blink_tween: Tween 
var click_cooldown: bool = false

# lock to protect the fade animation
var is_fading: bool = false 

func _ready():
	hide()
	indicator.hide()

func start_dialogue(queue: Array, fade_duration: float = 0.0):
	dialogue_queue = queue
	
	$MarginContainer/texturerectContainer.modulate.a = 1.0
	indicator.hide()
	if blink_tween:
		blink_tween.kill()
	
	if not dialogue_queue.is_empty():
		var first_speaker = dialogue_queue[0]["speaker"].strip_edges()
		
		if first_speaker == "":
			name_box.hide()
		else:
			name_box.show()
			name_label.text = first_speaker
			
		text_label.text = "" 
	
	if fade_duration > 0.0:
		is_fading = true 
		main_container.modulate.a = 0.0 
		show()
		
		var fade_tween = create_tween()
		fade_tween.tween_property(main_container, "modulate:a", 1.0, fade_duration)
		await fade_tween.finished 
		is_fading = false 
	else:
		main_container.modulate.a = 1.0
		show()
		
	next_line()

func next_line():
	if dialogue_queue.is_empty():
		dialogue_finished.emit() 
		
		await get_tree().create_timer(0.6).timeout
		
		var tween = create_tween()
		tween.tween_property($MarginContainer/texturerectContainer, "modulate:a", 0.0, 0.5)
		await tween.finished
		
		hide()
		return
	
	var current_line = dialogue_queue.pop_front()
	current_line_data = current_line
	
	line_started.emit(current_line)
	var speaker = current_line["speaker"].strip_edges() 
	var text = current_line["text"]
	
	if blink_tween:
		blink_tween.kill()
	indicator.hide()
	indicator.modulate.a = 1.0 
	
	if speaker == "":
		name_box.hide() 
	else:
		name_box.show() 
		name_label.text = speaker 
	
	text_label.text = text
	text_label.visible_characters = 0
	is_typing = true
	
	if active_tween:
		active_tween.kill()
		
	active_tween = create_tween()
	var typing_speed = text.length() * 0.04
	active_tween.tween_property(text_label, "visible_characters", text.length(), typing_speed)
	active_tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	indicator.text = "▶"
	indicator.show()
	
	line_finished.emit(current_line_data)
	
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(indicator, "modulate:a", 0.0, 1) 
	blink_tween.tween_property(indicator, "modulate:a", 1.0, 1.5) 

func _input(event):
	if visible and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# IF FADING OR ON COOLDOWN, COMPLETELY IGNORE THE CLICK
		if is_fading or click_cooldown:
			return 
			
		# --- DIALOGUE CLICK AUDIO TRIGGER ---
		# Fires the crisp menu click sound effect for text navigation instantly
		AudioManager.play_sfx("CLICK")
			
		if is_typing:
			if active_tween:
				active_tween.kill()
			text_label.visible_characters = -1 
			_on_typing_finished()
		else:
			next_line()
			
		click_cooldown = true
		await get_tree().create_timer(1.0).timeout
		click_cooldown = false
