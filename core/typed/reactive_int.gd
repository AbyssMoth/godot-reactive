## Типизированное реактивное int-значение: .value имеет тип int.
## Операторы filter/map/distinct, сериализация и подписки - как у ReactiveProperty.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactiveInt
extends ReactivePropertyBase

var value: int:
	get:
		return _value
	set(v):
		_set_value(v)

func _init(initial_value: int = 0, comparer: Callable = Callable()) -> void:
	super(initial_value, comparer)
