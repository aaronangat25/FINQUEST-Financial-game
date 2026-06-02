extends Control

# --- PRELOADED SCENES ---
const COFFEE_FLAVORS_UI_SCENE = preload("res://Scenes/Chapter 1/coffee_flavors_ui.tscn")
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn") 

# --- NODE REFERENCES ---
@onready var mns_button_container = $button_layer/mns_button_container
@onready var enc_button_container = $button_layer/enc_button_container

@onready var milk_btn = $button_layer/mns_button_container/milktbtn
@onready var strawberry_btn = $button_layer/mns_button_container/strawberrybtn
@onready var espresso_btn = $button_layer/enc_button_container/espressobtn
@onready var chocolate_btn = $button_layer/enc_button_container/chocolatebtn

# --- ANIMATION SCRIPT LAYERS ---
var active_flavors_ui: CanvasLayer 
var coffee_ui_intro: AnimatedSprite2D
var coffee_ui_intro2: AnimatedSprite2D
var coffee_ui_milk: AnimatedSprite2D
var coffee_ui_strawberry: AnimatedSprite2D
var coffee_ui_espresso: AnimatedSprite2D
var coffee_ui_chocolate: AnimatedSprite2D

# Combo Mix Sprites
var coffee_ui_milkxstraw: AnimatedSprite2D
var coffee_ui_milkxespresso: AnimatedSprite2D
var coffee_ui_milkxchocolate: AnimatedSprite2D
var coffee_ui_strawberryxmilk: AnimatedSprite2D
var coffee_ui_strawberryxchocolate: AnimatedSprite2D
var coffee_ui_chocolatexmilk: AnimatedSprite2D
var coffee_ui_chocolatexstrawberry: AnimatedSprite2D
var coffee_ui_espressoxmilk: AnimatedSprite2D

# Feedback UI Nodes
var like_ui: AnimatedSprite2D
var unlike_ui: AnimatedSprite2D

# --- HUD TRACKING LAYER ---
var active_hud: CanvasLayer

var is_input_locked: bool = false

# --- GAME SYSTEM TRACKERS ---
var choice_count: int = 0
var first_choice_flavor: String = ""

var has_selected_milk: bool = false
var has_selected_strawberry: bool = false
var has_selected_espresso: bool = false
var has_selected_chocolate: bool = false

func _ready() -> void:
	is_input_locked = true 
	choice_count = 0
	first_choice_flavor = ""
	
	has_selected_milk = false
	has_selected_strawberry = false
	has_selected_espresso = false
	has_selected_chocolate = false
	
	_hide_button_containers_instantly()

	# 1. Instantiate and mount the flavors animation canvas
	active_flavors_ui = COFFEE_FLAVORS_UI_SCENE.instantiate()
	add_child(active_flavors_ui)
	active_flavors_ui.layer = 1
	active_flavors_ui.hide()
	
	# 2. Instantiate and mount the Currency HUD scene
	if CURRENCY_HUD_SCENE:
		active_hud = CURRENCY_HUD_SCENE.instantiate()
		add_child(active_hud)
		active_hud.layer = 3 
		
		await get_tree().process_frame
		if active_hud.has_method("refresh_display"):
			active_hud.refresh_display()
	
	# Retrieve nodes
	coffee_ui_intro = active_flavors_ui.find_child("coffee_ui_intro", true, false)
	coffee_ui_intro2 = active_flavors_ui.find_child("coffee_ui_intro2", true, false)
	coffee_ui_milk = active_flavors_ui.find_child("coffee_ui_milk", true, false)
	coffee_ui_strawberry = active_flavors_ui.find_child("coffee_ui_strawberry", true, false)
	coffee_ui_espresso = active_flavors_ui.find_child("coffee_ui_espresso", true, false)
	coffee_ui_chocolate = active_flavors_ui.find_child("coffee_ui_chocolate", true, false)
	
	coffee_ui_milkxstraw = active_flavors_ui.find_child("coffee_ui_milkxstraw", true, false)
	coffee_ui_milkxespresso = active_flavors_ui.find_child("coffee_ui_milkxespresso", true, false)
	coffee_ui_milkxchocolate = active_flavors_ui.find_child("coffee_ui_milkxchocolate", true, false)
	coffee_ui_strawberryxmilk = active_flavors_ui.find_child("coffee_ui_strawberryxmilk", true, false)
	coffee_ui_strawberryxchocolate = active_flavors_ui.find_child("coffee_ui_strawberryxchocolate", true, false)
	coffee_ui_chocolatexmilk = active_flavors_ui.find_child("coffee_ui_chocolatexmilk", true, false)
	coffee_ui_chocolatexstrawberry = active_flavors_ui.find_child("coffee_ui_chocolatexstrawberry", true, false)
	coffee_ui_espressoxmilk = active_flavors_ui.find_child("coffee_ui_espressoxmilk", true, false)
	
	like_ui = active_flavors_ui.find_child("like_ui", true, false)
	unlike_ui = active_flavors_ui.find_child("unlike_ui", true, false)
	
	var all_sprites = [
		coffee_ui_intro, coffee_ui_intro2, coffee_ui_milk, 
		coffee_ui_strawberry, coffee_ui_espresso, coffee_ui_chocolate,
		coffee_ui_milkxstraw, coffee_ui_milkxespresso, coffee_ui_milkxchocolate,
		coffee_ui_strawberryxmilk, coffee_ui_strawberryxchocolate,
		coffee_ui_chocolatexmilk, coffee_ui_chocolatexstrawberry,
		coffee_ui_espressoxmilk, like_ui, unlike_ui
	]
	
	for sprite in all_sprites:
		if sprite:
			sprite.hide()
			sprite.stop()
			if sprite != like_ui and sprite != unlike_ui:
				_scale_sprite_to_fit_screen(sprite)
			else:
				sprite.modulate.a = 0.0
			
	if milk_btn: milk_btn.pressed.connect(func(): _on_flavor_button_pressed("milk"))
	if strawberry_btn: strawberry_btn.pressed.connect(func(): _on_flavor_button_pressed("strawberry"))
	if espresso_btn: espresso_btn.pressed.connect(func(): _on_flavor_button_pressed("espresso"))
	if chocolate_btn: chocolate_btn.pressed.connect(func(): _on_flavor_button_pressed("chocolate"))
			
	get_tree().root.size_changed.connect(_on_window_size_changed)
	await get_tree().process_frame
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()
	
	await get_tree().create_timer(2.0).timeout
	_play_intro_sequence()


