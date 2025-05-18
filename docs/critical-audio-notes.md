# Critical Audio Implementation Notes

## IMPORTANT - Read First

These critical notes apply across all audio implementation in the Beat Racer project. They have been verified in `test_comprehensive_audio.gd` and must be followed to avoid common implementation errors.

### Key Verified Facts

1. **AudioEffectDelay Properties** ✓
   - AudioEffectDelay does NOT have a 'mix' property
   - Use 'dry' property instead
   - Verified in test_audio_effect_properties.gd

2. **Slider Configuration Requirements** ✓
   - Sliders MUST have step = 0.01 for smooth operation
   - Without step property, sliders show binary behavior (only 0 or 1)
   - Configure programmatically as failsafe
   - Verified in test_ui_configuration.gd

3. **Verification Before Implementation**
   - Always run test_comprehensive_audio.gd before implementing audio effects
   - Use Context7 to verify property names
   - Use verification_helpers.gd to check properties exist

### Quick Reference Checklist

Before implementing any audio system:
- [ ] Run `./run_gut_tests.sh` to verify assumptions
- [ ] Check property names with Context7 documentation
- [ ] Verify sliders have step = 0.01
- [ ] Test with small implementations before full systems
- [ ] Add comprehensive logging for debugging

### Using Context7 for Godot Documentation

To look up specific Godot class documentation:

1. First, get the Godot library ID:
   ```
   mcp__context7-mcp__resolve-library-id:
     libraryName: "godot"
   ```

2. Then, get documentation for the specific class:
   ```
   mcp__context7-mcp__get-library-docs:
     context7CompatibleLibraryID: <returned_id_from_step_1>
     topic: "AudioEffectDelay"  # Replace with your class name
   ```

This is essential for verifying property names and methods before using them!

### Common Mistakes to Avoid

1. Using 'mix' property on AudioEffectDelay (doesn't exist)
2. Missing step property on sliders
3. Assuming property names without verification
4. Incorrect async handling in audio streams
5. Missing null checks for stream playback

For detailed implementation guidelines, see:
- [Audio Implementation](audio-implementation.md)
- [Audio Effect Guidelines](audio-effect-guidelines.md)
- [Testing and Debugging](testing-debugging.md)