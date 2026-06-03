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

# --- THE CRITICAL FIX: Positioned at top-level for clean project readability ---
var is_ready : bool = false

# --- ANDROID CRASH FIX: Mutex to prevent concurrent database access ---
var _mutex: Mutex = Mutex.new()

# =========================================
# GODOT READY
# =========================================

func _ready():
	initialize_database()

# =========================================
# SAFE QUERY WRAPPERS (MUTEX PROTECTED)
# =========================================

func safe_query(query_string: String):
	_mutex.lock()
	var result = db.query(query_string)
	_mutex.unlock()
	return result

func safe_query_with_bindings(query_string: String, bindings: Array = []):
	_mutex.lock()
	var result = db.query_with_bindings(query_string, bindings)
	_mutex.unlock()
	return result

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
		
		# --- THE CRITICAL FIX: Only flips to true after all data setups finish ---
		is_ready = true
		print("[DATABASE] Ready state activated cleanly. System singletons can now safely query.")
	else:
		print("[DATABASE ERROR] Failed to connect database.")

# =========================================
# CREATE TABLES
# =========================================

func create_tables():

	# =========================================
	# PLAYERS
	# =========================================
	safe_query("""
	CREATE TABLE IF NOT EXISTS players (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		player_name TEXT NOT NULL,
		job_path TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	""")

	# =========================================
	# PLAYER STATS
	# =========================================
	safe_query("""
	CREATE TABLE IF NOT EXISTS player_stats (
		player_id INTEGER PRIMARY KEY,
		bank_cash INTEGER DEFAULT 0, -- CHANGED FROM 1500 TO 0
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
	safe_query("""
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
	safe_query("""
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
	safe_query("""
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
	safe_query("""
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
	safe_query("""
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
	safe_query("""
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
	safe_query("""
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
	# Matrix containing all 12 official FinQuest: P.E.S.O. achievement keys [cite: 489, 490]
	# Financial rewards are left at 0 while design values are being finalized
	var achievements = [
		# --- PROLOGUE SEED DATA ---
		{
			"key": "PROLOGUE",
			"title": "Every Peso Counts",
			"description": "Complete the SHS Prologue tutorial sequence.",
			"reward": 0
		},
		{
			"key": "NO_PASAHE",
			"title": "No-Pasahe Grind",
			"description": "Choose to walk to school in the morning to save cash.",
			"reward": 0
		},
		
		# --- CHAPTER 1 SEED DATA ---
		{
			"key": "BANK_UNLOCKED",
			"title": "FinQuest Premium Member",
			"description": "Unlock your first virtual wallet and bank account feature.",
			"reward": 0
		},
		{
			"key": "BARISTA_PERFECT",
			"title": "Brewmaster Apprentice",
			"description": "Complete the Barista mini-task training perfectly.",
			"reward": 0
		},
		{
			"key": "CLERK_PERFECT",
			"title": "Aisle Manager",
			"description": "Correctly direct the student to Aisle 1 during clerk training.",
			"reward": 0
		},
		{
			"key": "CASHIER_PERFECT",
			"title": "Human Calculator",
			"description": "Compute change accurately under time limits during cashier training.",
			"reward": 0
		},
		
		# --- CHAPTER 2 SEED DATA ---
		{
			"key": "ACADEMIC_WEAPON",
			"title": "Academic Weapon",
			"description": "Achieve a perfect 1.0 GPA average score on Midterms.",
			"reward": 0
		},
		
		# --- CHAPTER 3 SEED DATA ---
		{
			"key": "INFLATION_FIGHTER",
			"title": "Inflation Fighter",
			"description": "Achieve Excellent Budgeting scores during an economic crisis.",
			"reward": 0
		},
		{
			"key": "SOPAS_STARBUCKS",
			"title": "Sopas over Starbucks",
			"description": "Opt to skip meals for cheap snacks or buy only essentials.",
			"reward": 0
		},
		
		# --- CHAPTER 4 SEED DATA ---
		{
			"key": "MAGNA_CUM_BUDGET",
			"title": "Magna Cum Budget",
			"description": "Secure an Outstanding 1.0 Thesis Defense rating with top budgeting choices.",
			"reward": 0
		},
		
		# --- CHAPTER 5 / ENDING SEED DATA ---
		{
			"key": "MID_ENDING",
			"title": "Corporate Ladder Climber",
			"description": "Unlocked the Office Worker Ending. Stable lifestyle secured!",
			"reward": 0
		},
		{
			"key": "GOOD_ENDING",
			"title": "CEO of My Own Life",
			"description": "Unlocked the Business Owner Ending. Attained Financial Freedom!",
			"reward": 0
		}
	]

	for achievement in achievements:
		safe_query_with_bindings("""
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

	print("[DATABASE] Production achievements table populated with 0-value placeholder rewards.")

# =========================================
# CREATE NEW PLAYER
# =========================================

func create_player(player_name : String, job_path : String):

	# Insert player
	safe_query_with_bindings("""
	INSERT INTO players (
		player_name,
		job_path
	)
	VALUES (?, ?);
	""", [
		player_name,
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

	safe_query_with_bindings("""
	INSERT INTO player_stats (
		player_id
	)
	VALUES (?);
	""", [
		player_id
	])

# =========================================
# DEFAULT CHAPTER PROGRESS (FIXED RANGE)
# =========================================

func create_default_chapter_progress(player_id : int):
	# Loop from 1 to 7 (range(1, 8) stops right before 8)
	for chapter in range(1, 8):
		var unlocked = 0
		if chapter == 1:
			unlocked = 1 # Prologue is the only one unlocked initially

		safe_query_with_bindings("""
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
		safe_query_with_bindings("""
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

	safe_query_with_bindings("""
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

	safe_query_with_bindings("""
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

	safe_query_with_bindings("""
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

	safe_query_with_bindings("""
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

	safe_query_with_bindings("""
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

	safe_query_with_bindings("""
	UPDATE chapter_progress
	SET is_completed = 1, completion_grade = ?, completed_at = CURRENT_TIMESTAMP
	WHERE player_id = ? AND chapter_number = ?;
	""", [float(grade), player_id, chapter_number])

	safe_query_with_bindings("""
	UPDATE chapter_progress
	SET is_unlocked = 1
	WHERE player_id = ? AND chapter_number = ?;
	""", [player_id, chapter_number + 1])

# =========================================
# SAVE GAME
# =========================================

func save_game(player_id : int, current_scene : String):

	safe_query_with_bindings("""
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

	safe_query_with_bindings("""
	SELECT *
	FROM players
	WHERE id = ?;
	""", [
		player_id
	])
	player_data["player"] = db.query_result

	safe_query_with_bindings("""
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

	safe_query("""
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

	safe_query_with_bindings("""
	SELECT *
	FROM achievements
	WHERE achievement_key = ?;
	""", [
		achievement_key
	])

	if db.query_result.size() <= 0:
		return

	var achievement = db.query_result[0]

	safe_query_with_bindings("""
	INSERT INTO player_achievements (
		player_id,
		achievement_id
	)
	VALUES (?, ?);
	""", [
		player_id,
		achievement["id"]
	])

	update_player_money(player_id, achievement["reward_money"])
	print("[DATABASE SUCCESS] Staged achievement committed permanently: ", achievement["title"])

# =========================================
# CHECK ACHIEVEMENT
# =========================================

func has_achievement(player_id : int, achievement_key : String):

	safe_query_with_bindings("""
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

	safe_query_with_bindings("""
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
	
# =================================================================
# THREAD-SAFE DATABASE CLOSING UTILITY
# =================================================================
# This function locks the mutex to make sure the database never closes 
# while a save operation or query is still running in another thread.
func safe_close_db() -> void:
	if db:
		_mutex.lock()
		print("[DATABASE] Mutex locked. Safe closing database connection...")
		db.close_db()
		_mutex.unlock()
		print("[DATABASE] Database closed cleanly without conflicts.")
		
# =========================================
# FETCH HISTORICAL TRANSACTIONS (EXCLUDING ZEROES)
# =========================================
func get_recent_wallet_transactions(player_id: int) -> Array:
	safe_query_with_bindings("""
		SELECT description, amount 
		FROM transactions 
		WHERE player_id = ? AND amount != 0 
		ORDER BY created_at DESC LIMIT 3;
	""", [player_id])
	return db.query_result

# =========================================
# DELETE SAVE DATA
# =========================================

func delete_save(player_id : int):

	safe_query_with_bindings("DELETE FROM player_achievements WHERE player_id = ?;", [player_id])
	safe_query_with_bindings("DELETE FROM ending_results WHERE player_id = ?;", [player_id])
	safe_query_with_bindings("DELETE FROM minigame_progress WHERE player_id = ?;", [player_id])
	safe_query_with_bindings("DELETE FROM player_choices WHERE player_id = ?;", [player_id])
	safe_query_with_bindings("DELETE FROM transactions WHERE player_id = ?;", [player_id])
	safe_query_with_bindings("DELETE FROM chapter_progress WHERE player_id = ?;", [player_id])
	safe_query_with_bindings("DELETE FROM player_stats WHERE player_id = ?;", [player_id])
	safe_query_with_bindings("DELETE FROM players WHERE id = ?;", [player_id])

	print("[DATABASE] Save data context completely deleted successfully.")
