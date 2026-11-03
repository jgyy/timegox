class_name Fmt
extends RefCounted

static func clock(sec: float) -> String:
	var s := int(sec)
	return "%d:%02d:%02d" % [int(s / 3600), int((s % 3600) / 60), s % 60]
