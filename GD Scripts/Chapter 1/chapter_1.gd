extends Control

var CURRENCY_HUD_SCENE = load("res://Scenes/Currency/currency_hud.tscn")
var GRAY_SCREEN_SCENE = load("res://Scenes/Gray Screen/gray_screen.tscn")
var PHONE_SCREEN_SCENE = load("res://Scenes/Phone Screen/phone_screen.tscn")
var DIALOGUE_BOX_SCENE = load("res://Scenes/Dialogue Box/dialogue_box.tscn") 
var PHONE_SCREEN_VIRTUAL_SCENE = load("res://Scenes/Phone Screen Virtual/phone_screen_virtual.tscn")

const DORM_BG = preload("res://Assets/Backgrounds/Chapter 1/dorm/dormbg.png")
const NEXT_SCENE = "res://Scenes/Chapter 1/chapter_1_scene_2.tscn"

@onready var jane = $JaneBigAnchor/jane2d
@onready var kylie = $KylieBigAnchor/kylie2d

@onready var jane_dialogue = $JaneDialogueAnchor/jane2d
@onready var kylie_dialogue = $KylieDialogueAnchor/kylie2d

@onready var animated_bg = $busarrivalbg
@onready var phone_mini = $PhoneMini
@onready var notification_pop = $NotificationPopControl
@onready var new_feature_control = $FeatureCanvas/NewFeatureControl

@onready var choose_control = $ChooseControl
@onready var jane_big_2 = $JaneBigAnchor2/jane2dbig

var currency_hud 
var dialogue_box 

var phone_screen_instance 
var virtual_bank_instance
var gray_screen_instance

var BANK_DIALOGUE: Array = [
	{"speaker": "", "text": "Before anything else, Jane’s parents transferred her P1,500 allowance for her first week."},
	{"speaker": "", "text": "This will serve as your starting balance in the FinQuest Bank."},
	{"speaker": "", "text": "Your money is stored in a virtual bank account."},
	{"speaker": "", "text": "Every decision affects your balance, so spend it wisely."}
]

var DORM_DIALOGUE: Array = [
	{"speaker": "Kylie", "text": "Uy, bagong salta? I’m Kylie! Welcome to the chaos of Manila life."},
	{"speaker": "Kylie", "text": "First tip: Huwag kang gagastos agad ng hindi kailangan."},
	{"speaker": "Jane", "text": "Hehe... I'll try. First time ko mag-manage ng pera on my own."},
	{"speaker": "Kylie", "text": "You’ll need a part-time job eventually. Mahirap kapag allowance lang."},
	{"speaker": "Kylie", "text": "Actually, may kinukuhang part-timers yung café sa kanto."}
]

func _ready() -> void:
	# Wait for database to be fully ready
	while not DatabaseManager.is_ready:
		await get_tree().process_frame
	
	# --- AUDIO INITIALIZATION ---
	AudioManager.play_chapter_music()
	
	# ANDROID FIX: Wait a bit longer for scene transitions to settle
	await get_tree().create_timer(0.3).timeout

