extends SceneTree
## The script file data/dialogue_ch1.md and scripts/main.gd agree: every ID main.gd asks for exists,
## no ID is written twice, and IDs nobody uses are listed (warning only).

const DialogueScript = preload("res://scripts/dialogue_script.gd")
const ID_IN_CODE := "\"((?:s0[1-8]|hall|common|legacy|sign|goal|hint)\\.[a-z0-9_]+(?:\\.[a-z0-9_]+)*)\""

func _initialize() -> void:
	var failures: Array[String] = []
	var md := FileAccess.get_file_as_string("res://data/dialogue_ch1.md")
	var lines := DialogueScript.parse(md)
	if lines.size() < 400:
		failures.append("only %d lines parsed" % lines.size())

	# No ID twice.
	var seen := {}
	for raw in md.split("\n"):
		if raw.begins_with("#### "):
			var id := raw.substr(5).strip_edges()
			if seen.has(id):
				failures.append("duplicate ID " + id)
			seen[id] = true

	# Every ID in main.gd is in the script.
	var code := FileAccess.get_file_as_string("res://scripts/main.gd")
	var re := RegEx.new()
	re.compile(ID_IN_CODE)
	var used := {}
	for m in re.search_all(code):
		var id := m.get_string(1)
		used[id] = true
		if not lines.has(id):
			failures.append("main.gd uses %s, but dialogue_ch1.md has no such line" % id)
		elif String(lines[id]).strip_edges() == "":
			failures.append(id + " is empty")
	for id in lines:
		if not used.has(id):
			print("warning: %s is in dialogue_ch1.md but main.gd never uses it" % id)

	# A few known lines, to be sure the parser keeps line breaks and placeholders.
	if lines.get("common.put_away", "") == "":
		failures.append("common.put_away missing")
	if not String(lines.get("s04.smear.open", "")).contains("{n}"):
		failures.append("s04.smear.open lost its {n}")
	if String(lines.get("s01.door.first_new", "")).count("\n") < 1:
		failures.append("s01.door.first_new lost its line break")

	if failures.is_empty():
		print("TEST PASS: dialogue script (%d lines, %d IDs used by main.gd)" % [lines.size(), used.size()])
		quit(0)
	else:
		for f in failures:
			print("TEST FAIL: " + f)
		quit(1)
