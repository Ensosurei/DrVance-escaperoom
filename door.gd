extends Control

# Signal emitted when the user successfully enters the exit code
signal door_unlocked

# Final access code required to escape (set by RoomRandomizer)
var required_code: String = "123"
var current_input: String = ""

@onready var display_label: Label = $DoorUI/DisplayLabel
@onready var keypad_grid: GridContainer = $DoorUI/KeypadGrid
@onready var submit_button: Button = $DoorUI/SubmitButton


func _ready() -> void:
	# Connect all button signals inside the KeypadGrid
	for child in keypad_grid.get_children():
		if child is Button:
			child.pressed.connect(_on_keypad_button_pressed.bind(child.text))
			
	# Connect submit button
	submit_button.pressed.connect(_on_submit_pressed)
	_update_display()


func set_access_code(code: String) -> void:
	required_code = code


func _on_keypad_button_pressed(digit: String) -> void:
	# Allow maximum 3 digits
	if current_input.length() < 3:
		current_input += digit
		_update_display()


func _on_submit_pressed() -> void:
	if current_input == required_code:
		display_label.text = "ACCESS GRANTED"
		door_unlocked.emit()
	else:
		display_label.text = "ERROR"
		current_input = ""


func _update_display() -> void:
	if current_input == "":
		display_label.text = "---"
	else:
		display_label.text = current_input
