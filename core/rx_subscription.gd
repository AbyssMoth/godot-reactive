## Подписка на один сигнал. Создаётся внутри ReactiveProperty.subscribe().
## Развитие твоего ReactiveSubscription: защищён от двойного dispose
## и от случая, когда источник (эмиттер) уже освобождён.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name RxSubscription
extends RxDisposable

var _signal: Signal
var _callback: Callable
var _disposed: bool = false

func _init(source_signal: Signal, callback: Callable) -> void:
	_signal = source_signal
	_callback = callback

func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	# get_object() == null -> эмиттер уже освобождён, отключать нечего.
	if not _callback.is_null() and _signal.get_object() != null:
		if _signal.is_connected(_callback):
			_signal.disconnect(_callback)

func is_disposed() -> bool:
	return _disposed
