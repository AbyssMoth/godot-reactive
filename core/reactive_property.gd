## Реактивное значение (Variant) - аналог ReactiveProperty из R3/UniRx.
## Подписка сразу присылает текущее значение, затем - все изменения.
## Для строгой типизации см. ReactiveInt/ReactiveFloat/ReactiveBool/ReactiveString/ReactiveVector2.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name ReactiveProperty
extends ReactivePropertyBase

## Текущее значение. Присваивание уведомит подписчиков, если значение реально изменилось.
var value: Variant:
	get:
		return _value
	set(v):
		_set_value(v)
