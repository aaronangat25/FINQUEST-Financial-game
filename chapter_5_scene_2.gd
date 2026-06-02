extends Control

# --- PRELOADED SCENES ---
const CURRENCY_HUD_SCENE = preload("res://Scenes/Currency/currency_hud.tscn")
const DIALOGUE_BOX_SCENE = preload("res://Scenes/Dialogue Box/dialogue_box.tscn")

# --- NODE REFERENCES ---
@onready var jane_thinking = $Jane2DThinkingAnchor/jane2d_thinking 
@onready var jane_big_anchor = $JaneBigAnchor
@onready var jane_big_sprite = $JaneBigAnchor/jane2d         
@onready var phone_mini = $PhoneMini               
@onready var phone_ringing = $PhoneRinging        
@onready var mom_anchor = $MomAnchor
@onready var mom_sprite = $MomAnchor/mom2d        
@onready var dad_anchor = $DadAnchor
@onready var dad_sprite = $DadAnchor/dad2d        
@onready var jane_talking = $JaneDialogueAnchor/jane2d

var currency_hud
var active_dialogue_box

# State Flags
var is_phone_waiting_for_click: bool = false

func _ready() -> void:
	# Continuous ambient exploration tracks flowing through call setups smoothly
	AudioManager.play_chapter_music()

	
	Global.player_money = GameManager.on_hand_cash

	# 1. Persistent UI setup
	currency_hud = CURRENCY_HUD_SCENE.instantiate()
	call_deferred("add_child", currency_hud)
	currency_hud.show()
	
	# 2. Reset visibility defaults at frame zero (Keep Jane Hidden)
	if jane_thinking:
		jane_thinking.hide()
		jane_thinking.modulate.a = 0.0
	if jane_big_anchor: jane_big_anchor.hide()
	if jane_big_sprite: jane_big_sprite.hide()
	if phone_ringing: phone_ringing.hide()
	if mom_anchor: mom_anchor.hide()
	if dad_anchor: dad_anchor.hide()
	
	if jane_talking:
		jane_talking.hide()
		jane_talking.modulate.a = 0.0
		var talking_parent = jane_talking.get_parent()
		if talking_parent is CanvasItem: talking_parent.hide()
	
	# Enforce visibility priority over backdrops but keep hidden initially
	if phone_mini:
		phone_mini.hide()
		if "layer" in phone_mini:
			phone_mini.layer = 10 
			
	await get_tree().process_frame
	
	# Force display synchronization on scene ready load
	if currency_hud and currency_hud.has_method("refresh_display"):
		currency_hud.refresh_display()
	
	if TransitionManager.color_rect.visible:
		await TransitionManager.fade_from_black()
		
	_play_ringing_intro()


# --- STEP 1: THE INCOMING CALL ALERT ---
func _play_ringing_intro() -> void:
	await get_tree().create_timer(0.5).timeout
	
	if jane_big_anchor: jane_big_anchor.hide()
	if jane_big_sprite: jane_big_sprite.hide()
		
	# Spawn the alert dialogue overlay text window
	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	active_dialogue_box.is_fading = true 
	active_dialogue_box.show()
	
	var name_box_panel = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer/Panel")
	if name_box_panel:
		name_box_panel.hide()
		
	var box_visual = active_dialogue_box.get_node_or_null("MarginContainer/texturerectContainer")
	if box_visual:
		box_visual.modulate.a = 0.0
		var t_box_in = create_tween()
		t_box_in.tween_property(box_visual, "modulate:a", 1.0, 0.5)
		await t_box_in.finished
	
	# --- AUDIO LAYER INITIALIZATION ---
	# Starts looping your custom MP3 ringtone asset right as the text wrapper triggers!
	AudioManager.play_sfx("PHONE_RING")
	
	# Play dialogue text while phone is hidden
	active_dialogue_box.is_fading = false
	active_dialogue_box.start_dialogue([{"speaker": "", "text": "Someone is calling,\npick it up"}])
	
	if name_box_panel: 
		name_box_panel.hide()
	
	await active_dialogue_box.dialogue_finished
	
	# Dialogue box fades out completely and disappears
	if box_visual:
		var t_box_out = create_tween()
		t_box_out.tween_property(box_visual, "modulate:a", 0.0, 0.5)
		await t_box_out.finished
	active_dialogue_box.queue_free()
	
	# Now we show her alongside the mini phone ring alerts
	if jane_big_anchor:
		jane_big_anchor.show()
		jane_big_anchor.modulate.a = 1.0
	if jane_big_sprite:
		jane_big_sprite.show()
		jane_big_sprite.modulate.a = 1.0

	if phone_mini:
		phone_mini.show()
		if "layer" in phone_mini:
			phone_mini.layer = 10 
		if phone_mini.has_method("appear"):
			phone_mini.appear()
		if phone_mini.has_method("trigger_notification"):
			phone_mini.trigger_notification()
			
	is_phone_waiting_for_click = true


