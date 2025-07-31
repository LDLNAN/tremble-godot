# Custom Fonts Setup Guide

## 🎯 **Theme-Based Font System (Recommended)**

Your project now uses a **theme-based font system** that automatically applies custom fonts to all UI elements!

## 📁 Font Directory Structure
```
tremble/
├── fonts/                    # Place your .ttf/.otf files here
│   ├── title_font.ttf       # For titles and headings
│   ├── button_font.ttf      # For buttons and interactive elements
│   ├── menu_font.ttf        # For labels and general text
│   └── console_font.ttf     # For console output and input
├── resources/
│   └── ui_theme.tres        # Theme with font assignments
```

## 🚀 **Quick Setup (3 Steps)**

### Step 1: Add Font Files
1. Download your preferred fonts (`.ttf` or `.otf`)
2. Place them in the `fonts/` directory
3. Rename them to match the theme expectations:
   - `title_font.ttf` - For titles
   - `button_font.ttf` - For buttons  
   - `menu_font.ttf` - For labels
   - `console_font.ttf` - For console (recommended: monospace font)

### Step 2: Update Theme (Already Done!)
The theme is already configured to use these fonts:
- **Buttons**: Use `button_font.ttf` (size 20)
- **Labels**: Use `menu_font.ttf` (size 18)
- **Console**: Use `console_font.ttf` (size 14)
- **Titles**: Can be customized per element

### Step 3: Test
1. Start the game
2. All UI elements automatically use your custom fonts!
3. No code changes needed

## 🎨 **Recommended Gaming Fonts**

### Free Fonts (Google Fonts):
- **Orbitron** - Futuristic/Sci-fi
- **Audiowide** - Action games
- **Russo One** - Modern/Industrial
- **Bungee** - Bold/Arcade style
- **Press Start 2P** - Retro/Pixel art

### Console-Specific Fonts (Monospace):
- **Fira Code** - Modern monospace with ligatures
- **JetBrains Mono** - Clean monospace for coding
- **Source Code Pro** - Adobe's monospace font
- **Roboto Mono** - Google's monospace variant
- **Cascadia Code** - Microsoft's monospace font

### Download Steps:
1. Go to [fonts.google.com](https://fonts.google.com)
2. Search for your preferred font
3. Download the `.ttf` file
4. Rename and place in `fonts/` directory

## 🔧 **Advanced Customization**

### Custom Font Sizes
If you want different font sizes, edit `resources/ui_theme.tres`:
```gdscript
Button/font_sizes/font_size = 24        # Larger buttons
Label/font_sizes/font_size = 20         # Larger labels
```

### Custom Font Colors
The theme already includes custom colors:
```gdscript
Button/colors/font_color = Color(0.9, 0.9, 0.9, 1)        # Normal
Button/colors/font_hover_color = Color(1, 1, 1, 1)        # Hover
Button/colors/font_pressed_color = Color(0.8, 0.8, 0.8, 1) # Pressed
```

### Adding New Font Types
To add a new font type (e.g., for console):
1. Add font file to `fonts/` directory
2. Add to theme: `[ext_resource type="FontFile" path="res://fonts/console_font.ttf" id="4_console_font"]`
3. Apply to control: `RichTextLabel/fonts/font = ExtResource("4_console_font")`

## ⚠️ **Important Notes**

- **Font licensing**: Ensure you have proper licenses for commercial use
- **File size**: Large font files can impact loading times
- **Fallbacks**: System fonts will be used if custom fonts are missing
- **Testing**: Test fonts at different resolutions and sizes

## 🎯 **Benefits of Theme-Based System**

✅ **Automatic**: All UI elements use custom fonts automatically  
✅ **Consistent**: Same fonts across all menus and screens  
✅ **Maintainable**: Change fonts in one place (theme file)  
✅ **Performance**: No runtime font loading or application  
✅ **Clean Code**: No font-related code in scripts  

## 📝 **Example: Adding Orbitron Font**

1. **Download**: Get Orbitron from Google Fonts
2. **Rename**: `Orbitron-Regular.ttf` → `button_font.ttf`
3. **Place**: In `fonts/` directory
4. **Test**: Start game - all buttons now use Orbitron!

## 📝 **Example: Adding Console Font**

1. **Download**: Get Fira Code from Google Fonts
2. **Rename**: `FiraCode-Regular.ttf` → `console_font.ttf`
3. **Place**: In `fonts/` directory
4. **Test**: Press tilde (`) to open console - now uses Fira Code!

That's it! No code changes needed. The theme handles everything automatically. 