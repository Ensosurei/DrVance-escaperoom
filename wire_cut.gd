extends Control

signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var assigned_digit: String = "0"
var is_completed: bool = false

var wire_colors: Array[Dictionary] = [
	{"name": "RED", "color": Color(0.9, 0.2, 0.2, 1.0)},
	{"name": "BLUE", "color": Color(0.2, 0.4, 0.9, 1.0)},
	{"name": "YELLOW", "color": Color(0.9, 0.8, 0.2, 1.0)},
	{"name": "GREEN", "color": Color(0.2, 0.8, 0.3, 1.0)}
]

var correct_wire_index: int = 0

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var instructions_label: Label = $VBoxContainer/InstructionsLabel
@onready var wires_container: VBoxContainer = $VBoxContainer/WiresContainer
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var digit_label: Label = $VBoxContainer/DigitLabel
@onready var snip_audio: AudioStreamPlayer = $SnipAudio

@onready var wire_buttons: Array[Button] = [
	$VBoxContainer/WiresContainer/Wire1,
	$VBoxContainer/WiresContainer/Wire2,
	$VBoxContainer/WiresContainer/Wire3,
	$VBoxContainer/WiresContainer/Wire4
]


func _ready() -> void:
	_setup_automatic_layout()
	_generate_puzzle()
	
	# Comprobar si el archivo de audio está cargado correctamente
	if snip_audio:
		if snip_audio.stream == null:
			print("ALERTA: SnipAudio no tiene ningún archivo asignado en su propiedad Stream.")
		else:
			print("Audio cargado con éxito: ", snip_audio.stream.resource_path)
	
	for i in range(wire_buttons.size()):
		wire_buttons[i].pressed.connect(_on_wire_cut.bind(i))


func _setup_automatic_layout() -> void:
	vbox.anchors_preset = PRESET_CENTER
	vbox.custom_minimum_size = Vector2(460, 380)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	
	wires_container.alignment = BoxContainer.ALIGNMENT_CENTER
	wires_container.add_theme_constant_override("separation", 12)
	
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	digit_label.text = "CODE: ?"
	status_label.text = "STATUS: ARMED"


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _generate_puzzle() -> void:
	correct_wire_index = randi_range(0, wire_colors.size() - 1)
	var target_color_name: String = wire_colors[correct_wire_index]["name"]
	
	instructions_label.text = "DEFUSAL MANUAL: Cut the " + target_color_name + " wire to disarm."
	
	for i in range(wire_buttons.size()):
		wire_buttons[i].text = "--- [ " + wire_colors[i]["name"] + " WIRE ] ---"
		wire_buttons[i].modulate = wire_colors[i]["color"]
		wire_buttons[i].custom_minimum_size = Vector2(300, 42)


func _on_wire_cut(wire_idx: int) -> void:
	if is_completed:
		return
		
	if snip_audio and snip_audio.stream != null:
		snip_audio.play()
		
	wire_buttons[wire_idx].disabled = true
	wire_buttons[wire_idx].text = "--- [ SNIPPED ] ---"
	wire_buttons[wire_idx].modulate = Color(0.4, 0.4, 0.4, 1.0)
	
	if wire_idx == correct_wire_index:
		_complete_puzzle()
	else:
		_trigger_penalty()


func _trigger_penalty() -> void:
	status_label.text = "WRONG WIRE! SHORT CIRCUIT! -30s"
	status_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
	penalty_triggered.emit(30.0)


func _complete_puzzle() -> void:
	is_completed = true
	for btn in wire_buttons:
		btn.disabled = true
		

	status_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
	status_label.text = "CIRCUIT DEFUSED!"
	digit_label.text = "CODE DIGIT FOUND: " + assigned_digit
	puzzle_solved.emit(assigned_digit)
