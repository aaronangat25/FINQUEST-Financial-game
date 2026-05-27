extends Control

# Signal to tell chapter_1 a choice was clicked
signal choice_made(selected_choice: String)

@onready var choice_a = $ChoicesContainer/choiceA_btn
@onready var choice_b = $ChoicesContainer/choiceB_btn
@onready var choice_c = $ChoicesContainer/choiceC_btn

var has_chosen: bool = false

func _ready() -> void:
	modulate.a = 0.0
	hide()
	
	choice_a.pressed.connect(_on_choice_a_pressed)
	choice_b.pressed.connect(_on_choice_b_pressed)
	choice_c.pressed.connect(_on_choice_c_pressed)

func appear() -> void:
	show()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

# Function to fade the choices out smoothly
func exit() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

func _on_choice_a_pressed() -> void:
	_process_choice("A")

func _on_choice_b_pressed() -> void:
	_process_choice("B")

func _on_choice_c_pressed() -> void:
	_process_choice("C")

func _process_choice(selected_choice: String) -> void:
	if has_chosen:
		return
		
	has_chosen = true
	Global.chapter_1_cafe_choice = selected_choice
	print("Saved choice: ", Global.chapter_1_cafe_choice)
	
	choice_made.emit(selected_choice)
