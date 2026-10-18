extends Control

signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var assigned_digit: String = "0"
var is_completed: bool = false

# Values for target positions
var target_tension: int = 0
var target_pin: int = 0

# Tolerance range (+/- 5 units)
var tolerance: int = 5

@onready var instructions_label: Label = $VBoxContainer/InstructionsLabel
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var tension_slider: HSlider = $VBoxContainer/LockPanel/ControlsVBox/TensionSlider
@onready var pin_slider: HSlider = $VBoxContainer/LockPanel/ControlsVBox/PinSlider
@onready var unlock_button: Button = $VBoxContainer/UnlockButton
@onready var digit_label: Label = $VBoxContainer/DigitLabel

# Audio player reference
@onready var slider_audio: AudioStreamPlayer = $SliderAudio


func _ready() -> void:
	instructions_label.text = "INSTRUCTIONS: Move sliders to find the sweet spot using the color hint."
	status_label.text = "STATUS: COLD"
	status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	digit_label.text = "CODE: ?"
	unlock_button.text = "TRY UNLOCK"
	
	# Configure sliders to work strictly with integers (0 to 100, step 1)
	tension_slider.min_value = 0
	tension_slider.max_value = 100
	tension_slider.step = 1.0
	
	pin_slider.min_value = 0
	pin_slider.max_value = 100
	pin_slider.step = 1.0
	
	_generate_random_lock()
	
	# Conectar señales de valor para el feedback visual
	tension_slider.value_changed.connect(_on_slider_changed)
	pin_slider.value_changed.connect(_on_slider_changed)
	
	# Conectar señales de arrastre del mouse para el audio en bucle mientras se presiona
	tension_slider.drag_started.connect(_on_slider_drag_started)
	tension_slider.drag_ended.connect(_on_slider_drag_ended)
	
	pin_slider.drag_started.connect(_on_slider_drag_started)
	pin_slider.drag_ended.connect(_on_slider_drag_ended)
	
	unlock_button.pressed.connect(_on_unlock_pressed)
	
	_update_feedback()


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _generate_random_lock() -> void:
	# Generate random target integer values
	target_tension = randi_range(10, 90)
	target_pin = randi_range(10, 90)


func _on_slider_changed(_value: float) -> void:
	if is_completed:
		return
	_update_feedback()


# Se activa cuando el usuario hace clic y empieza a arrastrar cualquier slider
func _on_slider_drag_started() -> void:
	if is_completed:
		return
	if slider_audio and not slider_audio.playing:
		slider_audio.play()


# Se activa cuando el usuario suelta el mouse del slider
func _on_slider_drag_ended(_value_changed: bool) -> void:
	if slider_audio and slider_audio.playing:
		slider_audio.stop()


func _update_feedback() -> void:
	var current_tension: int = int(tension_slider.value)
	var current_pin: int = int(pin_slider.value)
	
	var tension_diff: int = abs(current_tension - target_tension)
	var pin_diff: int = abs(current_pin - target_pin)
	var total_diff: int = tension_diff + pin_diff
	
	# Proximity indicator logic
	if total_diff <= tolerance * 2:
		status_label.text = "STATUS: HOT! (Very close!)"
		status_label.modulate = Color(0.2, 1.0, 0.2, 1.0) # Green
	elif total_diff <= tolerance * 5:
		status_label.text = "STATUS: WARM (Getting closer...)"
		status_label.modulate = Color(1.0, 1.0, 0.2, 1.0) # Yellow
	else:
		status_label.text = "STATUS: COLD (Far away)"
		status_label.modulate = Color(1.0, 0.3, 0.3, 1.0) # Red


func _on_unlock_pressed() -> void:
	if is_completed:
		return
		
	var current_tension: int = int(tension_slider.value)
	var current_pin: int = int(pin_slider.value)
	
	var tension_diff: int = abs(current_tension - target_tension)
	var pin_diff: int = abs(current_pin - target_pin)
	
	# Validate if sliders are within tolerance
	if tension_diff <= tolerance and pin_diff <= tolerance:
		_complete_puzzle()
	else:
		_trigger_penalty()


func _trigger_penalty() -> void:
	status_label.text = "SNAP! LOCKPICK BROKE! -30s"
	status_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
	penalty_triggered.emit(30.0)


func _complete_puzzle() -> void:
	is_completed = true
	unlock_button.disabled = true
	tension_slider.editable = false
	pin_slider.editable = false
	
	# Asegurarnos de cortar cualquier sonido activo al resolver
	if slider_audio and slider_audio.playing:
		slider_audio.stop()
	
	status_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
	status_label.text = "LOCK PICKED SUCCESSFULLY!"
	digit_label.text = "CODE DIGIT FOUND: " + assigned_digit
	puzzle_solved.emit(assigned_digit)
