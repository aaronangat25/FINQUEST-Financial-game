extends CanvasLayer

signal bank_app_clicked

@onready var bank_button = $PhoneScreenControl/PhoneScreen/BankTextureButton

func _ready() -> void:
	bank_button.disabled = true
	bank_button.pressed.connect(_on_bank_button_pressed)

func _on_bank_button_pressed() -> void:
	bank_app_clicked.emit()

func unlock_app() -> void:
	bank_button.disabled = false
