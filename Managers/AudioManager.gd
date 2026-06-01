extends Node

# --- AUDIO TRACK PATHS (BGM) ---
const MAIN_MENU_MUSIC = "res://Assets/Audio/Music/FINQUEST-MAIN-MENU.ogg"
const GENERAL_MUSIC = "res://Assets/Audio/Music/GENERAL-MUSIC.ogg"
const COFFEE_SHOP_MUSIC = "res://Assets/Audio/Music/COFFEE-SHOP-POSSBLE-3.ogg"
const CONVENIENCE_STORE_MUSIC = "res://Assets/Audio/Music/Convenience-Store-and-supermarket.ogg"
const BAD_ENDING_MUSIC = "res://Assets/Audio/Music/For-bad-endings.ogg"

# --- SOUND EFFECT PATHS (SFX Inventory) ---
const SFX_MAP = {
	"CLICK": "res://Assets/Audio/SFX/Menu-Selection-Click.ogg",
	"SCANNER": "res://Assets/Audio/SFX/Barcode Scanner.ogg",
	"BUS": "res://Assets/Audio/SFX/Bus atmosphere.ogg",
	"DOORBELL": "res://Assets/Audio/SFX/Convinieence store doorbell.ogg",
	"ERROR": "res://Assets/Audio/SFX/error.ogg",
	"DEDUCT": "res://Assets/Audio/SFX/Money deduct.ogg",
	"NOTIFICATION": "res://Assets/Audio/SFX/Phone Notification.ogg",
	"TRAIN": "res://Assets/Audio/SFX/Train-Station-Sound-Effect.ogg",
	"INCOME": "res://Assets/Audio/SFX/Withdraw-or-money-increase.ogg",
	"BELL": "res://Assets/Audio/SFX/School bell sound effect.ogg",
	"PHONE_RING": "res://Assets/Audio/SFX/Ring call.ogg",
	"ROOSTER": "res://Assets/Audio/SFX/Rooster Sound.ogg",
	"BIRD": "res://Assets/Audio/SFX/Bird Sound.ogg"
}

# --- RUNTIME VARIABLES ---
var player_1 : AudioStreamPlayer
var player_2 : AudioStreamPlayer
var current_player : AudioStreamPlayer
var current_track_path : String = ""

# Dedicated channel for loopable environment details
var ambience_player : AudioStreamPlayer
var active_ambience_tween : Tween

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	
	# Initialize music players
	player_1 = AudioStreamPlayer.new()
	player_2 = AudioStreamPlayer.new()
	add_child(player_1)
	add_child(player_2)
	
	# --- FIXED ROUTING: Redirect Music to the Music Bus ---
	player_1.bus = "Music"
	player_2.bus = "Music"
	current_player = player_1

	# Initialize ambience channel
	ambience_player = AudioStreamPlayer.new()
	# --- FIXED ROUTING: Ambience counts as SFX/Environment ---
	ambience_player.bus = "SFX"
	add_child(ambience_player)

	# Global interaction hooks
	get_tree().node_added.connect(_on_scene_node_added)
	_hook_existing_buttons(get_tree().root)

# =================================================================
# GLOBAL AUTOMATED INTERACTION LISTENER
# =================================================================
func _on_scene_node_added(node: Node) -> void:
	if node is Button or node is TextureButton:
		_connect_button_click(node)

func _hook_existing_buttons(root_node: Node) -> void:
	if root_node is Button or root_node is TextureButton:
		_connect_button_click(root_node)
	for child in root_node.get_children():
		_hook_existing_buttons(child)

func _connect_button_click(button_node: Node) -> void:
	if not button_node.pressed.is_connected(_play_automatic_click):
		button_node.pressed.connect(_play_automatic_click)

func _play_automatic_click() -> void:
	play_sfx("CLICK")

