extends Control

# --- PRELOADED SCENES & ASSETS ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DORM_BG = preload("res://Assets/Backgrounds/Chapter 1/dorm/dormbg.png")

# --- OUTDOOR EATING BACKGROUNDS ---
const KARINDERYA_BG = preload("res://Assets/Backgrounds/Chapter 1/outdooreat/karinderyabg.png")
const FASTFOOD_BG = preload("res://Assets/Backgrounds/Chapter 1/outdooreat/fastfoodbg.png")
const RESTO_BG = preload("res://Assets/Backgrounds/Chapter 1/outdooreat/restobg.png")

# --- UI OVERLAYS ---
const GRAY_SCREEN_SCENE = preload("res://Scenes/Gray Screen/gray_screen.tscn")
const PHONE_LOCK_SCENE = preload("res://Scenes/Phone/phone_lock_screen.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var sunrise_bg = $sunrisebg
@onready var jane = $JaneBigAnchor/jane2d
@onready var phone_mini = $PhoneMini
@onready var kylie = $KylieDialogueAnchor/kylie2d
@onready var jane_dialogue = $JaneDialogueAnchor/jane2d

# --- CHOICE UI REFERENCES ---
@onready var choose_control_2 = $ChooseControl2
@onready var karinderya_btn = $ChooseControl2/ChoicesContainer2/KarinderyaA_btn
@onready var fastfood_btn = $ChooseControl2/ChoicesContainer2/FastfoodB_btn
@onready var resto_btn = $ChooseControl2/ChoicesContainer2/RestoC_btn

# --- NOTIFICATION UI REFERENCES ---
@onready var notif_deduc = $Notifdeduc
@onready var notif_deduc_text = $Notifdeduc/Notifdeducpanel/Notifdeducttext

var currency_hud 
var active_background: TextureRect 

var active_gray_screen
var active_phone_lock
var active_dialogue_box

var choices_locked: bool = true

func _ready() -> void:

	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	
	choose_control_2.hide()
	choose_control_2.modulate.a = 0.0
	
	if notif_deduc:
		notif_deduc.hide()
	
	karinderya_btn.pressed.connect(_on_karinderya_pressed)
	fastfood_btn.pressed.connect(_on_fastfood_pressed)
	resto_btn.pressed.connect(_on_resto_pressed)
	
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	add_child(currency_hud)
	
	sunrise_bg.stop() 
	sunrise_bg.frame = 0
	
	phone_mini.phone_clicked.connect(_on_phone_clicked)
	
	_play_morning_ambience()
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.transition_finished
	
	_play_sunrise_sequence()


# --- SIMULTANEOUS AMBIENCE CARRIER ---
func _play_morning_ambience() -> void:
	print("[ENVIRONMENT] Scene loaded. Instantiating rooster and bird audio channels...")
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("ROOSTER")
		AudioManager.play_sfx("BIRD")


func _play_sunrise_sequence() -> void:
	sunrise_bg.play("idle")
	await sunrise_bg.animation_finished
	await get_tree().create_timer(1.0).timeout
	
	await TransitionManager.fade_to_black()
	sunrise_bg.hide()
	
	active_background = TextureRect.new()
	active_background.texture = DORM_BG
	active_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	active_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	add_child(active_background)
	move_child(active_background, 0) 
	
	await get_tree().create_timer(0.5).timeout
	await TransitionManager.fade_from_black()
	
	AudioManager.play_chapter_music()
	
	jane.appear()
	await get_tree().create_timer(1.0).timeout
	
	phone_mini.appear()
	await get_tree().create_timer(1.0).timeout
	
	AudioManager.play_sfx("NOTIFICATION")
	phone_mini.trigger_notification()


func _on_phone_clicked() -> void:
	phone_mini.hide()
	jane.hide()
	
	active_gray_screen = GRAY_SCREEN_SCENE.instantiate()
	add_child(active_gray_screen)
	
	active_phone_lock = PHONE_LOCK_SCENE.instantiate()
	add_child(active_phone_lock)
	
	var padlock_btn = active_phone_lock.get_node("PhoneLockScreenControl/phonelockscreen/padlocktexturebutton/padlockbutton")
	
	if padlock_btn:
		padlock_btn.pressed.connect(_on_padlock_pressed)
	else:
		print("ERROR: Could not find padlock. Check the node path!")


func _on_padlock_pressed() -> void:
	if active_gray_screen: active_gray_screen.queue_free()
	if active_phone_lock: active_phone_lock.queue_free()
		
	jane.hide()
	phone_mini.hide()
	
	await get_tree().create_timer(0.5).timeout
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	
	active_dialogue_box.is_fading = true
	
	var box_visual = active_dialogue_box.get_node("MarginContainer/texturerectContainer")
	var text_label = active_dialogue_box.get_node("MarginContainer/texturerectContainer/TextLabel")
	var name_panel = active_dialogue_box.get_node("MarginContainer/texturerectContainer/Panel")
	
	if box_visual:
		if text_label: text_label.text = ""
		if name_panel: name_panel.hide()
		
		active_dialogue_box.show() 
		box_visual.modulate.a = 0.0 
		var tween_in = create_tween()
		tween_in.tween_property(box_visual, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await tween_in.finished
	
	kylie.appear()
	await get_tree().create_timer(0.6).timeout
	
	var scene_2_dialogue = [
		{
			"speaker": "Kylie", 
			"text": "Let’s grab breakfast outside. Madami mura dito."
		}
	]
	
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue(scene_2_dialogue)
	
	await active_dialogue_box.dialogue_finished
	
	kylie.exit(true)
	await get_tree().create_timer(1.2).timeout
	
	active_dialogue_box.queue_free()
	
	choose_control_2.show()
	var tween_choices = create_tween()
	tween_choices.tween_property(choose_control_2, "modulate:a", 1.0, 0.5)
	
	await tween_choices.finished
	choices_locked = false


# --- FOOD CHOICE HANDLERS ---

func _on_karinderya_pressed() -> void:
	if choices_locked: return
	choices_locked = true
	GameManager.log_choice("chap1_breakfast_spending", "A")
	execute_food_transition(KARINDERYA_BG, 60)


func _on_fastfood_pressed() -> void:
	if choices_locked: return
	choices_locked = true
	GameManager.log_choice("chap1_breakfast_spending", "B")
	execute_food_transition(FASTFOOD_BG, 120)


func _on_resto_pressed() -> void:
	if choices_locked: return
	choices_locked = true
	GameManager.log_choice("chap1_breakfast_spending", "C")
	execute_food_transition(RESTO_BG, 350)


# --- THE TRANSITION LOGIC ---
func execute_food_transition(new_bg: Texture2D, cost: int) -> void:
	if not GameManager.verify_pocket_cash(cost):
		choices_locked = false
		return

	AudioManager.play_sfx("DEDUCT")
	
	GameManager.request_expense_payment(cost, "Chapter 1 Sandbox Breakfast Spending")
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	var tween = create_tween()
	tween.tween_property(choose_control_2, "modulate:a", 0.0, 0.5)
	
	await TransitionManager.fade_to_black()
	choose_control_2.hide() 
	
	if active_background:
		active_background.texture = new_bg
		
	await get_tree().create_timer(1.0).timeout
	await TransitionManager.fade_from_black()
	
	await get_tree().create_timer(1.5).timeout
	
	if notif_deduc_text:
		if cost == 60:
			notif_deduc_text.text = "– P60 was reducted to your\nallowance."
		elif cost == 120:
			notif_deduc_text.text = "– P120 was reducted to your\nallowance."
		elif cost == 350:
			notif_deduc_text.text = "– P350 was reducted to your\nallowance."
			
	if notif_deduc:
		notif_deduc.show()
		
	await get_tree().create_timer(2.0).timeout
	if notif_deduc:
		notif_deduc.hide()
		
	jane_dialogue.hide()
	jane_dialogue.modulate.a = 0.0
	kylie.hide()
	kylie.modulate.a = 1.0
	
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	
	var inner_box = active_dialogue_box.get_node("MarginContainer")
	if inner_box:
		inner_box.modulate.a = 0.0
		var tween_box_in = create_tween()
		tween_box_in.tween_property(inner_box, "modulate:a", 1.0, 0.4)
		await tween_box_in.finished
	
	var line_1_text = ""
	if cost == 60:
		line_1_text = "Ang sarap naman dito, parang lutong bahay talaga!"
	elif cost == 120:
		line_1_text = "Ang sarap dito, fast food service nga!"
	elif cost == 350:
		line_1_text = "Wow, ang ganda naman dito! Medyo mahal nga lang."

	var unified_dialogue = [
		{
			"speaker": "Jane",
			"text": line_1_text
		},
		{
			"speaker": "Kylie",
			"text": "Sa totoo lang! Ano, Jane, tara na? May shift ka pa sa training mo."
		},
		{
			"speaker": "Jane",
			"text": "Alright, tara na!"
		}
	]
	
	# Using array structure to safely bypass lambda scope pass-by-value quirks
	var dialogue_state = [false]
	active_dialogue_box.dialogue_finished.connect(func(): dialogue_state[0] = true)
	
	active_dialogue_box.start_dialogue(unified_dialogue)
	
	jane_dialogue.show()
	if jane_dialogue.has_method("appear"):
		jane_dialogue.appear("idle", false)
	else:
		var tween_jane_in = create_tween()
		tween_jane_in.tween_property(jane_dialogue, "modulate:a", 1.0, 0.4)
		await tween_jane_in.finished

	var current_tracked_speaker = "Jane"
	
	while not dialogue_state[0] and is_instance_valid(active_dialogue_box) and active_dialogue_box.visible:
		await get_tree().process_frame
		
		var text_node = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer/TextLabel")
		if text_node:
			var current_visible_text = text_node.text
			
			# (UNTOUCHED LINES 1 AND 2)
			if current_visible_text.begins_with("Sa") and current_tracked_speaker != "Kylie":
				current_tracked_speaker = "Kylie"
				jane_dialogue.hide()
				kylie.show()
				if kylie.get_node_or_null("AnimatedSprite2D"):
					kylie.get_node("AnimatedSprite2D").play("idle")
					
			elif current_visible_text.begins_with("Al") and current_tracked_speaker != "Jane":
				current_tracked_speaker = "Jane"
				kylie.hide()
				jane_dialogue.show()
				if jane_dialogue.get_node_or_null("AnimatedSprite2D"):
					jane_dialogue.get_node("AnimatedSprite2D").play("idle")
					
		if not active_dialogue_box.is_inside_tree():
			break
	
	# 🟢 FIXED OUTRO RULES: Removed the duplicate await freeze bug completely
	if jane_dialogue.has_method("exit"):
		jane_dialogue.exit(true)
	
	# Force explicit master alpha modulation tracking over Jane to guarantee visual cleanup
	var tween_char_out = create_tween()
	tween_char_out.tween_property(jane_dialogue, "modulate:a", 0.0, 0.4)
	await tween_char_out.finished
	
	jane_dialogue.hide()
	kylie.hide()
	
	# Spacing buffer break window before starting box animations
	await get_tree().create_timer(0.15).timeout 
	
	# Dialogue box fades out last safely
	if inner_box and is_instance_valid(active_dialogue_box):
		var tween_box_out = create_tween()
		tween_box_out.tween_property(inner_box, "modulate:a", 0.0, 0.3)
		await tween_box_out.finished
		
	if is_instance_valid(active_dialogue_box):
		active_dialogue_box.queue_free()
	
	# --- SCENE TRANSITION AND MINI-GAME HANDOFFS ---
	var time_skip_layer = CanvasLayer.new()
	time_skip_layer.layer = 128 
	
	var time_skip_black = ColorRect.new()
	time_skip_black.color = Color(0, 0, 0, 0) 
	time_skip_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	time_skip_layer.add_child(time_skip_black)
	add_child(time_skip_layer)
	
	var slow_fade_in = create_tween()
	slow_fade_in.tween_property(time_skip_black, "color:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	await slow_fade_in.finished
	
	if Global.chapter_1_cafe_choice == "A":
		AudioManager.play_coffee_shop_music()
		TransitionManager.transition_to("res://Scenes/Chapter 1/chapter_1_barista.tscn")
	elif Global.chapter_1_cafe_choice == "B":
		AudioManager.play_convenience_store_music()
		TransitionManager.transition_to("res://Scenes/Chapter 1/chapter_1_storeclerk.tscn")
	elif Global.chapter_1_cafe_choice == "C":
		AudioManager.play_convenience_store_music()
		TransitionManager.transition_to("res://Scenes/Chapter 1/chapter_1_cashier.tscn")


func _on_window_resized():
	var screen_size = get_viewport_rect().size
	if sunrise_bg and sunrise_bg.sprite_frames:
		var frame_size = sunrise_bg.sprite_frames.get_frame_texture("idle", 0).get_size()
		if frame_size.x > 0 and frame_size.y > 0:
			sunrise_bg.scale = screen_size / frame_size
			sunrise_bg.position = screen_size / 2.0
