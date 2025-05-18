extends Node
class_name BeatEventSystem

# Beat Event System
# Manages beat-synchronized events for the game
# Allows objects to register for beat-based callbacks

signal event_triggered(event_name: String, beat_number: int, data: Dictionary)
signal event_registered(event_name: String)
signal event_unregistered(event_name: String)
signal quantization_changed(quantization: Quantization)

# Quantization levels for event timing
enum Quantization {
	BEAT,        # Every beat
	HALF_BEAT,   # Every half beat  
	QUARTER_BEAT,# Every quarter beat
	MEASURE,     # Every measure
	TWO_MEASURES,# Every 2 measures
	FOUR_MEASURES# Every 4 measures
}

# Event data structure
class BeatEvent:
	var name: String
	var callback: Callable
	var quantization: Quantization
	var delay: float = 0.0  # Delay in beats
	var repeat_count: int = -1  # -1 = infinite
	var current_count: int = 0
	var metadata: Dictionary = {}
	var enabled: bool = true
	var last_triggered_beat: int = -1

# Registered events
var _events: Dictionary = {}  # Dictionary[String, BeatEvent]
var _quantization_intervals: Dictionary = {
	Quantization.BEAT: 1.0,
	Quantization.HALF_BEAT: 0.5,
	Quantization.QUARTER_BEAT: 0.25,
	Quantization.MEASURE: 4.0,  # Assumes 4/4 time
	Quantization.TWO_MEASURES: 8.0,
	Quantization.FOUR_MEASURES: 16.0
}

# Event queue for delayed events
var _event_queue: Array[Dictionary] = []

# References
var _beat_manager: Node = null
var _current_quantization: Quantization = Quantization.BEAT

# Debug
var _debug_logging: bool = true
var _total_events_triggered: int = 0

func _ready():
	_log("=== BeatEventSystem Initialization ===")
	
	# Get reference to BeatManager
	_beat_manager = get_node("/root/BeatManager") if has_node("/root/BeatManager") else null
	
	if not _beat_manager:
		push_error("BeatManager not found! BeatEventSystem requires BeatManager to function.")
		return
	
	_connect_signals()
	
	_log("BeatEventSystem initialized")
	_log("===================================")

func _log(message: String) -> void:
	if _debug_logging:
		var timestamp = Time.get_time_string_from_system()
		print("[%s] BeatEventSystem: %s" % [timestamp, message])

func _connect_signals():
	if _beat_manager:
		_beat_manager.connect("beat_occurred", _on_beat_occurred)
		_beat_manager.connect("half_beat_occurred", _on_half_beat_occurred)
		_beat_manager.connect("measure_completed", _on_measure_completed)
		_log("Connected to BeatManager signals")

# Event registration
func register_event(
	name: String, 
	callback: Callable, 
	quantization: Quantization = Quantization.BEAT,
	delay: float = 0.0,
	repeat_count: int = -1,
	metadata: Dictionary = {}
) -> bool:
	
	if _events.has(name):
		push_warning("Event '%s' already registered. Updating." % name)
	
	var event = BeatEvent.new()
	event.name = name
	event.callback = callback
	event.quantization = quantization
	event.delay = delay
	event.repeat_count = repeat_count
	event.metadata = metadata
	event.enabled = true
	
	_events[name] = event
	
	emit_signal("event_registered", name)
	_log("Registered event: %s (quantization: %s, delay: %.2f beats)" % 
		[name, _get_quantization_name(quantization), delay])
	
	return true

func unregister_event(name: String) -> bool:
	if not _events.has(name):
		push_warning("Event '%s' not found" % name)
		return false
	
	_events.erase(name)
	emit_signal("event_unregistered", name)
	_log("Unregistered event: %s" % name)
	
	return true

func set_event_enabled(name: String, enabled: bool) -> bool:
	if not _events.has(name):
		push_warning("Event '%s' not found" % name)
		return false
	
	_events[name].enabled = enabled
	_log("Event '%s' %s" % [name, "enabled" if enabled else "disabled"])
	return true

func is_event_enabled(name: String) -> bool:
	if not _events.has(name):
		return false
	return _events[name].enabled

# Beat callbacks
func _on_beat_occurred(beat_number: int, beat_time: float):
	_process_events_for_quantization(Quantization.BEAT, beat_number, beat_time)
	_process_event_queue(beat_number)

func _on_half_beat_occurred(half_beat_number: int, beat_time: float):
	_process_events_for_quantization(Quantization.HALF_BEAT, half_beat_number, beat_time)
	
	# Also process quarter beats on even half beats
	if half_beat_number % 2 == 0:
		_process_events_for_quantization(Quantization.QUARTER_BEAT, half_beat_number / 2, beat_time)

func _on_measure_completed(measure_number: int, measure_time: float):
	var beat_number = measure_number * _beat_manager.beats_per_measure
	
	_process_events_for_quantization(Quantization.MEASURE, beat_number, measure_time)
	
	# Process multi-measure quantizations
	if measure_number % 2 == 0:
		_process_events_for_quantization(Quantization.TWO_MEASURES, beat_number, measure_time)
	
	if measure_number % 4 == 0:
		_process_events_for_quantization(Quantization.FOUR_MEASURES, beat_number, measure_time)

