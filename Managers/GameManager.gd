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
var current_chapter : int = 1         # 1 = Prologue, 2 = Chapter 1, 3 = Chapter 2, etc.
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
	# FORCE STABLE FLOATING POINT CONSTRAINTS
	# Explicitly wrapping the parameter inside float() prevents SQLite columns
	# from truncating your '1.50' values down into broken '0.50' structures!
	var protected_grade : float = float(grade)
	# If this is the first graded chapter (Chapter 2 / index 3 in your system tracker),
	# or if grades haven't been recorded yet, set the baseline.
	if grades == 0.0:
		grades = protected_grade
		print("[GRADE TRACKER] First grade recorded: ", grades)
	else:
		# If a grade already exists (like from Chapter 2), calculate the running average!
		var old_grade = grades
		grades = (old_grade + protected_grade) / 2.0
		print("[GRADE TRACKER] Running Average Calculated! Old: ", old_grade, " | New: ", protected_grade, " | Average: ", grades)

	# 1. Updates current chapter rows inside SQLite
	DatabaseManager.complete_chapter(player_id, current_chapter, grade)

	# 2. Advance the local runtime progress variable
	current_chapter += 1
	
	# 3. Synchronize player_stats record with the new active progression step
	DatabaseManager.db.query_with_bindings("""
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
	
	# Update localized visual runtime trackers dynamically for level feedback
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
	
	# 1. ALWAYS write the narrative choices permanently to SQLite
	for choice in buffered_choices:
		DatabaseManager.db.query_with_bindings("""
			INSERT INTO player_choices (player_id, chapter_number, scene_key, choice_key, choice_value, effect_summary)
			VALUES (?, ?, ?, ?, ?, ?);
		""", [choice["player_id"], choice["chapter_number"], choice["scene_key"], choice["choice_key"], choice["choice_value"], ""])
	
	# 2. PROLOGUE SANDBOX RULE ONLY
	# FIXED: Remove 'or current_chapter == 2'. Only the Prologue (Index 1) resets to base.
	# Chapter 1 (Index 2) needs to save its actual ending cash and log transactions!
	if current_chapter == 1:
		print("[DATABASE SAVE] Prologue sandbox complete. Hardwriting ₱3,000 bank and ₱0 pocket balances to row cells...")
		bank_cash = 3000
		on_hand_cash = 0
		
		DatabaseManager.db.query_with_bindings("""
			UPDATE player_stats
			SET bank_cash = 3000, on_hand_cash = 0
			WHERE player_id = ?;
		""", [player_id])
	
	# 3. STANDARD PLAYTHROUGH (Chapter 1 / Index 2 and onwards now processes here!)
	else:
		# Calculate actual transaction adjustments using the active buffer registers
		var net_change = buffered_bank_change + buffered_on_hand_change
		if net_change > 0:
			total_income += net_change
		else:
			total_expenses += abs(net_change)
			
		# Log the bank app transactions to your SQLite table cleanly
		if buffered_bank_change != 0:
			DatabaseManager.add_transaction(player_id, current_chapter, "BANK_SETTLEMENT", buffered_bank_change, current_chapter_description)
			
		# Update the true wallet balances directly into your player_stats columns
		DatabaseManager.db.query_with_bindings("""
			UPDATE player_stats
			SET bank_cash = ?, on_hand_cash = ?, total_income = ?, total_expenses = ?
			WHERE player_id = ?;
		""", [bank_cash, on_hand_cash, total_income, total_expenses, player_id])
	
	# 4. Wipe staging cache buffers clean
	clear_temporary_buffer()
	print("[DATABASE SAVE] Chapter flush sequence complete.")

# Clears memory caches if the player finishes or exits early mid-game
# Clears memory caches if the player finishes or exits early mid-game
# Clears memory caches if the player finishes or exits early mid-game
func clear_temporary_buffer() -> void:
	print("[SYSTEM BUFFER] Clearing staging caches and forcing sandbox validation...")
	buffered_choices.clear()
	buffered_bank_change = 0
	buffered_on_hand_change = 0
	current_chapter_description = ""
	
	# --- THE MASTER RESET FIX ---
	# If the user is in either the Prologue (1) or Chapter 1 (2), 
	# hard-wipe the running memory variables back to pristine sandbox baselines!
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
