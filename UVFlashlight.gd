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

# Referencias para los dos sonidos
@onready var switch_sound: AudioStreamPlayer = $SwitchSound
@onready var loop_sound: AudioStreamPlayer = $LoopSound


func _ready() -> void:
	digit_label.text = "Click the button to turn on the UV flashlight..."
	
	hidden_clue.visible = false
	flashlight_beam.visible = false
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
	
	# 1. Reproducir siempre el sonido de clic/switch al alternar
	if switch_sound:
		switch_sound.play()
	
	if toggled_on:
		digit_label.text = "UV Flashlight ACTIVE. Move the cursor across the wall..."
		# 2. Reproducir el zumbido continuo en bucle mientras esté encendida
		if loop_sound and not loop_sound.playing:
			loop_sound.play()
	else:
		digit_label.text = "Flashlight turned off."
		# 3. Detener el zumbido cuando se apaga
		if loop_sound and loop_sound.playing:
			loop_sound.stop()


func _process(_delta: float) -> void:
	if not flashlight_on or is_completed:
		return
		
	flashlight_beam.global_position = get_global_mouse_position() - (flashlight_beam.size / 2.0)
	
	var beam_center = flashlight_beam.global_position + (flashlight_beam.size / 2.0)
	var clue_center = hidden_clue.global_position + (hidden_clue.size / 2.0)
	var distance = beam_center.distance_to(clue_center)
	
	if distance < 70.0:
		hidden_clue.visible = true
		hidden_clue.modulate = Color(0.2, 0.9, 1.0, 1.0)
		_complete_puzzle()


func _complete_puzzle() -> void:
	is_completed = true
	flashlight_on = false
	flashlight_beam.visible = false
	flashlight_button.disabled = true
	digit_label.text = "CODE DIGIT FOUND: " + assigned_digit
	
	# Detener el zumbido al resolver el puzzle
	if loop_sound and loop_sound.playing:
		loop_sound.stop()
		
	puzzle_solved.emit(assigned_digit)
