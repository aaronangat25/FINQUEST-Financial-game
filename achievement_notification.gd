extends CanvasLayer

# --- UPDATED INTERNAL REFERENCE ---
@onready var achievement_banner: Panel = $AchievementBanner

func _ready() -> void:
	# Tuck it tightly out of bounds above the screen boundary on creation
	if achievement_banner:
		achievement_banner.position.y = -200
	else:
		print("[ERROR] Cannot find AchievementBanner node! Check hierarchy names.")

func trigger_popup(image_path: String) -> void:
	if achievement_banner == null:
		return
		
	var texture_asset = load(image_path)
	if not texture_asset:
		print("[ERROR] Achievement asset file not found at: ", image_path)
		return

	# 1. Assign the texture style to the panel background
	var new_style = StyleBoxTexture.new()
	new_style.texture = texture_asset
	achievement_banner.add_theme_stylebox_override("panel", new_style)

	# 2. Setup the animation tween
	var tween = create_tween().set_parallel(false)
	
	# --- FIXED SLIDE TARGET POSITION ---
	# Changed from 40 down to 10 or 15. This forces the banner to stay tightly 
	# at the very top boundary of the viewport screen.
	tween.tween_property(achievement_banner, "position:y", 12, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	# Keep it visible on screen for 2.5 seconds
	tween.tween_interval(4.5)
	
	# Slide Up back out of view completely (Y: -200)
	tween.tween_property(achievement_banner, "position:y", -200, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	# Clear the instance from memory completely when finished
	tween.finished.connect(queue_free)
