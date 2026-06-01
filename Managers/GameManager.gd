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
var bank_cash : int = 0
var on_hand_cash : int = 0             # Persistent pocket wallet balance
var financial_wisdom_points : int = 0
var grades : float = 0.0

# GAME PROGRESSION
var current_chapter : int = 1          # 1 = Prologue, 2 = Chapter 1, 3 = Chapter 2, etc.
var current_scene : String = ""

# GAME TOTALS
var total_income : int = 0
var total_expenses : int = 0

# =================================================================
# TEMPORARY RUNTIME STAGE BUFFER (GLITCH PREVENTION)
# =================================================================
var buffered_choices : Array = []
var buffered_bank_change : int = 0    # Tracks net bank deposits/withdrawals this run
var buffered_on_hand_change : int = 0 # Tracks net visual wallet fluctuations this run
var current_chapter_description : String = ""


# =================================================================
# FINQUEST: P.E.S.O. INTEGRATED ACHIEVEMENT SYSTEM
# =================================================================

const NOTIFICATION_SCENE = preload("res://Scenes/AchievementNotificatioon/achievement_notification.tscn")

# Temporary runtime staging cache for achievements earned mid-chapter
var buffered_achievements : Array = []

var unlocked_achievements: Dictionary = {
	"PROLOGUE": false,
	"NO_PASAHE": false,
	"BANK_UNLOCKED": false,
	"BARISTA_PERFECT": false,
	"CLERK_PERFECT": false,
	"CASHIER_PERFECT": false,
	"ACADEMIC_WEAPON": false,
	"INFLATION_FIGHTER": false,
	"SOPAS_STARBUCKS": false,
	"MAGNA_CUM_BUDGET": false,
	"MID_ENDING": false,
	"GOOD_ENDING": false
}

const ACHIEVEMENT_ASSETS: Dictionary = {
	"PROLOGUE": "res://Assets/Achievements/prologue achievement.png",
	"NO_PASAHE": "res://Assets/Achievements/no pamasahe achievement.png",
	"BANK_UNLOCKED": "res://Assets/Achievements/virtual bank achievement.png",
	"BARISTA_PERFECT": "res://Assets/Achievements/barista achievement.png",
	"CLERK_PERFECT": "res://Assets/Achievements/clerk achievement.png",
	"CASHIER_PERFECT": "res://Assets/Achievements/cashier achievement.png",
	"ACADEMIC_WEAPON": "res://Assets/Achievements/academic weapon achievement.png",
	"INFLATION_FIGHTER": "res://Assets/Achievements/inflation fighter achievement.png",
	"SOPAS_STARBUCKS": "res://Assets/Achievements/meal achievement.png",
	"MAGNA_CUM_BUDGET": "res://Assets/Achievements/graduation achievement.png",
	"MID_ENDING": "res://Assets/Achievements/corporate achievement.png",
	"GOOD_ENDING": "res://Assets/Achievements/business owner achievement.png"
}

## Globally available function to unlock and show any title achievement notification banner
func unlock_achievement(achievement_id: String) -> void:
	if not unlocked_achievements.has(achievement_id):
		print("[ACHIEVEMENT ERROR] Invalid achievement code: ", achievement_id)
		return
		
	if unlocked_achievements[achievement_id] == true:
		return
		
	unlocked_achievements[achievement_id] = true
	print("[ACHIEVEMENT UNLOCKED] Staged mid-game: ", achievement_id)
	
	buffered_achievements.append(achievement_id)
	
	var notification_instance = NOTIFICATION_SCENE.instantiate()
	get_tree().root.add_child(notification_instance)
	get_tree().root.move_child(notification_instance, -1)
	
	var asset_path = ACHIEVEMENT_ASSETS[achievement_id]
	notification_instance.trigger_popup(asset_path)

	var sfx_player = AudioStreamPlayer.new()
	var sfx_stream = load("res://Assets/Audio/SFX/AchievementUnlocked.ogg")
	
	if sfx_stream:
		sfx_player.stream = sfx_stream
		sfx_player.bus = "Master" 
		
		get_tree().root.add_child(sfx_player)
		sfx_player.play()
		sfx_player.finished.connect(sfx_player.queue_free)
	else:
		print("[AUDIO ERROR] Could not load AchievementUnlocked.ogg! Verify file path.")


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
	
	# --- FIX FOR BUG 2 ---
	# The absolute second a new game initializes, we hand her the 3,000 tutorial bank cash
	# so her phone banking screen will never read 0 pesos on a clean playthrough!
	bank_cash = 3000
	on_hand_cash = 0
	
	print("New game started. Tutorial initialized with Bank Account: ₱3000")

