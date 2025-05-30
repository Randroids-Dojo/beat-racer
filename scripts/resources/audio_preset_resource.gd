extends Resource
class_name AudioPresetResource

@export var preset_name: String = "Untitled Preset"
@export var creation_date: String = ""
@export var bus_settings: Dictionary = {}

# Structure of bus_settings:
# {
#   "BusName": {
#     "volume_db": float,
#     "muted": bool,
#     "soloed": bool,
#     "effects": [
#       {
#         "enabled": bool,
#         "parameters": {
#           "param_name": value
#         }
#       }
#     ]
#   }
# }

func save_from_audio_manager():
	creation_date = Time.get_datetime_string_from_system()
	bus_settings.clear()
	
	var buses = ["Master", "Melody", "Bass", "Percussion", "SFX"]
	
	for bus_name in buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			continue
		
		var bus_data = {
			"volume_db": AudioServer.get_bus_volume_db(bus_idx),
			"muted": AudioServer.is_bus_mute(bus_idx),
			"soloed": AudioServer.is_bus_solo(bus_idx),
			"effects": []
		}
		
		# Save effect settings
		for effect_idx in range(AudioServer.get_bus_effect_count(bus_idx)):
			var effect = AudioServer.get_bus_effect(bus_idx, effect_idx)
			if not effect:
				continue
			
			var effect_data = {
				"enabled": AudioServer.is_bus_effect_enabled(bus_idx, effect_idx),
				"class_name": effect.get_class(),
				"parameters": {}
			}
			
			# Save effect parameters based on type
			_save_effect_parameters(effect, effect_data["parameters"])
			
			bus_data["effects"].append(effect_data)
		
		bus_settings[bus_name] = bus_data

func _save_effect_parameters(effect: AudioEffect, params: Dictionary):
	var effect_class = effect.get_class()
	
	if effect is AudioEffectReverb:
		params["room_size"] = effect.room_size
		params["damping"] = effect.damping
		params["wet"] = effect.wet
		params["dry"] = effect.dry
		params["spread"] = effect.spread
		params["hipass"] = effect.hipass
		params["predelay_msec"] = effect.predelay_msec
		params["predelay_feedback"] = effect.predelay_feedback
	
	elif effect is AudioEffectDelay:
		params["dry"] = effect.dry
		params["tap1_active"] = effect.tap1_active
		params["tap1_delay_ms"] = effect.tap1_delay_ms
		params["tap1_level_db"] = effect.tap1_level_db
		params["tap1_pan"] = effect.tap1_pan
		params["tap2_active"] = effect.tap2_active
		params["tap2_delay_ms"] = effect.tap2_delay_ms
		params["tap2_level_db"] = effect.tap2_level_db
		params["tap2_pan"] = effect.tap2_pan
		params["feedback_active"] = effect.feedback_active
		params["feedback_delay_ms"] = effect.feedback_delay_ms
		params["feedback_level_db"] = effect.feedback_level_db
		params["feedback_lowpass"] = effect.feedback_lowpass
	
	elif effect is AudioEffectCompressor:
		params["threshold"] = effect.threshold
		params["ratio"] = effect.ratio
		params["gain"] = effect.gain
		params["attack_us"] = effect.attack_us
		params["release_ms"] = effect.release_ms
		params["mix"] = effect.mix
		params["sidechain"] = effect.sidechain
	
	elif effect is AudioEffectChorus:
		params["dry"] = effect.dry
		params["wet"] = effect.wet
		params["voice_count"] = effect.voice_count
		# Store voice parameters
		for i in range(1, 5):  # Chorus supports up to 4 voices
			var prefix = "voice/%d/" % i
			params[prefix + "delay_ms"] = effect.get(prefix + "delay_ms")
			params[prefix + "rate_hz"] = effect.get(prefix + "rate_hz")
			params[prefix + "depth_ms"] = effect.get(prefix + "depth_ms")
			params[prefix + "level_db"] = effect.get(prefix + "level_db")
			params[prefix + "cutoff_hz"] = effect.get(prefix + "cutoff_hz")
			params[prefix + "pan"] = effect.get(prefix + "pan")
	
	elif effect is AudioEffectEQ:
		# Save band gains
		for i in range(effect.get_band_count()):
			params["band_%d_gain_db" % i] = effect.get_band_gain_db(i)
	
	elif effect is AudioEffectDistortion:
		params["mode"] = effect.mode
		params["pre_gain"] = effect.pre_gain
		params["keep_hf_hz"] = effect.keep_hf_hz
		params["drive"] = effect.drive
		params["post_gain"] = effect.post_gain
	
	elif effect is AudioEffectLimiter:
		params["ceiling_db"] = effect.ceiling_db
		params["threshold_db"] = effect.threshold_db
		params["soft_clip_db"] = effect.soft_clip_db
		params["soft_clip_ratio"] = effect.soft_clip_ratio
	
	elif effect is AudioEffectFilter:
		params["cutoff_hz"] = effect.cutoff_hz
		params["resonance"] = effect.resonance
		params["gain"] = effect.gain
		params["db"] = effect.db

func apply_to_audio_manager():
	for bus_name in bus_settings:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			continue
		
		var bus_data = bus_settings[bus_name]
		
		# Apply volume, mute, solo
		AudioServer.set_bus_volume_db(bus_idx, bus_data.get("volume_db", 0.0))
		AudioServer.set_bus_mute(bus_idx, bus_data.get("muted", false))
		AudioServer.set_bus_solo(bus_idx, bus_data.get("soloed", false))
		
		# Apply effect settings
		if "effects" in bus_data:
			for effect_idx in range(min(bus_data["effects"].size(), AudioServer.get_bus_effect_count(bus_idx))):
				var effect_data = bus_data["effects"][effect_idx]
				var effect = AudioServer.get_bus_effect(bus_idx, effect_idx)
				
				if not effect:
					continue
				
				# Enable/disable effect
				AudioServer.set_bus_effect_enabled(bus_idx, effect_idx, effect_data.get("enabled", true))
				
				# Apply parameters if classes match
				if effect.get_class() == effect_data.get("class_name", ""):
					_apply_effect_parameters(effect, effect_data.get("parameters", {}))

func _apply_effect_parameters(effect: AudioEffect, params: Dictionary):
	for param_name in params:
		var value = params[param_name]
		
		# Handle special cases
		if effect is AudioEffectEQ and param_name.begins_with("band_"):
			var band_idx = int(param_name.split("_")[1])
			effect.set_band_gain_db(band_idx, value)
		elif param_name in effect:
			effect.set(param_name, value)