extends Control

# =========================================
# FINQUEST PROLOGUE UTILITY RUNTIME
# =========================================

@onready var saving_screen = $SavingScreen # Path to your instantiated scene node

@onready var dialogue_box = $DialogueBox
@onready var background = $sunrise_bg 
@onready var transition_manager = $Transition_Manager

@onready var jane = $DialogueBox/JaneAnchor/jane2d
@onready var mom = $DialogueBox/MomAnchor/mom2d
@onready var dad = $DialogueBox/DadAnchor/dad2d

@onready var currency_hud = $CurrencyHUD
@onready var choices_container = $choices_container1
@onready var choices_container2 = $choices_container2

@onready var jane_big = $JaneBigAnchor/jane2dbig

@onready var rideatrain_btn = $choices_container1/rideatrain_btn
@onready var rideabus_btn = $choices_container1/rideabus_btn
@onready var walkschool_btn = $choices_container1/walkschool_btn

@onready var siomairice_btn = $choices_container2/siomairice_btn
@onready var bread_btn = $choices_container2/bread_btn

@onready var choices_container3 = $choices_container3
@onready var rideatrain_btn1 = $choices_container3/rideatrain_btn1
@onready var walktohome_btn = $choices_container3/walktohome_btn

const DINING_TABLE = preload("res://Assets/Backgrounds/Prologue/diningtable.jpg")
const OUTSIDE_BG = preload("res://Assets/Backgrounds/Prologue/outside_bg.png") 

# Preload the choice backgrounds
const TRAIN_BG = preload("res://Assets/Backgrounds/Prologue/rideatrainbg.jpg")
const BUS_BG = preload("res://Assets/Backgrounds/Prologue/rideabusbg.png")
const WALK_BG = preload("res://Assets/Backgrounds/Prologue/walktoschoolbg.png")

const CLASSROOM_BG = preload("res://Assets/Backgrounds/Prologue/classroombg.png")
const CANTEEN_BG = preload("res://Assets/Backgrounds/Prologue/canteenbg.jpg")
const OUTSIDEDARK_BG = preload("res://Assets/Backgrounds/Prologue/outsidedark_bg.png")

var current_scene = "breakfast"
var lunch_choice = ""

# --- THE MAGIC FIX: Lightweight Lock to ignore spam clicks! ---
var input_locked: bool = false

@onready var stats_screen = $StatsScreen
@onready var transport_label = $StatsScreen/Panel/TransportaionName/TransportLabel
@onready var lunch_label = $StatsScreen/Panel/LunchName/LunchLabel
@onready var total_label = $StatsScreen/Panel/TotalName/TotalLabel
@onready var feedback_label = $StatsScreen/Panel/FeedbackLabel

var transport_spent = 0
var lunch_spent = 0

const CHAPTER_1_SCENE = "res://Scenes/Chapter 1/chapter_1.tscn" 
@onready var chapter1_btn = $StatsScreen/Panel/Chapter1_btn
@onready var main_menu_btn = $StatsScreen/Panel/main_menu_btn


