extends Node

# =========================================
# FINQUEST ENDING SYSTEM
# =========================================

# ENDING TYPES
const BANKRUPT = "bankrupt"
const DROPOUT = "dropout"
const UNEMPLOYED = "unemployed"
const OFFICE_WORKER = "office_worker"
const BUSINESS_OWNER = "business_owner"

# =========================================
# CALCULATE FINAL ENDING
# =========================================
func calculate_ending() -> String:

	var money = GameManager.bank_cash
	var wisdom = GameManager.financial_wisdom_points
	var grades = GameManager.grades

	# 1. Bankrupt Ending
	if money <= 0:
		save_ending(BANKRUPT)
		return BANKRUPT

	# 2. Dropout Ending
	if money <= 500 and grades >= 3.00:
		save_ending(DROPOUT)
		return DROPOUT

	# 3. Business Owner Ending
	if wisdom >= 80 and money >= 5000:
		save_ending(BUSINESS_OWNER)
		return BUSINESS_OWNER

	# 4. Office Worker Ending
	if money >= 1500 and grades <= 1.50:
		save_ending(OFFICE_WORKER)
		return OFFICE_WORKER

	# 5. Default Ending
	save_ending(UNEMPLOYED)
	return UNEMPLOYED

# =========================================
# SAVE ENDING RESULT
# =========================================
func save_ending(ending_type : String):

	DatabaseManager.db.query_with_bindings("""
	INSERT INTO ending_results (
		player_id,
		ending_type,
		final_money,
		final_grade,
		financial_wisdom_points
	)
	VALUES (?, ?, ?, ?, ?);
	""", [
		GameManager.player_id,
		ending_type,
		GameManager.bank_cash,
		GameManager.grades,
		GameManager.financial_wisdom_points
	])

	print("Ending saved successfully to user database log matrix: ", ending_type)

# =========================================
# GET ENDING DESCRIPTION
# =========================================
func get_ending_description(ending_type : String) -> String:

	match ending_type:
		BANKRUPT:
			return "Ubos ang ipon."
		DROPOUT:
			return "Hindi kinaya ang tuition."
		UNEMPLOYED:
			return "Graduate but unemployed."
		OFFICE_WORKER:
			return "Stable office worker life."
		BUSINESS_OWNER:
			return "Successful business owner."

	return "Unknown ending."

# =========================================
# CHECK IF PLAYER WON (SAFE FROM DOUBLE DATABASE SAVES)
# =========================================
func is_good_ending() -> bool:

	# --- FIXED: Read variable status caches straight from memory to ---
	# --- prevent duplicate data insertion rows during calculations ---
	var money = GameManager.bank_cash
	var wisdom = GameManager.financial_wisdom_points

	return wisdom >= 80 and money >= 5000
