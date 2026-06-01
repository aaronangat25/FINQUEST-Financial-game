extends CanvasLayer

# --- PRELOADED SCENES ---
const PHONE_VIRTUAL_SCENE = preload("res://Scenes/Phone Screen Virtual/phone_screen_virtual.tscn")

# --- NODE REFERENCES ---
@onready var money_label = $MarginContainer/MoneyPanel/MoneyLabel
@onready var withdraw_btn = $withdraw_btn

var current_money: int = 0 
var active_phone_instance: Node = null

func _ready():
	if self is CanvasLayer:
		self.layer = 1
	
	# Initial synchronization with the active memory runtime variable
	refresh_display()
	
	# --- PROLOGUE AUTOMATIC HIDE CHECK ---
	if withdraw_btn:
		if "current_chapter" in GameManager and GameManager.current_chapter == 1:
			withdraw_btn.hide()
		else:
			withdraw_btn.show()
			if not withdraw_btn.pressed.is_connected(_on_withdraw_btn_pressed):
				withdraw_btn.pressed.connect(_on_withdraw_btn_pressed)


func add_money(amount: int):
	# Update active tracking state in memory buffers
	GameManager.on_hand_cash += amount
	
	# Log expenses safely if checking for visual metrics
	if amount < 0:
		GameManager.total_expenses += abs(amount)
		
	# Synchronize display numbers immediately
	refresh_display()


# --- THE REACTIVE SYNCHRONIZATION FIX ---
func refresh_display():
	current_money = GameManager.on_hand_cash
	update_ui()


func update_ui():
	if money_label:
		money_label.text = "P" + str(current_money)


# --- WITHDRAW CLICK INTERACTION ---
func _on_withdraw_btn_pressed() -> void:
	if is_instance_valid(active_phone_instance):
		return

	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("CLICK")
		
	print("[BANK INTERFACE] Spawning Virtual Bank Screen overlay...")
	
	active_phone_instance = PHONE_VIRTUAL_SCENE.instantiate()
	get_tree().current_scene.add_child(active_phone_instance)
	
	# --- VISUAL LAYER PRIORITY SORTING ---
	if active_phone_instance is CanvasLayer:
		active_phone_instance.layer = self.layer + 10
	elif active_phone_instance is Control:
		active_phone_instance.z_index = 100
		active_phone_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# --- 🟢 THE MID-CHAPTER WALLET UPDATE FIX ---
	# Connect to the custom signal emitted by your virtual phone script on a successful transaction
	if active_phone_instance.has_signal("money_withdrawn"):
		if not active_phone_instance.money_withdrawn.is_connected(_on_phone_money_withdrawn):
			active_phone_instance.money_withdrawn.connect(_on_phone_money_withdrawn)

	# --- BACK BUTTON AUTO-WIRING ---
	var back_btn = active_phone_instance.find_child("BackButton", true, false)
	if back_btn:
		if not back_btn.pressed.is_connected(_on_phone_cancel_pressed):
			back_btn.pressed.connect(_on_phone_cancel_pressed)


# --- SIGNAL CAPTURE LOOP ---
func _on_phone_money_withdrawn(_amount: int) -> void:
	print("[HUD REPAINT] Withdrawal registered mid-chapter. Syncing memory registers with UI views.")
	# Pulls the newly updated on_hand_cash value from GameManager and pushes it to your text label instantly!
	refresh_display()


# --- CANCEL INTERACTION WORKFLOW ---
func _on_phone_cancel_pressed() -> void:
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("CLICK")
		
	print("[BANK INTERFACE] Closing interface safely. Dropping asset allocations...")
	
	if is_instance_valid(active_phone_instance):
		active_phone_instance.queue_free()
		active_phone_instance = null