func _ready():
	# --- AUDIO INITIALIZATION ---
	AudioManager.play_chapter_music() # Fires up GENERAL MUSIC.mp3 immediately!
	
	input_locked = true # Lock inputs during the opening animation!
	
	# --- HIS CRITICAL ANTI-BLINK FIXES ---
	if is_instance_valid(stats_screen):
		stats_screen.hide()
		stats_screen.modulate.a = 0.0
	
	if is_instance_valid(choices_container):
		choices_container.hide()
		choices_container.modulate.a = 0.0
		
	if is_instance_valid(choices_container2):
		choices_container2.hide()
		choices_container2.modulate.a = 0.0 
	
	if is_instance_valid(choices_container3):
		choices_container3.hide()
		choices_container3.modulate.a = 0.0
	# -------------------------------------
	
	# --- HIS TRANSITION TITLE CARD FADE-OUT OPTIMIZATION ---
	var title_label = TransitionManager.get_node_or_null("TitleLabel")
	if title_label and title_label.visible:
		var t_title = create_tween()
		t_title.tween_property(title_label, "modulate:a", 0.0, 1.0)
		await t_title.finished
		title_label.hide()
		
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()

	dialogue_box.line_started.connect(_on_line_started)
	dialogue_box.line_finished.connect(_on_line_finished) 
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	
	rideatrain_btn.pressed.connect(_on_rideatrain_pressed)
	rideabus_btn.pressed.connect(_on_rideabus_pressed)
	walkschool_btn.pressed.connect(_on_walkschool_pressed)
	
	siomairice_btn.pressed.connect(_on_siomairice_pressed)
	bread_btn.pressed.connect(_on_bread_pressed)
	
	rideatrain_btn1.pressed.connect(_on_rideatrain_home_pressed)
	walktohome_btn.pressed.connect(_on_walktohome_pressed)
	
	# Connect your navigation buttons cleanly
	if chapter1_btn and not chapter1_btn.pressed.is_connected(_on_chapter1_btn_pressed):
		chapter1_btn.pressed.connect(_on_chapter1_btn_pressed)
	if main_menu_btn and not main_menu_btn.pressed.is_connected(_on_main_menu_btn_pressed):
		main_menu_btn.pressed.connect(_on_main_menu_btn_pressed) 
		
	var breakfast_sequence = [
		{"speaker": "", "text": "The sun is rising."},
		{"speaker": "Mom", "text": "Good morning, Jane! 9 am ang pasok mo diba?", "bg": DINING_TABLE, "show_jane": true, "show_mom": true},
		{"speaker": "Jane", "text": "Opo! I'm excited... and kinda nervous."},
		{"speaker": "Dad", "text": "You'll do great, anak. Eto ang weekly allowance mo: P500.", "show_dad": true, "hide_mom": true, "add_money": 500},
		{"speaker": "Mom", "text": "Remember, that has to cover your lunch, transportation, and any school needs until Friday.", "show_mom": true, "hide_dad": true},
		{"speaker": "Jane", "text": "Opo mom! I’ll spend it wisely."},
		{"speaker": "Mom", "text": "Lagi mo sinasabi yan."},
		{"speaker": "Dad", "text": "Just make smart choices, okay? Every peso counts.", "show_dad": true, "hide_mom": true}
	]
	
	await get_tree().create_timer(1.2).timeout
	dialogue_box.start_dialogue(breakfast_sequence, 1.0)
	input_locked = false # Unlock for dialogue clicks

func _on_line_started(line_data):
	if line_data.has("bg"):
		background.texture = line_data["bg"]
	if line_data.has("show_jane") and line_data["show_jane"] == true:
		jane.appear("idle", false) 
	if line_data.has("show_mom") and line_data["show_mom"] == true:
		if line_data.has("bg"): 
			mom.appear("idle", false) 
		else:
			mom.appear("idle", true) 
	if line_data.has("hide_mom") and line_data["hide_mom"] == true:
		mom.exit() 
	if line_data.has("show_dad") and line_data["show_dad"] == true:
		dad.appear("idle", true)
	if line_data.has("hide_dad") and line_data["hide_dad"] == true:
		dad.exit() 
		
func _on_line_finished(line_data):
	if line_data.has("add_money"):
		currency_hud.add_money(line_data["add_money"])

func _on_dialogue_finished():
	if input_locked: return 
	input_locked = true     # Lock while UI animates in/out
	
	if current_scene == "breakfast":
		jane.exit(true)
		mom.exit(true)
		dad.exit(true)
		current_scene = "outside" 
		transition_to_outside()
		
	elif current_scene == "outside":
		jane.exit(true) 
		show_choice_buttons()
		
	elif current_scene == "canteen":
		jane.exit() 
		dialogue_box.hide() 
		dialogue_box.get_node("MarginContainer/texturerectContainer").modulate.a = 0.0
		
		jane_big.appear()
		choices_container2.show()
		var tween = create_tween()
		tween.tween_property(choices_container2, "modulate:a", 1.0, 0.5)
		
		await tween.finished
		input_locked = false 
		
	elif current_scene == "after_lunch":
		jane.exit(true) 
		await get_tree().create_timer(0.5).timeout 
		
		if lunch_choice == "bread":
			rideatrain_btn1.show() 
			walktohome_btn.hide()  
		elif lunch_choice == "siomai":
			rideatrain_btn1.show() 
			walktohome_btn.show()  
			
		jane_big.modulate.a = 0.0 
		jane_big.show()           
		jane_big.appear()         
			
		choices_container3.show()
		var tween = create_tween()
		tween.tween_property(choices_container3, "modulate:a", 1.0, 0.5)
		
		await tween.finished
		input_locked = false 
		
	elif current_scene == "evening":
		jane.exit(true)
		show_stats_screen() 
		
