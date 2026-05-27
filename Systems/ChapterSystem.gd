extends Node

# =========================================
# FINQUEST CHAPTER SYSTEM
# =========================================

# =========================================
# GET CURRENT CHAPTER
# =========================================
func get_current_chapter() -> int:

	return GameManager.current_chapter

# =========================================
# UNLOCK NEXT CHAPTER
# =========================================
func unlock_next_chapter():

	var next_chapter = GameManager.current_chapter + 1

	DatabaseManager.db.query_with_bindings("""
	UPDATE chapter_progress
	SET is_unlocked = 1
	WHERE player_id = ?
	AND chapter_number = ?;
	""", [
		GameManager.player_id,
		next_chapter
	])

	print("Chapter unlocked: ", next_chapter)

# =========================================
# COMPLETE CURRENT CHAPTER
# =========================================
func complete_current_chapter(grade : float):

	var current_chapter = GameManager.current_chapter

	# 1. Update GameManager stats cache memory values
	GameManager.grades = grade

	# 2. Mark completed inside localized DB table index
	DatabaseManager.complete_chapter(
		GameManager.player_id,
		current_chapter,
		grade
	)

	# 3. Safe-unlock the next step block
	unlock_next_chapter()

	# --- FIXED: Double-increment risk managed. GameManager.current_chapter ---
	# --- is already incremented safely inside DatabaseManager.complete_chapter ---
	print("Chapter ", current_chapter, " completed with grade: ", grade)

	# 4. Save state tracking to disk profile
	SaveManager.auto_save()

# =========================================
# CHECK IF CHAPTER IS UNLOCKED
# =========================================
func is_chapter_unlocked(chapter_number : int) -> bool:

	DatabaseManager.db.query_with_bindings("""
	SELECT is_unlocked
	FROM chapter_progress
	WHERE player_id = ?
	AND chapter_number = ?;
	""", [
		GameManager.player_id,
		chapter_number
	])

	if DatabaseManager.db.query_result.size() <= 0:
		return false

	return DatabaseManager.db.query_result[0]["is_unlocked"] == 1

# =========================================
# CHECK IF CHAPTER IS COMPLETED
# =========================================
func is_chapter_completed(chapter_number : int) -> bool:

	DatabaseManager.db.query_with_bindings("""
	SELECT is_completed
	FROM chapter_progress
	WHERE player_id = ?
	AND chapter_number = ?;
	""", [
		GameManager.player_id,
		chapter_number
	])

	if DatabaseManager.db.query_result.size() <= 0:
		return false

	return DatabaseManager.db.query_result[0]["is_completed"] == 1

# =========================================
# REQUIREMENT: CHAPTER 2 NEEDS 3 MINIGAMES
# =========================================
func can_unlock_chapter_2() -> bool:

	DatabaseManager.db.query_with_bindings("""
	SELECT SUM(times_played) as total
	FROM minigame_progress
	WHERE player_id = ?;
	""", [
		GameManager.player_id
	])

	var result = DatabaseManager.db.query_result

	if result.size() <= 0:
		return false

	var total = result[0]["total"]

	if total == null:
		total = 0

	return total >= 3

# =========================================
# TRY UNLOCK CHAPTER 2
# =========================================
func try_unlock_chapter_2():

	if can_unlock_chapter_2():
		DatabaseManager.db.query_with_bindings("""
		UPDATE chapter_progress
		SET is_unlocked = 1
		WHERE player_id = ?
		AND chapter_number = 2;
		""", [
			GameManager.player_id
		])
		print("Chapter 2 unlocked safely matching requirement thresholds.")

# =========================================
# GET ALL CHAPTER DATA
# =========================================
func get_all_chapter_progress() -> Array:

	DatabaseManager.db.query_with_bindings("""
	SELECT *
	FROM chapter_progress
	WHERE player_id = ?;
	""", [
		GameManager.player_id
	])

	return DatabaseManager.db.query_result
