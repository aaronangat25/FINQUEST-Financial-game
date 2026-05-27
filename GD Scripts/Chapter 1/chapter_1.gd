extends Control

const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_SCREEN_SCENE = preload("res://Scenes/Phone Screen/phone_screen.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn") 
const PHONE_SCREEN_VIRTUAL_SCENE = preload("res://Scenes/Phone Screen Virtual/phone_screen_virtual.tscn") # <-- UPDATE THIS PATH!

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

# --- NEW: Variable to hold our instantiated big phone screen so we can hide it later ---
var phone_screen_instance 
var virtual_bank_instance

var gray_screen_instance

var BANK_DIALOGUE: Array = [
	{"speaker": "", "text": "Before anything else, Jane’s parents transferred her P3,000 allowance for her first week."},
	{"speaker": "", "text": "This will serve as your starting balance in the FinQuest Bank."},
	{"speaker": "", "text": "Your money is stored in a virtual bank account."},
	{"speaker": "", "text": "Every decision affects your balance, so spend it wisely."}
]

# --- NEW: The Dorm Dialogue Array ---
var DORM_DIALOGUE: Array = [
	{"speaker": "Kylie", "text": "Uy, bagong salta? I’m Kylie! Welcome to the chaos of Manila life."},
	{"speaker": "Kylie", "text": "First tip: Huwag kang gagastos agad ng hindi kailangan."},
	{"speaker": "Jane", "text": "Hehe... I'll try. First time ko mag-manage ng pera on my own."},
	{"speaker": "Kylie", "text": "You’ll need a part-time job eventually. Mahirap kapag allowance lang."},
	{"speaker": "Kylie", "text": "Actually, may kinukuhang part-timers yung café sa kanto."}
]

func _ready() -> void:
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	phone_mini.phone_clicked.connect(_on_phone_clicked)
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
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
	phone_mini.trigger_notification()

	choose_control.choice_made.connect(_on_choice_made)

func _on_phone_clicked() -> void:
	phone_mini.visible = false
	notification_pop.visible = false
	
	gray_screen_instance = GRAY_SCREEN_SCENE.instantiate()
	add_child(gray_screen_instance)
	
	phone_screen_instance = PHONE_SCREEN_SCENE.instantiate()
	add_child(phone_screen_instance)
	
	# click on the bank app
	phone_screen_instance.bank_app_clicked.connect(_on_bank_app_clicked)
	
	# Create invisible shield to block clicks
	var click_shield = ColorRect.new()
	click_shield.color = Color(0, 0, 0, 0) 
	click_shield.set_anchors_preset(Control.PRESET_FULL_RECT) 
	click_shield.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# Add shield to the instance variable
	phone_screen_instance.add_child(click_shield)
	
	await new_feature_control.play_feature_intro()
	dialogue_box.start_dialogue(BANK_DIALOGUE, 1.0)
	await dialogue_box.dialogue_finished
	await get_tree().create_timer(0.5).timeout
	
	click_shield.queue_free()
	# Force bank button to unlock and accept clicks
	phone_screen_instance.unlock_app()


func _on_bank_app_clicked() -> void:
	# Hide the main phone screen
	if phone_screen_instance:
		phone_screen_instance.visible = false
		
	# Instantiate the virtual bank screen
	virtual_bank_instance = PHONE_SCREEN_VIRTUAL_SCENE.instantiate()
	add_child(virtual_bank_instance)
	
	# Listen for the withdrawal signal
	virtual_bank_instance.money_withdrawn.connect(_on_money_withdrawn)
	
	# for the back button signal 
	virtual_bank_instance.back_clicked.connect(_on_virtual_bank_back_clicked)


# Function that adds the money to HUD
func _on_money_withdrawn(amount: int) -> void:
	# calls the add_money function that already exists inside currency_hud.gd
	currency_hud.add_money(amount)


func _on_window_resized():
	var screen_size = get_viewport_rect().size
	var frame_size = animated_bg.sprite_frames.get_frame_texture("idle", 0).get_size()
	
	if frame_size.x > 0 and frame_size.y > 0:
		animated_bg.scale = screen_size / frame_size
		animated_bg.position = screen_size / 2.0

#  Function to handle the back button click
func _on_virtual_bank_back_clicked() -> void:
	# Instantly destroy the phone UI, gray screen, and hide Jane.
	if virtual_bank_instance:
		virtual_bank_instance.queue_free()
	if phone_screen_instance:
		phone_screen_instance.queue_free()
	if gray_screen_instance:
		gray_screen_instance.queue_free()
		
	jane.hide() 
	
	# Wait 1.0 second. 
	# During this time, only the bus background and the Currency HUD are visible
	await get_tree().create_timer(1.0).timeout
	
	# Start the transition by fading to black
	await TransitionManager.fade_to_black()
		
	# The screen is black Switch the background to the Dorm in secret
	var dorm_background = TextureRect.new()
	dorm_background.texture = DORM_BG
	dorm_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	dorm_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	add_child(dorm_background)
	move_child(dorm_background, 0) 
	
	# Hide the old bus arrival background
	animated_bg.hide()
	
	#  Wait 0.5 seconds while black for dramatic cinematic effect
	await get_tree().create_timer(1.5).timeout
	
	# Fade out the black screen to reveal the Dorm!
	await TransitionManager.fade_from_black()
	
	# Wait exactly 1.0 second after the dorm appears (CHANGED)
	await get_tree().create_timer(1.0).timeout
	
	# Tell Kylie to fade in (uses the default "idle" animation)
	kylie.appear()
	
	# Wait 2.0 seconds while she is fully visible on screen (CHANGED)
	await get_tree().create_timer(2.0).timeout
	
	# Tell Kylie to fade out smoothly
	kylie.exit(true)
	
	# Wait 0.5 seconds to ensure Big Kylie is completely invisible before moving on
	await get_tree().create_timer(0.5).timeout
	
	
	# Start the dialogue box fade-in FIRST (0.5 means it takes half a second)
	dialogue_box.start_dialogue(DORM_DIALOGUE, 0.5)
	
	# Wait exactly 0.5 seconds for the dialogue box to finish appearing
	await get_tree().create_timer(0.5).timeout
	
	#  Now that the box is there, trigger the characters to fade in!
	jane_dialogue.appear()
	kylie_dialogue.appear()
	
	# Wait for the player to click through all the text
	await dialogue_box.dialogue_finished
	
	# Instantly trigger the character fade-out!
	jane_dialogue.exit(true)
	kylie_dialogue.exit(true)
	
	# Wait 1.0 second after the characters fade out
	await get_tree().create_timer(1.0).timeout
	
	# FADE IN TOGETHER
	choose_control.appear()
	jane_big_2.appear()

func _on_choice_made(selected_choice: String) -> void:
	
	# Save it to Global
	Global.job_choice = selected_choice
	
	# Fade the choices menu out
	choose_control.exit()
	
	# Force Jane to fade out using a direct tween
	var tween = create_tween()
	tween.tween_property(jane_big_2, "modulate:a", 0.0, 0.5)
	
	# Wait exactly 0.5 seconds for both fade animations to finish
	await get_tree().create_timer(0.5).timeout
	
	# The screen is clean, Trigger the transition to Scene 2
	TransitionManager.transition_to(NEXT_SCENE)
