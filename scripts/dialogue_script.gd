extends RefCounted
## Reads data/dialogue_ch1.md: every "#### some.id" heading starts a line of text; the lines under it,
## up to the next heading, are the text ("\n" between them). Lines starting with ">" are notes for the
## writer and are skipped, as are blank lines at the start and end of each entry.

const ID_PATTERN := "^[a-z0-9_]+(\\.[a-z0-9_]+)+$"

## ID -> text. Duplicate IDs are reported with push_error (the later one wins).
static func load_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("cannot open dialogue script " + path)
		return {}
	return parse(f.get_as_text())

static func parse(source: String) -> Dictionary:
	var id_re := RegEx.new()
	id_re.compile(ID_PATTERN)
	var out := {}
	var id := ""
	var body: Array[String] = []
	for raw in source.split("\n"):
		var line := raw.trim_suffix("\r")
		if line.begins_with("#"):
			_flush(out, id, body)
			id = ""
			body = []
			var heading := line.lstrip("#").strip_edges()
			if id_re.search(heading):
				id = heading
			continue
		if id == "" or line.begins_with(">"):
			continue
		body.append(line)
	_flush(out, id, body)
	return out

static func _flush(out: Dictionary, id: String, body: Array[String]) -> void:
	if id == "":
		return
	while not body.is_empty() and body[0].strip_edges() == "":
		body.pop_front()
	while not body.is_empty() and body[-1].strip_edges() == "":
		body.pop_back()
	if out.has(id):
		push_error("dialogue script: duplicate ID " + id)
	out[id] = "\n".join(body)
