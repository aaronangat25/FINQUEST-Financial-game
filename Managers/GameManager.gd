extends Node

# =========================================
# FINQUEST GAME MANAGER
# =========================================

# ACTIVE PLAYER DATA
var player_id : int = 1
var player_name : String = ""
var gender : String = ""
var job_path : String = ""

# PLAYER STATS
var bank_cash : int = 3000
var financial_wisdom_points : int = 0
var grades : float = 0.0

# GAME PROGRESSION
var current_chapter : int = 1         # 1 = Prologue, 2 = Chapter 1, 3 = Chapter 2, etc.
var current_scene : String = ""

# GAME TOTALS
var total_income : int = 0
var total_expenses : int = 0

# =========================================
# START NEW GAME
# =========================================
func start_new_game(new_player_name : String, new_gender : String, new_job_path : String):

	player_id = DatabaseManager.create_player(
		new_player_name,
		new_gender,
		new_job_path
	)

	player_name = new_player_name
	gender = new_gender
	job_path = new_job_path

	load_player_stats()
	print("New game started.")

# =========================================
# LOAD PLAYER STATS
# =========================================
func load_player_stats():

	# --- FIXED: Pulled split-line query together to prevent compiler panic ---
	var result = DatabaseManager.get_player_stats(player_id)

	if result.size() <= 0:
		return

	var stats = result[0]
	bank_cash = stats["bank_cash"]
	financial_wisdom_points = stats["financial_wisdom_points"]
	grades = stats["grades"]
	current_chapter = stats["current_chapter"]
	current_scene = stats["current_scene"]
	total_income = stats["total_income"]
	total_expenses = stats["total_expenses"]

	print("Player stats loaded.")

# =========================================
# GET UNLOCKED CHAPTERS FROM DB
# =========================================
func get_unlocked_chapters() -> Array:

	# Query the database to find all chapters marked as unlocked for the active player
	DatabaseManager.db.query_with_bindings("""
		SELECT chapter_number 
		FROM chapter_progress 
		WHERE player_id = ? AND is_unlocked = 1;
	""", [player_id])
	
	var unlocked_list = []
	for row in DatabaseManager.db.query_result:
		unlocked_list.append(int(row["chapter_number"]))
		
	return unlocked_list
	
	
# =========================================
# ADD FINANCIAL WISDOM
# =========================================
func add_financial_wisdom(points : int):

	financial_wisdom_points += points

# =========================================
# CHANGE SCENE
# =========================================
func set_current_scene(scene_name : String):

	current_scene = scene_name

# =========================================
# COMPLETE CHAPTER
# =========================================
func complete_current_chapter(grade : float):

	grades = grade

	# 1. Updates current chapter row to completed, and sets the next row to unlocked in SQLite
	DatabaseManager.complete_chapter(
		player_id,
		current_chapter,
		grade
	)

	# 2. Advance the local runtime progress variable
	current_chapter += 1
	
	# 3. Synchronize player_stats record with the new active progression step
	DatabaseManager.db.query_with_bindings("""
		UPDATE player_stats
		SET current_chapter = ?
		WHERE player_id = ?;
	""", [current_chapter, player_id])

	print("Chapter completed. Next available chapter: ", current_chapter)

# =========================================
# RESET GAME DATA
# =========================================
func reset_game_data():

	player_id = 1
	player_name = ""
	gender = ""
	job_path = ""
	bank_cash = 3000
	financial_wisdom_points = 0
	grades = 0.0
	current_chapter = 1
	current_scene = ""
	total_income = 0
	total_expenses = 0
