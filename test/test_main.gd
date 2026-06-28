## Прогон тестов в редакторе / через MCP (project_run mode="custom").
## Печатает результат в консоль игры и выходит.
##
## (c) 2026 Abyss Moth / RimuruDev. MIT.
extends Node

func _ready() -> void:
	var r := RxTestRunner.new().run_all()
	print("RX_TESTS_BEGIN")
	for f in r["failures"]:
		print("  FAIL [%s :: %s] %s" % [f["file"], f["test"], f["msg"]])
		push_error("RX_TEST FAIL [%s::%s] %s" % [f["file"], f["test"], f["msg"]])
	print("RX_TESTS suites=%d total=%d passed=%d failed=%d" % [r["suites"], r["total"], r["passed"], r["failed"]])
	print("RX_TESTS_RESULT " + ("OK" if r["failed"] == 0 else "FAILED"))
	await get_tree().create_timer(2.0).timeout
	get_tree().quit(0 if r["failed"] == 0 else 1)
