## Тесты на утечки: коннекты сигналов снимаются, объекты освобождаются.
## Главная причина утечек в реактивщине - забытые подписки, держащие объекты.
## (c) 2026 Abyss Moth / RimuruDev. MIT.
extends RxTest

func test_dispose_removes_connection() -> void:
	var p := ReactiveProperty.new(0)
	assert_connections(p.changed, 0, "до подписки 0 коннектов")
	var sub := p.subscribe(func(_v): pass)
	assert_connections(p.changed, 1, "после подписки 1 коннект")
	sub.dispose()
	assert_connections(p.changed, 0, "после dispose 0 (нет утечки коннекта)")

func test_double_dispose_safe() -> void:
	var p := ReactiveProperty.new(0)
	var sub := p.subscribe(func(_v): pass)
	sub.dispose()
	sub.dispose()
	assert_connections(p.changed, 0, "двойной dispose безопасен")
	assert_true(sub.is_disposed(), "is_disposed == true")

func test_bag_removes_all_connections() -> void:
	var bag := RxDisposableBag.new()
	var p := ReactiveProperty.new(0)
	bag.add(p.subscribe(func(_v): pass))
	bag.add(p.filter(func(_v): return true).subscribe(func(_v): pass))
	assert_connections(p.changed, 2, "две активные подписки")
	bag.dispose()
	assert_connections(p.changed, 0, "мешок снял все коннекты")

func test_property_frees_after_dispose() -> void:
	var p := ReactiveProperty.new(0)
	var sub := p.subscribe(func(_v): pass)
	var wr := weakref(p)
	sub.dispose()
	sub = null
	p = null
	assert_freed(wr, "ReactiveProperty освобождается после dispose + drop")

func test_operator_chain_frees_source() -> void:
	var p := ReactiveProperty.new(0)
	var sub := p.filter(func(_v): return true).map(func(v): return v).distinct().subscribe(func(_v): pass)
	var wr := weakref(p)
	sub.dispose()
	sub = null
	p = null
	assert_freed(wr, "цепочка операторов не держит источник после dispose")

func test_bind_to_node_wires_tree_exited() -> void:
	var node := Node.new()
	var p := ReactiveProperty.new(0)
	var sub := p.subscribe(func(_v): pass)
	assert_eq(sub.bind_to_node(node), sub, "bind_to_node возвращает себя")
	assert_connections(node.tree_exited, 1, "подписан на tree_exited ноды")
	node.free()
	sub.dispose()
