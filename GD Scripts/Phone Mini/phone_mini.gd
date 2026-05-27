extends CanvasLayer

signal phone_clicked

@onready var phone_body = $phonebody
@onready var texture_button = $phonebody/TextureButton
@onready var phone_normal = $phonebody/TextureButton/phonenormal
@onready var phone_notif = $phonebody/TextureButton/phonenotif

func _ready() -> void:
	phone_body.modulate.a = 0.0
	texture_button.disabled = true
	phone_normal.visible = true
	phone_notif.visible = false
	
	texture_button.pressed.connect(_on_phonenotif_pressed)

func appear() -> void:
	var tween = create_tween()
	tween.tween_property(phone_body, "modulate:a", 1.0, 1.0)

func trigger_notification() -> void:
	phone_normal.visible = false
	phone_notif.visible = true
	texture_button.disabled = false

# When the button is clicked, emit our custom signal
func _on_phonenotif_pressed() -> void:
# Instantly disable the button so it can't be double-clicked
	texture_button.disabled = true
	
	phone_clicked.emit()
