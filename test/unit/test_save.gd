## Тесты сериализации: SaveSystem (JSON/binary/AES), версии/миграции,
## типизированные поля в ReactiveModel, авто-обновление подписчиков.
## (c) 2026 Abyss Moth / RimuruDev. MIT.
extends RxTest

const PATH := "user://_rx_test.sav"


## Модель с типизированными полями - проверяем, что они тоже сериализуются.
class TypedProgress extends ReactiveModel:
	var coins := ReactiveInt.new(0)
	var ratio := ReactiveFloat.new(0.0)
	var title := ReactiveString.new("")

	func _schema() -> Dictionary:
		return {"coins": coins, "ratio": ratio, "title": title}


## Модель версии 2 с миграцией старого ключа name -> player_name.
class MigratingModel extends ReactiveModel:
	var player_name := ReactiveString.new("")

	func _schema() -> Dictionary:
		return {"player_name": player_name}

	func _version() -> int:
		return 2

	func _migrate(data: Dictionary, from_version: int) -> Dictionary:
		if from_version < 2 and data.has("name"):
			data["player_name"] = data["name"]
			data.erase("name")
		return data


func after_each() -> void:
	SaveSystem.delete(PATH)

func test_json_round_trip() -> void:
	var m := PlayerProgressExample.new()
	m.coins.value = 123
	m.player_name.value = "Rim"
	assert_eq(SaveSystem.save(PATH, m), OK, "save")
	var l := PlayerProgressExample.new()
	assert_eq(SaveSystem.load(PATH, l), OK, "load")
	assert_eq(l.coins.value, 123, "coins")
	assert_type(l.coins.value, TYPE_INT, "coins int, а не float (JSON-coerce)")
	assert_eq(l.player_name.value, "Rim", "name")

func test_load_triggers_subscribers() -> void:
	var m := PlayerProgressExample.new()
	m.coins.value = 5
	SaveSystem.save(PATH, m)
	m.coins.value = 999
	var got := [0]
	m.coins.subscribe(func(v): got[0] = v)
	assert_eq(got[0], 999, "до загрузки 999")
	SaveSystem.load(PATH, m)
	assert_eq(got[0], 5, "загрузка сама обновила подписчика -> 5")

func test_encrypted() -> void:
	var m := PlayerProgressExample.new()
	m.coins.value = 42
	assert_eq(SaveSystem.save(PATH, m, "pw"), OK, "enc save")
	var l := PlayerProgressExample.new()
	assert_eq(SaveSystem.load(PATH, l, "pw"), OK, "enc load")
	assert_eq(l.coins.value, 42, "enc value")

func test_godot_binary_codec() -> void:
	var m := PlayerProgressExample.new()
	m.coins.value = 7
	assert_eq(SaveSystem.save(PATH, m, "", SaveSystem.Codec.GODOT_BINARY), OK, "bin save")
	var l := PlayerProgressExample.new()
	assert_eq(SaveSystem.load(PATH, l, "", SaveSystem.Codec.GODOT_BINARY), OK, "bin load")
	assert_eq(l.coins.value, 7, "bin value")

func test_missing_file() -> void:
	SaveSystem.delete(PATH)
	var l := PlayerProgressExample.new()
	assert_eq(SaveSystem.load(PATH, l), ERR_FILE_NOT_FOUND, "нет файла -> ERR_FILE_NOT_FOUND")

func test_typed_fields_serialize() -> void:
	var m := TypedProgress.new()
	m.coins.value = 9
	m.ratio.value = 0.5
	m.title.value = "hi"
	SaveSystem.save(PATH, m)
	var l := TypedProgress.new()
	SaveSystem.load(PATH, l)
	assert_eq(l.coins.value, 9, "typed coins")
	assert_type(l.coins.value, TYPE_INT, "typed coins остался int")
	assert_almost_eq(l.ratio.value, 0.5, 0.0001, "typed ratio")
	assert_eq(l.title.value, "hi", "typed title")

func test_version_migration() -> void:
	# Пишем "старый" файл version=1 с ключом name руками.
	var envelope := {"version": 1, "data": {"name": "OldHero"}}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_buffer(JSON.stringify(envelope).to_utf8_buffer())
	f.close()
	var m := MigratingModel.new()
	assert_eq(SaveSystem.load(PATH, m), OK, "load v1 файла моделью v2")
	assert_eq(m.player_name.value, "OldHero", "миграция name -> player_name сработала")
