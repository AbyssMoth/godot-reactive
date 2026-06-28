## Базовый "отписчик". Держи результат subscribe() и вызови dispose(),
## чтобы отписаться. Обычно подписки складывают в RxDisposableBag.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name RxDisposable
extends RefCounted

## Отписаться / освободить ресурс. Идемпотентно (повторный вызов безопасен).
func dispose() -> void:
	pass

func is_disposed() -> bool:
	return true

## Положить подписку в "мешок" для массовой отписки. Возвращает себя (для чейнинга).
##   prop.subscribe(cb).add_to(_bag)
func add_to(bag: RxDisposableBag) -> RxDisposable:
	if bag != null:
		bag.add(self)
	return self

## Авто-dispose, когда нода покидает дерево (удобно для view).
## ВНИМАНИЕ: срабатывает при ЛЮБОМ выходе из дерева (в т.ч. переродительство/пул).
## Для пулящихся нод используй RxDisposableBag вручную в _exit_tree().
func bind_to_node(node: Node) -> RxDisposable:
	if node != null and is_instance_valid(node):
		node.tree_exited.connect(dispose, CONNECT_ONE_SHOT)
	return self
