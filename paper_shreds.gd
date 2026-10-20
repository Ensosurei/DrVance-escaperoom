extends Control

signal puzzle_solved(digit: String)
signal penalty_triggered(seconds: float)

var assigned_digit: String = "0"
var is_completed: bool = false
var selected_shred_index: int = -1

# Cada trozo tiene su identificador correcto (0, 1, 2)
var shred_pieces_data: Array[Dictionary] = [
	{"id": 0, "text": "[-TOP-]\nSEC"},
	{"id": 1, "text": "[-MID-]\nRET"},
	{"id": 2, "text": "[-BTM-]\n#CODE"}
]

# Guardar qué pieza está en cada ranura (-1 = vacía)
var placed_slots: Array[int] = [-1, -1, -1]

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var instructions_label: Label = $VBoxContainer.get_node_or_null("InstructionsLabel")
@onready var target_slots_hbox: HBoxContainer = $VBoxContainer.get_node_or_null("TargetSlotsHBox")
@onready var shreds_pool_hbox: HBoxContainer = $VBoxContainer.get_node_or_null("ShredsPoolHBox")
@onready var status_label: Label = $VBoxContainer.get_node_or_null("StatusLabel")
@onready var digit_label: Label = $VBoxContainer.get_node_or_null("DigitLabel")
@onready var paper_audio: AudioStreamPlayer = get_node_or_null("PaperAudio")

var slot_buttons: Array[Button] = []
var shred_buttons: Array[Button] = []


func _ready() -> void:
	_setup_automatic_layout()
	_generate_pieces()


func set_puzzle_digit(digit: String) -> void:
	assigned_digit = digit


func _setup_automatic_layout() -> void:
	if vbox:
		vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		vbox.custom_minimum_size = Vector2(560, 420)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 18)

	if instructions_label:
		instructions_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		instructions_label.text = "INSTRUCTIONS: Reassemble the 3 shredded paper pieces in order (Top to Bottom)."
		instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if target_slots_hbox:
		target_slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		target_slots_hbox.add_theme_constant_override("separation", 20)

	if shreds_pool_hbox:
		shreds_pool_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		shreds_pool_hbox.add_theme_constant_override("separation", 20)

	if status_label:
		status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_label.text = "STATUS: DOCUMENT SHREDDED"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if digit_label:
		digit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		digit_label.text = "CODE: ?"
		digit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _generate_pieces() -> void:
	# 1. Crear las 3 ranuras superiores
	if target_slots_hbox:
		for child in target_slots_hbox.get_children():
			child.queue_free()
		slot_buttons.clear()

		for i in range(3):
			var slot_btn = Button.new()
			slot_btn.name = "Slot_" + str(i)
			slot_btn.text = "SLOT " + str(i + 1) + "\n[EMPTY]"
			slot_btn.custom_minimum_size = Vector2(130, 95)
			_apply_style(slot_btn, Color(0.18, 0.2, 0.22), Color(0.4, 0.45, 0.5))
			slot_btn.pressed.connect(_on_slot_pressed.bind(i))
			target_slots_hbox.add_child(slot_btn)
			slot_buttons.append(slot_btn)

	# 2. Desordenar y crear las 3 piezas en el pool inferior
	if shreds_pool_hbox:
		for child in shreds_pool_hbox.get_children():
			child.queue_free()
		shred_buttons.clear()

		var shuffled_data = shred_pieces_data.duplicate()
		shuffled_data.shuffle()

		for item in shuffled_data:
			var shred_btn = Button.new()
			shred_btn.name = "Shred_" + str(item["id"])
			shred_btn.text = item["text"]
			shred_btn.custom_minimum_size = Vector2(130, 95)
			_apply_style(shred_btn, Color(0.85, 0.82, 0.72), Color(0.3, 0.3, 0.3), Color(0.1, 0.1, 0.1))
			shred_btn.pressed.connect(_on_shred_pressed.bind(item["id"], shred_btn))
			shreds_pool_hbox.add_child(shred_btn)
			shred_buttons.append(shred_btn)


func _apply_style(btn: Button, bg_col: Color, border_col: Color, font_col: Color = Color.WHITE) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", font_col)


func _on_shred_pressed(piece_id: int, btn: Button) -> void:
	if is_completed:
		return

	selected_shred_index = piece_id

	# Resaltar la pieza activa
	for b in shred_buttons:
		if is_instance_valid(b) and b.visible:
			_apply_style(b, Color(0.85, 0.82, 0.72), Color(0.3, 0.3, 0.3), Color(0.1, 0.1, 0.1))

	_apply_style(btn, Color(1.0, 0.95, 0.6), Color(0.9, 0.6, 0.1), Color(0.1, 0.1, 0.1))

	if status_label:
		status_label.text = "PIECE SELECTED: Choose a target slot above!"
		status_label.modulate = Color(1.0, 0.9, 0.3, 1.0)


func _on_slot_pressed(slot_idx: int) -> void:
	if is_completed:
		return

	if selected_shred_index == -1:
		if status_label:
			status_label.text = "Select a paper shred from below first!"
			status_label.modulate = Color(1.0, 0.5, 0.5, 1.0)
		return

	# Si la ranura ya tenía una pieza, no sobreescribir
	if placed_slots[slot_idx] != -1:
		return

	if paper_audio and paper_audio.stream != null:
		paper_audio.play()

	# Colocar la pieza en la ranura
	placed_slots[slot_idx] = selected_shred_index
	slot_buttons[slot_idx].text = shred_pieces_data[selected_shred_index]["text"]
	_apply_style(slot_buttons[slot_idx], Color(0.9, 0.88, 0.78), Color(0.2, 0.6, 0.2), Color(0.1, 0.1, 0.1))

	# Ocultar el botón del pool
	for b in shred_buttons:
		if is_instance_valid(b) and b.name == "Shred_" + str(selected_shred_index):
			b.visible = false

	selected_shred_index = -1

	# Comprobar si las 3 ranuras ya están ocupadas
	if not placed_slots.has(-1):
		_validate_document()


func _validate_document() -> void:
	# El orden correcto es 0 (TOP), 1 (MID), 2 (BTM)
	if placed_slots[0] == 0 and placed_slots[1] == 1 and placed_slots[2] == 2:
		_complete_puzzle()
	else:
		_trigger_penalty()


func _trigger_penalty() -> void:
	if status_label:
		status_label.text = "INCORRECT ASSEMBLY! PAPER RESET. -30s"
		status_label.modulate = Color(1.0, 0.2, 0.2, 1.0)

	penalty_triggered.emit(30.0)

	# Resetear slots y piezas
	placed_slots = [-1, -1, -1]
	selected_shred_index = -1
	_generate_pieces()


func _complete_puzzle() -> void:
	is_completed = true

	for btn in slot_buttons:
		btn.disabled = true

	if status_label:
		status_label.modulate = Color(0.2, 1.0, 0.2, 1.0)
		status_label.text = "DOCUMENT RESTORED!"

	if digit_label:
		digit_label.text = "CODE DIGIT FOUND: " + assigned_digit

	puzzle_solved.emit(assigned_digit)
