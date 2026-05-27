extends Node2D

@onready var anim_sprite = $AnimatedSprite2D
var is_on_screen: bool = false

func _ready():
	# Start completely invisible so the cinematic transitions work
	modulate.a = 0.0

# --- Function to fade the character in ---
func appear(anim_name: String = "idle", instant: bool = false):
	# Play whatever animation is requested (defaults to "idle")
	if anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)
		
	if not is_on_screen:
		is_on_screen = true
		
		if instant:
			modulate.a = 1.0 # Instantly snap to visible
		else:
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 1.0, 0.5) # Smooth 0.5s fade in

# --- Function to fade the character out ---
func exit(fade: bool = false):
	if is_on_screen:
		is_on_screen = false
		
		if fade == true:
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.5) # Smooth 0.5s fade out
		else:
			modulate.a = 0.0 # Instantly snap to invisible
