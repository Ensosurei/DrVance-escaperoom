extends Control

# Signals emitted for puzzle completion or time penalty
signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var assigned_digit: String = "0"
var is_completed: bool = false
var target_pattern: Array[bool] = []

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var panel_container: PanelContainer = $VBoxContainer/PanelContainer
@onready var switches_grid: HBoxContainer = $VBoxContainer/PanelContainer/SwitchesGrid
@onready var test_button: Button = $VBoxContainer/TestButton
@onready var digit_label: Label = $VBoxContainer/DigitLabel
@onready var click_sound: AudioStreamPlayer = $ClickSound

@onready var leds: Array[Control] = [
	$VBoxContainer/PanelContainer/SwitchesGrid/Module1/Led1,
	$VBoxContainer/PanelContainer/SwitchesGrid/Module2/Led2,
	$VBoxContainer/PanelContainer/SwitchesGrid/Module3/Led3,
	$VBoxContainer/PanelContainer/SwitchesGrid/Module4/Led4
]

@onready var switches: Array[CheckButton] = [
	$VBoxContainer/PanelContainer/SwitchesGrid/Module1/Switch1,
	$VBoxContainer/PanelContainer/SwitchesGrid/Module2/Switch2,
	$VBoxContainer/PanelContainer/SwitchesGrid/Module3/Switch3,
	$VBoxContainer/PanelContainer/SwitchesGrid/Module4/Switch4
]


func _ready() -> void:
	_setup_automatic_layout()
	
	status_label.text = "Match the breaker pattern indicated by the LED lights."
	digit_label.text = "CODE: ?"
	test_button.text = "TEST POWER"
	
	_generate_random_pattern()
	test_button.pressed.connect(_on_test_button_pressed)
	
	# Conectar el sonido de clic a cada interruptor
	for sw in switches:
		sw.toggled.connect(_on_switch_toggled)


func _setup_automatic_layout() -> void:
	vbox.anchors_preset = PRESET_CENTER
	vbox.custom_minimum_size = Vector2(480, 320)
	
	switches_grid.alignment = BoxContainer.ALIGNMENT_CENTER
	switches_grid.add_theme_constant_override("separation", 24)
	
	for i in range(4):
		var module = switches_grid.get_child(i)
		module.alignment = BoxContainer.ALIGNMENT_CENTER
		
		leds[i].custom_minimum_size = Vector2(32, 32)
		switches[i].custom_minimum_size = Vector2(64, 48)
		switches[i].text = "B" + str(i + 1)

	test_button.custom_minimum_size = Vector2(200, 48)


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _generate_random_pattern() -> void:
	target_pattern.clear()
	
	for i in range(4):
		var is_on: bool = randf() > 0.5
		target_pattern.append(is_on)
		
		if leds[i] != null:
			if is_on:
				leds[i].modulate = Color(0.2, 1.0, 0.2, 1.0) # Verde brillante
			else:
				leds[i].modulate = Color(1.0, 0.2, 0.2, 1.0) # Rojo brillante


# Función que reproduce el sonido cada vez que activas/desactivas un switch
func _on_switch_toggled(_toggled_on: bool) -> void:
	if click_sound:
		click_sound.play()


func _on_test_button_pressed() -> void:
	if is_completed:
		return
		
	var current_pattern: Array[bool] = []
	for switch in switches:
		current_pattern.append(switch.button_pressed)
	
	if current_pattern == target_pattern:
		_complete_puzzle()
	else:
		_trigger_penalty()


func _trigger_penalty() -> void:
	status_label.text = "SHORT CIRCUIT! -30 SECONDS PENALTY!"
	status_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	penalty_triggered.emit(30.0)


func _complete_puzzle() -> void:
	is_completed = true
	test_button.disabled = true
	
	for switch in switches:
		switch.disabled = true
		
	status_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
	status_label.text = "POWER RESTORED!"
	digit_label.text = "CODE DIGIT FOUND: " + assigned_digit
	puzzle_solved.emit(assigned_digit)
