## Headless-прогон тестов для CI:
##   godot --headless -s res://addons/abyss_moth/reactive/test/run_tests.gd
## Код возврата: 0 - все ок, 1 - есть падения.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
extends SceneTree

func _initialize() -> void:
	var r := RxTestRunner.new().run_all()
	print("\n=== abyss_moth/reactive tests ===")
	for f in r["failures"]:
		print("  FAIL [%s :: %s] %s" % [f["file"], f["test"], f["msg"]])
	print("suites=%d  total=%d  passed=%d  failed=%d" % [r["suites"], r["total"], r["passed"], r["failed"]])
	print("RESULT: " + ("OK" if r["failed"] == 0 else "FAILED"))
	quit(0 if r["failed"] == 0 else 1)
