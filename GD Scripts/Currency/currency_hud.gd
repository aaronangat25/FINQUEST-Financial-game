extends CanvasLayer

@onready var money_label = $MarginContainer/MoneyPanel/MoneyLabel

var current_money: int = 0 

func _ready():
	if self is CanvasLayer:
		self.layer = 1
	
	# Initial synchronization with the active memory runtime variable
	refresh_display()

func add_money(amount: int):
	# Update active tracking state in memory buffers
	GameManager.on_hand_cash += amount
	
	# Log expenses safely if checking for visual metrics
	if amount < 0:
		GameManager.total_expenses += abs(amount)
		
	# Synchronize display numbers immediately
	refresh_display()

# --- THE REACTIVE SYNCHRONIZATION FIX ---
# This function forces the visual label to pull the absolute latest state
# straight from the Game Manager singleton, regardless of who modified it!
func refresh_display():
	current_money = GameManager.on_hand_cash
	update_ui()

func update_ui():
	if money_label:
		money_label.text = "P" + str(current_money)
