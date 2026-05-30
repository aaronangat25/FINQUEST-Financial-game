extends Control

const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_SCREEN_SCENE = preload("res://Scenes/Phone Screen/phone_screen.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn") 
const PHONE_SCREEN_VIRTUAL_SCENE = preload("res://Scenes/Phone Screen Virtual/phone_screen_virtual.tscn")

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
	{"speaker": "", "text": "Before anything else, Jane’s parents transferred her P3,000 allowance for her first week."},
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
	# --- AUDIO INITIALIZATION ---
	# Bridges the chapter entrance over the bus arrival screen animation sequence
	AudioManager.play_chapter_music()

	# =================================================================
	# AUTOMATIC DEVELOPER SAFETY INJECTION FOR DIRECT TESTING (F5)
	# =================================================================
	DatabaseManager.db.query_with_bindings("SELECT COUNT(*) as total FROM player_stats WHERE player_id = ?;", [GameManager.player_id])
	var row_exists = false
	if DatabaseManager.db.query_result.size() > 0 and DatabaseManager.db.query_result[0]["total"] > 0:
		row_exists = true
		
	if not row_exists:
		print("[DEVELOPER SAFETY] No data entries found for testing. Injecting default profile rows for Player 1...")
		DatabaseManager.db.query("""
			INSERT OR IGNORE INTO players (id, player_name, gender, job_path) 
			VALUES (1, 'Jane Dev', 'Female', 'Cafe');
		""")
		DatabaseManager.db.query("""
			INSERT OR IGNORE INTO player_stats (player_id, bank_cash, on_hand_cash, current_chapter) 
			VALUES (1, 3000, 0, 2);
		""")
		for chapter in range(1, 8):
			var unlocked = 1 if chapter <= 2 else 0
			DatabaseManager.db.query_with_bindings("""
				INSERT OR IGNORE INTO chapter_progress (player_id, chapter_number, is_unlocked, is_completed) 
				VALUES (1, ?, ?, 0);
			""", [chapter, unlocked])
	# =================================================================

	GameManager.load_player_stats()
	
	# =================================================================
	# THE MASTER SANDBOX PROTECTION SYSTEM (ANTI-EXPLOIT WIPE)
	# =================================================================
	GameManager.current_chapter = 2
	GameManager.on_hand_cash = 0
	GameManager.bank_cash = 3000
	GameManager.clear_temporary_buffer()
	
	print("[SANDBOX RESET] Chapter 1 Initialized. Bank Cash: ₱", GameManager.bank_cash, " | On-Hand Cash: ₱", GameManager.on_hand_cash, " | Active Chapter Tracker: ", GameManager.current_chapter)
	
	DatabaseManager.db.query_with_bindings("""
		UPDATE player_stats
		SET bank_cash = 3000, on_hand_cash = 0, current_chapter = 2
		WHERE player_id = ?;
	""", [GameManager.player_id])
	# =================================================================
	
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	phone_mini.phone_clicked.connect(_on_phone_clicked)
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	currency_hud.add_money(GameManager.on_hand_cash)
	
	dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(dialogue_box)
	
	jane.modulate.a = 0.0
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.transition_finished
		
	animated_bg.play("idle")
	
	await animated_bg.animation_finished
	jane.appear()
	await get_tree().create_timer(1.0).timeout
	phone_mini.appear()
	notification_pop.appear()
	await get_tree().create_timer(2.0).timeout
	notification_pop.show_hint_and_blink()
	await get_tree().create_timer(1.0).timeout
	
	# Trigger your smartphone text alert notification ping audio
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
	# Trigger the confirmation chime sound effect ("Withdraw or money increase")
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
		
	var dorm_background = TextureRect.new()
	dorm_background.texture = DORM_BG
	dorm_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dorm_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	add_child(dorm_background)
	move_child(dorm_background, 0)
	
	animated_bg.hide()
	
	await get_tree().create_timer(1.5).timeout
	await TransitionManager.fade_from_black()
	
	# --- GENERAL BACKGROUND MUSIC TRANSITION ---
	# Fades menu theme out and cross-fades general exploration music in inside the dorm
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
	Global.job_choice = selected_choice
	
	if selected_choice == "A" or selected_choice == "Cafe":
		GameManager.log_choice("chap1_job_path", "A")
	elif selected_choice == "B" or selected_choice == "Clerk":
		GameManager.log_choice("chap1_job_path", "B")
	elif selected_choice == "C" or selected_choice == "Cashier":
		GameManager.log_choice("chap1_job_path", "C")
	else:
		GameManager.log_choice("chap1_job_path", selected_choice)

	choose_control.exit()
	
	var tween = create_tween()
	tween.tween_property(jane_big_2, "modulate:a", 0.0, 0.5)
	
	await get_tree().create_timer(0.5).timeout
	TransitionManager.transition_to(NEXT_SCENE)
