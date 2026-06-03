extends CanvasLayer

# --- NODE REFERENCES ---
@onready var panel = $Panel
@onready var cancel_btn = $Panel/menu_button_container/cancel_btn
@onready var real_quit_btn = $Panel/menu_button_container/quit_btn

func _ready() -> void:
	# Hide the overlay menu entirely on game launch frame
	hide()
	
	# Connect our UI interaction elements safely
	if cancel_btn and not cancel_btn.pressed.is_connected(_on_cancel_btn_pressed):
		cancel_btn.pressed.connect(_on_cancel_btn_pressed)
		
	if real_quit_btn and not real_quit_btn.pressed.is_connected(_on_quit_btn_pressed):
		real_quit_btn.pressed.connect(_on_quit_btn_pressed)


# --- INPUT INTERCEPTOR ENGINE ---
func _input(event: InputEvent) -> void:
	# Listens globally for Android/Mobile device hardware back navigation buttons
	# 'go_back' or standard 'ui_cancel' map action triggers
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("go_back"):
		# If it's already visible, pressing back can act as a cancel toggle
		if visible:
			_on_cancel_btn_pressed()
		else:
			_show_quit_confirmation()
			
		# Consume the input event frame so other menu overlays don't catch it
		get_viewport().set_input_as_handled()


# --- DISPLAY CONTROLLERS ---
func _show_quit_confirmation() -> void:
	# --- FIXED: Instantly appears without any scale or zoom tweening ---
	show()


func _on_cancel_btn_pressed() -> void:
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("CLICK") 
		
	hide()


func _on_quit_btn_pressed() -> void:
	print("Quit confirmed! Tearing down execution tree...")
	# Safely terminates the Godot engine process loop
	get_tree().quit()
