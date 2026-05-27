extends Control

func _ready() -> void:
	# Instantly strip away the black transition screen as soon as this menu initializes
	if TransitionManager.has_method("fade_from_black_instant"):
		TransitionManager.fade_from_black_instant()
	elif TransitionManager.has_method("fade_from_black"):
		TransitionManager.fade_from_black()
