## Внутренние операторы потока. Напрямую не используются -
## их создают методы Observable.filter()/map()/distinct().
## Каждый оператор лишь оборачивает подписку на источник, поэтому
## dispose() результата снимает всю цепочку разом.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name RxOperators
extends RefCounted


## filter(): пропускает значения, прошедшие предикат.
class Filter extends Observable:
	var _source: Observable
	var _predicate: Callable

	func _init(source: Observable, predicate: Callable) -> void:
		_source = source
		_predicate = predicate

	func subscribe(on_next: Callable, emit_current: bool = true) -> RxDisposable:
		var gate := func(v: Variant) -> void:
			if not on_next.is_valid():
				return
			if _predicate.is_valid() and _predicate.call(v):
				on_next.call(v)
		return _source.subscribe(gate, emit_current)


## map(): преобразует каждое значение перед выдачей.
class Map extends Observable:
	var _source: Observable
	var _selector: Callable

	func _init(source: Observable, selector: Callable) -> void:
		_source = source
		_selector = selector

	func subscribe(on_next: Callable, emit_current: bool = true) -> RxDisposable:
		var gate := func(v: Variant) -> void:
			if on_next.is_valid():
				on_next.call(_selector.call(v))
		return _source.subscribe(gate, emit_current)


## distinct(): не пропускает повтор предыдущего значения (на каждую подписку своя память).
class Distinct extends Observable:
	var _source: Observable

	func _init(source: Observable) -> void:
		_source = source

	func subscribe(on_next: Callable, emit_current: bool = true) -> RxDisposable:
		var has_last := [false]
		var last := [null]
		var gate := func(v: Variant) -> void:
			if not on_next.is_valid():
				return
			if has_last[0] and last[0] == v:
				return
			has_last[0] = true
			last[0] = v
			on_next.call(v)
		return _source.subscribe(gate, emit_current)
