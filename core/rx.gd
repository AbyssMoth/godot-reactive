## Короткие фабрики, чтобы меньше писать. Всё опционально.
##   var hp := Rx.prop(100)
##   var bag := Rx.bag()
##   var total := Rx.computed([coins, gems], func(c, g): return c + g)
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name Rx
extends RefCounted

static func prop(initial_value: Variant = null) -> ReactiveProperty:
	return ReactiveProperty.new(initial_value)

static func bag() -> RxDisposableBag:
	return RxDisposableBag.new()

## Производное значение от нескольких источников.
## sources: Array[ReactiveProperty]; selector: Callable(v0, v1, ...) -> Variant.
## Пересчитывается при изменении любого источника. Возвращает read-only.
## ВНИМАНИЕ: живёт столько же, сколько источники (держит на них подписки).
## Не создавай "одноразовые" computed в циклах/кадрах.
static func computed(sources: Array, selector: Callable) -> ReadOnlyReactiveProperty:
	var compute := func() -> Variant:
		var args: Array = []
		for s in sources:
			args.append(s.value)
		return selector.callv(args)
	var result := ReactiveProperty.new(compute.call())
	for s in sources:
		s.subscribe(func(_v): result.value = compute.call(), false)
	return result.to_read_only()