# =================================================================
	# AUTOMATIC DEVELOPER SAFETY INJECTION FOR DIRECT TESTING (F5)
	# =================================================================
	print("[DEVELOPER SAFETY] Checking for default testing profile rows...")
	
	var random_id = randi_range(100000, 999999)
	var randomized_username = "user" + str(random_id)
		
	# 1. Establish the baseline player record row if it doesn't exist
	DatabaseManager.safe_query_with_bindings("""
		INSERT OR IGNORE INTO players (id, player_name, job_path) 
		VALUES (1, ?, NULL);
	""", [randomized_username])
	
	# 🟢 FIXED: Automatically inject the missing baseline row into player_stats table for Player 1!
	DatabaseManager.safe_query("""
		INSERT OR IGNORE INTO player_stats (player_id, bank_cash, on_hand_cash, current_chapter)
		VALUES (1, 1500, 0, 2);
	""")
	
	for chapter in range(1, 8):
		var unlocked = 1 if chapter <= 2 else 0
		DatabaseManager.safe_query_with_bindings("""
			INSERT OR IGNORE INTO chapter_progress (player_id, chapter_number, is_unlocked, is_completed) 
			VALUES (1, ?, ?, 0);
		""", [chapter, unlocked])
	# =================================================================

	GameManager.load_player_stats()
	
	# =================================================================
	# THE MASTER SANDBOX PROTECTION SYSTEM (FORCE FRESH START OVERRIDE)
	# =================================================================
	print("[FORCE OVERRIDE] Resetting job selection and establishing a fresh runtime sandbox...")
	
	GameManager.current_chapter = 2
	GameManager.on_hand_cash = 0
	GameManager.bank_cash = 1500
	GameManager.job_path = ""
	Global.job_choice = ""
	GameManager.clear_temporary_buffer()
	
	# Completely clear out old job choices on disk so re-entering starts fresh
	DatabaseManager.safe_query_with_bindings("""
		UPDATE players 
		SET job_path = NULL 
		WHERE id = ?;
	""", [GameManager.player_id])
	
	DatabaseManager.safe_query_with_bindings("""
		UPDATE player_stats
		SET bank_cash = 1500, on_hand_cash = 0, current_chapter = 2
		WHERE player_id = ?;
	""", [GameManager.player_id])
	# =================================================================
	
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	phone_mini.phone_clicked.connect(_on_phone_clicked)
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	if currency_hud:
		
		add_child(currency_hud)
		var withdraw_btn = currency_hud.get_node_or_null("withdraw_btn")
		if withdraw_btn:
			withdraw_btn.hide()
	
	currency_hud.add_money(GameManager.on_hand_cash)
	
	dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(dialogue_box)
	
	jane.modulate.a = 0.0
	
	# FIXED SEQUENCE: Fire animation loop early while screen is pitch black
	animated_bg.play("idle")
	
	# Give the phone GPU a single active processing frame to register texture nodes in the dark
	await get_tree().process_frame
	
	# Now that assets are cached safely, wait for the black screen mask to disappear
	if TransitionManager.color_rect.visible:
		await TransitionManager.transition_finished
		
	# Wait smoothly for the bus sequence loop to naturally wrap up its frames
	await animated_bg.animation_finished
	
	
	jane.appear()
	await get_tree().create_timer(1.0).timeout
	phone_mini.appear()
	notification_pop.appear()
	await get_tree().create_timer(2.0).timeout
	notification_pop.show_hint_and_blink()
	await get_tree().create_timer(1.0).timeout
	
	AudioManager.play_sfx("NOTIFICATION")
	phone_mini.trigger_notification()

	choose_control.choice_made.connect(_on_choice_made)

func _on_phone_clicked() -> void:
	phone_mini.visible = false
	notification_pop.visible = false
	
	gray_screen_instance = GRAY_SCREEN_SCENE.instantiate()
	add_child(gray_screen_instance)
	
	phone_screen_instance = PHONE_SCREEN_SCENE.instantiate()
	add_child(phone_screen_instance)
	
	phone_screen_instance.bank_app_clicked.connect(_on_bank_app_clicked)
	
	var click_shield = ColorRect.new()
	click_shield.color = Color(0, 0, 0, 0)
	click_shield.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	phone_screen_instance.add_child(click_shield)
	
	await new_feature_control.play_feature_intro()
	dialogue_box.start_dialogue(BANK_DIALOGUE, 1.0)
	await dialogue_box.dialogue_finished
	await get_tree().create_timer(0.5).timeout
	
	# ACHIEVEMENT INTEGRATION: Unlocks when the bank application overview finishes
	GameManager.unlock_achievement("BANK_UNLOCKED")
	
	click_shield.queue_free()
	phone_screen_instance.unlock_app()

