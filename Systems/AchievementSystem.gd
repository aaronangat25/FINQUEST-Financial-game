extends Node

# =========================================
# FINQUEST ACHIEVEMENT SYSTEM
# =========================================

# This system handles:
# - Achievement logic
# - Achievement checking
# - Achievement unlocking
# - Reward notifications

# =========================================
# UNLOCK ACHIEVEMENT
# =========================================

func unlock(achievement_key : String):

	var player_id = GameManager.player_id

	# Prevent duplicate unlocks
	if DatabaseManager.has_achievement(
		player_id,
		achievement_key
	):
		return

	# Unlock achievement
	DatabaseManager.unlock_achievement(
		player_id,
		achievement_key
	)

	print("[ACHIEVEMENT SYSTEM] Achievement unlocked: ", achievement_key)

# =========================================
# CHECK MONEY ACHIEVEMENTS
# =========================================

func check_money_achievements():

	# SAVE ₱5000
	if GameManager.bank_cash >= 5000:

		unlock("SAVE_5000")

# =========================================
# CHECK CHAPTER ACHIEVEMENTS
# =========================================

func check_chapter_achievements(chapter_number : int):

	match chapter_number:

		1:
			unlock("COMPLETE_CHAPTER_1")

# =========================================
# CHECK MINIGAME ACHIEVEMENTS
# =========================================

func check_minigame_achievements():

	var jobs_played = []

	# Check all minigames
	DatabaseManager.db.query_with_bindings("""
	SELECT job_type
	FROM minigame_progress
	WHERE player_id = ?
	AND times_played > 0;
	""", [
		GameManager.player_id
	])

	for row in DatabaseManager.db.query_result:

		jobs_played.append(
			row["job_type"]
		)

	# All jobs played
	if (
		"barista" in jobs_played
		and "cashier" in jobs_played
		and "clerk" in jobs_played
	):

		unlock("PLAY_ALL_JOBS")

# =========================================
# CHECK ENDING ACHIEVEMENTS
# =========================================

func check_ending_achievements():

	unlock("GRADUATE")

# =========================================
# CHECK FIRST SALARY
# =========================================

func check_first_salary(amount : int):

	if amount > 0:

		unlock("FIRST_SALARY")

# =========================================
# GET PLAYER ACHIEVEMENTS
# =========================================

func get_player_achievements():

	return DatabaseManager.get_player_achievements(
		GameManager.player_id
	)

# =========================================
# DEBUG TEST
# =========================================

func debug_unlock_all():

	unlock("FIRST_SALARY")

	unlock("SAVE_5000")

	unlock("COMPLETE_CHAPTER_1")

	unlock("PLAY_ALL_JOBS")

	unlock("GRADUATE")

	print("[ACHIEVEMENT SYSTEM] All achievements unlocked.")
