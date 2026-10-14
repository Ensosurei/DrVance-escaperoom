extends Control

# Target time in seconds (5 minutes)
const GAME_DURATION: float = 300.0

# Current wall index (0 = Wall 1, 1 = Wall 2, 2 = Wall 3, 3 = Wall 4 / Door)
var current_wall_index: int = 0
var walls: Array[Control] = []
var time_left: float = GAME_DURATION
var is_game_active: bool = true

# Node references
@onready var wall1: Control = $WallsContainer/Wall1
@onready var wall2: Control = $WallsContainer/Wall2
@onready var wall3: Control = $WallsContainer/Wall3
@onready var wall4: Control = $WallsContainer/Wall4

@onready var timer_label: Label = $HUD/TimerLabel
@onready var left_button: Button = $HUD/LeftButton
@onready var right_button: Button = $HUD/RightButton
@onready var game_timer: Timer = $GameTimer


func _ready() -> void:
	# Populate walls array
	walls = [wall1, wall2, wall3, wall4]
	
	# Connect UI button signals
	left_button.pressed.connect(_on_left_button_pressed)
	right_button.pressed.connect(_on_right_button_pressed)
	
	# Configure and start countdown timer
	game_timer.wait_time = 1.0
	game_timer.one_shot = false
	game_timer.timeout.connect(_on_game_timer_timeout)
	game_timer.start()
	
	# Display initial wall and update timer UI
	_update_wall_visibility()
	_update_timer_display()


func _update_wall_visibility() -> void:
	# Hide all walls and show only the active wall
	for i in range(walls.size()):
		if walls[i] != null:
			walls[i].visible = (i == current_wall_index)


func _on_left_button_pressed() -> void:
	if not is_game_active:
		return
	# Navigate to previous wall with wrap-around
	current_wall_index = (current_wall_index - 1 + walls.size()) % walls.size()
	_update_wall_visibility()


func _on_right_button_pressed() -> void:
	if not is_game_active:
		return
	# Navigate to next wall with wrap-around
	current_wall_index = (current_wall_index + 1) % walls.size()
	_update_wall_visibility()


func _on_game_timer_timeout() -> void:
	if not is_game_active:
		return
		
	time_left -= 1.0
	_update_timer_display()
	
	if time_left <= 0.0:
		_trigger_game_over()


func _update_timer_display() -> void:
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _trigger_game_over() -> void:
	is_game_active = false
	game_timer.stop()
	timer_label.text = "00:00 - PURGE ACTIVE"
	# Placeholder for Game Over screen instantiation or sound trigger
	print("Game Over: Facility purge sequence initiated.")


func _trigger_victory() -> void:
	is_game_active = false
	game_timer.stop()
	print("Victory: Facility door unlocked successfully.")
