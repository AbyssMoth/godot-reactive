## Типизированное реактивное bool-значение: .value имеет тип bool.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactiveBool
extends ReactivePropertyBase

var value: bool:
	get:
		return _value
	set(v):
		_set_value(v)

func _init(initial_value: bool = false, comparer: Callable = Callable()) -> void:
	super(initial_value, comparer)
