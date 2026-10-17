extends Control

# Signal emitted when the valve is fully turned
signal puzzle_solved(digit: String)

# Assigned digit for this puzzle instance
var assigned_digit: String = "0"
var total_rotation: float = 0.0
var is_dragging: bool = false
var last_mouse_angle: float = 0.0
var is_completed: bool = false

# Adjust this value to control difficulty (higher number = slower fill / more rotations needed)
@export var rotation_difficulty_factor: float = 5

@onready var valve_sprite: Sprite2D = $VBoxContainer/WheelContainer/ValveSprite
@onready var click_area: Button = $VBoxContainer/WheelContainer/ClickArea
@onready var pressure_bar: ProgressBar = $VBoxContainer/PressureBar
@onready var digit_label: Label = $VBoxContainer/DigitLabel
@onready var valve_sound: AudioStreamPlayer = $ValveSound


func _ready() -> void:
	digit_label.text = "?"
	pressure_bar.min_value = 0.0
	pressure_bar.max_value = 360.0
	pressure_bar.value = 0.0
	
	# Connect click area signals
	click_area.button_down.connect(_on_valve_down)
	click_area.button_up.connect(_on_valve_up)


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _on_valve_down() -> void:
	if is_completed:
		return
	is_dragging = true
	var center = click_area.global_position + (click_area.size / 2.0)
	last_mouse_angle = center.angle_to_point(get_global_mouse_position())
	
	# Start loop sound when interaction begins
	if valve_sound and not valve_sound.playing:
		valve_sound.play()


func _on_valve_up() -> void:
	is_dragging = false
	# Stop loop sound when user releases the button
	if valve_sound and valve_sound.playing:
		valve_sound.stop()


func _process(_delta: float) -> void:
	if not is_dragging or is_completed:
		return
		
	var center = click_area.global_position + (click_area.size / 2.0)
	var current_angle = center.angle_to_point(get_global_mouse_position())
	var angle_diff = wrapf(current_angle - last_mouse_angle, -PI, PI)
	
	# Register rotational progress with difficulty scale factor
	if angle_diff > 0:
		var degrees_turned = rad_to_deg(angle_diff)
		
		# Rotate the visual sprite normally
		valve_sprite.rotation_degrees += degrees_turned
		
		# Fill the progress bar more slowly based on difficulty factor
		total_rotation += degrees_turned / rotation_difficulty_factor
		pressure_bar.value = total_rotation
		
		if total_rotation >= 360.0:
			_complete_puzzle()
			
	last_mouse_angle = current_angle


func _complete_puzzle() -> void:
	is_completed = true
	is_dragging = false
	pressure_bar.value = 360.0
	digit_label.text = "CODE: " + assigned_digit
	
	# Stop looping sound upon puzzle completion
	if valve_sound and valve_sound.playing:
		valve_sound.stop()
		
	puzzle_solved.emit(assigned_digit)
