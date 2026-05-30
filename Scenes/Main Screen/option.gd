extends CanvasLayer

# --- VERIFIED INTERNAL REFERENCE PATHS ---
@onready var music_toggle: CheckBox = $OptionPanel/MusicToggle
@onready var sfx_toggle: CheckBox = $OptionPanel/SFXToggle
@onready var close_btn: Button = $OptionPanel/close_container/CloseBtn

# --- DEDICATED HARDWARE BUS INDICES ---
@onready var music_bus_idx = AudioServer.get_bus_index("Music")
@onready var sfx_bus_idx = AudioServer.get_bus_index("SFX")
@onready var master_bus_idx = AudioServer.get_bus_index("Master")

func _ready() -> void:
	# Verifying every single node path resolves perfectly
	if music_toggle == null:
		print("[ERROR] Cannot find MusicToggle path! Check the name inside OptionPanel.")
	if sfx_toggle == null:
		print("[ERROR] Cannot find SFXToggle path! Check the name inside OptionPanel.")
	if close_btn == null:
		print("[ERROR] Cannot find CloseBtn path! Check close_container/CloseBtn.")

	# Fallback Safety: If separate "Music" or "SFX" buses don't exist yet in your Mixer, default to Master
	if music_bus_idx == -1: music_bus_idx = master_bus_idx
	if sfx_bus_idx == -1: sfx_bus_idx = master_bus_idx

	# 1. Sync check box states with running hardware levels safely
	if music_toggle:
		music_toggle.button_pressed = !AudioServer.is_bus_mute(music_bus_idx)
		if not music_toggle.toggled.is_connected(_on_music_toggled):
			music_toggle.toggled.connect(_on_music_toggled)
		
	if sfx_toggle:
		sfx_toggle.button_pressed = !AudioServer.is_bus_mute(sfx_bus_idx)
		if not sfx_toggle.toggled.is_connected(_on_sfx_toggled):
			sfx_toggle.toggled.connect(_on_sfx_toggled)
		
	# 2. Wire up the close button event handler programmatically
	if close_btn and not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)


# --- HARDWARE MUTING BUS TOGGLES ---

func _on_music_toggled(is_volume_on: bool) -> void:
	AudioServer.set_bus_mute(music_bus_idx, !is_volume_on)
	print("[AUDIO] Music active state updated: ", is_volume_on)

func _on_sfx_toggled(is_volume_on: bool) -> void:
	AudioServer.set_bus_mute(sfx_bus_idx, !is_volume_on)
	print("[AUDIO] SFX active state updated: ", is_volume_on)


# --- INTERACTIVE CLOSURE ---

func _on_close_pressed() -> void:
	self.hide() 
	print("[UI] Options menu closed.")
