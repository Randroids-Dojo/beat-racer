# BEAT RACER
## Visual Design Guide

---

## 1. VISUAL IDENTITY

### 1.1 Brand Identity
![Brand Identity](https://via.placeholder.com/800x400)

#### Logo
- Primary logo features stylized "BEAT RACER" text with musical note and car silhouette integration
- Minimum clear space: Height of "B" in "BEAT" on all sides
- Always maintain aspect ratio when scaling
- Available in horizontal and stacked configurations

#### Color Palette
- **Primary Colors**
  - Beat Blue: #1A1A2E - Dark blue background, primary UI elements
  - Pulse Purple: #7A4EBC - Accent color, interactive elements
  - Race Red: #E94560 - Highlight color, active elements

- **Secondary Colors**
  - Sound Yellow: #FFD460 - For right lane indicators
  - Beat Teal: #4ECDC4 - For left lane indicators
  - Neutral Gray: #777777 - For center lane and UI backgrounds

- **UI Accent Colors**
  - White: #FFFFFF - Text and icons
  - Black: #000000 - Shadows and contrast elements
  - Success Green: #44C767 - Confirmation indicators
  - Alert Orange: #FF9F1C - Warning indicators

#### Typography
- **Primary Font: Montserrat**
  - Headings: Montserrat Bold
  - Subheadings: Montserrat SemiBold
  - Body: Montserrat Regular
  - UI Elements: Montserrat Medium

- **Secondary Font: Roboto Mono**
  - Used for numerical displays, timer, BPM counters
  - Technical information and code-like elements

#### Visual Motifs
- Sound wave patterns
- Circular track elements
- Musical notation integrated with racing imagery
- Light trails representing both sound waves and vehicle paths

---

## 2. USER INTERFACE DESIGN

### 2.1 Screen Layouts

#### Main Menu
![Main Menu Layout](https://via.placeholder.com/800x600)

- Centered logo with animated sound wave effect
- Main navigation buttons (Play, Gallery, Options, Tutorial)
- Background features abstract track shape with ambient animation
- Bottom bar for credits, version info, and additional links

#### Track Selection Screen
![Track Selection](https://via.placeholder.com/800x600)

- Grid or carousel of track thumbnails
- Track details panel showing:
  - Track name and description
  - Difficulty level (1-5 indicator)
  - Length/loop duration
  - Optimal BPM range
- Top bar for navigation and sorting options
- Bottom panel for BPM selection and starting options

#### In-Game HUD
![In-Game HUD](https://via.placeholder.com/800x600)

- **Top Section**
  - Beat timeline showing 16/32 segments of the loop
  - Current progress indicator
  - BPM display
  - Menu/pause button

- **Bottom Section**
  - Vehicle selector with horizontal scrolling
  - Quick mix controls (volume, mute)
  - Record/play transport controls

- **Side Elements**
  - Layer/track list showing active vehicles
  - Minimized mixer panel (expandable)

#### Mixer Panel
![Mixer Panel](https://via.placeholder.com/400x600)

- Individual channel strips for each vehicle/instrument
- Volume faders with visual level indicators
- Mute/solo buttons
- Basic effect controls (reverb, delay amount)
- Color coding corresponding to vehicle types

#### Settings Screen
![Settings Screen](https://via.placeholder.com/800x600)

- Audio settings (master volume, effects level)
- Visual settings (performance options, color blindness modes)
- Control settings (driving sensitivity, auto-quantize options)
- Account settings and cloud save options
- Credits and legal information

### 2.2 UI Components

#### Buttons
![Button States](https://via.placeholder.com/600x200)

- **Primary Buttons**
  - Rounded rectangle with 8px corner radius
  - Pulse Purple background with white text
  - Hover: 10% lighter, includes subtle glow effect
  - Pressed: 10% darker with inset shadow
  - Disabled: Desaturated with 50% opacity

- **Secondary Buttons**
  - Stroke only (2px) with Pulse Purple outline
  - White or Pulse Purple text
  - Hover: Background fill at 20% opacity
  - Pressed: Background fill at 40% opacity with inset shadow

- **Icon Buttons**
  - Circular with 40px diameter
  - Consistent icon style using 24px icons
  - Same state changes as primary buttons

#### Icons
![Icon Set](https://via.placeholder.com/800x400)

- Consistent line weight (2px)
- Rounded cap style
- 24px x 24px standard size
- Minimum padding: 8px on all sides
- Include icons for:
  - Transport controls (play, pause, stop, record)
  - Vehicle types (sedan, sports car, van, motorcycle, truck)
  - Audio controls (volume, mute, solo)
  - Navigation (home, back, settings, help)
  - File operations (save, load, export)

#### Progress Indicators
![Progress Indicators](https://via.placeholder.com/600x300)

- **Beat Timeline**
  - Horizontal bar divided into 16 or 32 segments
  - Current position indicator
  - Color coding showing active sound segments
  - 2px separator lines between beats

- **Loading Spinner**
  - Circular animation with musical note elements
  - Follows primary color scheme
  - Used during track loading or export operations

#### Notification System
![Notifications](https://via.placeholder.com/400x300)

- Toast notifications appear from bottom
- 3-second default display time
- Color-coded based on message type:
  - Success: Green
  - Information: Purple
  - Warning: Orange
  - Error: Red

### 2.3 Responsive Design

#### Mobile Layout Adaptation
![Mobile Layout](https://via.placeholder.com/400x800)

- Vertical orientation optimized for phones
- Touch-friendly button sizes (minimum 44px tap target)
- Simplified HUD with expandable panels
- Bottom navigation bar with essential controls

#### Tablet Layout Adaptation
![Tablet Layout](https://via.placeholder.com/800x600)

- Hybrid approach between mobile and desktop
- Side panels for mixer controls
- Larger track view area
- Split-screen options for simultaneous track and mixer view

#### Desktop Layout Adaptation
![Desktop Layout](https://via.placeholder.com/1200x800)

- Maximized track view area
- Detailed mixer panel
- Keyboard shortcut support with on-screen indicators
- Multi-window support for advanced users

---

## 3. GAME WORLD DESIGN

### 3.1 Track Design

#### Track Elements
![Track Elements](https://via.placeholder.com/800x400)

- **Lane System**
  - Center lane: Neutral gray with subtle texture
  - Left lane: Teal accents with sound wave patterns
  - Right lane: Yellow accents with alternative pattern
  - Lane width: 120px standard (scalable)
  - Lane dividers: White dashed lines (5px dash, 5px gap)

- **Beat Markers**
  - Vertical lines crossing all lanes
  - 16 or 32 per complete track loop
  - Subtle pulse animation synced to BPM
  - More prominent marking for measure beginnings (every 4 beats)

- **Special Track Sections**
  - Start/finish line with distinct visual treatment
  - Optional modifier zones (future feature)

#### Track Themes
![Track Themes](https://via.placeholder.com/800x400)

- **Neon Circuit**
  - Dark background with glowing neon lane elements
  - Cyber-inspired grid patterns
  - Electric blue and purple accent colors

- **Studio Space**
  - Clean white/gray background resembling a recording studio
  - Subtle sound wave patterns embedded in lanes
  - Professional, minimalist aesthetic

- **Beat Street**
  - Urban environment with graffiti-inspired elements
  - Concrete textures and street markings
  - Hip-hop influenced visual elements

- **Synth Space**
  - Abstract cosmic background
  - Ethereal particle effects
  - Sci-fi inspired visual treatments

### 3.2 Vehicle Design

#### Vehicle Types
![Vehicle Types](https://via.placeholder.com/800x400)

- **Sedan (Bass)**
  - Rounded, substantial form
  - Blue color scheme with sound wave details
  - Bass clef motif in design elements
  - Leaves subtle blue trail when in left lane
  - Leaves deeper blue trail when in right lane

- **Sports Car (Melody)**
  - Sleek, aerodynamic design
  - Red color scheme with musical note accents
  - Treble clef motif in design elements
  - Leaves bright red trail when in left lane
  - Leaves darker red trail when in right lane

- **Van (Percussion)**
  - Boxy, sturdy design
  - Orange/yellow color scheme with drum pattern details
  - Drum symbol motifs in design
  - Leaves staccato orange trail when in left lane
  - Leaves dotted yellow trail when in right lane

- **Motorcycle (Synth)**
  - Streamlined, futuristic design
  - Purple color scheme with waveform details
  - Synthesizer key/knob motifs
  - Leaves wavy purple trail when in left lane
  - Leaves pulsing violet trail when in right lane

- **Truck (Atmospheric)**
  - Large, imposing design
  - Green color scheme with ambient pattern details
  - Cloud and atmosphere motifs
  - Leaves misty green trail when in left lane
  - Leaves cloudy teal trail when in right lane

#### Vehicle Animation States

- **Idle State**
  - Subtle hover animation
  - Pulsing headlights synced to BPM
  - Small particle effects around wheels

- **Driving State**
  - Wheel rotation animation
  - Direction-based turning visuals
  - Speed-based squash and stretch effects
  - Lane-specific color effects

- **Sound Generation State**
  - Music visualizer effects emanating from vehicle
  - Intensity based on current sound output
  - Color-coded to match instrument type

### 3.3 Visual Effects

#### Sound Visualization
![Sound Visualization](https://via.placeholder.com/800x400)

- **Left Lane Effects**
  - Circular sound wave ripples
  - Beat-synced intensity
  - Color matches vehicle type
  - 30% transparency baseline

- **Right Lane Effects**
  - Alternative waveform pattern
  - Lower frequency visualization
  - Darker shade of vehicle color
  - 40% transparency baseline

- **Lane Transition Effects**
  - Flash effect when crossing lane boundaries
  - Smooth color transition between lane types
  - Brief particle burst at transition point

#### Path Visualization
![Path Visualization](https://via.placeholder.com/800x400)

- **Recording Phase**
  - Bright, solid path trail following vehicle
  - Color intensity pulsing with beat
  - Trail fades after 3-5 seconds

- **Playback Phase**
  - Persistent path showing complete loop
  - Color intensity varies based on sound activity
  - Sound ripple effects at active points

#### Ambient Effects
![Ambient Effects](https://via.placeholder.com/800x400)

- **Beat Pulse**
  - Global subtle pulse effect on BPM
  - Affects lighting, scale of elements
  - Intensity adjustable in settings

- **Background Reactivity**
  - Background elements react to overall musical intensity
  - Particle systems respond to specific frequency ranges
  - Color shifts based on dominant instrument

---

## 4. ANIMATION GUIDELINES

### 4.1 UI Animations

#### Transition Animations
- Screen transitions: 300ms ease-in-out
- Panel expansions: 200ms ease-out
- Button state changes: 100ms ease

#### Feedback Animations
- Button press: 100ms squish (90% scale) and rebound
- Success indicators: 500ms pulse with glow effect
- Error indicators: 300ms shake (3px left-right)

### 4.2 Vehicle Animations

#### Movement Animation
- Turning: Gradual rotation with slight banking effect
- Acceleration: Slight backward tilt and scale increase
- Braking: Slight forward tilt and scale decrease

#### Sound-Reactive Animation
- Beat-synced bouncing (subtle 5% scale variation)
- Active sound production: Part-specific animations (e.g., vibrating speakers)
- Instrument-specific effects (bass makes vehicle vibrate, melody makes it glow)

### 4.3 Environment Animations

#### Beat Marker Animations
- BPM-synced pulse effect (80%-100% opacity)
- Current position highlight sweeping across track
- Measure markers have additional scale animation

#### Background Animations
- Subtle floating motion for decorative elements
- Parallax scrolling effect for multi-layered backgrounds
- Audio-reactive particle systems

---

## 5. ASSET SPECIFICATIONS

### 5.1 Resolution Guidelines

#### Base Resolutions
- Mobile: 1080x1920 (9:16)
- Tablet: 1920x1080 (16:9)
- Desktop: 1920x1080 (16:9)

#### Asset Scaling
- UI elements: Vector-based when possible
- Raster graphics: Provide at 2x resolution for high-DPI displays
- Texture maps: Power of 2 dimensions (1024x1024, 2048x2048)

### 5.2 Asset List

#### UI Assets
- Logo (various configurations)
- Button sets (all states)
- Icon set (all function types)
- Progress indicators
- Panels and windows
- Decorative elements

#### Vehicle Assets
- 5 base vehicle types
- Multiple color/style variations per type
- Animation sheets for all states
- Effect sprites for sound generation

#### Track Assets
- Lane textures and patterns
- Beat marker visuals
- Start/finish line elements
- Track border and decorative elements
- Theme-specific environment objects

#### Effect Assets
- Sound visualization patterns
- Path trail effects
- Particle effect sheets
- Transition effects

#### Marketing Assets
- App store screenshots (multiple resolutions)
- Promotional banners
- Social media templates
- Video thumbnail templates

### 5.3 File Format Specifications

#### Vector Graphics
- SVG format for UI elements
- AI source files for design editing
- PDF exports for documentation

#### Raster Graphics
- PNG with transparency for UI elements
- JPG for background textures
- Sprite sheets in PNG format

#### Animation Files
- Spine animation files for complex character animations
- JSON for simpler UI animations
- MP4/GIF previews for documentation

---

## 6. ACCESSIBILITY CONSIDERATIONS

### 6.1 Color Blindness Support
![Color Blindness Modes](https://via.placeholder.com/800x400)

- Alternative color schemes for:
  - Protanopia (red-blind)
  - Deuteranopia (green-blind)
  - Tritanopia (blue-blind)
- Pattern differentiation beyond color
- High contrast mode option

### 6.2 Text Readability
- Minimum text size: 14pt for body text
- Sans-serif fonts throughout
- Contrast ratio compliance: AA level minimum, AAA where possible
- Text scaling support up to 200%

### 6.3 Input Alternatives
- Touch, keyboard, and controller support
- Customizable controls
- Auto-drive options for focus on music creation
- Simple and advanced control schemes

---

## 7. IMPLEMENTATION GUIDELINES

### 7.1 Asset Organization

#### Folder Structure
```
/assets
  /ui
    /buttons
    /icons
    /panels
    /typography
  /vehicles
    /sedan
    /sports_car
    /van
    /motorcycle
    /truck
  /tracks
    /neon_circuit
    /studio_space
    /beat_street
    /synth_space
  /effects
    /sound_waves
    /particles
    /transitions
  /audio
    /ui_sfx
    /instruments
    /ambient
```

#### Naming Conventions
- All lowercase with underscores
- Prefix for asset type (btn_, icn_, veh_, etc.)
- Include state in filename (btn_play_normal, btn_play_hover)
- Include resolution for raster assets (icn_save_24px, icn_save_48px)

### 7.2 Style Implementation

#### CSS Variables (Web Version)
```css
:root {
  /* Primary Colors */
  --color-beat-blue: #1A1A2E;
  --color-pulse-purple: #7A4EBC;
  --color-race-red: #E94560;
  
  /* Secondary Colors */
  --color-sound-yellow: #FFD460;
  --color-beat-teal: #4ECDC4;
  --color-neutral-gray: #777777;
  
  /* Font Sizes */
  --font-size-heading: 32px;
  --font-size-subheading: 24px;
  --font-size-body: 16px;
  --font-size-small: 14px;
  
  /* Spacing */
  --spacing-xs: 4px;
  --spacing-s: 8px;
  --spacing-m: 16px;
  --spacing-l: 24px;
  --spacing-xl: 32px;
}
```

#### Unity/Game Engine Implementation
- Scriptable objects for theme data
- Material libraries for consistent styling
- UI prefabs for common elements
- Animation controller organization matching asset structure

---

## 8. APPENDIX

### 8.1 Inspiration References
![Inspiration Board](https://via.placeholder.com/800x800)

- Screenshot collection of relevant UI examples
- Art style mood boards
- Animation reference videos

### 8.2 Development Tools

#### Design Software
- Figma for UI/UX design
- Adobe Photoshop for raster graphics
- Adobe Illustrator for vector assets
- Spine for 2D animation

#### Implementation
- Unity game engine
- TexturePacker for sprite optimization
- ShaderGraph for visual effects

### 8.3 Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-05-15 | Initial visual guide |
| 1.1 | TBD | Future updates |