# --- INTERFACE BUTTON SELECTION ENGINE ---
func _on_flavor_button_pressed(flavor_type: String) -> void:
	if is_input_locked: return
	
	if flavor_type == "milk" and has_selected_milk: return
	if flavor_type == "strawberry" and has_selected_strawberry: return
	if flavor_type == "espresso" and has_selected_espresso: return
	if flavor_type == "chocolate" and has_selected_chocolate: return
	
	is_input_locked = true 
	choice_count += 1
	_hide_button_containers()
	
	if flavor_type == "milk": has_selected_milk = true
	elif flavor_type == "strawberry": has_selected_strawberry = true
	elif flavor_type == "espresso": has_selected_espresso = true
	elif flavor_type == "chocolate": has_selected_chocolate = true

	if choice_count == 1:
		first_choice_flavor = flavor_type
		
		if coffee_ui_intro2:
			_scale_sprite_to_fit_screen(coffee_ui_intro2)
			coffee_ui_intro2.show()
			coffee_ui_intro2.play("idle")
			if coffee_ui_intro: coffee_ui_intro.hide()
			
			await _wait_for_animation_runtime(coffee_ui_intro2, "idle")
			await get_tree().create_timer(1.0).timeout
			
		_process_first_choice_animation(flavor_type)
		
	elif choice_count == 2:
		_process_second_choice_animation(flavor_type)


# --- RUN ANIMATION FOR FIRST INGREDIENT CHOICE ---
func _process_first_choice_animation(flavor_type: String) -> void:
	var target_sprite: AnimatedSprite2D = null
	
	if flavor_type == "milk": target_sprite = coffee_ui_milk
	elif flavor_type == "strawberry": target_sprite = coffee_ui_strawberry
	elif flavor_type == "espresso": target_sprite = coffee_ui_espresso
	elif flavor_type == "chocolate": target_sprite = coffee_ui_chocolate
	
	if target_sprite:
		_scale_sprite_to_fit_screen(target_sprite)
		target_sprite.show()
		target_sprite.play("idle")
		
		if coffee_ui_intro2: coffee_ui_intro2.hide()
		await _wait_for_animation_runtime(target_sprite, "idle")
		
	_reveal_button_containers()