# =================================================================
# CENTRALISED CROSS-FADE MECHANICS (BGM)
# =================================================================
func play_track(track_path: String, fade_duration: float = 1.0, force_restart: bool = false) -> void:
	if current_track_path == track_path and not force_restart:
		return
		
	current_track_path = track_path
	
	var old_player = current_player
	var new_player = player_2 if current_player == player_1 else player_1
	current_player = new_player
	
	var stream_resource = load(track_path)
	if not stream_resource:
		print("[AUDIO ERROR] Failed to load audio stream file at: ", track_path)
		return
		
	new_player.stream = stream_resource
	new_player.volume_db = -60.0
	new_player.play()
	
	var fade_tween = create_tween().set_parallel(true)
	
	if old_player.playing:
		fade_tween.tween_property(old_player, "volume_db", -60.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade_tween.chain().tween_callback(old_player.stop)
	
	fade_tween.tween_property(new_player, "volume_db", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# =================================================================
# AMBIENCE SOUND EFFECTS CONTROLLER (FADE UP / FADE OUT)
# =================================================================
func play_ambience(sfx_key: String, fade_duration: float = 0.5, start_from_sec: float = 0.0) -> void:
	if not SFX_MAP.has(sfx_key):
		return
		
	if active_ambience_tween:
		active_ambience_tween.kill()
		
	var stream_resource = load(SFX_MAP[sfx_key])
	if not stream_resource:
		return
		
	ambience_player.stream = stream_resource
	ambience_player.volume_db = -60.0
	
	ambience_player.play(start_from_sec)
	
	active_ambience_tween = create_tween()
	active_ambience_tween.tween_property(ambience_player, "volume_db", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
func fade_out_ambience(fade_duration: float = 1.0) -> void:
	if not ambience_player.playing:
		return
		
	if active_ambience_tween:
		active_ambience_tween.kill()
		
	active_ambience_tween = create_tween()
	active_ambience_tween.tween_property(ambience_player, "volume_db", -60.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_ambience_tween.chain().tween_callback(ambience_player.stop)

# =================================================================
# GLOBAL MUSIC HELPERS
# =================================================================
func play_menu_music() -> void:
	play_track(MAIN_MENU_MUSIC, 1.2, false)

func play_chapter_music() -> void:
	play_track(GENERAL_MUSIC, 1.5, false)

func restart_general_music() -> void:
	play_track(GENERAL_MUSIC, 1.0, true)

func play_coffee_shop_music() -> void:
	play_track(COFFEE_SHOP_MUSIC, 1.0, false)

func play_convenience_store_music() -> void:
	play_track(CONVENIENCE_STORE_MUSIC, 1.0, false)

func play_bad_ending_music() -> void:
	play_track(BAD_ENDING_MUSIC, 1.0, false)

# =================================================================
# FIXED SCHOOL BELL CUT MECHANICS
# =================================================================
func play_bell_short() -> void:
	var bell_player = AudioStreamPlayer.new()
	# --- FIXED ROUTING: Redirect Bell to SFX Bus ---
	bell_player.bus = "SFX"
	add_child(bell_player)
	
	var stream_resource = load(SFX_MAP["BELL"])
	if not stream_resource:
		bell_player.queue_free()
		return
		
	bell_player.stream = stream_resource
	bell_player.play(2.0)
	
	await get_tree().create_timer(2.0).timeout
	
	if is_instance_valid(bell_player):
		bell_player.stop()
		bell_player.queue_free()
		
# =================================================================
# AUTOMATED ONE-SHOT SFX ENGINE & LOOP TRACKER
# =================================================================
var active_looping_sfx: Dictionary = {}

func play_sfx(sfx_key: String, start_from_sec: float = 0.0) -> void:
	if not SFX_MAP.has(sfx_key):
		return
		
	var sfx_player = AudioStreamPlayer.new()
	# --- FIXED ROUTING: Redirect One-Shot SFX to SFX Bus ---
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	var stream_resource = load(SFX_MAP[sfx_key])
	if not stream_resource:
		sfx_player.queue_free()
		return
		
	sfx_player.stream = stream_resource
	
	if sfx_key == "PHONE_RING":
		sfx_player.stream.loop = true
		active_looping_sfx[sfx_key] = sfx_player
	else:
		sfx_player.finished.connect(sfx_player.queue_free)
		
	sfx_player.play(start_from_sec)

# =================================================================
# SPECIFIC SFX STOP TRIGGER
# =================================================================
func stop_sfx(sfx_key: String) -> void:
	if active_looping_sfx.has(sfx_key):
		var player = active_looping_sfx[sfx_key]
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
		active_looping_sfx.erase(sfx_key)

# =================================================================
# FORCE STOP MUSIC FUNCTION
# =================================================================
func stop_all_music() -> void:
	if active_looping_sfx.has("PHONE_RING"):
		stop_sfx("PHONE_RING")
		
	if is_instance_valid(player_1):
		player_1.stop()
		player_1.volume_db = -60.0
	if is_instance_valid(player_2):
		player_2.stop()
		player_2.volume_db = -60.0
		
	current_track_path = ""
