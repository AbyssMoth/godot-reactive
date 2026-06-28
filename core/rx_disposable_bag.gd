## Контейнер подписок - аналог CompositeDisposable из R3.
## Складывай сюда результаты subscribe() и вызови dispose() (обычно в _exit_tree),
## чтобы снять их все разом. Так не нужно хранить каждую подписку отдельно.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name RxDisposableBag
extends RxDisposable

var _items: Array[RxDisposable] = []
var _disposed: bool = false

## Добавить подписку. Если мешок уже disposed - подписка сразу гасится.
func add(disposable: RxDisposable) -> RxDisposable:
	if disposable == null:
		return disposable
	if _disposed:
		disposable.dispose()
		return disposable
	_items.append(disposable)
	return disposable

## Снять все подписки, но оставить мешок пригодным для повторного использования.
func clear() -> void:
	for d in _items:
		if d != null:
			d.dispose()
	_items.clear()

## Снять все подписки окончательно.
func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	clear()

func is_disposed() -> bool:
	return _disposed

func size() -> int:
	return _items.size()
