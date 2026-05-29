extends Node

# =========================================
# FINQUEST SAVE MANAGER
# =========================================

# =========================================
# SAVE GAME
# =========================================

func save_game():
	# --- ADD THIS MASTER LOCK REGULATION LINE ---
	# If the player is in Chapter 1, BLOCK the saving engine from writing 
	# temporary tutorial pocket change into your persistent SQLite rows!
	if GameManager.current_chapter == 1:
		print("[SAVE GUARD] Chapter 1 active. Auto-save rejected to protect sandbox data integrity.")
		return

	# Your original untouched save logic rows continue below safely:
	DatabaseManager.db.query_with_bindings("""
	UPDATE player_stats
	SET
		bank_cash = ?,
		financial_wisdom_points = ?,
		grades = ?,
		current_chapter = ?,
		current_scene = ?,
		total_income = ?,
		total_expenses = ?,
		last_saved = CURRENT_TIMESTAMP
	WHERE player_id = ?;
	""", [
		GameManager.bank_cash,
		GameManager.financial_wisdom_points,
		GameManager.grades,
		GameManager.current_chapter,
		GameManager.current_scene,
		GameManager.total_income,
		GameManager.total_expenses,
		GameManager.player_id
	])

	print("Game saved successfully.")

# =========================================
# LOAD GAME
# =========================================

func load_game() -> bool:

	if !DatabaseManager.save_exists():
		print("No save file found.")
		return false

	var data = DatabaseManager.load_game(1)

	if data.is_empty():
		return false

	var player = data["player"][0]
	var stats = data["stats"][0]

	# PLAYER INFO
	GameManager.player_id = player["id"]
	GameManager.player_name = player["player_name"]
	GameManager.gender = player["gender"]
	GameManager.job_path = player["job_path"]

	# PLAYER STATS
	GameManager.bank_cash = stats["bank_cash"]
	GameManager.financial_wisdom_points = stats["financial_wisdom_points"]
	GameManager.grades = stats["grades"]
	GameManager.current_chapter = stats["current_chapter"]
	GameManager.current_scene = stats["current_scene"]
	GameManager.total_income = stats["total_income"]
	GameManager.total_expenses = stats["total_expenses"]

	print("Game loaded successfully.")
	return true

# =========================================
# AUTO SAVE
# =========================================

func auto_save():

	save_game()
	print("Autosave complete.")

# =========================================
# DELETE SAVE
# =========================================

func delete_save():

	DatabaseManager.delete_save(
		GameManager.player_id
	)

	GameManager.reset_game_data()
	print("Save deleted.")

# =========================================
# SAVE ON APP CLOSE
# =========================================

func _notification(what):

	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		if DatabaseManager.db:
			DatabaseManager.db.close_db()
		get_tree().quit()
