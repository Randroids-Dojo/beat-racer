# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Generating 2D Sprites

Use the generate_2d_sprite MCP command to create 2D sprites for the game. This command uses the Hunyuan3D-2mini-Turbo model to generate images.

### Usage

```
generate_2d_sprite("your_prompt_here")
```

The command will:
1. Enhance your prompt (e.g., "fire" becomes "Generate a 2D sprite: fire, high detailed, complete object, not cut off, white solid background")
2. Generate an image using the mubarak-alketbi/Hunyuan3D-2mini-Turbo model
3. Save the result to a file like: `/Users/randroid/Dev/AI/MCPs/game-asset-mcp/assets/2d_asset_generate_2d_asset_[timestamp]_[id].jpg`

### Examples

- `generate_2d_sprite("fire")` - Creates a fire sprite
- `generate_2d_sprite("race car")` - Creates a race car sprite
- `generate_2d_sprite("power up")` - Creates a power-up sprite

### Tips

- Keep prompts simple and descriptive
- The model will automatically add details for quality and formatting
- Generated sprites have white backgrounds for easy integration
- Consider the game's visual theme when creating prompts (see Visual Design Guide below)

## Looking Up Godot Documentation

Use the context7 MCP to look up relevant Godot documentation by retrieving documentation directly for specific topics:

```
mcp__context7-mcp__get-library-docs({
  "context7CompatibleLibraryID": "godotengine/godot-docs",
  "topic": "physics",
  "tokens": 8000
})
```

Note: The library ID for Godot documentation is always `"godotengine/godot-docs"`. You don't need to resolve it first.

### Example Topics

- "physics" - Physics bodies, forces, and collision
- "mobile" - Mobile rendering and optimization
- "signals" - Godot's signal system
- "Area2D" - For implementing track boundaries
- "PathFollow2D" - For vehicle track following
- "CharacterBody2D" - For vehicle movement
- "RigidBody2D" - For physics-based vehicles
- "GDScript" - Scripting language reference
- "TileMap" - For track construction
- "AudioStreamPlayer2D" - For spatial audio

### Tips for Effective Documentation Lookup

- Be specific with your topic when using get-library-docs
- Increase token count if you need more comprehensive documentation (default: 5000, max: 8000 recommended)
- Try different search terms if you don't find what you need initially
- Use both general topics (e.g., "physics") and specific class names (e.g., "RigidBody2D")
- For direct URL access: Use the format `https://context7.com/godotengine/godot-docs/topic.txt`

### Working Example

To get physics documentation for implementing vehicle movement:

```
mcp__context7-mcp__get-library-docs({
  "context7CompatibleLibraryID": "godotengine/godot-docs",
  "topic": "CharacterBody2D",
  "tokens": 6000
})
```

## Project Overview

Beat Racer is an innovative music creation game where players drive vehicles around a top-down track to create musical loops. By navigating between different lanes, drivers generate beats and musical patterns that automatically repeat after completing a lap.

## Development Commands

### Running the Project
```bash
# Open the project in Godot editor
godot project.godot

# Run the project directly from command line
godot --path . --playtest
```

### Building the Project
```bash
# Export templates need to be installed first
# Export for various platforms:
godot --export "Platform Name" output_file
```

### Testing the Project
```bash
# No test framework configured yet
# Manual testing scenarios defined in each story
```

## Project Structure

- **project.godot**: Main Godot project configuration file
- **icon.svg**: Project icon
- **.godot/**: Auto-generated Godot cache and metadata (should not be manually edited)

## Architecture

The project is configured for mobile rendering with Godot 4.4 features:
- Mobile rendering method for optimization
- Three-lane system where left/right lanes produce sounds, center lane is silent
- 16/32 time segments per loop for musical timing
- Multiple vehicle types representing different instruments
- Automated loop playback after lap completion

## Key Development Notes

- Mobile-focused project with touch controls and optimization
- Core gameplay loop: Drive → Create Beat Pattern → Auto-Loop → Layer
- Development follows Agile methodology with epics and user stories
- Stories are numbered consecutively (001, 002, etc.) for easy reference
- See `backlog.md` for development roadmap and `stories/` for detailed requirements

## Project Files

- `beat-racer-gdd.md`: Complete game design document
- `backlog.md`: Development epics prioritized for implementation
- `stories/`: User stories with acceptance criteria and test scenarios

## Visual Design Guide Summary

### Color Palette
**Primary Colors:**
- Beat Blue: #1A1A2E (dark blue background, UI elements)
- Pulse Purple: #7A4EBC (accent color, interactive elements)
- Race Red: #E94560 (highlight color, active elements)

**Secondary Colors:**
- Sound Yellow: #FFD460 (right lane indicators)
- Beat Teal: #4ECDC4 (left lane indicators)
- Neutral Gray: #777777 (center lane and UI backgrounds)

### Typography
- Primary Font: Montserrat (Bold for headings, Regular for body)
- Secondary Font: Roboto Mono (for numerical displays, timers)

### Vehicle Types and Colors
- **Sedan (Bass)**: Blue color scheme with sound wave details
- **Sports Car (Melody)**: Red color scheme with musical note accents
- **Van (Percussion)**: Orange/yellow color scheme with drum patterns
- **Motorcycle (Synth)**: Purple color scheme with waveform details
- **Truck (Atmospheric)**: Green color scheme with ambient patterns

### Track Themes
- **Neon Circuit**: Dark with glowing neon, cyber-inspired
- **Studio Space**: Clean white/gray, minimalist professional
- **Beat Street**: Urban graffiti-inspired with concrete textures
- **Synth Space**: Abstract cosmic with sci-fi treatment

### Asset Specifications
- Base resolution: 1920x1080 for desktop
- Provide 2x resolution for high-DPI displays
- Texture maps: Power of 2 dimensions (1024x1024, 2048x2048)
- UI elements should be vector-based when possible

For complete visual guidelines, see `beat-racer-visual-guide.md`

## Common Godot Patterns

When developing:
- Create scenes in a `scenes/` directory
- Place scripts in a `scripts/` directory or alongside their scenes
- Store assets (images, audio, etc.) in organized subdirectories
- Use Godot's signal system for decoupled communication
- Follow GDScript naming conventions (snake_case for variables/functions, PascalCase for classes)