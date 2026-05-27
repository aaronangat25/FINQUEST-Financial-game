extends Node2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var bubble_sprite = $AnimatedSprite2D2

func _ready():
	modulate.a = 0.0

func appear():
	anim_sprite.play("idle")
	
	bubble_sprite.play("idle") 

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
