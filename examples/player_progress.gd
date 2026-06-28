## Пример сериализуемой реактивной модели прогресса игрока.
## Показывает: реактивные поля + _schema() + версия + миграция.
## Можешь удалить папку examples/ - на работу аддона она не влияет.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name PlayerProgressExample
extends ReactiveModel

var coins := ReactiveProperty.new(0)
var gems := ReactiveProperty.new(0)
var hp := ReactiveProperty.new(100)
var level := ReactiveProperty.new(1)
var player_name := ReactiveProperty.new("Hero")

func _schema() -> Dictionary:
	return {
		"coins": coins,
		"gems": gems,
		"hp": hp,
		"level": level,
		"player_name": player_name,
	}

func _version() -> int:
	return 1

func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	# Пример: раньше поле называлось "name", стало "player_name".
	#if from_version < 2 and data.has("name"):
	#	data["player_name"] = data["name"]
	#	data.erase("name")
	return data
