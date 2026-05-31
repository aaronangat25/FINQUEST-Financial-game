extends CanvasLayer

@onready var vbox_container: VBoxContainer = $AchievementPanel/ScrollContainer/MarginContainer/VBoxContainer
@onready var close_btn: Button = $AchievementPanel/close_container/CloseBtn

# UI Overlay node references
@onready var dark_bg: Panel = $DarkBG
@onready var tutorial_panel: Panel = $TutorialPanel
@onready var tutorial_label: RichTextLabel = $TutorialPanel/TutorialLabel

# Dict matrix matching your 12 manual node names to your official SQLite achievement_keys
const MASTER_DATA: Dictionary = {
	"Achievement1": {
		"key": "PROLOGUE",
		"title": "Every Peso Counts",
		"desc": "[color=#5E5E5E]Every Peso Counts[/color]\n\nHow to Unlock: Complete the SHS Prologue tutorial sequence.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement2": {
		"key": "NO_PASAHE",
		"title": "No-Pasahe Grind",
		"desc": "[color=#5E5E5E]No-Pasahe Grind[/color]\n\nHow to Unlock: Choose Option 2: Walk to school in Scene 2.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement3": {
		"key": "BANK_UNLOCKED",
		"title": "FinQuest Premium Member",
		"desc": "[color=#5E5E5E]FinQuest Premium Member[/color]\n\nHow to Unlock: Enter Scene 1 and trigger the virtual bank account feature.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement4": {
		"key": "BARISTA_PERFECT",
		"title": "Brewmaster Apprentice",
		"desc": "[color=#5E5E5E]Brewmaster Apprentice[/color]\n\nHow to Unlock: Complete the Barista mini-task in Scene 4 perfectly.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement5": {
		"key": "CLERK_PERFECT",
		"title": "Aisle Manager",
		"desc": "[color=#5E5E5E]Aisle Manager[/color]\n\nHow to Unlock: Choose A. 'Sa aisle 1, right side.' during the Store Clerk tutorial.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement6": {
		"key": "CASHIER_PERFECT",
		"title": "Human Calculator",
		"desc": "[color=#5E5E5E]Human Calculator[/color]\n\nHow to Unlock: Choose B. ₱40 during the Cashier tutorial change-computation.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement7": {
		"key": "ACADEMIC_WEAPON",
		"title": "Academic Weapon",
		"desc": "[color=#5E5E5E]Academic Weapon[/color]\n\nHow to Unlock: Achieve a perfect 1.0 grade in Chapter 2 Midterms.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement8": {
		"key": "INFLATION_FIGHTER",
		"title": "Inflation Fighter",
		"desc": "[color=#5E5E5E]Inflation Fighter[/color]\n\nHow to Unlock: Achieve the 'Excellent Budgeting' monthly result in Chapter 3.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement9": {
		"key": "SOPAS_STARBUCKS",
		"title": "Sopas over Starbucks",
		"desc": "[color=#5E5E5E]Sopas over Starbucks[/color]\n\nHow to Unlock: Skip a meal or buy only essentials during Chapter 3 Inflation.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement10": {
		"key": "MAGNA_CUM_BUDGET",
		"title": "Magna Cum Budget",
		"desc": "[color=#5E5E5E]Magna Cum Budget[/color]\n\nHow to Unlock: Secure an 'Outstanding Defense (1.0)' in Chapter 4 Thesis.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement11": {
		"key": "MID_ENDING",
		"title": "Corporate Ladder Climber",
		"desc": "[color=#5E5E5E]Corporate Ladder Climber[/color]\n\nHow to Unlock: Complete Chapter 5 and attain the Office Worker Ending.\n\n[color=green]Progress: Complete[/color]"
	},
	"Achievement12": {
		"key": "GOOD_ENDING",
		"title": "CEO of My Own Life",
		"desc": "[color=#5E5E5E]CEO of My Own Life[/color]\n\nHow to Unlock: Complete Chapter 5 and attain the Business Owner Ending.\n\n[color=green]Progress: Complete[/color]"
	}
}

func _ready() -> void:
	dark_bg.visible = false
	tutorial_panel.visible = false
	
	if close_btn:
		close_btn.pressed.connect(_on_close_menu_pressed)
		
	sync_with_sqlite_database()

## Direct synchronization connection with the SQLite local files
func sync_with_sqlite_database() -> void:
	# Fallback safety: Stop execution if the user id tracker hasn't set up yet
	var active_player_id = GameManager.player_id
	if active_player_id <= 0:
		print("[ACHIEVEMENT BACKEND ENGINE] Warning: Active Player Session not tracked yet. Defaulting to mock state.")
		return

	# Query your exact player_achievements junction table row entries
	DatabaseManager.db.query_with_bindings("""
		SELECT a.achievement_key 
		FROM player_achievements pa
		INNER JOIN achievements a ON pa.achievement_id = a.id
		WHERE pa.player_id = ?;
	""", [active_player_id])
	
	var unlocked_keys = []
	for row in DatabaseManager.db.query_result:
		unlocked_keys.append(row["achievement_key"])
		
	# Loop through your 12 UI scene tree elements to apply dynamic modulation and text string injections
	for slot_node in vbox_container.get_children():
		var node_name = slot_node.name
		
		if MASTER_DATA.has(node_name):
			var data = MASTER_DATA[node_name]
			var is_unlocked: bool = unlocked_keys.has(data["key"])
			
			# Apply exact coloration presets based on factual saved tracking table data
			if is_unlocked:
				slot_node.modulate = Color("5df05d") # Complete: Vibrant clean green
			else:
				slot_node.modulate = Color("aba178") # Incomplete: Grayish-yellow
				
			if slot_node is Button:
				# Clean old active signal connections to avoid duplication glitches during scene changes
				if slot_node.pressed.is_connected(_on_achievement_clicked):
					slot_node.pressed.disconnect(_on_achievement_clicked)
					
				# Build correct string formats based on structural save state calculations
				var final_text = data["desc"]
				if not is_unlocked:
					final_text = final_text.replace("[color=green]Progress: Complete[/color]", "[color=crimson]Progress: Incomplete[/color]")
				
				slot_node.pressed.connect(_on_achievement_clicked.bind(final_text))

func _on_achievement_clicked(text_to_show: String) -> void:
	if "bbcode_text" in tutorial_label:
		tutorial_label.bbcode_text = text_to_show
	else:
		tutorial_label.text = text_to_show
		
	dark_bg.visible = true
	tutorial_panel.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if tutorial_panel.visible:
			dark_bg.visible = false
			tutorial_panel.visible = false
			get_viewport().set_input_as_handled()

func _on_close_menu_pressed() -> void:
	visible = false
