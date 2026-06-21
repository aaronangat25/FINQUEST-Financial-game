extends Button

# --- CONFIGURATION OPTIONS ---
@export var is_pulse_enabled: bool = true
@export var pulse_scale_multiplier: float = 1.07
@export var pulse_duration: float = 0.3           

var pulse_tween: Tween
var is_user_hovering: bool = false

# --- THE ABSOLUTE FIX: Hard-locked to true on frame zero ---
# This guarantees it is completely silent when the scene starts, no matter what!
var is_conversation_active: bool = true 

func _ready() -> void:
	# 1. Center pivot metrics
	pivot_offset = size / 2.0
	item_rect_changed.connect(func(): pivot_offset = size / 2.0)
	
	# 2. Connect interface signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	# 3. Context check for Chapter 3 Scene 4
	var current_scene_root = get_tree().current_scene
	var scene_file_path = current_scene_root.scene_file_path.to_lower() if current_scene_root else ""
	
	if "scene_4" in scene_file_path:
		# Force block the animation completely during the initialization phase
		is_conversation_active = true
		stop_pulse_animation_instantly()
	else:
		is_conversation_active = false
		if is_pulse_enabled and not disabled:
			start_pulse_animation()


# --- EXTERNAL TRIGGER SIGNAL COMMAND ---
# This is explicitly called ONLY when the absolute final line of text vanishes!
func allow_pulse_after_conversation() -> void:
	is_conversation_active = false
	print("[BUTTON STATUS] Dialogue finished. Starting pulse loop now.")
	if is_pulse_enabled and not disabled and not is_user_hovering:
		start_pulse_animation()


# --- ENGINE PROPERTY SETTER INTERCEPTOR ---
func _set(property: StringName, value: Variant) -> bool:
	if property == &"disabled":
		disabled = value
		if value == true:
			stop_pulse_animation_instantly()
		elif not is_user_hovering and not is_conversation_active:
			start_pulse_animation()
		return true
	return false


# --- PULSING LOOP ENGINE ---
func start_pulse_animation() -> void:
	# If a conversation is active, the pulse is strictly forbidden from playing
	if disabled or not is_pulse_enabled or is_conversation_active: return
	if is_user_hovering or is_pressed(): return
	
	if pulse_tween:
		pulse_tween.kill()
		
	pulse_tween = create_tween().set_loops()
	
	# Phase A: Grow Big
	pulse_tween.tween_property(self, "scale", Vector2(pulse_scale_multiplier, pulse_scale_multiplier), pulse_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# Phase B: Shrink Back
	pulse_tween.tween_property(self, "scale", Vector2.ONE, pulse_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)


func stop_pulse_animation_instantly() -> void:
	if pulse_tween:
		pulse_tween.kill()
	
	var reset_tween = create_tween()
	reset_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)


# --- MOUSE SIGNAL INTERCEPTORS ---
func _on_mouse_entered() -> void:
	is_user_hovering = true
	stop_pulse_animation_instantly()

func _on_mouse_exited() -> void:
	is_user_hovering = false
	if not disabled and not is_pressed() and not is_conversation_active:
		start_pulse_animation()

func _on_button_down() -> void:
	stop_pulse_animation_instantly()

func _on_button_up() -> void:
	if not is_user_hovering and not disabled and not is_conversation_active:
		start_pulse_animation()


func set_button_enabled_state(is_clickable: bool) -> void:
	disabled = !is_clickable
	if is_clickable:
		if not is_user_hovering and not is_conversation_active:
			start_pulse_animation()
	else:
		stop_pulse_animation_instantly()
