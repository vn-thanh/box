extends Node
## SaveSystem — autoload quản lý save/load game
## Mỗi save là 1 file JSON trong user://saves/
## File name = <world_name>.save (sanitize dấu cách thành _)

const SAVE_DIR := "user://saves/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

## Trả về danh sách save: [{name, path, timestamp, world_size}]
func list_saves() -> Array[Dictionary]:
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		return []

	var saves: Array[Dictionary] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".save"):
			var full_path := SAVE_DIR + fname
			var data := _read_file(full_path)
			if data:
				var entry := {
					"name": data.get("world_name", fname.get_basename()),
					"path": full_path,
					"timestamp": data.get("save_time", 0),
					"world_size": data.get("world_size", 80.0),
					"npc_count": data.get("npc_count", 0),
				}
				saves.append(entry)
		fname = dir.get_next()
	dir.list_dir_end()

	# Sắp xếp mới nhất trước
	saves.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	return saves

## Lưu game state hiện tại
func save_game(world_name: String, world_size: float, npc_data: Array) -> bool:
	var safe_name := _sanitize_name(world_name)
	if safe_name.is_empty():
		safe_name = "World"
	var path := SAVE_DIR + safe_name + ".save"

	var data := {
		"world_name": world_name,
		"world_size": world_size,
		"save_time": Time.get_unix_time_from_system(),
		"npc_count": npc_data.size(),
		"npcs": npc_data,
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: không thể ghi file %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

## Load game state từ path
func load_game(path: String) -> Dictionary:
	return _read_file(path)

## Xóa save file
func delete_save(path: String) -> bool:
	return DirAccess.remove_absolute(path)

## Định dạng thời gian lưu dạng chuỗi dễ đọc
func format_time(timestamp: int) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]

func _read_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content := file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(content)
	if result is Dictionary:
		return result
	return {}

func _sanitize_name(world_name_raw: String) -> String:
	return world_name_raw.replace(" ", "_").replace("/", "_").replace("\\", "_").replace(":", "_")