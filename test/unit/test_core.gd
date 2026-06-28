## Тесты ядра: ReactiveProperty, операторы, computed, read-only, мешок.
## (c) 2026 Abyss Moth / RimuruDev. MIT.
extends RxTest

func test_emit_current_and_updates() -> void:
	var p := ReactiveProperty.new(10)
	var got := [null]
	var sub := p.subscribe(func(v): got[0] = v)
	assert_eq(got[0], 10, "emit_current")
	p.value = 20
	assert_eq(got[0], 20, "update")
	sub.dispose()
	p.value = 30
	assert_eq(got[0], 20, "после dispose тишина")

func test_no_emit_on_equal() -> void:
	var p := ReactiveProperty.new(1)
	var n := [0]
	p.subscribe(func(_v): n[0] += 1, false)
	p.value = 1
	assert_eq(n[0], 0, "равное не эмитит")
	p.value = 2
	assert_eq(n[0], 1, "изменение эмитит")

func test_force_set_emits_equal() -> void:
	var p := ReactiveProperty.new(5)
	var n := [0]
	p.subscribe(func(_v): n[0] += 1, false)
	p.force_set(5)
	assert_eq(n[0], 1, "force_set эмитит даже равное")

func test_mutate() -> void:
	var p := ReactiveProperty.new(10)
	p.mutate(func(x): return x + 5)
	assert_eq(p.value, 15, "mutate +5")

func test_filter() -> void:
	var hp := ReactiveProperty.new(100)
	var n := [0]
	hp.filter(func(v): return v <= 0).subscribe(func(_v): n[0] += 1, false)
	hp.value = 50
	assert_eq(n[0], 0, "50 не проходит")
	hp.value = 0
	assert_eq(n[0], 1, "0 проходит")

func test_distinct_edge() -> void:
	var hp := ReactiveProperty.new(100)
	var n := [0]
	hp.filter(func(v): return v <= 0).distinct().subscribe(func(_v): n[0] += 1, false)
	hp.value = 0
	hp.value = -5
	assert_eq(n[0], 2, "0 и -5 - два разных события")

func test_map() -> void:
	var c := ReactiveProperty.new(0)
	var got := [null]
	c.map(func(x): return x >= 100).subscribe(func(b): got[0] = b)
	assert_false(got[0], "0 -> false")
	c.value = 150
	assert_true(got[0], "150 -> true")

func test_read_only() -> void:
	var p := ReactiveProperty.new(7)
	var ro := p.to_read_only()
	assert_eq(ro.value, 7, "ro=7")
	var got := [0]
	ro.subscribe(func(v): got[0] = v)
	p.value = 8
	assert_eq(ro.value, 8, "ro обновился")
	assert_eq(got[0], 8, "ro подписчик")

func test_computed() -> void:
	var a := ReactiveProperty.new(1)
	var b := ReactiveProperty.new(2)
	var sum := Rx.computed([a, b], func(x, y): return x + y)
	assert_eq(sum.value, 3, "1+2")
	a.value = 10
	assert_eq(sum.value, 12, "10+2")

func test_bag_mass_dispose() -> void:
	var bag := RxDisposableBag.new()
	var p := ReactiveProperty.new(0)
	var n := [0]
	bag.add(p.subscribe(func(_v): n[0] += 1))
	assert_eq(n[0], 1, "initial")
	p.value = 1
	assert_eq(n[0], 2, "update")
	bag.dispose()
	p.value = 2
	assert_eq(n[0], 2, "после dispose мешка тишина")
