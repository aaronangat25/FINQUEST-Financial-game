extends Control

func _ready() -> void:
	# Hide the feature text initially
	modulate.a = 0.0

# This function plays the whole sequence
func play_feature_intro() -> void:
	# 1. Fade in over 1 second
	var fade_in = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 1.0)
	await fade_in.finished
	
	# 2. Wait exactly 2.0 seconds while it is fully visible
	await get_tree().create_timer(2.0).timeout
	
	# 3. Fade out over 1 second
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 1.0)
	await fade_out.finished
