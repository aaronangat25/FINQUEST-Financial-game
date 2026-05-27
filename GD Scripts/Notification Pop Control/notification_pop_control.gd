extends Control

# Get the reference to the hint text node
@onready var hint_click_text = $NotificationPop/hintclicktext

func _ready() -> void:
	# Hide the entire notification control at the start
	modulate.a = 0.0
	
	# Make sure the hint text is specifically hidden so it doesn't fade in yet
	hint_click_text.visible = false

# Call this to fade in the main banner (matches the phone's 1-second fade)
func appear() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

# Call this to show the hint text and make it blink slowly
func show_hint_and_blink() -> void:
	hint_click_text.visible = true
	
	# Create a looping tween for the blinking effect
	var blink_tween = create_tween().set_loops()
	
	# Fade out over 1.0 second, then fade back in over 1.0 second
	blink_tween.tween_property(hint_click_text, "modulate:a", 0.0, 1.0)
	blink_tween.tween_property(hint_click_text, "modulate:a", 1.0, 1.0)
