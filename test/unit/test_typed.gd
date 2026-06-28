## Тесты типизированных свойств: ReactiveInt/Float/Bool/String/Vector2.
## (c) 2026 Abyss Moth / RimuruDev. MIT.
extends RxTest

func test_reactive_int() -> void:
	var hp := ReactiveInt.new(100)
	assert_type(hp.value, TYPE_INT, "value это int")
	var got := [0]
	hp.subscribe(func(v): got[0] = v)
	assert_eq(got[0], 100, "emit_current")
	hp.value = 50
	assert_eq(hp.value, 50, "set typed")
	assert_eq(got[0], 50, "подписчик")

func test_reactive_int_default() -> void:
	var x := ReactiveInt.new()
	assert_eq(x.value, 0, "дефолт int = 0, а не null")
	assert_type(x.value, TYPE_INT, "дефолт это int")

func test_reactive_float() -> void:
	var f := ReactiveFloat.new(1.5)
	assert_type(f.value, TYPE_FLOAT, "float")
	f.value = 2.25
	assert_almost_eq(f.value, 2.25, 0.0001, "float set")

func test_reactive_bool() -> void:
	var b := ReactiveBool.new(false)
	assert_type(b.value, TYPE_BOOL, "bool")
	var got := [null]
	b.subscribe(func(v): got[0] = v)
	b.value = true
	assert_true(got[0], "bool true пришёл подписчику")

func test_reactive_string() -> void:
	var s := ReactiveString.new("a")
	assert_type(s.value, TYPE_STRING, "string")
	s.value = "b"
	assert_eq(s.value, "b", "string set")

func test_reactive_vector2() -> void:
	var v := ReactiveVector2.new(Vector2.ZERO)
	assert_type(v.value, TYPE_VECTOR2, "vector2")
	v.value = Vector2(3, 4)
	assert_eq(v.value, Vector2(3, 4), "vector2 set")

func test_typed_operators_and_readonly() -> void:
	var hp := ReactiveInt.new(100)
	var n := [0]
	hp.filter(func(x): return x <= 0).distinct().subscribe(func(_v): n[0] += 1, false)
	hp.value = 0
	assert_eq(n[0], 1, "операторы работают на типизированных")
	assert_eq(hp.to_read_only().value, 0, "read_only с типизированного")
