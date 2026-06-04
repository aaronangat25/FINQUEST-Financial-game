extends CanvasLayer

@onready var color_rect = $blackscreen
@onready var title_label = $TitleLabel

signal transition_finished

# Global safety tracker state tracking flag
var is_transitioning: bool = false

func _ready():
	# CRITICAL: Allow this node to process frames even when the engine is paused!
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	self.layer = 128
	color_rect.hide()
	title_label.hide() # Making sure text is hidden by default
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func transition_to(scene_path: String, title_text: String = "", black_screen_delay: float = 0.0):
	# Lock down pause interactions instantly
	is_transitioning = true
	
	color_rect.show()
	color_rect.color.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Fade to black
	var tween = create_tween()
	# Force tween to process during pause state safely
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(color_rect, "color:a", 1.0, 1.0)
	await tween.finished 
	
	# The Title Text Sequence
	if title_text != "":
		title_label.text = title_text
		title_label.modulate.a = 0.0 
		title_label.show()
		
		var text_tween = create_tween()
		text_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
		text_tween.tween_property(title_label, "modulate:a", 1.0, 0.5) 
		text_tween.tween_interval(1.5) 
		text_tween.tween_property(title_label, "modulate:a", 0.0, 0.5) 
		await text_tween.finished
		
		title_label.hide()
		
	# Hold the black screen if we asked for a delay
	if black_screen_delay > 0.0:
		await get_tree().create_timer(black_screen_delay).timeout
	
	# Swap the scene behind the black screen
	get_tree().change_scene_to_file(scene_path)
	
	# Fade black screen away to reveal the new scene
	var tween2 = create_tween()
	tween2.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween2.tween_property(color_rect, "color:a", 0.0, 1.0)
	await tween2.finished 
	
	color_rect.hide()
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Release transition lock
	is_transitioning = false
	transition_finished.emit()

func fade_to_black():
	is_transitioning = true
	color_rect.color.a = 0.0 
	color_rect.show()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
	await tween.finished

func fade_from_black():
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(color_rect, "color:a", 0.0, 0.5)
	await tween.finished
	
	color_rect.hide()
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