# --- STEP 2: DETECT PHONE PICK UP CLICK ---
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_phone_waiting_for_click:
			if phone_mini and phone_mini.get_child_count() > 0:
				var phone_ui = phone_mini.get_child(0)
				if phone_ui is Control and phone_ui.get_global_rect().has_point(event.position):
					
					is_phone_waiting_for_click = false
					if phone_mini: phone_mini.hide()
					
					# --- THE PERFECT AUDIO RESET STOP ---
					# Safely breaks out of the loop tracker so it doesn't bleed into parent lines!
					AudioManager.stop_sfx("PHONE_RING")
					
					# Make her disappear instantly when the call is answered
					if jane_big_sprite: jane_big_sprite.hide()
					if jane_big_anchor: jane_big_anchor.hide()
					
					_start_family_call_conversation()


# --- STEP 3: THE FAMILY CALL CONVERSATION LOOP ---
func _start_family_call_conversation() -> void:
	if phone_ringing:
		phone_ringing.show()
		phone_ringing.modulate.a = 1.0

	# =====================================================================
	# Turn 1: Mom Dialogue Frame
	# =====================================================================
	if mom_anchor:
		mom_anchor.show()
		mom_anchor.modulate.a = 1.0
	if mom_sprite:
		mom_sprite.show()
		mom_sprite.modulate.a = 1.0
		if mom_sprite.has_method("appear"): mom_sprite.appear()

	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	move_child(active_dialogue_box, get_child_count() - 1)
	active_dialogue_box.is_fading = false
	
	active_dialogue_box.start_dialogue([{"speaker": "Mom", "text": "Anak, proud na proud kami sa’yo."}])
	await active_dialogue_box.dialogue_finished
	active_dialogue_box.queue_free()
	
	if mom_anchor: mom_anchor.hide()
	await get_tree().process_frame

	# =====================================================================
	# Turn 2: Dad Dialogue Frame
	# =====================================================================
	if dad_anchor:
		dad_anchor.show()
		dad_anchor.modulate.a = 1.0
	if dad_sprite:
		dad_sprite.show()
		dad_sprite.modulate.a = 1.0
		if dad_sprite.has_method("appear"): dad_sprite.appear()

	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	move_child(active_dialogue_box, get_child_count() - 1)
	active_dialogue_box.is_fading = false
	
	active_dialogue_box.start_dialogue([{"speaker": "Dad", "text": "From SHS hanggang college… ang dami mong pinagdaanan."}])
	await active_dialogue_box.dialogue_finished
	active_dialogue_box.queue_free()
	
	if dad_anchor: dad_anchor.hide()
	await get_tree().process_frame

	# =====================================================================
	# Turn 3: Jane Responds on Call
	# =====================================================================
	if jane_talking:
		var talking_parent = jane_talking.get_parent()
		if talking_parent is CanvasItem:
			talking_parent.show()
			talking_parent.modulate.a = 1.0
			
		jane_talking.show()
		jane_talking.modulate.a = 1.0
		if jane_talking.has_method("appear"): 
			jane_talking.appear("idle", false)

	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	move_child(active_dialogue_box, get_child_count() - 1)
	active_dialogue_box.is_fading = false
	
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Hindi ko rin po kinaya wiithout your support."}])
	await active_dialogue_box.dialogue_finished
	active_dialogue_box.queue_free()
	
	if jane_talking: 
		jane_talking.hide()
		var talking_parent = jane_talking.get_parent()
		if talking_parent is CanvasItem: talking_parent.hide()
	await get_tree().process_frame

	# =====================================================================
	# Turn 4: Mom Speaks Again
	# =====================================================================
	if mom_anchor:
		mom_anchor.show()
		mom_anchor.modulate.a = 1.0
	if mom_sprite:
		mom_sprite.show()
		mom_sprite.modulate.a = 1.0
		if mom_sprite.has_method("appear"): mom_sprite.appear()

	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	move_child(active_dialogue_box, get_child_count() - 1)
	active_dialogue_box.is_fading = false
	
	active_dialogue_box.start_dialogue([
		{"speaker": "Mom", "text": "At hindi lang support namiin—ikaw din."},
		{"speaker": "Mom", "text": "Natuto kang mag-budget, magtrabaho, at maging responsable."}
	])
	await active_dialogue_box.dialogue_finished
	active_dialogue_box.queue_free()
	
	if mom_anchor: mom_anchor.hide()
	await get_tree().process_frame

	# =====================================================================
	# Turn 5: Dad Concludes
	# =====================================================================
	if dad_anchor:
		dad_anchor.show()
		dad_anchor.modulate.a = 1.0
	if dad_sprite:
		dad_sprite.show()
		dad_sprite.modulate.a = 1.0
		if dad_sprite.has_method("appear"): dad_sprite.appear()

	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	move_child(active_dialogue_box, get_child_count() - 1)
	active_dialogue_box.is_fading = false
	
	active_dialogue_box.start_dialogue([{"speaker": "Dad", "text": "The real test starts after graduation."}])
	await active_dialogue_box.dialogue_finished
	active_dialogue_box.queue_free()
	
	if dad_anchor: dad_anchor.hide()
	await get_tree().process_frame

	# =====================================================================
	# Turn 6: Jane Thinking Reflection Monologue
	# =====================================================================
	if jane_thinking:
		var thinking_parent = jane_thinking.get_parent()
		if thinking_parent is CanvasItem:
			thinking_parent.show()
			thinking_parent.modulate.a = 1.0
		jane_thinking.show()
		jane_thinking.modulate.a = 1.0
		if jane_thinking.has_method("appear"):
			jane_thinking.appear("idle", false)

	active_dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(active_dialogue_box)
	move_child(active_dialogue_box, get_child_count() - 1)
	active_dialogue_box.is_fading = false
	
	active_dialogue_box.start_dialogue([{"speaker": "Jane", "text": "Tama sila… this is just the beginning."}])
	await active_dialogue_box.dialogue_finished
	active_dialogue_box.queue_free()
	
	if jane_thinking:
		jane_thinking.hide()
		var thinking_parent = jane_thinking.get_parent()
		if thinking_parent is CanvasItem: thinking_parent.hide()

	# Fade graphics layers out parallelly
	var t_end = create_tween().set_parallel(true)
	if phone_ringing: t_end.tween_property(phone_ringing, "modulate:a", 0.0, 0.4)
	await t_end.finished
	
	if phone_ringing: phone_ringing.hide()
	_transition_to_scene_3()


# --- STEP 4: NEXT SCENE PIPELINE TRANSITION ---
func _transition_to_scene_3() -> void:
	if TransitionManager.has_method("fade_to_black"):
		await TransitionManager.fade_to_black()
		
	var next_scene_path = "res://Scenes/Chapter 5/chapter_5_scene_3.tscn"
	ResourceLoader.load_threaded_request(next_scene_path)
	var load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
	
	while load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().create_timer(0.1).timeout 
		load_status = ResourceLoader.load_threaded_get_status(next_scene_path)
		
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		get_tree().change_scene_to_packed(new_scene)
