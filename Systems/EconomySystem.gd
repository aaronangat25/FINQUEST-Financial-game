extends Node

# =========================================
# FINQUEST ECONOMY SYSTEM
# =========================================

# =========================================
# ADD MONEY (INCOME REWARDS)
# =========================================
func add_money(amount : int, transaction_type : String = "choice", description : String = "Income Reward"):
	
	GameManager.bank_cash += amount
	GameManager.total_income += amount

	DatabaseManager.add_transaction(
		GameManager.player_id,
		GameManager.current_chapter,
		transaction_type,
		amount,
		description
	)
	print("Money added: ", amount)

# =========================================
# SPEND MONEY (EXPENSES / DEDUCTIONS)
# =========================================
func spend_money(amount : int, transaction_type : String = "choice", description : String = "Expense"):
	
	# Ensure the amount is treated as a clean mathematical deduction
	var deduction = -abs(amount)
	
	GameManager.bank_cash += deduction # Safely reduces cash balance
	GameManager.total_expenses += abs(amount)

	DatabaseManager.add_transaction(
		GameManager.player_id,
		GameManager.current_chapter,
		transaction_type,
		deduction,
		description
	)
	print("Money spent: ", abs(amount))

# =========================================
# UTILITY CHECKS
# =========================================
func can_afford(amount : int) -> bool:
	return GameManager.bank_cash >= amount

func is_bankrupt() -> bool:
	return GameManager.bank_cash <= 0

func get_total_savings() -> int:
	return GameManager.bank_cash

# =========================================
# RECEIVE WEEKLY ALLOWANCE
# =========================================
func receive_allowance(amount : int = 3000):

	add_money(
		amount,
		"allowance",
		"Weekly allowance from parents"
	)

# =========================================
# RECEIVE SALARY
# =========================================
func receive_salary(job_type : String, amount : int):

	add_money(
		amount,
		"salary",
		job_type + " salary"
	)

# =========================================
# TRANSACTION WRAPPERS (WITH AFFORDABILITY CHECK)
# =========================================
func buy_food(food_name : String, cost : int) -> bool:

	if !can_afford(cost):
		print("Not enough money for food.")
		return false

	spend_money(cost, "food", food_name)
	return true

func pay_transport(transport_type : String, cost : int) -> bool:

	if !can_afford(cost):
		print("Not enough money for transport.")
		return false

	spend_money(cost, "transport", transport_type)
	return true

func buy_groceries(grocery_type : String, cost : int) -> bool:

	if !can_afford(cost):
		print("Not enough money for groceries.")
		return false

	spend_money(cost, "grocery", grocery_type)
	return true

func pay_printing(print_type : String, cost : int) -> bool:

	if !can_afford(cost):
		print("Not enough money for thesis printing.")
		return false

	spend_money(cost, "printing", print_type)
	return true

func graduation_expense(package_name : String, cost : int) -> bool:

	if !can_afford(cost):
		print("Not enough money for graduation packages.")
		return false

	spend_money(cost, "celebration", package_name)
	return true

# =========================================
# PENALTY SYSTEM
# =========================================
func apply_penalty(amount : int, reason : String):

	spend_money(
		amount,
		"penalty",
		reason
	)

# =========================================
# GAME MECHANICS (INFLATION & WISDOM)
# =========================================
func apply_inflation(base_price : int, inflation_percent : float) -> int:

	var inflated_price = base_price + (base_price * inflation_percent)
	return int(inflated_price)

func reward_financial_wisdom(points : int):

	GameManager.financial_wisdom_points += points
	print("Financial wisdom added: ", points)

# =========================================
# GET TRANSACTION HISTORY
# =========================================
func get_transaction_history() -> Array:

	DatabaseManager.db.query_with_bindings("""
	SELECT *
	FROM transactions
	WHERE player_id = ?
	ORDER BY created_at DESC;
	""", [
		GameManager.player_id
	])

	return DatabaseManager.db.query_result
