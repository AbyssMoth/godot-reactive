## База для сериализуемой реактивной модели состояния.
## Поля-ReactiveProperty объявляешь как обычно, а в _schema() отдаёшь
## карту { "имя_в_файле": поле }. serialize()/deserialize() ходят по ней.
##
## Сохранение "почти бесплатно":
##   serialize()        -> Dictionary (чистые данные, готов к JSON)
##   deserialize(dict)  -> выставляет .value у полей -> подписчики обновляются сами
##
## Строки-ключи в _schema() - это имена в файле сейва. Они стабильны и НЕ ломаются
## обфускацией: обфускатор переименует идентификаторы полей, но не строковые ключи.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactiveModel
extends RefCounted

var _schema_cache: Dictionary = {}

## ОБЯЗАТЕЛЬНО переопредели: верни { "field_key": <ReactiveProperty | ReactiveModel> }.
## Вложенные ReactiveModel сериализуются рекурсивно.
func _schema() -> Dictionary:
	return {}

## Версия формата сейва. Поднимай при изменении схемы и обрабатывай в _migrate().
func _version() -> int:
	return 1

## Миграция старых данных к текущей версии. По умолчанию - как есть.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	return data

## Состояние -> чистый Dictionary (готов к JSON).
func serialize() -> Dictionary:
	var out: Dictionary = {}
	var schema: Dictionary = _get_schema()
	for key in schema:
		out[key] = _serialize_field(schema[key])
	return out

## Чистый Dictionary -> состояние. Выставляет .value у полей (триггерит подписки).
func deserialize(data: Dictionary) -> void:
	if data == null:
		return
	var schema: Dictionary = _get_schema()
	for key in schema:
		if not data.has(key):
			continue
		var field: Variant = schema[key]
		if field is ReactivePropertyBase:
			field.set_value_raw(_coerce(data[key], field.get_value()))
		elif field is ReactiveModel:
			field.deserialize(data[key])

func _get_schema() -> Dictionary:
	if _schema_cache.is_empty():
		_schema_cache = _schema()
	return _schema_cache

func _serialize_field(field: Variant) -> Variant:
	if field is ReactivePropertyBase:
		return field.get_value()
	if field is ReactiveModel:
		return field.serialize()
	return field

## Приводит входящее значение к типу текущего (важно для JSON: int приходит как float).
static func _coerce(incoming: Variant, type_hint: Variant) -> Variant:
	match typeof(type_hint):
		TYPE_INT:
			return int(incoming)
		TYPE_FLOAT:
			return float(incoming)
		TYPE_BOOL:
			return bool(incoming)
		TYPE_STRING:
			return str(incoming)
		_:
			return incoming
