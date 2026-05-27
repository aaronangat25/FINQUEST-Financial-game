extends Node2D

@onready var anim_sprite = $AnimatedSprite2D
var is_on_screen: bool = false

func _ready():
	modulate.a = 0.0

func appear(anim_name: String = "idle", instant: bool = false):
	if anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)
		
	if not is_on_screen:
		is_on_screen = true
		
		if instant:
			modulate.a = 1.0 
		else:
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 1.0, 0.5) 

# fade Leo out 
func exit(fade: bool = false):
	if is_on_screen:
		is_on_screen = false
		
		if fade == true:
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.5) 
		else:
			modulate.a = 0.0 
