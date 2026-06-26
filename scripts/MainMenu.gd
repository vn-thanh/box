extends Control
## MainMenu — màn hình chính
## 3 nút: New Game (input tên world + kích cỡ), Load (danh sách save), Exit

const MAIN_SCENE := "res://scenes/Main.tscn"

# Main panel
var _panel: Panel
var _title_label: Label

# New Game dialog
var _new_game_panel: Panel
var _name_input: LineEdit
var _size_slider: HSlider
var _size_label: Label

# Load dialog
var _load_panel: Panel
var _save_list: ItemList
var _save_info_label: Label
var _delete_btn: Button
var _load_confirm_btn: Button

# --- Buttons ---
var _btn_new: Button
var _btn_load: Button
var _btn_exit: Button


func _ready() -> void:
	_build_ui()
	_connect_signals()
	get_tree().set_auto_accept_quit(false)

	# Kiểm tra có save không — ẩn nút Load nếu rỗng
	_refresh_load_button_state()


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.14, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	_title_label = Label.new()
	_title_label.text = "BOX"
	_title_label.add_theme_font_size_override("font_size", 72)
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector2(0, 60)
	_title_label.size = Vector2(get_viewport().get_visible_rect().size.x, 100)
	add_child(_title_label)

	var subtitle := Label.new()
	subtitle.text = "A Ghibli World"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 140)
	subtitle.size = Vector2(get_viewport().get_visible_rect().size.x, 30)
	add_child(subtitle)

	# Main button container
	var screen_w := get_viewport().get_visible_rect().size.x
	var center_x := screen_w / 2.0

	# Main panel (decorative)
	_panel = Panel.new()
	_panel.size = Vector2(320, 260)
	_panel.position = Vector2(center_x - 160, 200)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.18, 0.25, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.4, 0.55, 0.8)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	# Buttons
	_btn_new = _make_button("New Game", Vector2(center_x - 100, 220), Vector2(200, 50))
	_btn_load = _make_button("Load Game", Vector2(center_x - 100, 285), Vector2(200, 50))
	_btn_exit = _make_button("Exit", Vector2(center_x - 100, 350), Vector2(200, 50))
	add_child(_btn_new)
	add_child(_btn_load)
	add_child(_btn_exit)

	# --- New Game Dialog ---
	_new_game_panel = _make_dialog_panel(Vector2(420, 280), "Create New World")
	_new_game_panel.visible = false
	add_child(_new_game_panel)

	var name_label := Label.new()
	name_label.text = "World Name:"
	name_label.position = Vector2(20, 50)
	name_label.size = Vector2(120, 25)
	_new_game_panel.add_child(name_label)

	_name_input = LineEdit.new()
	_name_input.text = "My World"
	_name_input.position = Vector2(140, 47)
	_name_input.size = Vector2(260, 30)
	_new_game_panel.add_child(_name_input)

	var size_label_title := Label.new()
	size_label_title.text = "World Size:"
	size_label_title.position = Vector2(20, 95)
	size_label_title.size = Vector2(120, 25)
	_new_game_panel.add_child(size_label_title)

	_size_slider = HSlider.new()
	_size_slider.min_value = 40
	_size_slider.max_value = 200
	_size_slider.step = 10
	_size_slider.value = 80
	_size_slider.position = Vector2(140, 95)
	_size_slider.size = Vector2(200, 25)
	_new_game_panel.add_child(_size_slider)

	_size_label = Label.new()
	_size_label.text = "80 m"
	_size_label.position = Vector2(350, 93)
	_size_label.size = Vector2(60, 25)
	_new_game_panel.add_child(_size_label)

	var start_btn := _make_button("Start", Vector2(100, 210), Vector2(120, 40))
	_new_game_panel.add_child(start_btn)
	start_btn.pressed.connect(_on_start_new_game)

	var cancel_btn := _make_button("Cancel", Vector2(240, 210), Vector2(120, 40))
	_new_game_panel.add_child(cancel_btn)
	cancel_btn.pressed.connect(func(): _new_game_panel.visible = false)

	# --- Load Game Dialog ---
	_load_panel = _make_dialog_panel(Vector2(520, 380), "Load World")
	_load_panel.visible = false
	add_child(_load_panel)

	_save_list = ItemList.new()
	_save_list.position = Vector2(20, 50)
	_save_list.size = Vector2(480, 220)
	_save_list.item_selected.connect(_on_save_selected)
	_load_panel.add_child(_save_list)

	_save_info_label = Label.new()
	_save_info_label.text = ""
	_save_info_label.position = Vector2(20, 280)
	_save_info_label.size = Vector2(320, 25)
	_save_info_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 0.9))
	_load_panel.add_child(_save_info_label)

	_load_confirm_btn = _make_button("Load", Vector2(350, 320), Vector2(70, 40))
	_load_panel.add_child(_load_confirm_btn)
	_load_confirm_btn.disabled = true
	_load_confirm_btn.pressed.connect(_on_load_confirm)

	_delete_btn = _make_button("Delete", Vector2(430, 320), Vector2(70, 40))
	_load_panel.add_child(_delete_btn)
	_delete_btn.disabled = true
	_delete_btn.pressed.connect(_on_delete_save)

	var close_load_btn := _make_button("Close", Vector2(20, 320), Vector2(70, 40))
	_load_panel.add_child(close_load_btn)
	close_load_btn.pressed.connect(func(): _load_panel.visible = false)


