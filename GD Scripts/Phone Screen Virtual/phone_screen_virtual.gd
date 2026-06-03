extends CanvasLayer

signal money_withdrawn(amount: int)
# Signal to tell chapter_1 want to leave 
signal back_clicked 

var is_input_active: bool = false 

@onready var balance_label = $PhoneScreenVirtualControl/VirtualBankScreen/availbalancetextlabel/balancetextlabel
@onready var deposit_button = $PhoneScreenVirtualControl/VirtualBankScreen/DepositTextureButton/depositbutton
@onready var withdraw_button = $PhoneScreenVirtualControl/VirtualBankScreen/WithdrawTextureButton/withdrawbutton
@onready var withdraw_input = $PhoneScreenVirtualControl/VirtualBankScreen/WithdrawInput
@onready var deposit_warning = $PhoneScreenVirtualControl/DepositWarningLabel

@onready var back_button = $PhoneScreenVirtualControl/VirtualBankScreen/BackTextureButton/BackButton

# 🟢 FIXED: Target label inside the gray panel box using quotation marks to escape numeric notation safely
@onready var transaction_log_label = get_node("PhoneScreenVirtualControl/VirtualBankScreen/3kfrommomlabel")

func _ready() -> void:
	# INITIALIZE WITH LIVE DATABASE VALUE		
	_update_balance_text()
	withdraw_input.hide()
	deposit_warning.hide()
	
	# Connect buttons dynamically
	deposit_button.pressed.connect(_on_deposit_button_pressed)
	withdraw_button.pressed.connect(_on_withdraw_button_pressed)
	withdraw_input.text_submitted.connect(_on_withdraw_input_submitted)
	#back_button.pressed.connect(_on_back_button_pressed)
	
	# 🟢 Render the lone single transaction string right on load
	_update_recent_transactions_display()

func _update_balance_text() -> void:
	# Reads value directly from your global GameManager script
	balance_label.text = "P" + str(GameManager.bank_cash) + ".00"

# 🟢 REFRESH TRANSACTION LOG LABELS (DESCRIPTION ONLY - NO PRICING LABELS)
func _update_recent_transactions_display() -> void:
	if not transaction_log_label:
		return
		
	# 1. Check live transient mid-chapter memory buffer first
	var mid_chapter_bank_delta = GameManager.buffered_bank_change
	var mid_chapter_desc = GameManager.current_chapter_description
	
	if mid_chapter_bank_delta != 0:
		# If it's a manual withdrawal button press
		if "Withdrawal" in mid_chapter_desc or "withdrawal" in mid_chapter_desc.to_lower():
			transaction_log_label.text = "You withdrew money"
		else:
			# Shows only the narrative event name text (e.g., "Chapter 1 Cashier Part-Time Training Reward")
			transaction_log_label.text = mid_chapter_desc
		return
		
	# 2. Database Fallback: Load the single latest completed transaction line from SQLite
	var history = DatabaseManager.get_recent_wallet_transactions(GameManager.player_id)
	
	if history.size() > 0:
		var record = history[0]
		var amount_val = record["amount"]
		var description_text = record["description"]
		
		# Fallback direct replacement if it's the baseline Prologue settlement cash row
		if description_text == "BANK_SETTLEMENT" and amount_val == 1500:
			transaction_log_label.text = "You received 1,500 from Mom"
		else:
			if "Withdrawal" in description_text or "withdrawal" in description_text.to_lower():
				transaction_log_label.text = "You withdrew money"
			else:
				# Strictly displays the dynamic record event description string
				transaction_log_label.text = description_text
	else:
		# Clean default display text rule for fresh game states
		transaction_log_label.text = "You received 1,500 from Mom"

# Emit the signal when clicked
func _on_back_button_pressed() -> void:
	back_clicked.emit()

func _on_deposit_button_pressed() -> void:
	deposit_button.disabled = true
	withdraw_button.disabled = true
	back_button.disabled = true # Lock back button
	
	deposit_warning.show()
	await get_tree().create_timer(3.0).timeout
	
	deposit_warning.hide()
	deposit_button.disabled = false
	withdraw_button.disabled = false
	back_button.disabled = false # Unlock back button

# 🟢 FIXED AND SEPARATED ENTIRELY
func _on_withdraw_button_pressed() -> void:
	deposit_button.disabled = true
	withdraw_button.disabled = true
	back_button.disabled = true # Lock back button
	
	withdraw_input.show()
	withdraw_input.grab_focus()
	
	await get_tree().process_frame
	is_input_active = true

func _on_withdraw_input_submitted(text: String) -> void:
	var amount = int(text)
	
	# Checked against GameManager.bank_cash directly
	if amount > 0 and amount <= GameManager.bank_cash:
		
		# Deduct from online bank account via our new architecture function
		# Moves money out of bank account (-amount) and adds it to your sandbox pocket accumulator (+amount)
		GameManager.stage_finance_change(-amount, amount, "Virtual Bank App Withdrawal")
		
		_update_balance_text()
		
		# Update the transaction display instantly to reflect the withdrawal line item!
		_update_recent_transactions_display()
		
		_close_input_and_enable_buttons()
		
		# Triggers chapter_1 listener to visually update her pocket currency HUD layout views!
		money_withdrawn.emit(amount)
	else:
		print("Invalid amount or not enough funds!")
		withdraw_input.text = "" 

func _input(event: InputEvent) -> void:
	if is_input_active and withdraw_input.visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not withdraw_input.get_global_rect().has_point(event.global_position):
			_close_input_and_enable_buttons()

func _close_input_and_enable_buttons() -> void:
	is_input_active = false
	withdraw_input.hide()
	withdraw_input.text = "" 
	
	await get_tree().create_timer(0.1).timeout
	
	deposit_button.disabled = false
	withdraw_button.disabled = false
	back_button.disabled = false # Unlock back button
