extends CanvasLayer

@onready var money_label = $MarginContainer/MoneyPanel/MoneyLabel

var current_money: int = 0 

func _ready():
	# Force the HUD to stay on the bottom layer
	if self is CanvasLayer:
		self.layer = 1
	
	# When the HUD spawns immediately grab the saved money from the Global bank
	current_money = Global.player_money
	update_ui()

func add_money(amount: int):
	# Update the current money
	current_money += amount
	
	# Save the new amount back to the Global bank
	Global.player_money = current_money
	
	# If the amount is negative (meaning Jane spent money), add it to expenses!
	if amount < 0:
		Global.total_expenses += abs(amount) 
		
	# Update the UI
	update_ui()

func update_ui():
	money_label.text = "P" + str(current_money)
	
	
