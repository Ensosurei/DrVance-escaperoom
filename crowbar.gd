extends Control

signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var assigned_digit: String = "0"
var is_completed: bool = false
var has_crowbar_selected: bool = false
var is_dragging: bool = false

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var instructions_label: Label = $VBoxContainer.get_node_or_null("InstructionsLabel")
@onready var status_label: Label = $VBoxContainer.get_node_or_null("StatusLabel")
@onready var digit_label: Label = $VBoxContainer.get_node_or_null("DigitLabel")
@onready var pry_audio: AudioStreamPlayer = get_node_or_null("PryAudio")

var workspace_box: HBoxContainer
var crate_button: Button
var crowbar_button: Button
var drag_proxy: Label = null


func _ready() -> void:
	_setup_clean_layout()


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _setup_clean_layout() -> void:
	# 1. Configurar y centrar el contenedor vertical
	if vbox:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.custom_minimum_size = Vector2(560, 420)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 24)

	# 2. Configurar textos y DESACTIVAR su colisión con el ratón (MOUSE_FILTER_IGNORE)
	if instructions_label:
		instructions_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		instructions_label.text = "INSTRUCTIONS: Drag the Crowbar onto the Crate (or click Crowbar, then Crate)."
		instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if status_label:
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_label.text = "STATUS: CRATE IS NAILED SHUT"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if digit_label:
		digit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		digit_label.text = "CODE: ?"
		digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 3. Recrear o limpiar la fila central horizontal (Workspace)
	var old_ws = $VBoxContainer.get_node_or_null("WorkspaceHBox")
	if not old_ws:
		old_ws = $VBoxContainer.get_node_or_null("WorkspaceHbox")
	if old_ws:
		old_ws.queue_free()

	workspace_box = HBoxContainer.new()
	workspace_box.name = "ActiveWorkspace"
	workspace_box.alignment = BoxContainer.ALIGNMENT_CENTER
	workspace_box.add_theme_constant_override("separation", 50)
	
	# Insertarlo ordenadamente entre InstructionsLabel y StatusLabel
	vbox.add_child(workspace_box)
	vbox.move_child(workspace_box, 1)

	# 4. Crear el Botón de la CAJA
	crate_button = Button.new()
	crate_button.name = "CrateBtn"
	crate_button.text = "\n[ CRATE ]\n\nNAILED SHUT\n(DROP HERE)\n"
	crate_button.custom_minimum_size = Vector2(200, 150)
	crate_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_button_color(crate_button, Color(0.35, 0.22, 0.12), Color(0.7, 0.45, 0.2))
	crate_button.pressed.connect(_on_crate_pressed)
	workspace_box.add_child(crate_button)

	# 5. Crear el Botón de la PALANCA
	crowbar_button = Button.new()
	crowbar_button.name = "CrowbarBtn"
	crowbar_button.text = "\n[ CROWBAR ]\n\nSTEEL TOOL\n(DRAG / CLICK)\n"
	crowbar_button.custom_minimum_size = Vector2(180, 150)
	crowbar_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_button_color(crowbar_button, Color(0.18, 0.24, 0.32), Color(0.3, 0.7, 1.0))
	crowbar_button.pressed.connect(_on_crowbar_pressed)
	crowbar_button.gui_input.connect(_on_crowbar_drag_input)
	workspace_box.add_child(crowbar_button)


func _set_button_color(btn: Button, bg_col: Color, border_col: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)


# --- Interacción 1: Clic Directo ---
func _on_crowbar_pressed() -> void:
	if is_completed:
		return
	has_crowbar_selected = true
	_set_button_color(crowbar_button, Color(0.55, 0.5, 0.1), Color(1.0, 0.9, 0.2)) # Amarillo brillante
	if status_label:
		status_label.text = "CROWBAR IN HAND: Now click or drag it to the Crate!"
		status_label.modulate = Color(1.0, 0.9, 0.3, 1.0)


func _on_crate_pressed() -> void:
	if is_completed:
		return
	if has_crowbar_selected:
		_open_crate_success()
	else:
		if status_label:
			status_label.text = "The crate is nailed shut! You need the crowbar first."
			status_label.modulate = Color(1.0, 0.4, 0.4, 1.0)


# --- Interacción 2: Arrastrar con el Ratón (Drag & Drop) ---
func _on_crowbar_drag_input(event: InputEvent) -> void:
	if is_completed:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			has_crowbar_selected = true
			_set_button_color(crowbar_button, Color(0.55, 0.5, 0.1), Color(1.0, 0.9, 0.2))
			_spawn_drag_proxy()
		elif is_dragging:
			is_dragging = false
			_destroy_drag_proxy()
			# Comprobar si se soltó sobre el área de la caja
			if crate_button and crate_button.get_global_rect().has_point(get_global_mouse_position()):
				_open_crate_success()


func _process(_delta: float) -> void:
	if is_dragging and drag_proxy:
		drag_proxy.global_position = get_global_mouse_position() + Vector2(12, 12)


func _spawn_drag_proxy() -> void:
	if not drag_proxy:
		drag_proxy = Label.new()
		drag_proxy.text = "⛏️ CROWBAR"
		drag_proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		drag_proxy.modulate = Color(1.0, 1.0, 0.3, 1.0)
		add_child(drag_proxy)


func _destroy_drag_proxy() -> void:
	if drag_proxy:
		drag_proxy.queue_free()
		drag_proxy = null


func _open_crate_success() -> void:
	is_completed = true

	if pry_audio and pry_audio.stream != null:
		pry_audio.play()

	if crowbar_button:
		crowbar_button.visible = false

	if crate_button:
		crate_button.text = "\n[ CRATE OPENED! ]\n\nUNLOCKED\n"
		_set_button_color(crate_button, Color(0.15, 0.4, 0.18), Color(0.3, 0.9, 0.4))
		crate_button.disabled = true

	if status_label:
		status_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
		status_label.text = "CRATE PRYED OPEN!"

	if digit_label:
		digit_label.text = "CODE DIGIT FOUND: " + assigned_digit

	puzzle_solved.emit(assigned_digit)
