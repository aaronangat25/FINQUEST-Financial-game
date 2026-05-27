extends Control

const PROLOGUE_SCENE = "res://Scenes/Prologue/prologue.tscn"

@onready var play_btn = $chapter_selection_bg/current_chapter/play_container/play_btn

func _ready():
	play_btn.pressed.connect(_on_play_btn_pressed)

func _on_play_btn_pressed():
	TransitionManager.transition_to(PROLOGUE_SCENE, "PROLOGUE")
