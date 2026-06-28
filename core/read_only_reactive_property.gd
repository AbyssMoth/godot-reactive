## Только-чтение поверх ReactivePropertyBase: есть value и subscribe(), но нет сеттера.
## Отдавай во view/презентеры, чтобы состояние нельзя было поменять "мимо" владельца.
## Работает и с типизированными свойствами (value тут - Variant).
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReadOnlyReactiveProperty
extends Observable

var _source: ReactivePropertyBase

var value: Variant:
	get:
		return _source.get_value()

func _init(source: ReactivePropertyBase) -> void:
	_source = source

func subscribe(on_next: Callable, emit_current: bool = true) -> RxDisposable:
	return _source.subscribe(on_next, emit_current)
