## Типизированное реактивное float-значение: .value имеет тип float.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactiveFloat
extends ReactivePropertyBase

var value: float:
	get:
		return _value
	set(v):
		_set_value(v)

func _init(initial_value: float = 0.0, comparer: Callable = Callable()) -> void:
	super(initial_value, comparer)