# --- RUN ANIMATION FOR SECOND INGREDIENT MIX COMBO ---
func _process_second_choice_animation(second_flavor: String) -> void:
	var target_combo_sprite: AnimatedSprite2D = null
	var previous_active_sprite: AnimatedSprite2D = null
	
	if first_choice_flavor == "milk": previous_active_sprite = coffee_ui_milk
	elif first_choice_flavor == "strawberry": previous_active_sprite = coffee_ui_strawberry
	elif first_choice_flavor == "espresso": previous_active_sprite = coffee_ui_espresso
	elif first_choice_flavor == "chocolate": previous_active_sprite = coffee_ui_chocolate

	# Combinations
	if first_choice_flavor == "milk":
		if second_flavor == "strawberry": target_combo_sprite = coffee_ui_milkxstraw
		elif second_flavor == "espresso": target_combo_sprite = coffee_ui_milkxespresso
		elif second_flavor == "chocolate": target_combo_sprite = coffee_ui_milkxchocolate

	elif first_choice_flavor == "strawberry":
		if second_flavor == "milk": target_combo_sprite = coffee_ui_strawberryxmilk
		elif second_flavor == "chocolate": target_combo_sprite = coffee_ui_strawberryxchocolate

	elif first_choice_flavor == "chocolate":
		if second_flavor == "milk": target_combo_sprite = coffee_ui_chocolatexmilk
		elif second_flavor == "strawberry": target_combo_sprite = coffee_ui_chocolatexstrawberry

	elif first_choice_flavor == "espresso":
		if second_flavor == "milk": target_combo_sprite = coffee_ui_espressoxmilk

	if target_combo_sprite:
		_scale_sprite_to_fit_screen(target_combo_sprite)
		target_combo_sprite.show()
		target_combo_sprite.play("idle")
		
		if previous_active_sprite: previous_active_sprite.hide()
		await _wait_for_animation_runtime(target_combo_sprite, "idle")
		print("Combo mix animation completely finished!")
		
		# Check combo outcomes matching
		if (first_choice_flavor == "espresso" and second_flavor == "milk") or (first_choice_flavor == "milk" and second_flavor == "espresso"):
			await get_tree().create_timer(1.5).timeout
			# Pass true to activate reward loops synchronized with the visual popping effect
			await _run_like_ui_sequence(true) 
		else:
			await get_tree().create_timer(1.5).timeout
			await _run_unlike_ui_sequence()
			
		await get_tree().create_timer(1.5).timeout
		_trigger_final_scene_exit()


# --- DYNAMIC LIKE_UI POP EFFECT SEQUENCER ---
func _run_like_ui_sequence(should_payout: bool = false) -> void:
	if like_ui:
		print("Fading in like_ui fast...")
		like_ui.show()
		like_ui.frame = 0
		
		var t_in = create_tween()
		t_in.tween_property(like_ui, "modulate:a", 1.0, 0.2)
		
		# --- FIXED: USING CLERK STORE SYSTEM TO PERMANENTLY ADJUST BALANCES ---
		if should_payout:
			# Play income cash register audio chime if configured
			if AudioManager.has_method("play_sfx"):
				AudioManager.play_sfx("INCOME")
				
			# Route finance addition through GameManager securely
			GameManager.stage_finance_change(0, 150, "Chapter 1 Barista Training Perfect Reward")
			
			# Fallback backup updates to direct global registers to double-safeguard pipeline
			if "current_money" in Global: Global.current_money += 150
			if "player_money" in Global: Global.player_money += 150
			
			# Force immediate re-draw call on the container text label node
			if active_hud and active_hud.has_method("refresh_display"):
				active_hud.refresh_display()
			
		await t_in.finished
		
		like_ui.play("idle")
		await _wait_for_animation_runtime(like_ui, "idle")
		
		var t_out = create_tween()
		t_out.tween_property(like_ui, "modulate:a", 0.0, 0.2)
		await t_out.finished
		like_ui.hide()


# --- DYNAMIC UNLIKE_UI POP EFFECT SEQUENCER ---
func _run_unlike_ui_sequence() -> void:
	if unlike_ui:
		unlike_ui.show()
		unlike_ui.frame = 0
		var t_in = create_tween()
		t_in.tween_property(unlike_ui, "modulate:a", 1.0, 0.2)
		await t_in.finished
		
		unlike_ui.play("idle")
		await _wait_for_animation_runtime(unlike_ui, "idle")
		
		var t_out = create_tween()
		t_out.tween_property(unlike_ui, "modulate:a", 0.0, 0.2)
		await t_out.finished
		unlike_ui.hide()


