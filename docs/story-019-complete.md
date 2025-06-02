# Story 019: Audio Export - Complete

## Overview
Story 019 implements a comprehensive audio export system that allows players to export their Beat Racer compositions as audio files. The system captures real-time audio output during playback and saves it as WAV files with optional metadata.

## Implementation Summary

### Core Components

1. **GameAudioRecorder** (`scripts/systems/game_audio_recorder.gd`)
   - Base class for audio recording functionality
   - Manages AudioEffectRecord on dedicated Record bus
   - Handles WAV file saving and recording state
   - Configurable max duration and auto-save options

2. **CompositionRecorder** (`scripts/systems/composition_recorder.gd`)
   - Extends GameAudioRecorder with metadata tracking
   - Captures beat events, lane changes, and audio settings
   - Generates composition metadata including BPM, duration, and layers
   - Supports export with custom options

3. **ExportDialog** (`scripts/components/ui/export_dialog.gd`)
   - User interface for export options
   - Filename customization with auto-generated timestamps
   - Format selection (WAV supported, MP3/OGG placeholders)
   - Quality options and file size estimation
   - Metadata inclusion toggle

### Audio Bus Configuration

```gdscript
# Record bus setup for capturing all game audio
- Master Bus
  └── Record Bus (with AudioEffectRecord)
      ├── Melody Bus
      ├── Bass Bus  
      ├── Percussion Bus
      └── SFX Bus
```

### Export Workflow

1. **User initiates export** via Export button in UI
2. **System checks** for recorded layers
3. **Audio recording starts** with composition metadata
4. **Playback begins** automatically if not already playing
5. **Timer monitors** playback duration
6. **Recording stops** after one complete loop
7. **Export dialog** appears with options
8. **Files are saved** to user://recordings/

### Metadata Structure

```json
{
  "track_name": "My Composition",
  "start_time": "2025-01-06T10:30:00",
  "bpm": 120,
  "beats_per_measure": 4,
  "duration": 32.5,
  "audio_settings": {
    "Melody_volume": -6.0,
    "Bass_volume": -3.0,
    "Percussion_volume": 0.0,
    "SFX_volume": -12.0
  },
  "layer_info": [
    {"index": 0, "has_data": true, "sample_count": 245}
  ],
  "sound_bank_info": {
    "bank_name": "Electronic",
    "bank_index": 0
  },
  "beat_events": [
    {"beat": 0, "time": 0.0},
    {"beat": 1, "time": 0.5}
  ],
  "stats": {
    "total_beats": 65,
    "total_lane_changes": 42,
    "average_bpm": 120.0
  }
}
```

## Key Features

### 1. Real-time Audio Capture
- Uses Godot's AudioEffectRecord for native audio capture
- Records all game audio buses simultaneously
- Maintains audio quality and synchronization

### 2. Automatic Playback Integration
- Seamlessly switches to playback mode for export
- Calculates loop duration from recorded layers
- Stops recording after one complete cycle

### 3. Comprehensive Metadata
- Tracks all composition parameters
- Records beat timing and lane events
- Preserves audio bus settings and effects

### 4. User-friendly Export Options
- Custom filename with auto-generated timestamps
- Optional metadata export as JSON
- File size estimation before export
- Option to open export folder after completion

## Technical Details

### Recording Bus Setup
```gdscript
func _setup_recording_bus() -> void:
    # Create or find Record bus
    record_bus_idx = AudioServer.get_bus_index("Record")
    if record_bus_idx == -1:
        AudioServer.add_bus()
        record_bus_idx = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(record_bus_idx, "Record")
    
    # Route game buses to Record bus
    for bus_name in ["Melody", "Bass", "Percussion", "SFX"]:
        var bus_idx = AudioServer.get_bus_index(bus_name)
        if bus_idx != -1:
            AudioServer.set_bus_send(bus_idx, "Record")
    
    # Add AudioEffectRecord
    record_effect = AudioEffectRecord.new()
    AudioServer.add_bus_effect(record_bus_idx, record_effect)
```

### Export Process
```gdscript
func export_with_options(options: Dictionary) -> Dictionary:
    var filename = options.get("filename", "untitled")
    var include_metadata = options.get("include_metadata", true)
    
    # Save audio file
    var audio_path = save_recording(filename + ".wav")
    
    # Save metadata if requested
    if include_metadata:
        var metadata_path = save_directory + filename + "_metadata.json"
        var file = FileAccess.open(metadata_path, FileAccess.WRITE)
        file.store_string(JSON.stringify(composition_metadata, "\t"))
        file.close()
    
    return {
        "audio_path": audio_path,
        "metadata_path": metadata_path
    }
```

## Integration Points

1. **Main Game Scene** (`scenes/main_game_with_save.gd`)
   - Creates and manages CompositionRecorder instance
   - Handles export button clicks and workflow
   - Coordinates between playback and recording systems

2. **UI Panel** (`scripts/ui/main_game_ui_panel_with_save.gd`)
   - Export button with state management
   - Status updates during export process
   - Integration with save/load system

3. **Game State Manager**
   - Provides recorded layer data
   - Manages playback mode transitions
   - Ensures proper state for export

## Testing

### Unit Tests (`test_audio_export.gd`)
- Audio recorder setup and bus configuration
- Recording start/stop functionality
- File saving and duration tracking
- Metadata capture and validation
- Signal emission verification

### Integration Tests (`test_audio_export_integration.gd`)
- Complete export workflow simulation
- UI component interaction
- File generation verification
- Audio bus routing validation
- Export dialog functionality

## Future Enhancements

1. **Additional Export Formats**
   - MP3 export via external tool integration
   - OGG Vorbis support
   - FLAC for lossless compression

2. **Advanced Options**
   - Normalize audio levels
   - Trim silence from start/end
   - Export individual layers separately
   - Batch export multiple compositions

3. **Cloud Integration**
   - Direct upload to cloud services
   - Share via URL generation
   - Social media integration

## Usage Example

```gdscript
# User clicks Export button
func _on_export_pressed():
    # System starts recording
    composition_recorder.start_composition_recording("My Track", layers)
    
    # Playback begins automatically
    game_state_manager.change_mode(GameMode.PLAYBACK)
    
    # After playback completes, dialog appears
    export_dialog.setup("My Track", duration)
    export_dialog.popup_centered()
    
    # User confirms export
    # Files saved to user://recordings/my_track_20250106_1030.wav
```

## Conclusion

Story 019 successfully implements a complete audio export system that integrates seamlessly with Beat Racer's existing architecture. Players can now capture and share their musical creations as standard audio files, complete with metadata for future reference or reimporting.