func _process_events_for_quantization(quantization: Quantization, beat_number: int, beat_time: float):
	for event_name in _events:
		var event = _events[event_name]
		
		if not event.enabled:
			continue
			
		if event.quantization != quantization:
			continue
			
		# Check if this event should trigger based on its interval
		var interval = _quantization_intervals[quantization]
		if beat_number % interval != 0:
			continue
			
		# Avoid double-triggering
		if event.last_triggered_beat == beat_number:
			continue
			
		event.last_triggered_beat = beat_number
		
		# Handle delayed events
		if event.delay > 0:
			_queue_delayed_event(event, beat_number, beat_time)
		else:
			_trigger_event(event, beat_number, beat_time)

func _queue_delayed_event(event: BeatEvent, beat_number: int, beat_time: float):
	var trigger_beat = beat_number + event.delay
	
	_event_queue.append({
		"event": event,
		"trigger_beat": trigger_beat,
		"beat_time": beat_time,
		"original_beat": beat_number
	})
	
	_log("Queued delayed event: %s (trigger at beat %d)" % [event.name, trigger_beat])

func _process_event_queue(current_beat: int):
	var events_to_remove = []
	
	for i in range(_event_queue.size()):
		var queued = _event_queue[i]
		
		if current_beat >= queued.trigger_beat:
			_trigger_event(queued.event, queued.original_beat, queued.beat_time)
			events_to_remove.append(i)
	
	# Remove triggered events from queue (in reverse order)
	for i in range(events_to_remove.size() - 1, -1, -1):
		_event_queue.remove_at(events_to_remove[i])

func _trigger_event(event: BeatEvent, beat_number: int, beat_time: float):
	# Check repeat count
	if event.repeat_count > 0:
		if event.current_count >= event.repeat_count:
			return
		event.current_count += 1
	
	# Prepare event data
	var data = {
		"beat_number": beat_number,
		"beat_time": beat_time,
		"quantization": event.quantization,
		"metadata": event.metadata
	}
	
	# Call the callback
	if event.callback.is_valid():
		event.callback.call(data)
	
	# Emit signal
	emit_signal("event_triggered", event.name, beat_number, data)
	
	_total_events_triggered += 1
	
	if _debug_logging and _total_events_triggered % 10 == 0:
		_log("Event triggered: %s (total: %d)" % [event.name, _total_events_triggered])

# Utility methods
func get_events_for_quantization(quantization: Quantization) -> Array[String]:
	var result = []
	
	for event_name in _events:
		var event = _events[event_name]
		if event.quantization == quantization:
			result.append(event_name)
	
	return result

func get_all_events() -> Array[String]:
	return _events.keys()

func clear_all_events():
	_events.clear()
	_event_queue.clear()
	_log("Cleared all events")

func set_quantization(quantization: Quantization):
	_current_quantization = quantization
	emit_signal("quantization_changed", quantization)
	_log("Default quantization set to: %s" % _get_quantization_name(quantization))

func get_quantization() -> Quantization:
	return _current_quantization

func _get_quantization_name(quantization: Quantization) -> String:
	match quantization:
		Quantization.BEAT: return "BEAT"
		Quantization.HALF_BEAT: return "HALF_BEAT"
		Quantization.QUARTER_BEAT: return "QUARTER_BEAT"
		Quantization.MEASURE: return "MEASURE"
		Quantization.TWO_MEASURES: return "TWO_MEASURES"
		Quantization.FOUR_MEASURES: return "FOUR_MEASURES"
		_: return "UNKNOWN"

# Convenience methods for common event patterns
func register_one_shot_event(name: String, callback: Callable, delay_beats: float = 0.0):
	register_event(name, callback, _current_quantization, delay_beats, 1)

func register_repeating_event(
	name: String, 
	callback: Callable, 
	quantization: Quantization,
	repeat_count: int = -1
):
	register_event(name, callback, quantization, 0.0, repeat_count)

func register_measure_event(name: String, callback: Callable, every_n_measures: int = 1):
	var quantization = Quantization.MEASURE
	
	if every_n_measures == 2:
		quantization = Quantization.TWO_MEASURES
	elif every_n_measures == 4:
		quantization = Quantization.FOUR_MEASURES
	
	register_event(name, callback, quantization)

# Debug methods
func print_debug_info():
	print("=== BeatEventSystem Debug Info ===")
	print("Total Events: %d" % _events.size())
	print("Active Events: %d" % _count_active_events())
	print("Queued Events: %d" % _event_queue.size())
	print("Total Triggered: %d" % _total_events_triggered)
	print("Current Quantization: %s" % _get_quantization_name(_current_quantization))
	print()
	print("Registered Events:")
	for event_name in _events:
		var event = _events[event_name]
		print("  %s: %s, enabled: %s, count: %d/%d" % [
			event_name,
			_get_quantization_name(event.quantization),
			str(event.enabled),
			event.current_count,
			event.repeat_count
		])
	print("================================")

func _count_active_events() -> int:
	var count = 0
	for event in _events.values():
		if event.enabled:
			count += 1
	return count