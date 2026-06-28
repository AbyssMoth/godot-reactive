## Пример использования: подписки, операторы, мешок отписок, сейв/лоад.
## Повесь скрипт на любую Node, запусти сцену - смотри вывод в консоль.
## Можешь удалить папку examples/ - на работу аддона она не влияет.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
extends Node

const SAVE_PATH := "user://progress_example.sav"

var _progress := PlayerProgressExample.new()
var _bag := RxDisposableBag.new()

func _ready() -> void:
	# 1) View: подписался - сразу получил текущее значение, затем все изменения.
	_progress.coins.subscribe(func(v): print("[coins] = ", v)).add_to(_bag)

	# 2) Смерть: edge-triggered - только когда hp реально стало <= 0.
	_progress.hp.filter(func(v): return v <= 0).distinct() \
		.subscribe(func(_v): print("[death] игрок погиб"), false).add_to(_bag)

	# 3) "Хватает на покупку за 100": производное от монет.
	_progress.coins.map(func(c): return c >= 100).distinct() \
		.subscribe(func(ok): print("[shop] доступно: ", ok)).add_to(_bag)

	# 4) Производное от нескольких источников (кошелёк = монеты + кристаллы).
	var wallet := Rx.computed([_progress.coins, _progress.gems], func(c, g): return c + g)
	wallet.subscribe(func(total): print("[wallet] всего: ", total)).add_to(_bag)

	# Меняем состояние "где угодно" - подписчики обновятся сами.
	print("--- меняем состояние ---")
	_progress.coins.value += 150   # coins=150, shop -> доступно, wallet=150
	_progress.gems.value += 10     # wallet=160
	_progress.hp.value = 0         # death

	# 5) Сейв/лоад одним вызовом.
	print("--- save/load ---")
	SaveSystem.save(SAVE_PATH, _progress)
	_progress.coins.value = 999    # "испортили" значение
	SaveSystem.load(SAVE_PATH, _progress)   # вернёт сохранённое -> подписчик [coins] обновится сам

func _exit_tree() -> void:
	_bag.dispose()   # снимаем все подписки разом