func _make_button(text: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 18)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.25, 0.35, 0.95)
	style_normal.border_width_left = 1
	style_normal.border_width_right = 1
	style_normal.border_width_top = 1
	style_normal.border_width_bottom = 1
	style_normal.border_color = Color(0.35, 0.45, 0.6, 0.6)
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.4, 0.55, 1.0)
	style_hover.border_width_left = 1
	style_hover.border_width_right = 1
	style_hover.border_width_top = 1
	style_hover.border_width_bottom = 1
	style_hover.border_color = Color(0.5, 0.6, 0.8, 1.0)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.15, 0.2, 0.3, 1.0)
	style_pressed.corner_radius_top_left = 6
	style_pressed.corner_radius_top_right = 6
	style_pressed.corner_radius_bottom_left = 6
	style_pressed.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	return btn


func _make_dialog_panel(sz: Vector2, title_text: String) -> Panel:
	var screen_size := get_viewport().get_visible_rect().size
	var p := Panel.new()
	p.size = sz
	p.position = Vector2(screen_size.x / 2 - sz.x / 2, screen_size.y / 2 - sz.y / 2)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.22, 0.97)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.45, 0.6, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	p.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1))
	title.position = Vector2(20, 15)
	title.size = Vector2(sz.x - 40, 30)
	p.add_child(title)

	var sep := HSeparator.new()
	sep.position = Vector2(20, 42)
	sep.size = Vector2(sz.x - 40, 2)
	p.add_child(sep)

	return p


func _connect_signals() -> void:
	_btn_new.pressed.connect(func(): _new_game_panel.visible = true)
	_btn_load.pressed.connect(_open_load_dialog)
	_btn_exit.pressed.connect(_on_exit)
	_size_slider.value_changed.connect(_on_size_changed)


# ============================================================
# SIGNAL HANDLERS
# ============================================================
func _on_size_changed(value: float) -> void:
	_size_label.text = "%d m" % int(value)


func _on_start_new_game() -> void:
	var world_name := _name_input.text.strip_edges()
	if world_name.is_empty():
		world_name = "World"
	var world_size := float(_size_slider.value)

	# Lưu meta vào autoload tạm để Main đọc
	var meta := {
		"world_name": world_name,
		"world_size": world_size,
	}
	get_tree().set_meta("new_game_meta", meta)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _open_load_dialog() -> void:
	_save_list.clear()
	_save_info_label.text = ""
	_load_confirm_btn.disabled = true
	_delete_btn.disabled = true

	var saves := SaveSystem.list_saves()
	if saves.is_empty():
		_save_info_label.text = "No save files found."
		_load_panel.visible = true
		return

	for save in saves:
		var time_str := SaveSystem.format_time(int(save.timestamp))
		var item_text := "%s  —  %s  (%d NPCs)" % [save.name, time_str, save.npc_count]
		_save_list.add_item(item_text)
		_save_list.set_item_metadata(_save_list.item_count - 1, save)

	_load_panel.visible = true


func _on_save_selected(idx: int) -> void:
	_load_confirm_btn.disabled = false
	_delete_btn.disabled = false
	var save: Dictionary = _save_list.get_item_metadata(idx)
	_save_info_label.text = "World: %s  |  Size: %dm  |  Saved: %s" % [
		save.name, int(save.world_size), SaveSystem.format_time(int(save.timestamp))
	]


func _on_load_confirm() -> void:
	var items := _save_list.get_selected_items()
	if items.is_empty():
		return
	var save: Dictionary = _save_list.get_item_metadata(items[0])
	var data := SaveSystem.load_game(save.path)
	if data.is_empty():
		_save_info_label.text = "Failed to load save file."
		return

	get_tree().set_meta("load_game_data", data)
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_delete_save() -> void:
	var items := _save_list.get_selected_items()
	if items.is_empty():
		return
	var save: Dictionary = _save_list.get_item_metadata(items[0])
	SaveSystem.delete_save(save.path)
	_open_load_dialog()


func _on_exit() -> void:
	get_tree().quit()


func _refresh_load_button_state() -> void:
	var saves := SaveSystem.list_saves()
	_btn_load.disabled = saves.is_empty()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()