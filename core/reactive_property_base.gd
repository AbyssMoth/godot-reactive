## База для ReactiveProperty и типизированных свойств (ReactiveInt/Float/...).
## Здесь вся логика, КРОМЕ публичного value - его объявляет наследник со своим
## типом (в GDScript нельзя переопределить тип унаследованного члена, поэтому
## value живёт в наследниках, а не тут). Напрямую этот класс не используют.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactivePropertyBase
extends Observable

## new_value, old_value. old_value удобно для логов/"sender"-подобной отладки.
signal changed(new_value: Variant, old_value: Variant)

var _value: Variant
var _comparer: Callable

## comparer: опц. Callable(a, b) -> bool - своё сравнение "равно ли".
func _init(initial_value: Variant = null, comparer: Callable = Callable()) -> void:
	_value = initial_value
	_comparer = comparer

func subscribe(on_next: Callable, emit_current: bool = true) -> RxDisposable:
	var handler := func(new_value: Variant, _old_value: Variant) -> void:
		if on_next.is_valid():
			on_next.call(new_value)
	changed.connect(handler)
	if emit_current and on_next.is_valid():
		on_next.call(_value)
	return RxSubscription.new(changed, handler)

## Текущее значение как Variant (для сериализации и общих случаев).
func get_value() -> Variant:
	return _value

## Выставить значение с проверкой изменения (эквивалент присваивания value).
func set_value_raw(v: Variant) -> void:
	_set_value(v)

## Уведомить даже если значение "равно".
func force_set(v: Variant) -> void:
	var old: Variant = _value
	_value = v
	changed.emit(_value, old)

## value = mutator(value). Read-modify-write: count.mutate(func(x): return x + 1).
func mutate(mutator: Callable) -> void:
	set_value_raw(mutator.call(_value))

## Read-only обёртка - отдавай во view, чтобы они не меняли состояние.
func to_read_only() -> ReadOnlyReactiveProperty:
	return ReadOnlyReactiveProperty.new(self)

func _set_value(v: Variant) -> void:
	if _values_equal(_value, v):
		return
	var old: Variant = _value
	_value = v
	changed.emit(_value, old)

func _values_equal(a: Variant, b: Variant) -> bool:
	if _comparer.is_valid():
		return _comparer.call(a, b)
	return a == b
