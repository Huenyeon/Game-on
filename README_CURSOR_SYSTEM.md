# Cursor System Documentation

## Overview
This project now includes an enhanced cursor system that provides visual feedback when interacting with clickable elements.

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

### Press Effect Animation
When triggered, the system plays a sequence:
1. **Cursor2** → **Cursor3** → **Cursor4** → **Cursor1**
2. Each frame displays for 0.1 seconds (configurable via `animation_speed`)
3. Automatically returns to Cursor1 after completion

### Usage
To trigger the cursor effect in any script:

```gdscript
# Play the cursor animation
GlobalCursorManager.play_press_effect()

# Check if effect is currently playing
if GlobalCursorManager.is_effect_playing():
    # Effect is active
    pass

# Get current cursor name
var current = GlobalCursorManager.get_current_cursor()
```

### Integration Points
The cursor effect is automatically triggered on:
- **Menu buttons** (Start, Quit)
- **Desktop interactions** (clicking desktop area)
- **News/Publisher buttons** (switching between views)
- **Paper interactions** (opening/closing papers in game scene)

### Configuration
You can adjust the animation speed by modifying the `animation_speed` variable in the autoload script:
```gdscript
var animation_speed = 0.1  # Time between each cursor frame
```

## Technical Details
- Uses Godot's `Input.set_custom_mouse_cursor()` for cursor changes
- Implements async/await pattern for smooth animations
- Prevents multiple effects from running simultaneously
- Automatically manages cursor state and prevents conflicts

## Future Enhancements
- Add more cursor animation sequences
- Implement cursor effects for different interaction types
- Add sound effects to accompany cursor animations
- Create cursor themes for different game states
