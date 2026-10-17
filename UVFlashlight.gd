extends Control

# Signal emitted when the hidden clue is found
signal puzzle_solved(digit: String)

var assigned_digit: String = "0"
var is_completed: bool = false
var flashlight_on: bool = false

@onready var flashlight_button: Button = $FlashlightButton
@onready var flashlight_beam: Panel = $FlashlightBeam
@onready var hidden_clue: Label = $HiddenClue
@onready var digit_label: Label = $DigitLabel


func _ready() -> void:
	digit_label.text = "Haz clic en el botón para encender la linterna UV..."
	
	# Ocultar completamente el número al inicio para que no se distinga en la pared
	hidden_clue.visible = false
	flashlight_beam.visible = false
	
	# Asegurar el pivote al centro del Panel para que siga el mouse correctamente
	flashlight_beam.pivot_offset = flashlight_beam.size / 2.0
	
	flashlight_button.toggled.connect(_on_flashlight_toggled)


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit
	hidden_clue.text = digit


func _on_flashlight_toggled(toggled_on: bool) -> void:
	if is_completed:
		return
	flashlight_on = toggled_on
	flashlight_beam.visible = toggled_on
	if toggled_on:
		digit_label.text = "Linterna UV ACTIVA. Mueve el cursor por la pared..."
	else:
		digit_label.text = "Linterna apagada."


func _process(_delta: float) -> void:
	if not flashlight_on or is_completed:
		return
		
	# El centro del círculo de luz sigue la posición exacta del cursor
	flashlight_beam.global_position = get_global_mouse_position() - (flashlight_beam.size / 2.0)
	
	# Detectar la distancia entre el centro de la luz y la posición del número oculto
	var beam_center = flashlight_beam.global_position + (flashlight_beam.size / 2.0)
	var clue_center = hidden_clue.global_position + (hidden_clue.size / 2.0)
	var distance = beam_center.distance_to(clue_center)
	
	# Cuando el haz de luz pase por encima del área del número oculto (menos de 70px)
	if distance < 70.0:
		hidden_clue.visible = true
		hidden_clue.modulate = Color(0.2, 0.9, 1.0, 1.0) # Se ilumina brillante
		_complete_puzzle()


func _complete_puzzle() -> void:
	is_completed = true
	flashlight_on = false
	flashlight_beam.visible = false
	flashlight_button.disabled = true
	digit_label.text = "DÍGITO DE CÓDIGO ENCONTRADO: " + assigned_digit
	puzzle_solved.emit(assigned_digit)
