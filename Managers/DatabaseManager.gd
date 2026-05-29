extends Node

# =========================================
# FINQUEST DATABASE MANAGER
# Godot 4 + SQLite
# =========================================

# IMPORTANT:
# Install SQLite Plugin First
# Recommended:
# https://github.com/2shady4u/godot-sqlite

# =========================================
# SETUP
# =========================================

var db : SQLite

const DB_NAME = "user://finquest.db"

# =========================================
# GODOT READY
# =========================================

func _ready():
	initialize_database()

# =========================================
# INITIALIZE DATABASE
# =========================================

func initialize_database():

	db = SQLite.new()
	db.path = DB_NAME

	# Open database
	if db.open_db():
		print("[DATABASE] Connected successfully using standard stable plugin structures.")
		create_tables()
		create_default_achievements()
	else:
		print("[DATABASE ERROR] Failed to connect database.")

# =========================================
# CREATE TABLES
# =========================================

func create_tables():

	# =========================================
	# PLAYERS
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS players (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_name TEXT NOT NULL,
		gender TEXT NOT NULL,
		job_path TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	""")

	# =========================================
	# PLAYER STATS
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS player_stats (
		player_id INTEGER PRIMARY KEY,
		bank_cash INTEGER DEFAULT 0, -- CHANGED FROM 3000 TO 0
		on_hand_cash INTEGER DEFAULT 0,
		financial_wisdom_points INTEGER DEFAULT 0,
		grades REAL DEFAULT 0,
		current_chapter INTEGER DEFAULT 1,
		current_scene TEXT,
		total_income INTEGER DEFAULT 0,
		total_expenses INTEGER DEFAULT 0,
		play_time INTEGER DEFAULT 0,
		last_saved DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (player_id) REFERENCES players(id)
	);
	""")

	# =========================================
	# CHAPTER PROGRESS
	# =========================================
	# --- MASTER UNIQUE CONSTRAINT FIX ---
	# UNIQUE(player_id, chapter_number) ON CONFLICT IGNORE forces SQLite to block
	# duplicate chapter entries completely when direct scene testing (F5)!
	# Added DEFAULT 0.0 to completion_grade to safely support the functional SIS app tracking.
	db.query("""
	CREATE TABLE IF NOT EXISTS chapter_progress (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		chapter_number INTEGER NOT NULL,
		is_unlocked INTEGER DEFAULT 0,
		is_completed INTEGER DEFAULT 0,
		completion_grade REAL DEFAULT 0.0,
		completed_at DATETIME,
		FOREIGN KEY (player_id) REFERENCES players(id),
		UNIQUE(player_id, chapter_number) ON CONFLICT IGNORE
	);
	""")

	# =========================================
	# TRANSACTIONS
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS transactions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		chapter_number INTEGER,
		transaction_type TEXT NOT NULL,
		amount INTEGER NOT NULL,
		balance_after INTEGER,
		description TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (player_id) REFERENCES players(id)
	);
	""")

	# =========================================
	# PLAYER CHOICES
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS player_choices (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		chapter_number INTEGER NOT NULL,
		scene_key TEXT NOT NULL,
		choice_key TEXT NOT NULL,
		choice_value TEXT NOT NULL,
		effect_summary TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (player_id) REFERENCES players(id)
	);
	""")

	# =========================================
	# MINIGAME PROGRESS
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS minigame_progress (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		job_type TEXT NOT NULL,
		times_played INTEGER DEFAULT 0,
		highest_score INTEGER DEFAULT 0,
		average_score REAL DEFAULT 0,
		total_earnings INTEGER DEFAULT 0,
		last_played DATETIME,
		is_unlocked INTEGER DEFAULT 0,
		FOREIGN KEY (player_id) REFERENCES players(id)
	);
	""")

	# =========================================
	# ENDING RESULTS
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS ending_results (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		ending_type TEXT NOT NULL,
		final_money INTEGER,
		final_grade REAL,
		financial_wisdom_points INTEGER,
		achieved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (player_id) REFERENCES players(id)
	);
	""")

	# =========================================
	# ACHIEVEMENTS
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS achievements (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		achievement_key TEXT UNIQUE,
		title TEXT NOT NULL,
		description TEXT,
		reward_money INTEGER DEFAULT 0
	);
	""")

	# =========================================
	# PLAYER ACHIEVEMENTS
	# =========================================
	db.query("""
	CREATE TABLE IF NOT EXISTS player_achievements (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_id INTEGER NOT NULL,
		achievement_id INTEGER NOT NULL,
		unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (player_id) REFERENCES players(id),
		FOREIGN KEY (achievement_id) REFERENCES achievements(id)
	);
	""")

	print("[DATABASE] All database tables initialized.")

# =========================================
# CREATE DEFAULT ACHIEVEMENTS
# =========================================

func create_default_achievements():

	var achievements = [
		{
			"key": "FIRST_SALARY",
			"title": "First Salary",
			"description": "Earn your first income.",
			"reward": 100
		},
		{
			"key": "SAVE_5000",
			"title": "Saver",
			"description": "Reach ₱5000 savings.",
			"reward": 500
		},
		{
			"key": "COMPLETE_CHAPTER_1",
			"title": "Chapter 1 Complete",
			"description": "Finish Chapter 1.",
			"reward": 300
		},
		{
			"key": "PLAY_ALL_JOBS",
			"title": "Working Student",
			"description": "Play all minigames.",
			"reward": 500
		},
		{
			"key": "GRADUATE",
			"title": "Graduate",
			"description": "Finish the game.",
			"reward": 1000
		}
	]

	for achievement in achievements:
		db.query_with_bindings("""
		INSERT OR IGNORE INTO achievements (
			achievement_key,
			title,
			description,
			reward_money
		)
		VALUES (?, ?, ?, ?);
		""", [
			achievement["key"],
			achievement["title"],
			achievement["description"],
			achievement["reward"]
		])

	print("[DATABASE] Default achievements initialized.")

# =========================================
# CREATE NEW PLAYER
# =========================================

func create_player(player_name : String, gender : String, job_path : String):

	# Insert player
	db.query_with_bindings("""
	INSERT INTO players (
		player_name,
		gender,
		job_path
	)
	VALUES (?, ?, ?);
	""", [
		player_name,
		gender,
		job_path
	])

	# Get inserted player ID
	var player_id = db.last_insert_rowid

	# Create default player data records
	create_default_player_stats(player_id)
	create_default_chapter_progress(player_id)
	create_default_minigame_progress(player_id)

	print("[DATABASE] Player created successfully.")
	return player_id

# =========================================
# DEFAULT PLAYER STATS
# =========================================

func create_default_player_stats(player_id : int):

	db.query_with_bindings("""
	INSERT INTO player_stats (
		player_id
	)
	VALUES (?);
	""", [
		player_id
	])

# =========================================
# DEFAULT CHAPTER PROGRESS
# =========================================

# =========================================
# DEFAULT CHAPTER PROGRESS (FIXED RANGE)
# =========================================
func create_default_chapter_progress(player_id : int):
	# Loop from 1 to 7 (range(1, 8) stops right before 8)
	for chapter in range(1, 8):
		var unlocked = 0
		if chapter == 1:
			unlocked = 1 # Prologue is the only one unlocked initially

		db.query_with_bindings("""
		INSERT INTO chapter_progress (
			player_id,
			chapter_number,
			is_unlocked,
			is_completed,
			completion_grade
		)
		VALUES (?, ?, ?, ?, 0.0);
		""", [
			player_id,
			chapter,
			unlocked,
			0
		])
	print("[DATABASE] Default chapter progress records (1 to 7) generated.")

# =========================================
# DEFAULT MINIGAME DATA
# =========================================

func create_default_minigame_progress(player_id : int):

	var jobs = [
		"barista",
		"cashier",
		"clerk"
	]

	for job in jobs:
		db.query_with_bindings("""
		INSERT INTO minigame_progress (
			player_id,
			job_type,
			is_unlocked
		)
		VALUES (?, ?, ?);
		""", [
			player_id,
			job,
			0
		])

# =========================================
# GET PLAYER STATS
# =========================================

func get_player_stats(player_id : int):

	db.query_with_bindings("""
	SELECT *
	FROM player_stats
	WHERE player_id = ?;
	""", [
		player_id
	])

	return db.query_result

# =========================================
# UPDATE PLAYER MONEY
# =========================================

func update_player_money(player_id : int, amount : int):

	var current_balance = get_player_balance(player_id)
	var new_balance = current_balance + amount

	db.query_with_bindings("""
	UPDATE player_stats
	SET bank_cash = ?
	WHERE player_id = ?;
	""", [
		new_balance,
		player_id
	])

# =========================================
# GET PLAYER BALANCE
# =========================================

func get_player_balance(player_id : int):

	db.query_with_bindings("""
	SELECT bank_cash
	FROM player_stats
	WHERE player_id = ?;
	""", [
		player_id
	])

	if db.query_result.size() > 0:
		return db.query_result[0]["bank_cash"]

	return 0

# =========================================
# ADD TRANSACTION
# =========================================

func add_transaction(player_id : int, chapter_number : int, transaction_type : String, amount : int, description : String):

	var current_balance = get_player_balance(player_id)
	var new_balance = current_balance + amount

	update_player_money(player_id, amount)

	db.query_with_bindings("""
	INSERT INTO transactions (
		player_id,
		chapter_number,
		transaction_type,
		amount,
		balance_after,
		description
	)
	VALUES (?, ?, ?, ?, ?, ?);
	""", [
		player_id,
		chapter_number,
		transaction_type,
		amount,
		new_balance,
		description
	])

# =========================================
# SAVE PLAYER CHOICE
# =========================================

func save_player_choice(player_id : int, chapter_number : int, scene_key : String, choice_key : String, choice_value : String, effect_summary : String):

	db.query_with_bindings("""
	INSERT INTO player_choices (
		player_id,
		chapter_number,
		scene_key,
		choice_key,
		choice_value,
		effect_summary
	)
	VALUES (?, ?, ?, ?, ?, ?);
	""", [
		player_id,
		chapter_number,
		scene_key,
		choice_key,
		choice_value,
		effect_summary
	])

# =========================================
# COMPLETE CHAPTER
# =========================================

func complete_chapter(player_id : int, chapter_number : int, grade : float):
	# 1. Marks current chapter (e.g., Prologue = 1) as completed
	# CHANGED: Added casting constraint logic to match your architecture safely.
	db.query_with_bindings("""
	UPDATE chapter_progress
	SET is_completed = 1, completion_grade = ?, completed_at = CURRENT_TIMESTAMP
	WHERE player_id = ? AND chapter_number = ?;
	""", [float(grade), player_id, chapter_number])

	# 2. Instantly unlocks the NEXT sequential record row (e.g., Chapter 1 = 2)
	db.query_with_bindings("""
	UPDATE chapter_progress
	SET is_unlocked = 1
	WHERE player_id = ? AND chapter_number = ?;
	""", [player_id, chapter_number + 1])

# =========================================
# SAVE GAME
# =========================================

func save_game(player_id : int, current_scene : String):

	db.query_with_bindings("""
	UPDATE player_stats
	SET
		current_scene = ?,
		last_saved = CURRENT_TIMESTAMP
	WHERE player_id = ?;
	""", [
		current_scene,
		player_id
	])

	print("[SAVE] Game saved successfully.")

# =========================================
# LOAD GAME
# =========================================

func load_game(player_id : int):

	var player_data = {}

	db.query_with_bindings("""
	SELECT *
	FROM players
	WHERE id = ?;
	""", [
		player_id
	])
	player_data["player"] = db.query_result

	db.query_with_bindings("""
	SELECT *
	FROM player_stats
	WHERE player_id = ?;
	""", [
		player_id
	])
	player_data["stats"] = db.query_result

	return player_data

# =========================================
# CHECK IF SAVE EXISTS
# =========================================

func save_exists():

	db.query("""
	SELECT COUNT(*) as total
	FROM players;
	""")

	if db.query_result.size() > 0 and db.query_result[0]["total"] > 0:
		return true

	return false

# =========================================
# UNLOCK ACHIEVEMENT
# =========================================

func unlock_achievement(player_id : int, achievement_key : String):

	if has_achievement(player_id, achievement_key):
		return

	db.query_with_bindings("""
	SELECT *
	FROM achievements
	WHERE achievement_key = ?;
	""", [
		achievement_key
	])

	if db.query_result.size() <= 0:
		return

	var achievement = db.query_result[0]

	db.query_with_bindings("""
	INSERT INTO player_achievements (
		player_id,
		achievement_id
	)
	VALUES (?, ?);
	""", [
		player_id,
		achievement["id"]
	])

	# Give financial reward adjustment balance
	update_player_money(player_id, achievement["reward_money"])
	print("[ACHIEVEMENT] Unlocked: ", achievement["title"])

# =========================================
# CHECK ACHIEVEMENT
# =========================================

func has_achievement(player_id : int, achievement_key : String):

	db.query_with_bindings("""
	SELECT pa.id
	FROM player_achievements pa
	INNER JOIN achievements a
	ON pa.achievement_id = a.id
	WHERE pa.player_id = ?
	AND a.achievement_key = ?;
	""", [
		player_id,
		achievement_key
	])

	return db.query_result.size() > 0

# =========================================
# GET PLAYER ACHIEVEMENTS
# =========================================

func get_player_achievements(player_id : int):

	db.query_with_bindings("""
	SELECT
		a.title,
		a.description,
		a.reward_money,
		pa.unlocked_at
	FROM player_achievements pa
	INNER JOIN achievements a
	ON pa.achievement_id = a.id
	WHERE pa.player_id = ?;
	""", [
		player_id
	])

	return db.query_result

# =========================================
# DELETE SAVE DATA
# =========================================

func delete_save(player_id : int):

	db.query_with_bindings("DELETE FROM player_achievements WHERE player_id = ?;", [player_id])
	db.query_with_bindings("DELETE FROM ending_results WHERE player_id = ?;", [player_id])
	db.query_with_bindings("DELETE FROM minigame_progress WHERE player_id = ?;", [player_id])
	db.query_with_bindings("DELETE FROM player_choices WHERE player_id = ?;", [player_id])
	db.query_with_bindings("DELETE FROM transactions WHERE player_id = ?;", [player_id])
	db.query_with_bindings("DELETE FROM chapter_progress WHERE player_id = ?;", [player_id])
	db.query_with_bindings("DELETE FROM player_stats WHERE player_id = ?;", [player_id])
	db.query_with_bindings("DELETE FROM players WHERE id = ?;", [player_id])

	print("[DATABASE] Save data context completely deleted successfully.")
