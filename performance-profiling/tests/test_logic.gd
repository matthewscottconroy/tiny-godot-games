extends Node

# Drives the real FrameBudget from scripts/frame_budget.gd.

var _pass := 0
var _fail := 0

func _ready() -> void:
	test_budget_from_target_fps()
	test_section_timing_accumulates()
	test_unopened_section_end_is_harmless()
	test_frames_roll_into_history()
	test_window_is_bounded()
	test_averages_across_frames()
	test_worst_first_ordering()
	test_shares_sum_to_one()
	test_over_budget()
	test_reset()
	_report()

func expect(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", label)
	else:
		_fail += 1
		print("  FAIL  ", label)

func _report() -> void:
	var summary := "[performance-profiling] %d/%d passed" % [_pass, _pass + _fail]
	print(summary)
	if _fail > 0:
		push_error(summary)

# Burn a measurable amount of wall-clock time. Timing tests have to work with
# real elapsed time, so assertions below compare sections against each other
# rather than against absolute millisecond values.
func _burn(microseconds: int) -> void:
	var start := Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < microseconds:
		pass

func test_budget_from_target_fps() -> void:
	print("budget derives from the target frame rate")
	expect(is_equal_approx(FrameBudget.new(60.0).budget_ms, 1000.0 / 60.0), "60 fps is 16.67ms")
	expect(is_equal_approx(FrameBudget.new(30.0).budget_ms, 1000.0 / 30.0), "30 fps is 33.3ms")

func test_section_timing_accumulates() -> void:
	print("a section measured twice in one frame is summed")
	var b := FrameBudget.new()
	b.begin("work"); _burn(2000); b.end("work")
	b.begin("work"); _burn(2000); b.end("work")
	b.end_frame()
	var avg := b.averages()
	expect(avg.has("work"), "the section is reported")
	# Two 2ms burns should read as clearly more than one.
	expect(float(avg["work"]) > 2.0, "both measurements are included, not just the last")

func test_unopened_section_end_is_harmless() -> void:
	print("ending a section that was never begun")
	var b := FrameBudget.new()
	b.end("never_started")
	b.end_frame()
	expect(not b.averages().has("never_started"), "it contributes nothing rather than erroring")

func test_frames_roll_into_history() -> void:
	print("frames accumulate")
	var b := FrameBudget.new()
	for i in 5:
		b.begin("a"); _burn(200); b.end("a")
		b.end_frame()
	expect(b.samples() == 5, "one history entry per frame")

func test_window_is_bounded() -> void:
	print("the rolling window is bounded")
	var b := FrameBudget.new(60.0, 10)
	for i in 40:
		b.begin("a"); _burn(100); b.end("a")
		b.end_frame()
	expect(b.samples() == 10, "history never grows past the window")

func test_averages_across_frames() -> void:
	print("averaging smooths a single spike")
	var b := FrameBudget.new(60.0, 10)
	# One expensive frame among nine cheap ones.
	b.begin("spiky"); _burn(8000); b.end("spiky")
	b.end_frame()
	for i in 9:
		b.begin("spiky"); _burn(100); b.end("spiky")
		b.end_frame()
	var avg := float(b.averages()["spiky"])
	expect(avg < 8.0, "the average is well below the spike — that is the point of a window")
	expect(avg > 0.1, "but the spike still moves it")

func test_worst_first_ordering() -> void:
	print("sections are ranked by cost")
	var b := FrameBudget.new()
	b.begin("cheap"); _burn(200); b.end("cheap")
	b.begin("expensive"); _burn(6000); b.end("expensive")
	b.begin("middling"); _burn(2000); b.end("middling")
	b.end_frame()
	var rows := b.worst_first()
	expect(rows.size() == 3, "every section is listed")
	expect(rows[0]["section"] == "expensive", "the most expensive section is first")
	expect(rows[2]["section"] == "cheap", "the cheapest is last")

func test_shares_sum_to_one() -> void:
	print("shares are fractions of the measured total")
	var b := FrameBudget.new()
	b.begin("a"); _burn(2000); b.end("a")
	b.begin("b"); _burn(4000); b.end("b")
	b.end_frame()
	var total := 0.0
	for row in b.worst_first():
		total += float(row["share"])
	expect(is_equal_approx(total, 1.0), "the shares add up to 100%%")

func test_over_budget() -> void:
	print("over-budget detection")
	var tight := FrameBudget.new(1000.0)     # a 1ms budget
	tight.begin("work"); _burn(5000); tight.end("work")
	tight.end_frame()
	expect(tight.over_budget(), "5ms of work blows a 1ms budget")
	expect(tight.budget_used() > 1.0, "budget_used goes above 1.0 rather than clamping")

	var loose := FrameBudget.new(1.0)        # a 1000ms budget
	loose.begin("work"); _burn(1000); loose.end("work")
	loose.end_frame()
	expect(not loose.over_budget(), "the same work is fine against a large budget")

func test_reset() -> void:
	print("reset")
	var b := FrameBudget.new()
	b.begin("a"); _burn(500); b.end("a")
	b.end_frame()
	b.reset()
	expect(b.samples() == 0, "history is cleared")
	expect(b.averages().is_empty(), "sections are forgotten")
	expect(is_zero_approx(b.total_ms()), "the total goes back to zero")
