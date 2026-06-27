extends Control
## MainMenu — màn hình chính
## Nút: New Game, Load Game, Settings, Exit

const MAIN_SCENE := "res://scenes/Main.tscn"
const SETTINGS_PATH := "user://settings.cfg"

# Title
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

# Settings dialog
var _settings_panel: Panel
var _master_slider: HSlider
var _master_label: Label
var _fullscreen_check: CheckBox

# --- Buttons ---
var _btn_new: Button
var _btn_load: Button
var _btn_settings: Button
var _btn_exit: Button


func _ready() -> void:
	_build_ui()
	_connect_signals()
	get_tree().set_auto_accept_quit(false)
	_apply_loaded_settings()
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

	# Buttons (text button, không panel bọc)
	var screen_w := get_viewport().get_visible_rect().size.x
	var center_x := screen_w / 2.0
	var btn_w := 200
	var btn_h := 44
	var gap := 14
	var start_y := 220
	_btn_new = _make_button("New Game", Vector2(center_x - btn_w / 2.0, start_y), Vector2(btn_w, btn_h))
	_btn_load = _make_button("Load Game", Vector2(center_x - btn_w / 2.0, start_y + (btn_h + gap)), Vector2(btn_w, btn_h))
	_btn_settings = _make_button("Settings", Vector2(center_x - btn_w / 2.0, start_y + 2 * (btn_h + gap)), Vector2(btn_w, btn_h))
	_btn_exit = _make_button("Exit", Vector2(center_x - btn_w / 2.0, start_y + 3 * (btn_h + gap)), Vector2(btn_w, btn_h))
	add_child(_btn_new)
	add_child(_btn_load)
	add_child(_btn_settings)
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

	# --- Settings Dialog ---
	_settings_panel = _make_dialog_panel(Vector2(420, 260), "Settings")
	_settings_panel.visible = false
	add_child(_settings_panel)

	var vol_label := Label.new()
	vol_label.text = "Master Volume:"
	vol_label.position = Vector2(20, 60)
	vol_label.size = Vector2(150, 25)
	_settings_panel.add_child(vol_label)

	_master_slider = HSlider.new()
	_master_slider.min_value = 0
	_master_slider.max_value = 100
	_master_slider.step = 1
	_master_slider.value = 80
	_master_slider.position = Vector2(180, 60)
	_master_slider.size = Vector2(180, 25)
	_master_slider.value_changed.connect(_on_master_volume_changed)
	_settings_panel.add_child(_master_slider)

	_master_label = Label.new()
	_master_label.text = "80%"
	_master_label.position = Vector2(370, 58)
	_master_label.size = Vector2(40, 25)
	_settings_panel.add_child(_master_label)

	_fullscreen_check = CheckBox.new()
	_fullscreen_check.text = "Fullscreen"
	_fullscreen_check.position = Vector2(180, 110)
	_fullscreen_check.size = Vector2(160, 30)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_settings_panel.add_child(_fullscreen_check)

	var close_settings_btn := _make_button("Close", Vector2(150, 190), Vector2(120, 40))
	_settings_panel.add_child(close_settings_btn)
	close_settings_btn.pressed.connect(func():
		_settings_panel.visible = false
		_save_settings()
	)


func _make_button(text: String, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = sz
	btn.add_theme_font_size_override("font_size", 18)
	# Text button: nền trong suốt, chỉ hiện text; hover sáng nhẹ
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0, 0, 0, 0)
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(1, 1, 1, 0.08)
	var style_pressed := StyleBoxFlat.new()
	style_pressed.bg_color = Color(1, 1, 1, 0.04)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.7, 0.78, 0.88, 1))
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
	_btn_settings.pressed.connect(func(): _settings_panel.visible = true)
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


# ============================================================
# SETTINGS
# ============================================================
func _on_master_volume_changed(value: float) -> void:
	_master_label.text = "%d%%" % int(value)
	var db := linear_to_db(value / 100.0)
	if value <= 0:
		db = -80.0
	AudioServer.set_bus_volume_db(0, db)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", int(_master_slider.value))
	cfg.set_value("display", "fullscreen", _fullscreen_check.button_pressed)
	cfg.save(SETTINGS_PATH)


func _apply_loaded_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	var vol := int(cfg.get_value("audio", "master_volume", 80))
	var fs := bool(cfg.get_value("display", "fullscreen", false))
	_master_slider.value = vol
	_master_label.text = "%d%%" % vol
	_fullscreen_check.button_pressed = fs
	_on_master_volume_changed(float(vol))
	if fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)