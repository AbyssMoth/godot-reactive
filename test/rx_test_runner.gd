## Прогон всех test_*.gd из test/unit/. Используется и headless (run_tests.gd),
## и в редакторе (test_main.tscn). На каждый метод test_* - свежий экземпляр.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
class_name RxTestRunner
extends RefCounted

const TEST_DIR := "res://addons/abyss_moth/reactive/test/unit"

func run_all() -> Dictionary:
	var total := 0
	var passed := 0
	var suites := 0
	var failures: Array = []

	for path in _discover():
		var script: GDScript = load(path)
		if script == null:
			failures.append({"file": path.get_file(), "test": "(load)", "msg": "не удалось загрузить"})
			continue
		suites += 1
		var file: String = path.get_file()
		for method_name in _test_methods(script.new()):
			var t: Object = script.new()
			if t.has_method("before_each"):
				t.call("before_each")
			t.call(method_name)
			if t.has_method("after_each"):
				t.call("after_each")
			for r in t.call("get_results"):
				total += 1
				if r["passed"]:
					passed += 1
				else:
					failures.append({"file": file, "test": method_name, "msg": r["msg"]})

	return {
		"suites": suites,
		"total": total,
		"passed": passed,
		"failed": total - passed,
		"failures": failures,
	}

func _discover() -> Array:
	var out: Array = []
	var d := DirAccess.open(TEST_DIR)
	if d == null:
		push_error("RxTestRunner: нет папки " + TEST_DIR)
		return out
	for f in d.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append(TEST_DIR + "/" + f)
	out.sort()
	return out

func _test_methods(obj: Object) -> Array:
	var names: Array = []
	for m in obj.get_method_list():
		var n: String = m["name"]
		if n.begins_with("test_") and not names.has(n):
			names.append(n)
	names.sort()
	return names
