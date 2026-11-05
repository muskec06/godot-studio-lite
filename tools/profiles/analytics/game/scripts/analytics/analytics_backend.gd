class_name AnalyticsBackend
extends RefCounted
## Remote analytics interface. This base class sends nothing; it only keeps
## the last events in memory (tests read them). A real adapter (GameAnalytics,
## Firebase, …) extends this, overrides track() and flush(), and is installed
## with Analytics.use_backend(); see /metrics provider.

var events: Array[Dictionary] = []
var keep_last: int = 200


func track(event: Dictionary) -> void:
	events.append(event)
	if events.size() > keep_last:
		events.pop_front()


func flush() -> void:
	pass