func transition_to_outside():
	await get_tree().create_timer(0.5).timeout
	await transition_manager.fade_to_black()
	background.texture = OUTSIDE_BG
	await get_tree().create_timer(1.5).timeout
	await transition_manager.fade_from_black()
	
	dialogue_box.show()
	dialogue_box.get_node("MarginContainer/texturerectContainer").modulate.a = 1.0
		
	var outside_sequence = [
		{"speaker": "Jane", "text": "Okay, first decision of the day...", "show_jane": true}
	]
	dialogue_box.start_dialogue(outside_sequence, 1.0)
	input_locked = false 

func show_choice_buttons():
	await get_tree().create_timer(0.5).timeout
	choices_container.show()
	
	var tween = create_tween()
	tween.tween_property(choices_container, "modulate:a", 1.0, 0.5)
	jane_big.appear()
	
	await tween.finished
	input_locked = false 

# --- BUTTON CLICK FUNCTIONS ---

func _on_rideatrain_pressed():
	if input_locked: return
	input_locked = true
	currency_hud.add_money(-20)
	transport_spent += 20 
	execute_choice_transition(TRAIN_BG)

func _on_rideabus_pressed():
	if input_locked: return
	input_locked = true
	currency_hud.add_money(-35)
	transport_spent += 35
	execute_choice_transition(BUS_BG)

func _on_walkschool_pressed():
	if input_locked: return
	input_locked = true
	execute_choice_transition(WALK_BG)

# --- THE CINEMATIC CHOICE TRANSITION ---

func execute_choice_transition(new_bg):
	choices_container.hide()
	var tween = create_tween()
	tween.tween_property(jane_big, "modulate:a", 0.0, 0.5)
	
	await transition_manager.fade_to_black()
	background.texture = new_bg
	await get_tree().create_timer(1.0).timeout
	await transition_manager.fade_from_black()
	
	await get_tree().create_timer(2.0).timeout
	
	await transition_manager.fade_to_black()
	background.texture = CLASSROOM_BG
	await get_tree().create_timer(1.0).timeout
	await transition_manager.fade_from_black()
	
	await get_tree().create_timer(2.0).timeout
	
	await transition_manager.fade_to_black()
	background.texture = CANTEEN_BG
	await get_tree().create_timer(1.0).timeout
	await transition_manager.fade_from_black()
	
	current_scene = "canteen"
	
	var canteen_sequence = [
		{"speaker": "Jane", "text": "Hmm, anong lunch kaya? Meron silang siomai rice for P60 or just bread for P25.", "show_jane": true},
		{"speaker": "Jane", "text": "Hmm... should I go for the full meal or save a bit?"}
	]
	
	dialogue_box.show()
	dialogue_box.get_node("MarginContainer/texturerectContainer").modulate.a = 1.0
	dialogue_box.start_dialogue(canteen_sequence, 0.5)
	input_locked = false

func _on_siomairice_pressed():
	if input_locked: return
	input_locked = true
	currency_hud.add_money(-60)
	lunch_spent += 60 
	lunch_choice = "siomai" 
	show_after_lunch_dialogue()

func _on_bread_pressed():
	if input_locked: return
	input_locked = true
	currency_hud.add_money(-25)
	lunch_spent += 25
	lunch_choice = "bread"  
	show_after_lunch_dialogue()

