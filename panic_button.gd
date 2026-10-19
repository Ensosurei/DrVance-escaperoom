extends Control

signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var assigned_digit: String = "0"
var is_completed: bool = false
var cover_removed: bool = false

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var instructions_label: Label = $VBoxContainer.get_node_or_null("InstructionsLabel")
@onready var panel_housing: Control = $VBoxContainer.get_node_or_null("PanelHousing")
@onready var background_base: Panel = $VBoxContainer/PanelHousing.get_node_or_null("BackgroundBase")
@onready var red_button: Button = $VBoxContainer/PanelHousing.get_node_or_null("RedButton")
@onready var security_cover: Button = $VBoxContainer/PanelHousing.get_node_or_null("SecurityCover")
@onready var status_label: Label = $VBoxContainer.get_node_or_null("StatusLabel")
@onready var digit_label: Label = $VBoxContainer.get_node_or_null("DigitLabel")
@onready var alarm_audio: AudioStreamPlayer = get_node_or_null("AlarmAudio")


func _ready() -> void:
	_setup_layout()
	_connect_signals()


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _setup_layout() -> void:
	# Asegurar tamaño mínimo y centrado del contenedor principal
	if vbox:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.custom_minimum_size = Vector2(560, 420)
		vbox.size = Vector2(560, 420)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 20)

	if instructions_label:
		instructions_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		instructions_label.custom_minimum_size = Vector2(520, 40)
		instructions_label.text = "INSTRUCTIONS: Lift the safety cover, then engage the emergency button."
		instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if status_label:
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_label.custom_minimum_size = Vector2(520, 30)
		status_label.text = "STATUS: SAFETY COVER ENGAGED"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if digit_label:
		digit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		digit_label.custom_minimum_size = Vector2(520, 30)
		digit_label.text = "CODE: ?"
		digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Área de la caja
	if panel_housing:
		panel_housing.custom_minimum_size = Vector2(240, 220)
		panel_housing.mouse_filter = Control.MOUSE_FILTER_STOP

	# Fondo metálico que ocupa el espacio visible de la caja
	if background_base:
		background_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Centrar la carcasa gris dentro del ancho total disponible
		background_base.custom_minimum_size = Vector2(240, 220)
		background_base.size = Vector2(240, 220)
		background_base.set_anchors_preset(Control.PRESET_CENTER)
		background_base.position = Vector2((panel_housing.size.x - 240) / 2.0, 0)
		
		var bg_sb = StyleBoxFlat.new()
		bg_sb.bg_color = Color(0.18, 0.2, 0.22)
		bg_sb.border_color = Color(0.5, 0.55, 0.6)
		bg_sb.set_border_width_all(3)
		bg_sb.set_corner_radius_all(10)
		background_base.add_theme_stylebox_override("panel", bg_sb)

	# Botón rojo centrado en la carcasa
	if red_button:
		red_button.text = ""
		red_button.custom_minimum_size = Vector2(160, 140)
		red_button.size = Vector2(160, 140)
		red_button.set_anchors_preset(Control.PRESET_CENTER)
		_apply_button_style(red_button, Color(0.75, 0.15, 0.15), Color(1.0, 0.3, 0.3))

	# Tapa de seguridad amarilla centrada cubriendo el botón
	if security_cover:
		security_cover.text = "⚠️ SAFETY COVER ⚠️\n\n(CLICK TO OPEN)"
		security_cover.custom_minimum_size = Vector2(190, 160)
		security_cover.size = Vector2(190, 160)
		security_cover.set_anchors_preset(Control.PRESET_CENTER)
		_apply_button_style(security_cover, Color(0.85, 0.7, 0.15, 0.9), Color(1.0, 0.9, 0.2, 1.0))


func _apply_button_style(btn: Button, bg_col: Color, border_col: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)


func _connect_signals() -> void:
	if security_cover and not security_cover.pressed.is_connected(_on_cover_pressed):
		security_cover.pressed.connect(_on_cover_pressed)
	if red_button and not red_button.pressed.is_connected(_on_panic_button_pressed):
		red_button.pressed.connect(_on_panic_button_pressed)


func _on_cover_pressed() -> void:
	if cover_removed or is_completed:
		return

	cover_removed = true

	# Al quitar la tapa, se muestra el texto del botón rojo
	if red_button:
		red_button.text = "EMERGENCY\nPRESS"

	if security_cover:
		var tween = create_tween()
		tween.tween_property(security_cover, "position:y", security_cover.position.y - 140, 0.3)
		tween.parallel().tween_property(security_cover, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): security_cover.visible = false)

	if status_label:
		status_label.text = "WARNING: EMERGENCY BUTTON UNPROTECTED!"
		status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)


func _on_panic_button_pressed() -> void:
	if is_completed:
		return

	if not cover_removed:
		if status_label:
			status_label.text = "Safety cover is blocking the button!"
			status_label.modulate = Color(1.0, 0.5, 0.2, 1.0)
		return

	_complete_puzzle()


func _complete_puzzle() -> void:
	is_completed = true

	if alarm_audio and alarm_audio.stream != null:
		alarm_audio.play()

	if red_button:
		red_button.text = "ACTIVATED\n[OK]"
		_apply_button_style(red_button, Color(0.15, 0.6, 0.2), Color(0.3, 1.0, 0.4))
		red_button.disabled = true

	if status_label:
		status_label.modulate = Color(0.2, 1.0, 0.3, 1.0)
		status_label.text = "EMERGENCY PROTOCOL ENGAGED!"

	if digit_label:
		digit_label.text = "CODE DIGIT FOUND: " + assigned_digit

	puzzle_solved.emit(assigned_digit)