# =========================================
# LOAD PLAYER STATS (UPDATED & BULLETPROOF)
# =========================================
func load_player_stats():
	var result = DatabaseManager.get_player_stats(player_id)
	if result.size() <= 0:
		return

	var stats = result[0]
	
	# If a player quits mid-chapter, this reloads their exact hard-saved cash positions safely!
	bank_cash = stats["bank_cash"] if stats["bank_cash"] != null else 0
	on_hand_cash = stats["on_hand_cash"] if stats["on_hand_cash"] != null else 0
	financial_wisdom_points = stats["financial_wisdom_points"] if stats["financial_wisdom_points"] != null else 0
	grades = stats["grades"] if stats["grades"] != null else 0.0
	current_chapter = stats["current_chapter"] if stats["current_chapter"] != null else 1
	
	# --- SAFE TYPE CAST FALLBACKS ---
	current_scene = stats["current_scene"] if stats["current_scene"] != null else ""
	total_income = stats["total_income"] if stats["total_income"] != null else 0
	total_expenses = stats["total_expenses"] if stats["total_expenses"] != null else 0

	print("[SYSTEM STATS] Bank Account: ₱", bank_cash, " | Pocket Cash: ₱", on_hand_cash)

# =========================================
# GET UNLOCKED CHAPTERS FROM DB
# =========================================
func get_unlocked_chapters() -> Array:
	if not DatabaseManager or not DatabaseManager.is_ready:
		return []
	DatabaseManager.safe_query_with_bindings("""
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
	# FORCE STABLE FLOATING POINT CONSTRAINTS
	var protected_grade : float = float(grade)
	if grades == 0.0:
		grades = protected_grade
		print("[GRADE TRACKER] First grade recorded: ", grades)
	else:
		var old_grade = grades
		grades = (old_grade + protected_grade) / 2.0
		print("[GRADE TRACKER] Running Average Calculated! Old: ", old_grade, " | New: ", protected_grade, " | Average: ", grades)

	# 1. Updates current chapter rows inside SQLite
	DatabaseManager.complete_chapter(player_id, current_chapter, grade)

	# 2. Advance the local runtime progress variable
	current_chapter += 1
	
	# 3. Synchronize player_stats record with the new active progression step
	DatabaseManager.safe_query_with_bindings("""
		UPDATE player_stats
		SET current_chapter = ?
		WHERE player_id = ?;
	""", [current_chapter, player_id])

	print("Chapter completed safely. Grade updated to: ", protected_grade, " | Next available chapter: ", current_chapter)

# =================================================================
# STAGE FINANCE CHANGES MID-GAME
# =================================================================
func stage_finance_change(bank_delta: int, pocket_delta: int, description: String) -> void:
	buffered_bank_change += bank_delta
	buffered_on_hand_change += pocket_delta
	current_chapter_description = description
	
	bank_cash += bank_delta
	on_hand_cash += pocket_delta
	print("[BUFFER FINANCE] Bank Change: ₱", bank_delta, " | Pocket Change: ₱", pocket_delta)

# =================================================================
# STAGE A NARRATIVE CHOICE TO BUFFER
# =================================================================
func log_choice(choice_key: String, option_letter: String) -> void:
	var scene_key : String = "Unknown Scene"
	if get_tree() and get_tree().current_scene:
		scene_key = get_tree().current_scene.name
		
	print("[BUFFER STAGED] Scene: ", scene_key, " | Key: ", choice_key, " | Option: ", option_letter)
	
	buffered_choices.append({
		"player_id": player_id,
		"chapter_number": current_chapter,
		"scene_key": scene_key,
		"choice_key": choice_key,
		"choice_value": option_letter
	})

# =================================================================
# COMMIT ALL STAGED PROGRESS TO THE DATABASE AT CHAPTER END
# =================================================================
func flush_buffer_to_database() -> void:
	print("[DATABASE SAVE] Chapter ", current_chapter, " complete! Processing settlement...")
	
	for achievement_key in buffered_achievements:
		DatabaseManager.unlock_achievement(player_id, achievement_key)
	buffered_achievements.clear() # Wipe the cache clean for the next chapter execution!
	
	for choice in buffered_choices:
		DatabaseManager.safe_query_with_bindings("""
			INSERT INTO player_choices (player_id, chapter_number, scene_key, choice_key, choice_value, effect_summary)
			VALUES (?, ?, ?, ?, ?, ?);
		""", [choice["player_id"], choice["chapter_number"], choice["scene_key"], choice["choice_key"], choice["choice_value"], ""])
	
	if current_chapter == 1:
		print("[DATABASE SAVE] Prologue sandbox complete. Hardwriting ₱3,000 bank and ₱0 pocket balances to row cells...")
		bank_cash = 3000
		on_hand_cash = 0
		
		DatabaseManager.safe_query_with_bindings("""
			UPDATE player_stats
			SET bank_cash = 3000, on_hand_cash = 0
			WHERE player_id = ?;
		""", [player_id])
	
	else:
		var net_change = buffered_bank_change + buffered_on_hand_change
		if net_change > 0:
			total_income += net_change
		else:
			total_expenses += abs(net_change)
			
		if buffered_bank_change != 0:
			DatabaseManager.add_transaction(player_id, current_chapter, "BANK_SETTLEMENT", buffered_bank_change, current_chapter_description)
			
		DatabaseManager.safe_query_with_bindings("""
			UPDATE player_stats
			SET bank_cash = ?, on_hand_cash = ?, total_income = ?, total_expenses = ?
			WHERE player_id = ?;
		""", [bank_cash, on_hand_cash, total_income, total_expenses, player_id])
	
	clear_temporary_buffer()
	print("[DATABASE SAVE] Chapter flush sequence complete.")

# Clears memory caches if the player finishes or exits early mid-game
func clear_temporary_buffer() -> void:
	print("[SYSTEM BUFFER] Clearing staging caches and forcing sandbox validation...")
	buffered_choices.clear()
	buffered_achievements.clear()
	buffered_bank_change = 0
	buffered_on_hand_change = 0
	current_chapter_description = ""
	
	if current_chapter == 1 or current_chapter == 2:
		bank_cash = 3000
		on_hand_cash = 0

# =========================================
# RESET GAME DATA
# =========================================
func reset_game_data():
	player_id = 1
	player_name = ""
	gender = ""
	job_path = ""
	bank_cash = 0
	on_hand_cash = 0
	financial_wisdom_points = 0
	grades = 0.0
	current_chapter = 1
	current_scene = ""
	total_income = 0
	total_expenses = 0
	
	# Reset local tracking state on manual reset sequence calls
	for key in unlocked_achievements.keys():
		unlocked_achievements[key] = false

# =========================================
# FETCH ACTIVE GRADE HISTORY FOR SIS APP
# =========================================
func get_grade_history() -> Array:
	DatabaseManager.safe_query_with_bindings("""
		SELECT chapter_number, completion_grade 
		FROM chapter_progress 
		WHERE player_id = ? AND completion_grade > 0.0 
		ORDER BY chapter_number ASC;
	""", [player_id])
	
	return DatabaseManager.db.query_result

# =================================================================
# PRODUCTION GRADE RESTART RESYNCHRONIZATION INJECTOR (FIXED TABLES)
# =================================================================
func execute_production_factory_reset() -> void:
	print("[GAME MANAGER] Performing absolute database and memory purge...")
	
	# 1. Reset baseline account configuration stats inside running memory (RAM)
	bank_cash = 3000
	on_hand_cash = 0
	financial_wisdom_points = 0
	grades = 0.0
	current_chapter = 1
	current_scene = ""
	total_income = 0
	total_expenses = 0
	
	# Reset local runtime validation tracking keys
	for key in unlocked_achievements.keys():
		unlocked_achievements[key] = false
	
	# 2. Hard-clear any choices or transaction values currently sitting in the level buffers
	buffered_choices.clear()
	buffered_bank_change = 0
	buffered_on_hand_change = 0
	current_chapter_description = ""
	
	# 3. CLEAR ALL NARRATIVE DECISIONS FROM SQLITE
	DatabaseManager.safe_query_with_bindings("""
		DELETE FROM player_choices WHERE player_id = ?;
	""", [player_id])
	
	# 4. FIXED: Clear bank app ledger history using your exact table name: 'transactions'
	DatabaseManager.safe_query_with_bindings("""
		DELETE FROM transactions WHERE player_id = ?;
	""", [player_id])
	
	# 5. CLEAR MINIGAME AND ACHIEVEMENT TRACKERS FOR A TRUE FRESH RUN
	DatabaseManager.safe_query_with_bindings("""
		DELETE FROM player_achievements WHERE player_id = ?;
	""", [player_id])
	
	DatabaseManager.safe_query_with_bindings("""
		DELETE FROM minigame_progress WHERE player_id = ?;
	""", [player_id])
	
	# 6. Synchronize your active player stats columns back to baseline settings
	DatabaseManager.safe_query_with_bindings("""
		UPDATE player_stats
		SET bank_cash = 3000, 
		    on_hand_cash = 0, 
		    financial_wisdom_points = 0, 
		    grades = 0.0, 
		    current_chapter = 1,
		    total_income = 0,
		    total_expenses = 0
		WHERE player_id = ?;
	""", [player_id])
	
	print("[GAME MANAGER] All player choices, transactions, achievements, and stats completely purged.")
