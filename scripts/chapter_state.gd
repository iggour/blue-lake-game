extends RefCounted

class_name ChapterState

## First-chapter state shell.
## This records authored progression without implementing any of the new puzzles.

enum Slice {
	S01_ENTER,
	S02_LOST,
	S03_MIRROR,
	S04_VISITOR,
	S05_WINDOW,
	S06_PLATFORM,
	S07_RETURN,
	S08_TRUE_EXIT,
}

const SLICE_ORDER: Array[int] = [
	Slice.S01_ENTER,
	Slice.S02_LOST,
	Slice.S03_MIRROR,
	Slice.S04_VISITOR,
	Slice.S05_WINDOW,
	Slice.S06_PLATFORM,
	Slice.S07_RETURN,
	Slice.S08_TRUE_EXIT,
]

const SLICE_DEFINITIONS: Dictionary = {
	Slice.S01_ENTER: {"id": "S01", "title": "进入", "theme": "进入 / 观看", "knowledge": "我要出去。"},
	Slice.S02_LOST: {"id": "S02", "title": "迷路", "theme": "空间 / 方向", "knowledge": "这里的空间有问题。"},
	Slice.S03_MIRROR: {"id": "S03", "title": "镜子", "theme": "视觉 ≠ 现实", "knowledge": "Blue Lake 看到的世界不同于我的世界。"},
	Slice.S04_VISITOR: {"id": "S04", "title": "参观者", "theme": "不同的视觉经验", "knowledge": "看见不是绝对客观的。"},
	Slice.S05_WINDOW: {"id": "S05", "title": "《窗》", "theme": "观看 → 改变", "knowledge": "Blue Lake 不只是让我看见，它能改变东西。"},
	Slice.S06_PLATFORM: {"id": "S06", "title": "中央展台", "theme": "看见 / 存在", "knowledge": "不可见不等于不存在。"},
	Slice.S07_RETURN: {"id": "S07", "title": "回访", "theme": "重新观看 / 第二次阅读", "knowledge": "同一个世界可以被重新解释。"},
	Slice.S08_TRUE_EXIT: {"id": "S08", "title": "真正出口", "theme": "理解规则 / 离开", "knowledge": "我已经理解了这里的规则。"},
}

var current_slice: int = Slice.S01_ENTER
var map_state: StringName = &"gallery_initial"
var player_goal: StringName = &"none"
var completed_events: Dictionary = {}
var completed_slices: Dictionary = {}
var acquired_knowledge: Dictionary = {}
var blue_lake_state: StringName = &"uninitialized"
var triggered_story_events: Dictionary = {}
var unlocked_slices: Dictionary = {Slice.S01_ENTER: true}

func current_definition() -> Dictionary:
	return SLICE_DEFINITIONS.get(current_slice, {})

func current_id() -> String:
	return str(current_definition().get("id", "S01"))

func mark_event(event_id: StringName) -> void:
	completed_events[event_id] = true

func has_event(event_id: StringName) -> bool:
	return completed_events.get(event_id, false)

func learn(knowledge_id: StringName) -> void:
	acquired_knowledge[knowledge_id] = true

func knows(knowledge_id: StringName) -> bool:
	return acquired_knowledge.get(knowledge_id, false)

func mark_story_event(event_id: StringName) -> void:
	triggered_story_events[event_id] = true

func has_story_event(event_id: StringName) -> bool:
	return triggered_story_events.get(event_id, false)

func set_blue_lake_state(value: StringName) -> void:
	blue_lake_state = value

func unlock_slice(slice_id: int) -> void:
	unlocked_slices[slice_id] = true

func is_slice_unlocked(slice_id: int) -> bool:
	return unlocked_slices.get(slice_id, false)

func advance_to(slice_id: int) -> bool:
	if not is_slice_unlocked(slice_id):
		return false
	current_slice = slice_id
	return true

func set_map_state(value: StringName) -> void:
	map_state = value

func set_player_goal(value: StringName) -> void:
	player_goal = value

func complete_slice(slice_id: int) -> void:
	completed_slices[slice_id] = true
	var index := SLICE_ORDER.find(slice_id)
	if index >= 0 and index + 1 < SLICE_ORDER.size():
		unlock_slice(SLICE_ORDER[index + 1])

func is_slice_completed(slice_id: int) -> bool:
	return completed_slices.get(slice_id, false)
