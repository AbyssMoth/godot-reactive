## Типизированное реактивное Vector2-значение: .value имеет тип Vector2.
## Для сохранения через SaveSystem используй кодек GODOT_TEXT/GODOT_BINARY
## (JSON не хранит Vector2 без потерь).
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactiveVector2
extends ReactivePropertyBase

var value: Vector2:
	get:
		return _value
	set(v):
		_set_value(v)

func _init(initial_value: Vector2 = Vector2.ZERO, comparer: Callable = Callable()) -> void:
	super(initial_value, comparer)
