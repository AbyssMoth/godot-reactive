## Типизированное реактивное String-значение: .value имеет тип String.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactiveString
extends ReactivePropertyBase

var value: String:
	get:
		return _value
	set(v):
		_set_value(v)

func _init(initial_value: String = "", comparer: Callable = Callable()) -> void:
	super(initial_value, comparer)
