## Базовый класс юнит-теста. Наследуй и пиши методы test_*().
## Ассерты НЕ роняют прогон - копят результат, чтобы выполнить все проверки.
## Опционально можно определить before_each()/after_each().
##
## Тесты - dev-only (в релиз/обфускацию не попадают), поэтому строковые вызовы
## в раннере допустимы.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name RxTest
extends RefCounted

var _results: Array = []

func get_results() -> Array:
	return _results

# --- базовые ассерты ---

func assert_true(cond: bool, msg: String = "") -> void:
	_put(cond, "assert_true", msg, "(got false)")

func assert_false(cond: bool, msg: String = "") -> void:
	_put(not cond, "assert_false", msg, "(got true)")

func assert_eq(a: Variant, b: Variant, msg: String = "") -> void:
	_put(a == b, "assert_eq", msg, "(got %s, expected %s)" % [a, b])

func assert_ne(a: Variant, b: Variant, msg: String = "") -> void:
	_put(a != b, "assert_ne", msg, "(both %s)" % [a])

func assert_null(v: Variant, msg: String = "") -> void:
	_put(v == null, "assert_null", msg, "(got %s)" % [v])

func assert_not_null(v: Variant, msg: String = "") -> void:
	_put(v != null, "assert_not_null", msg, "(got null)")

func assert_almost_eq(a: float, b: float, eps: float = 0.00001, msg: String = "") -> void:
	_put(absf(a - b) <= eps, "assert_almost_eq", msg, "(got %s, expected ~%s)" % [a, b])

func assert_type(v: Variant, type_id: int, msg: String = "") -> void:
	_put(typeof(v) == type_id, "assert_type", msg, "(got type %d, expected %d)" % [typeof(v), type_id])

# --- детектор утечек ---

## Сколько коннектов сейчас висит на сигнале (0 после полной отписки).
func assert_connections(sig: Signal, expected: int, msg: String = "") -> void:
	var n := sig.get_connections().size()
	_put(n == expected, "assert_connections", msg, "(got %d, expected %d)" % [n, expected])

## Объект освобождён (weakref пуст). Лови утечки RefCounted после dispose().
func assert_freed(wr: WeakRef, msg: String = "") -> void:
	_put(wr.get_ref() == null, "assert_freed", msg, "(объект жив - утечка)")

func _put(passed: bool, kind: String, msg: String, fail_detail: String) -> void:
	var label := kind if msg.is_empty() else (kind + ": " + msg)
	if passed:
		_results.append({"passed": true, "msg": label})
	else:
		_results.append({"passed": false, "msg": label + " " + fail_detail})
