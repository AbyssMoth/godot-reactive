# Abyss Moth Reactive

Реактивные свойства в духе R3 / UniRx (C#) и сериализуемое состояние для GDScript (Godot 4).
Подписываешься на данные, фильтруешь потоки, а сохранение и загрузка делаются одним вызовом.

- Автор: RimuruDev. Студия: Abyss Moth. Лицензия: MIT.
- Движок: Godot 4.x (используются typed-фичи, проверено на 4.7).
- Зависимостей нет. Всё на `class_name`, обфускация-safe (нет вызовов методов и сигналов по строкам).

---

## Зачем

1. Реактивность. Один источник данных (`coins`, `hp`, ...) и много подписчиков. Поменял значение в одном месте - все view и системы обновились сами. При подписке сразу приходит текущее значение.
2. Сохранение. Состояние это чистые данные: `serialize()` даёт `Dictionary`, `deserialize()` выставляет значения обратно и сам триггерит подписки, так что после загрузки UI обновляется без ручной возни. Версии формата, миграции и опциональное AES-шифрование встроены.

---

## Установка

Аддон - это самодостаточная папка `addons/abyss_moth/reactive/`. Включать плагин в `Project Settings -> Plugins` **не обязательно**: классы глобальные и работают сразу. Плагин нужен лишь чтобы папка считалась аддоном.

Способы переиспользовать аддон в других проектах:

- **Git submodule** (как Unity UPM-from-git, работает с приватными репо):
  ```bash
  git submodule add git@github.com:AbyssMoth/godot-reactive.git addons/abyss_moth/reactive
  ```
- **gd-plug** - менеджер плагинов на GDScript, тянет с любого git-URL (вкл. приватные).
- **Просто скопировать** папку `addons/abyss_moth/reactive/` в другой проект.
- **Asset Library** (магазин в редакторе) - лишь один из каналов, для публичных пакетов. Не обязателен.

---

## Быстрый старт - реактивность

```gdscript
var coins := ReactiveProperty.new(0)
var hp := ReactiveProperty.new(100)

# View: подписался - сразу получил текущее значение, дальше все изменения.
coins.subscribe(func(v): label.text = str(v))

# Меняем где угодно - ВСЕ подписчики обновятся.
coins.value += 100
coins.value -= 50

# Смерть: edge-triggered, только когда hp реально стало <= 0.
hp.filter(func(v): return v <= 0).distinct() \
	.subscribe(func(_v): on_player_dead(), false)

# Виньетка на 90-95% HP - отдельная система, своя подписка + фильтр.
hp.filter(func(v): return v >= 90 and v <= 95) \
	.subscribe(func(_v): show_vignette())
```

### Отписка - через "мешок" (аналог `CompositeDisposable` / `.AddTo` из R3)

```gdscript
var _bag := RxDisposableBag.new()

func _ready() -> void:
	coins.subscribe(_on_coins).add_to(_bag)
	hp.subscribe(_on_hp).add_to(_bag)

func _exit_tree() -> void:
	_bag.dispose()   # снимает все подписки разом
```

Либо привязать к жизни ноды: `coins.subscribe(cb).bind_to_node(self)`.

---

## API ядра

### `ReactiveProperty`
- `ReactiveProperty.new(initial, comparer := Callable())` - `comparer(a, b) -> bool` опц. (своё "равно", напр. для словарей).
- `.value` - чтение/запись. Запись уведомляет подписчиков, **только если значение реально изменилось**.
- `.subscribe(on_next: Callable, emit_current := true) -> RxDisposable`.
- `.force_set(v)` - уведомить, даже если "равно".
- `.mutate(func(x): return x + 1)` - read-modify-write.
- `.to_read_only()` - отдать во view без права записи.

### Операторы (`Observable`) - чейнятся, в конце `subscribe()`
- `.filter(predicate)` - пропускать прошедшие предикат.
- `.map(selector)` - преобразовать значение.
- `.distinct()` - не пропускать повтор предыдущего значения.

### Отписка
- `RxDisposable` - `.dispose()`, `.is_disposed()`, `.add_to(bag)`, `.bind_to_node(node)`.
- `RxDisposableBag` - `.add(d)`, `.clear()`, `.dispose()`, `.size()`.

### `Rx` - короткие фабрики
- `Rx.prop(initial)`, `Rx.bag()`.
- `Rx.computed([a, b], func(av, bv): return av + bv)` - производное read-only значение от нескольких источников.

### Типизированные свойства

В GDScript нет дженериков, но для популярных типов есть строгие обёртки -
`ReactiveInt`, `ReactiveFloat`, `ReactiveBool`, `ReactiveString`, `ReactiveVector2`:
у них `.value` нужного типа, а операторы/сериализация/подписки работают как обычно.

```gdscript
var hp := ReactiveInt.new(100)     # hp.value : int
hp.value += 10                     # ок
hp.value = "oops"                  # ошибка ещё на компиляции
```

Для своих/редких типов - обычный `ReactiveProperty` (значение `Variant`). Главная цель,
обфускация, закрыта в любом случае: весь API на `Callable`/сигналах, без строковых имён.

---

## Кейсы использования

Один счётчик, много view. HUD и магазин читают монеты из одного источника, меняешь в любом месте - обновляются оба.

```gdscript
var coins := ReactiveInt.new(0)

# hud.gd
coins.subscribe(func(v): hud_label.text = str(v)).add_to(_bag)
# shop.gd
coins.subscribe(func(v): buy_button.disabled = v < price).add_to(_bag)

coins.value -= price   # купил, и HUD, и кнопка магазина обновились сами
```

HP: полоска, порог и смерть из одного значения. Три независимые системы подписаны на один `hp`.

```gdscript
var hp := ReactiveInt.new(100)

# полоска здоровья
hp.subscribe(func(v): health_bar.value = v).add_to(_bag)
# виньетка при низком HP: реагирует на вход в зону, без спама каждый кадр
hp.map(func(v): return v <= 25).distinct().subscribe(func(low): vignette.visible = low).add_to(_bag)
# смерть один раз при пересечении нуля
hp.filter(func(v): return v <= 0).distinct().subscribe(func(_v): die(), false).add_to(_bag)
```

Производное значение. "Хватает ли на покупку" пересчитывается само от монет и цены.

```gdscript
var coins := ReactiveInt.new(0)
var price := ReactiveInt.new(100)
var can_buy := Rx.computed([coins, price], func(c, p): return c >= p)
can_buy.subscribe(func(ok): buy_button.disabled = not ok).add_to(_bag)
```

Настройка, на которую завязано много систем. Переключатель звука: и микшер, и иконка реагируют.

```gdscript
var sound_on := ReactiveBool.new(true)
sound_on.subscribe(func(on): AudioServer.set_bus_mute(0, not on)).add_to(_bag)
sound_on.subscribe(func(on): sound_icon.texture = on_tex if on else off_tex).add_to(_bag)
```

Презентер не знает про источник. View подписан на read-only поле модели, а откуда данные (новая игра, загрузка сейва, чит-меню) - ему всё равно.

```gdscript
func bind(progress: PlayerProgress) -> void:
	progress.coins.to_read_only().subscribe(func(v): _render_coins(v)).add_to(_bag)
```

После `SaveSystem.load(...)` такие view обновятся сами: значения прилетят через те же подписки.

---

## Сохранение / загрузка

Наследуй модель от `ReactiveModel`, объяви поля и опиши `_schema()`:

```gdscript
class_name PlayerProgress
extends ReactiveModel

var coins := ReactiveProperty.new(0)
var hp := ReactiveProperty.new(100)
var level := ReactiveProperty.new(1)

func _schema() -> Dictionary:
	return { "coins": coins, "hp": hp, "level": level }   # ключи = имена в файле
```

Сохранение/загрузка - один вызов:

```gdscript
SaveSystem.save("user://progress.sav", progress)              # JSON
SaveSystem.load("user://progress.sav", progress)              # -> подписчики обновятся сами

SaveSystem.save("user://progress.sav", progress, "secret")    # + AES-шифрование (встроено в Godot)
SaveSystem.save("user://p.sav", progress, "", SaveSystem.Codec.GODOT_BINARY)   # компактный бинарь
```

### Версии и миграции

```gdscript
func _version() -> int:
	return 2

func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 2 and data.has("name"):
		data["player_name"] = data["name"]
		data.erase("name")
	return data
```

При `load`, если версия файла не равна текущей, перед применением вызывается `_migrate`.

### Кодеки

| Codec          | Чем хорош                                   | Нюанс                                            |
|----------------|---------------------------------------------|--------------------------------------------------|
| `JSON` (деф.)  | человекочитаемый, переносимый               | `int` читается как `float`* , нет `Vector2`/`Color` |
| `GODOT_TEXT`   | без потерь типов Godot, читаемый            | формат только Godot (`var_to_str`)               |
| `GODOT_BINARY` | компактный, быстрый, без потерь             | не человекочитаемый                              |

\* JSON-нюанс решается автоматически: `deserialize` приводит значение к текущему типу поля (`int/float/bool/String`). Для `Vector2`, `Color` и т.п. используй `GODOT_TEXT`/`GODOT_BINARY`.

### Вложенные модели

Поле в `_schema()` может быть другой `ReactiveModel` - сериализуется рекурсивно. Так удобно делать состояние по фичам: `inventory`, `settings`, `quests` - каждое своя модель, общий файл сейва.

---

## Тесты

Аддон везёт собственный мини-фреймворк (без зависимостей, в GUT-совместимом стиле) с **детектором утечек** - папка `test/`.

- В редакторе: открой и запусти сцену `test/test_main.tscn` - результат в консоли.
- Headless (для CI):
  ```bash
  godot --headless -s res://addons/abyss_moth/reactive/test/run_tests.gd
  # код возврата 0 - всё ок, 1 - есть падения
  ```

Свои тесты клади в `test/unit/test_*.gd`, наследуй `RxTest`:

```gdscript
extends RxTest

func test_coins_change() -> void:
	var coins := ReactiveInt.new(0)
	var got := [0]
	coins.subscribe(func(v): got[0] = v)
	coins.value = 50
	assert_eq(got[0], 50, "подписчик получил 50")

func test_no_leak() -> void:
	var p := ReactiveProperty.new(0)
	var sub := p.subscribe(func(_v): pass)
	assert_connections(p.changed, 1)   # подписка активна
	sub.dispose()
	assert_connections(p.changed, 0)   # отписались - коннект снят, утечки нет
```

Ассерты: `assert_eq/ne/true/false/null/not_null/almost_eq/type`, плюс для утечек
`assert_connections(signal, n)` и `assert_freed(weakref)`. Текущий статус - **4 сьюта, 67 проверок, зелёные.**

## Обфускация-safe

Нет ни одного вызова метода/сигнала по строковому имени - только ссылки на методы (`signal.connect(callable)`, bare-идентификаторы) и `Callable`. После переименования идентификаторов обфускатором ничего не отвалится. Единственные строки - это **ключи сейва** в `_schema()`; они и должны быть стабильными (это формат файла, а не логика).

---

## Лицензия

MIT (c) 2026 RimuruDev (Abyss Moth). См. [LICENSE](LICENSE).