func _trigger_final_scene_exit() -> void:
	if "barista_game_completed" in Global:
		Global.barista_game_completed = true

	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
	else:
		await get_tree().create_timer(1.0).timeout
		
	get_tree().change_scene_to_file("res://Scenes/Chapter 1/chapter_1_barista.tscn")
	
	if TransitionManager.has_method("fade_from_black"):
		await TransitionManager.fade_from_black()


# --- TIMING AND MATH CALCULATOR CORE ---
func _wait_for_animation_runtime(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if not sprite or not sprite.sprite_frames.has_animation(anim_name): return
	var frame_count = sprite.sprite_frames.get_frame_count(anim_name)
	var fps = sprite.sprite_frames.get_animation_speed(anim_name)
	var duration = float(frame_count) / float(fps)
	await get_tree().create_timer(duration).timeout


func _play_intro_sequence() -> void:
	if active_flavors_ui: active_flavors_ui.show() 
	if coffee_ui_intro:
		_scale_sprite_to_fit_screen(coffee_ui_intro)
		coffee_ui_intro.show()
		coffee_ui_intro.play("idle")
		await _wait_for_animation_runtime(coffee_ui_intro, "idle")
		await get_tree().create_timer(1.0).timeout 
		_reveal_button_containers()


# --- INTERFACE REVEAL CONTROLLERS ---
func _reveal_button_containers() -> void:
	if mns_button_container:
		mns_button_container.show()
		mns_button_container.modulate.a = 1.0
	if enc_button_container:
		enc_button_container.show()
		enc_button_container.modulate.a = 1.0
		
	if (first_choice_flavor == "strawberry" or first_choice_flavor == "chocolate") and espresso_btn:
		espresso_btn.hide()
	else:
		if espresso_btn: espresso_btn.show()

	if first_choice_flavor == "espresso":
		if strawberry_btn: strawberry_btn.hide()
		if chocolate_btn: chocolate_btn.hide()
	else:
		if strawberry_btn: strawberry_btn.show()
		if chocolate_btn: chocolate_btn.show()

	# Mouse Filter Controls
	if milk_btn:
		milk_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE if has_selected_milk else Control.MOUSE_FILTER_STOP
		if has_selected_milk: milk_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
		
	if strawberry_btn:
		strawberry_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE if has_selected_strawberry else Control.MOUSE_FILTER_STOP
		if has_selected_strawberry: strawberry_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
		
	if espresso_btn:
		espresso_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE if has_selected_espresso else Control.MOUSE_FILTER_STOP
		if has_selected_espresso: espresso_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
		
	if chocolate_btn:
		chocolate_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE if has_selected_chocolate else Control.MOUSE_FILTER_STOP
		if has_selected_chocolate: chocolate_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
		
	is_input_locked = false 


func _hide_button_containers() -> void:
	if mns_button_container: mns_button_container.hide()
	if enc_button_container: enc_button_container.hide()


func _hide_button_containers_instantly() -> void:
	if mns_button_container:
		mns_button_container.hide()
		mns_button_container.modulate.a = 0.0
	if enc_button_container:
		enc_button_container.hide()
		enc_button_container.modulate.a = 0.0


# --- TRANSFORM COORD POSITIONING ---
func _scale_sprite_to_fit_screen(sprite: AnimatedSprite2D) -> void:
	if not sprite or not sprite.sprite_frames: return
	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if texture:
		var v_size = sprite.get_viewport_rect().size
		var t_size = texture.get_size()
		sprite.scale = Vector2(v_size.x / t_size.x, v_size.y / t_size.y)
		sprite.global_position = v_size / 2.0


func _on_window_size_changed() -> void:
	var all_sprites = [
		coffee_ui_intro, coffee_ui_intro2, coffee_ui_milk, 
		coffee_ui_strawberry, coffee_ui_espresso, coffee_ui_chocolate,
		coffee_ui_milkxstraw, coffee_ui_milkxespresso, coffee_ui_milkxchocolate,
		coffee_ui_strawberryxmilk, coffee_ui_strawberryxchocolate,
		coffee_ui_chocolatexmilk, coffee_ui_chocolatexstrawberry,
		coffee_ui_espressoxmilk
	]
	for sprite in all_sprites:
		if is_instance_valid(sprite) and sprite.visible:
			_scale_sprite_to_fit_screen(sprite)
