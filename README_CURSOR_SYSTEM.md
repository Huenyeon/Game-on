# Cursor System Documentation

## Overview
This project now includes an enhanced cursor system that provides visual feedback when interacting with clickable elements. The cursors are automatically scaled to be larger and more visible.

## How It Works

### Autoload Script
The `GlobalCursorManager` autoload script manages all cursor-related functionality:
- **Location**: `res://scripts/autoload_cursor_manager.gd`
- **Autoload Name**: `GlobalCursorManager`

### Cursor Assets
The system uses 5 cursor images located in `res://assets/Cursors/`:
- `Cursor1.png` - Default cursor (normal state)
- `Cursor2.png` - Animation frame 1
- `Cursor3.png` - Animation frame 2  
- `Cursor4.png` - Animation frame 3
- `Cursor5.png` - Available for future use

### Cursor Size and Scaling
- **Default Scale**: 2.0x (cursors are automatically made 2x bigger)
- **Hotspot**: Automatically centered for larger cursors
- **Quality**: Uses LANCZOS interpolation for smooth scaling

### Press Effect Animation
When triggered, the system plays a sequence:
1. **Cursor2** → **Cursor3** → **Cursor4** → **Cursor1**
2. Each frame displays for 0.05 seconds (configurable via `animation_speed`)
3. Automatically returns to Cursor1 after completion
4. **Plays on EVERY click anywhere on the screen**

### Usage
To trigger the cursor effect in any script:

```gdscript
# Play the cursor animation
GlobalCursorManager.play_press_effect()

# Check if effect is currently playing
if GlobalCursorManager.is_effect_playing():
    # Effect is active
    pass

# Change cursor size
GlobalCursorManager.set_cursor_size(3.0)  # Make 3x bigger

# Get current cursor size
var size = GlobalCursorManager.get_cursor_size()

# Test the cursor system
GlobalCursorManager.test_cursor_system()
```

### Integration Points
The cursor effect is automatically triggered on:
- **Every single click anywhere on the screen**
- **Menu buttons** (Start, Quit)
- **Desktop interactions** (clicking desktop area)
- **News/Publisher buttons** (switching between views)
- **Paper interactions** (opening/closing papers in game scene)

### Configuration
You can adjust the animation speed and cursor size by modifying these variables in the autoload script:
```gdscript
var animation_speed = 0.05  # Time between each cursor frame
var cursor_scale = 2.0      # Cursor size multiplier
```

## Technical Details
- Uses Godot's `Input.set_custom_mouse_cursor()` for cursor changes
- Implements async/await pattern for smooth animations
- Automatically scales cursors to specified size
- Centers hotspot for larger cursors
- Prevents multiple effects from running simultaneously
- Automatically manages cursor state and prevents conflicts

## Godot Compatibility
- **Tested**: Works with Godot 4.4
- **Scaling**: Uses Image.resize() with LANCZOS interpolation
- **Hotspot**: Automatically calculated for larger cursors
- **Performance**: Efficient texture scaling and management

## Future Enhancements
- Add more cursor animation sequences
- Implement cursor effects for different interaction types
- Add sound effects to accompany cursor animations
- Create cursor themes for different game states
- Dynamic cursor size adjustment based on game state
