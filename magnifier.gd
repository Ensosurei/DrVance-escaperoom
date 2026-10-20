extends Control

signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var secret_pos: Vector2 = Vector2.ZERO
var assigned_digit: String = "0"
var is_completed: bool = false
var is_hovering_secret: bool = false

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var instructions_label: Label = $VBoxContainer.get_node_or_null("InstructionsLabel")
@onready var inspection_area: Control = $VBoxContainer.get_node_or_null("InspectionArea")
@onready var background_clues: Label = $VBoxContainer/InspectionArea.get_node_or_null("BackgroundClues")
@onready var secret_spot: Label = $VBoxContainer/InspectionArea.get_node_or_null("SecretSpot")
@onready var lens: Panel = $VBoxContainer/InspectionArea.get_node_or_null("Lens")
@onready var status_label: Label = $VBoxContainer.get_node_or_null("StatusLabel")
@onready var digit_label: Label = $VBoxContainer.get_node_or_null("DigitLabel")
@onready var focus_audio: AudioStreamPlayer = get_node_or_null("FocusAudio")


func _ready() -> void:
	_randomize_secret_position()
	_setup_layout()

func _randomize_secret_position() -> void:
	# Rango dentro del área de 480x240 dejando márgenes para que no se corte
	var min_x = 30.0
	var max_x = 480.0 - 140.0 # Ancho total menos ancho de la etiqueta
	var min_y = 30.0
	var max_y = 240.0 - 50.0  # Alto total menos alto de la etiqueta

	secret_pos = Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit
	if secret_spot:
		secret_spot.text = "[ CODE: " + assigned_digit + " ]"


func _setup_layout() -> void:
	if vbox:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.custom_minimum_size = Vector2(540, 420)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 18)

	if instructions_label:
		instructions_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		instructions_label.text = "INSTRUCTIONS: Move the magnifying glass across the blueprint to find the hidden digit."
		instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if status_label:
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_label.text = "STATUS: SEARCHING..."
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if digit_label:
		digit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		digit_label.text = "CODE: ?"
		digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if inspection_area:
		inspection_area.custom_minimum_size = Vector2(480, 240)
		inspection_area.mouse_filter = Control.MOUSE_FILTER_STOP
		inspection_area.gui_input.connect(_on_inspection_input)
		
	if secret_spot:
		secret_spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		secret_spot.size = Vector2(120, 30)
		secret_spot.position = secret_pos
		secret_spot.text = "[ CODE: " + assigned_digit + " ]"
		secret_spot.modulate = Color(1, 1, 1, 0.0)

		# Fondo técnico oscuro
		var bg_panel = Panel.new()
		bg_panel.name = "AreaBackground"
		bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var bg_sb = StyleBoxFlat.new()
		bg_sb.bg_color = Color(0.12, 0.15, 0.18)
		bg_sb.border_color = Color(0.35, 0.45, 0.55)
		bg_sb.set_border_width_all(2)
		bg_sb.set_corner_radius_all(6)
		bg_panel.add_theme_stylebox_override("panel", bg_sb)
		inspection_area.add_child(bg_panel)
		inspection_area.move_child(bg_panel, 0)

	if background_clues:
		background_clues.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background_clues.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background_clues.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		background_clues.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		background_clues.text = "SYS_DIAGNOSTICS // SECTOR 7G\nVALVE_PRESS: NORMAL\nCIRCUIT_PATH: RESISTANCE NOMINAL\nSUB_STATION_A: OFFLINE\nPROTOCOL_OVERRIDE_REF: 4096-B"
		background_clues.modulate = Color(0.45, 0.5, 0.55, 0.6)

	# Ubicación del número oculto (desplazado del centro)
	if secret_spot:
		secret_spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		secret_spot.size = Vector2(120, 30)
		secret_spot.position = secret_pos
		secret_spot.text = "[ CODE: " + assigned_digit + " ]"
		secret_spot.modulate = Color(1, 1, 1, 0.0) # Invisible hasta enfocar

	# Lente circular pequeña
	if lens:
		lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lens.size = Vector2(90, 90)
		lens.visible = false

		var lens_sb = StyleBoxFlat.new()
		lens_sb.bg_color = Color(0.2, 0.6, 1.0, 0.18)
		lens_sb.border_color = Color(0.3, 0.85, 1.0, 0.9)
		lens_sb.set_border_width_all(3)
		lens_sb.set_corner_radius_all(45) # Círculo perfecto
		lens.add_theme_stylebox_override("panel", lens_sb)


func _process(_delta: float) -> void:
	if is_completed or not inspection_area or not lens:
		return

	var m_pos = inspection_area.get_local_mouse_position()
	var in_bounds = Rect2(Vector2.ZERO, inspection_area.size).has_point(m_pos)

	if in_bounds:
		lens.visible = true
		lens.position = m_pos - (lens.size / 2.0)

		# Comprobar distancia entre el centro de la lupa y el secreto
		var secret_center = secret_pos + (secret_spot.size / 2.0) if secret_spot else secret_pos
		var dist = m_pos.distance_to(secret_center)

		if dist < 45.0:
			is_hovering_secret = true
			if secret_spot:
				secret_spot.modulate = Color(1.0, 0.9, 0.2, 1.0) # Brilla en dorado
			if status_label:
				status_label.text = "FOCUS REACHED: Click to register mark!"
				status_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
		else:
			is_hovering_secret = false
			if secret_spot:
				secret_spot.modulate = Color(1.0, 1.0, 1.0, 0.0) # Vuelve a ser invisible
			if status_label:
				status_label.text = "STATUS: SEARCHING..."
				status_label.modulate = Color.WHITE
	else:
		lens.visible = false


func _on_inspection_input(event: InputEvent) -> void:
	if is_completed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_hovering_secret:
			_complete_puzzle()
		else:
			if status_label:
				status_label.text = "NOTHING FOUND HERE! -30s"
				status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
			penalty_triggered.emit(30.0)


func _complete_puzzle() -> void:
	is_completed = true

	if focus_audio and focus_audio.stream != null:
		focus_audio.play()

	if lens:
		lens.visible = false

	if secret_spot:
		secret_spot.modulate = Color(0.2, 1.0, 0.3, 1.0)

	if status_label:
		status_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
		status_label.text = "SECRET MARK LOGGED!"

	if digit_label:
		digit_label.text = "CODE DIGIT FOUND: " + assigned_digit

	puzzle_solved.emit(assigned_digit)
