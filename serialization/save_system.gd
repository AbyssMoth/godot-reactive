## Сохранение/загрузка ReactiveModel одним вызовом.
## Конверт: { "version": int, "data": {...} } + версия/миграции + опц. AES-шифрование.
##
##   SaveSystem.save("user://progress.sav", progress)
##   SaveSystem.load("user://progress.sav", progress)
##   SaveSystem.save("user://progress.sav", progress, "secret")          # AES
##   SaveSystem.save("user://p.sav", progress, "", SaveSystem.Codec.GODOT_BINARY)
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name SaveSystem
extends RefCounted

enum Codec {
	JSON,          ## Человекочитаемый JSON. Переносимый; int/float и Vector2 - см. README.
	GODOT_TEXT,    ## var_to_str: без потерь для типов Godot (Vector2, Color...), читаемый.
	GODOT_BINARY,  ## var_to_bytes: компактный бинарь без потерь.
}

const _KEY_VERSION := "version"
const _KEY_DATA := "data"

## Сохранить модель. Пустой password = без шифрования. Возвращает Error (OK при успехе).
static func save(path: String, model: ReactiveModel, password: String = "", codec: Codec = Codec.JSON) -> Error:
	var envelope: Dictionary = {
		_KEY_VERSION: model._version(),
		_KEY_DATA: model.serialize(),
	}
	var bytes: PackedByteArray = _encode(envelope, codec)
	var file: FileAccess = _open(path, FileAccess.WRITE, password)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		push_error("SaveSystem.save: не открыть " + path + " (" + error_string(err) + ")")
		return err if err != OK else FAILED
	file.store_buffer(bytes)
	file.close()
	return OK

## Загрузить модель (выставит .value у полей -> подписчики обновятся). Возвращает Error.
static func load(path: String, model: ReactiveModel, password: String = "", codec: Codec = Codec.JSON) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var file: FileAccess = _open(path, FileAccess.READ, password)
	if file == null:
		var err: Error = FileAccess.get_open_error()
		push_error("SaveSystem.load: не открыть " + path + " (" + error_string(err) + ")")
		return err if err != OK else FAILED
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	var envelope: Variant = _decode(bytes, codec)
	if typeof(envelope) != TYPE_DICTIONARY:
		push_error("SaveSystem.load: повреждённый файл " + path)
		return ERR_FILE_CORRUPT

	var from_version: int = int(envelope.get(_KEY_VERSION, 1))
	var data: Variant = envelope.get(_KEY_DATA, {})
	if typeof(data) != TYPE_DICTIONARY:
		return ERR_FILE_CORRUPT

	if from_version != model._version():
		data = model._migrate(data, from_version)

	model.deserialize(data)
	return OK

## Удалить файл сейва. Возвращает true, если файл существовал и был удалён.
static func delete(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	return dir.remove(path.get_file()) == OK

static func exists(path: String) -> bool:
	return FileAccess.file_exists(path)

static func _open(path: String, mode: FileAccess.ModeFlags, password: String) -> FileAccess:
	if password.is_empty():
		return FileAccess.open(path, mode)
	return FileAccess.open_encrypted_with_pass(path, mode, password)

static func _encode(envelope: Dictionary, codec: Codec) -> PackedByteArray:
	match codec:
		Codec.GODOT_TEXT:
			return var_to_str(envelope).to_utf8_buffer()
		Codec.GODOT_BINARY:
			return var_to_bytes(envelope)
		_:
			return JSON.stringify(envelope, "\t").to_utf8_buffer()

static func _decode(bytes: PackedByteArray, codec: Codec) -> Variant:
	match codec:
		Codec.GODOT_TEXT:
			return str_to_var(bytes.get_string_from_utf8())
		Codec.GODOT_BINARY:
			return bytes_to_var(bytes)
		_:
			return JSON.parse_string(bytes.get_string_from_utf8())