func _on_bank_app_clicked() -> void:
	if phone_screen_instance:
		phone_screen_instance.visible = false
		
	virtual_bank_instance = PHONE_SCREEN_VIRTUAL_SCENE.instantiate()
	add_child(virtual_bank_instance)
	
	virtual_bank_instance.money_withdrawn.connect(_on_money_withdrawn)
	virtual_bank_instance.back_clicked.connect(_on_virtual_bank_back_clicked)

func _on_money_withdrawn(_amount: int) -> void:
	AudioManager.play_sfx("INCOME")
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()

func _on_window_resized():
	var screen_size = get_viewport_rect().size
	var frame_size = animated_bg.sprite_frames.get_frame_texture("idle", 0).get_size()
	
	if frame_size.x > 0 and frame_size.y > 0:
		animated_bg.scale = screen_size / frame_size
		animated_bg.position = screen_size / 2.0

func _on_virtual_bank_back_clicked() -> void:
	if virtual_bank_instance:
		virtual_bank_instance.queue_free()
	if phone_screen_instance:
		phone_screen_instance.queue_free()
	if gray_screen_instance:
		gray_screen_instance.queue_free()
		
	jane.hide()
	
	await get_tree().create_timer(1.0).timeout
	await TransitionManager.fade_to_black()
	
	if currency_hud:
		var withdraw_btn = currency_hud.get_node_or_null("withdraw_btn")
		if withdraw_btn:
			withdraw_btn.show()
		
	var dorm_background = TextureRect.new()
	dorm_background.texture = DORM_BG
	dorm_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dorm_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	add_child(dorm_background)
	move_child(dorm_background, 0)
	
	animated_bg.hide()
	
	await get_tree().create_timer(1.5).timeout
	await TransitionManager.fade_from_black()
	
	AudioManager.play_chapter_music()
	
	await get_tree().create_timer(1.0).timeout
	kylie.appear()
	
	await get_tree().create_timer(2.0).timeout
	kylie.exit(true)
	
	await get_tree().create_timer(0.5).timeout
	
	dialogue_box.start_dialogue(DORM_DIALOGUE, 0.5)
	await get_tree().create_timer(0.5).timeout
	
	jane_dialogue.appear()
	kylie_dialogue.appear()
	
	await dialogue_box.dialogue_finished
	
	jane_dialogue.exit(true)
	kylie_dialogue.exit(true)
	
	await get_tree().create_timer(1.0).timeout
	
	choose_control.appear()
	jane_big_2.appear()

func _on_choice_made(selected_choice: String) -> void:
	var dynamic_job = ""
	
	if selected_choice == "A" or selected_choice == "Cafe":
		dynamic_job = "Barista"   
		GameManager.log_choice("chap1_job_path", "A")
	elif selected_choice == "B" or selected_choice == "Clerk":
		dynamic_job = "Clerk"
		GameManager.log_choice("chap1_job_path", "B")
	elif selected_choice == "C" or selected_choice == "Cashier":
		dynamic_job = "Cashier"
		GameManager.log_choice("chap1_job_path", "C")
	else:
		dynamic_job = selected_choice
		GameManager.log_choice("chap1_job_path", selected_choice)
		
	# Sync running memory states
	Global.job_choice = dynamic_job
	GameManager.job_path = dynamic_job
	
	# Instantly overwrite the database cell right upon choice selection
	print("[DATABASE] Overwriting persistent profile job_path cell with: ", dynamic_job)
	DatabaseManager.safe_query_with_bindings("""
		UPDATE players 
		SET job_path = ? 
		WHERE id = ?;
	""", [dynamic_job, GameManager.player_id])

	choose_control.exit()
	
	var tween = create_tween()
	tween.tween_property(jane_big_2, "modulate:a", 0.0, 0.5)
	
	
	
	await get_tree().create_timer(0.5).timeout
	TransitionManager.transition_to(NEXT_SCENE)
