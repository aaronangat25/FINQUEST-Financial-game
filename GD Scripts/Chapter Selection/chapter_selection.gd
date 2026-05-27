extends Control

const PROLOGUE_SCENE = "res://Scenes/Prologue/prologue.tscn"

@onready var play_btn = $chapter_selection_bg/play_container/play_btn
@onready var next_arrow_btn : Button = $chapter_selection_bg/next_chapter_btn
@onready var back_arrow_btn : Button = $chapter_selection_bg/next_chapter_btn2

func _ready():
	play_btn.pressed.connect(_on_play_btn_pressed)

func _on_play_btn_pressed():
	TransitionManager.transition_to(PROLOGUE_SCENE, "PROLOGUE")