func show_after_lunch_dialogue():
	choices_container2.hide()
	jane_big.hide() 
	current_scene = "after_lunch"
	
	var sequence = [
		{"speaker": "", "text": "JANE IS HAVING A LUNCH AND ABOUT TO FINISH."},
		{"speaker": "Jane", "text": "OKAY, TAPOS NA AKONG KUMAIN! ANONG WAY KAYA AKO UUWI?", "show_jane": true}
	]
	
	await get_tree().create_timer(0.5).timeout
	
	dialogue_box.show() 
	dialogue_box.get_node("MarginContainer/texturerectContainer").modulate.a = 1.0
	dialogue_box.start_dialogue(sequence)
	input_locked = false
	
# --- GOING HOME FUNCTIONS ---

func _on_rideatrain_home_pressed():
	if input_locked: return
	input_locked = true
	currency_hud.add_money(-20) 
	transport_spent += 20
	execute_going_home_transition(TRAIN_BG)

func _on_walktohome_pressed():
	if input_locked: return
	input_locked = true
	execute_going_home_transition(WALK_BG)

func execute_going_home_transition(transit_bg):
	choices_container3.hide()
	var tween = create_tween()
	tween.tween_property(jane_big, "modulate:a", 0.0, 0.5)
	
	await transition_manager.fade_to_black()
	background.texture = transit_bg
	await get_tree().create_timer(1.0).timeout
	await transition_manager.fade_from_black()
	
	await get_tree().create_timer(2.0).timeout
	
	await transition_manager.fade_to_black()
	background.texture = OUTSIDEDARK_BG
	await get_tree().create_timer(1.0).timeout
	await transition_manager.fade_from_black()
	
	current_scene = "evening"
	
	var final_money = currency_hud.current_money
	var evening_text = "OKAY, I STARTED THE DAY WITH P500... NGAYON MERON NALANG AKONG P" + str(final_money)
	
	var evening_sequence = [
		{"speaker": "Jane", "text": evening_text, "show_jane": true}
	]
	
	dialogue_box.show()
	dialogue_box.get_node("MarginContainer/texturerectContainer").modulate.a = 1.0
	dialogue_box.start_dialogue(evening_sequence, 0.5)
	input_locked = false
	
func show_stats_screen():
	transport_label.text = "P" + str(transport_spent)
	lunch_label.text = "P" + str(lunch_spent)
	total_label.text = "P" + str(currency_hud.current_money)
	
	if currency_hud.current_money >= 400:
		feedback_label.text = "Good Job! Keep it up."
		feedback_label.add_theme_color_override("font_color", Color.SEA_GREEN)
	else:
		feedback_label.text = "You spent a lot today. \nBe careful!"
		feedback_label.add_theme_color_override("font_color", Color.INDIAN_RED)
	
	stats_screen.show()
	var tween = create_tween()
	tween.tween_property(stats_screen, "modulate:a", 1.0, 1.0)
	
	await tween.finished
	input_locked = false 

# =========================================
# PROCEED DIRECTLY TO CHAPTER 1 BUTTON
# =========================================
func _on_chapter1_btn_pressed():
	if input_locked: return
	input_locked = true
	
	chapter1_btn.disabled = true 
	main_menu_btn.disabled = true 
	stats_screen.hide()
	currency_hud.hide() 
	
	# --- FIXED: Force the sandbox cache to clean balances BEFORE saving progress!
	GameManager.flush_buffer_to_database()
	
	if is_instance_valid(saving_screen) and saving_screen.has_method("trigger_save_sequence"):
		saving_screen.trigger_save_sequence(CHAPTER_1_SCENE)
	else:
		TransitionManager.transition_to(CHAPTER_1_SCENE, "CHAPTER 1")

# =========================================
# SAVE PROGRESS AND EXIT TO MAIN MENU BUTTON
# =========================================
func _on_main_menu_btn_pressed():
	if input_locked: return
	input_locked = true
	
	chapter1_btn.disabled = true
	main_menu_btn.disabled = true 
	stats_screen.hide()
	currency_hud.hide()
	
	# --- FIXED: Wipes tutorial cash records safely on menu drop exit
	GameManager.flush_buffer_to_database()
	
	var main_screen_path = "res://Scenes/Main Screen/main_screen.tscn"
	if is_instance_valid(saving_screen) and saving_screen.has_method("trigger_save_sequence"):
		saving_screen.trigger_save_sequence(main_screen_path)
	else:
		TransitionManager.transition_to(main_screen_path)
