## Базовый "наблюдаемый" поток значений - аналог Observable из R3/UniRx.
## Сам по себе абстрактный: конкретная реализация - ReactiveProperty.
## Операторы filter()/map()/distinct() возвращают новый Observable для чейнинга.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name Observable
extends RefCounted

## Подписаться на поток.
## on_next: Callable(value) - вызывается при каждом новом значении.
## emit_current: при true сразу прислать текущее значение (если оно есть).
## Возвращает RxDisposable - вызови .dispose(), чтобы отписаться.
func subscribe(on_next: Callable, emit_current: bool = true) -> RxDisposable:
	push_error("Observable.subscribe() абстрактный - используй ReactiveProperty или оператор.")
	return null

## Пропускать только значения, для которых predicate(value) == true.
func filter(predicate: Callable) -> Observable:
	return RxOperators.Filter.new(self, predicate)

## Преобразовать каждое значение: value -> selector(value).
func map(selector: Callable) -> Observable:
	return RxOperators.Map.new(self, selector)

## Пропускать значение, только если оно отличается от предыдущего (edge-triggered).
func distinct() -> Observable:
	return RxOperators.Distinct.new(self)
