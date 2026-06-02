extends CanvasLayer 

@onready var intro_anim = $money_ui_control/money_ui_intro
@onready var idle_anim = $money_ui_control/money_ui_idle
@onready var outro_anim = $money_ui_control/money_ui_outro

@onready var popup_star = $popupstar
@onready var notif_control = $moneyreceivenotifcontrol
@onready var notif_text = $moneyreceivenotifcontrol/moneyreceivenotif/moneyreceivetext 

func _ready() -> void:
	intro_anim.hide()
	idle_anim.hide()
	outro_anim.hide()
	
	popup_star.hide()
	notif_control.modulate.a = 0.0 
	notif_control.hide()

# ADDED VARIABLES SO MAIN SCENE CAN SEND THE TEXT
func play_intro(job_name: String, job_salary: int) -> void:
	
	# Update the text dynamically before it fades in!
	notif_text.text = "+P1,500 from mom\n2months salary from your\npart time: " + job_name + " + P" + str(job_salary) + "\nrent: -P2000\ntotal: P1200"
	
	intro_anim.show()
	intro_anim.play() 
	
	await intro_anim.animation_finished
	intro_anim.hide()
	
	idle_anim.show()
	idle_anim.play()
	
	popup_star.show() 
	notif_control.show()
	
	var tween_in = create_tween()
	tween_in.tween_property(notif_control, "modulate:a", 1.0, 1.0)
	await tween_in.finished 
	
	# --- THE PERFECT SYNC POINT ---
	# The text panel has completed its fade-in transition envelope.
	# Fire the confirmation ding exactly as the player registers the visual numbers!
	AudioManager.play_sfx("INCOME")
	
	# The main script will wait for this exact moment before adding the money!


func play_outro() -> void:
	var tween_out = create_tween()
	tween_out.tween_property(notif_control, "modulate:a", 0.0, 0.5) 
	await tween_out.finished
	
	popup_star.hide()
	idle_anim.hide()
	
	outro_anim.show()
	outro_anim.play()
	
	await outro_anim.animation_finished
	outro_anim.hide()
