extends Control

signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var assigned_digit: String = "0"
var is_completed: bool = false

var current_values: Array[int] = [0, 0, 0]
var solution: Array[int] = [0, 0, 0]

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var instructions_label: Label = $VBoxContainer/InstructionsLabel
@onready var clue_label: Label = $VBoxContainer/ClueLabel
@onready var dials_container: HBoxContainer = $VBoxContainer/DialsContainer
@onready var open_button: Button = $VBoxContainer/OpenButton
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var digit_label: Label = $VBoxContainer/DigitLabel

# Referencia al reproductor de sonido
@onready var dial_audio: AudioStreamPlayer = $DialAudio

@onready var value_labels: Array[Label] = [
	$VBoxContainer/DialsContainer/Dial1/Value1,
	$VBoxContainer/DialsContainer/Dial2/Value2,
	$VBoxContainer/DialsContainer/Dial3/Value3
]

@onready var up_buttons: Array[Button] = [
	$VBoxContainer/DialsContainer/Dial1/UpBtn1,
	$VBoxContainer/DialsContainer/Dial2/UpBtn2,
	$VBoxContainer/DialsContainer/Dial3/UpBtn3
]

@onready var down_buttons: Array[Button] = [
	$VBoxContainer/DialsContainer/Dial1/DownBtn1,
	$VBoxContainer/DialsContainer/Dial2/DownBtn2,
	$VBoxContainer/DialsContainer/Dial3/DownBtn3
]


func _ready() -> void:
	_setup_automatic_layout()
	
	instructions_label.text = "INSTRUCTIONS: Align the 3 dials matching the engraved clue."
	status_label.text = "CRYPTEX: LOCKED"
	digit_label.text = "CODE: ?"
	open_button.text = "OPEN CRYPTEX"

	_generate_puzzle()

	for i in range(3):
		up_buttons[i].pressed.connect(_on_dial_step.bind(i, 1))
		down_buttons[i].pressed.connect(_on_dial_step.bind(i, -1))
		_update_dial_display(i)

	open_button.pressed.connect(_on_open_pressed)


func _setup_automatic_layout() -> void:
	vbox.anchors_preset = PRESET_CENTER
	vbox.custom_minimum_size = Vector2(520, 360)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	
	dials_container.alignment = BoxContainer.ALIGNMENT_CENTER
	dials_container.add_theme_constant_override("separation", 32)
	
	for i in range(3):
		up_buttons[i].custom_minimum_size = Vector2(50, 40)
		up_buttons[i].text = "▲"
		
		down_buttons[i].custom_minimum_size = Vector2(50, 40)
		down_buttons[i].text = "▼"
		
		value_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_labels[i].custom_minimum_size = Vector2(50, 30)

	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	open_button.custom_minimum_size = Vector2(220, 45)


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _generate_puzzle() -> void:
	solution[0] = randi_range(1, 9)
	solution[1] = randi_range(1, 9)
	solution[2] = randi_range(1, 9)

	var sum_all = solution[0] + solution[1] + solution[2]
	var diff_1_2 = solution[0] - solution[1]
	clue_label.text = "CLUE: Sum = %d  |  D1 - D2 = %d  |  D3 = %d" % [sum_all, diff_1_2, solution[2]]


func _on_dial_step(dial_idx: int, direction: int) -> void:
	if is_completed:
		return
		
	# Reproducir el chasquido del dial en cada paso
	if dial_audio:
		dial_audio.play()
		
	current_values[dial_idx] = (current_values[dial_idx] + direction) % 10
	if current_values[dial_idx] < 0:
		current_values[dial_idx] = 9
	_update_dial_display(dial_idx)


func _update_dial_display(dial_idx: int) -> void:
	value_labels[dial_idx].text = str(current_values[dial_idx])


func _on_open_pressed() -> void:
	if is_completed:
		return

	if current_values == solution:
		_complete_puzzle()
	else:
		_trigger_penalty()


func _trigger_penalty() -> void:
	status_label.text = "MECHANISM JAMMED! -30s PENALTY!"
	status_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	penalty_triggered.emit(30.0)


func _complete_puzzle() -> void:
	is_completed = true
	open_button.disabled = true
	for btn in up_buttons + down_buttons:
		btn.disabled = true

	status_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
	status_label.text = "CRYPTEX OPENED!"
	digit_label.text = "CODE DIGIT FOUND: " + assigned_digit
	puzzle_solved.emit(assigned_digit)
