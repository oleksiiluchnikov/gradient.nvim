# 🌈 Gradient.nvim

A robust color gradient utility for Neovim that generates smooth color transitions between hex colors and highlight groups.

## ✨ Features

- **Generate gradients from:**
  - Hex colors (e.g., `#FF0000`)
  - Highlight group names (e.g., `"Error"`)
  - Mix of both with multiple stops

- **Advanced features:**
  - Easing functions (linear, ease-in, ease-out, ease-in-out, custom)
  - Pick colors at specific positions
  - Reverse gradients
  - Gradient information and utilities

- **Robust error handling:**
  - Returns `nil, error_msg` instead of crashing
  - Validates all inputs
  - Detects circular highlight group links

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'oleksiiluchnikov/gradient.nvim',
}
```

## 🚀 Usage

### Basic Gradients

Generate gradient from hex colors:

```lua
local gradient = require('gradient')

-- Generate 5 colors from black to white
local colors = gradient.from_stops(5, '#000000', '#FFFFFF')
-- Result: { "#000000", "#404040", "#808080", "#BFBF3F", "#FFFFFF" }

-- Generate 7 colors through red
local colors = gradient.from_stops(7, '#000000', '#FF0000', '#FFFFFF')
-- Result: 7 colors transitioning black → red → white
```

Error handling:

```lua
local colors, err = gradient.from_stops(5, '#INVALID', '#FFFFFF')
if not colors then
  print("Error: " .. err)
end
```

### Using Highlight Groups

Generate gradient from highlight group colors:

```lua
-- From Normal background to foreground
local colors = gradient.from_hl_bg_to_fg(7, 'Normal')

-- Mix hex colors and highlight groups
local colors = gradient.from_stops(10, '#000000', 'Error', '#FFFFFF')
```

### Pick Colors at Positions

Get a specific color from a gradient:

```lua
-- Get color at 60% between black and red
local color = gradient.pick_color_from_pos(0.6, '#000000', '#FF0000')
-- Result: "#990000"

-- With multiple stops
local color = gradient.pick_color_from_pos(0.5, '#000000', '#FF0000', '#FFFFFF')
```

### Easing Functions

Create gradients with non-linear transitions:

```lua
-- Ease-in (slow start, fast end)
local colors = gradient.from_stops_eased(10, 'ease-in', '#000000', '#FFFFFF')

-- Ease-out (fast start, slow end)
local colors = gradient.from_stops_eased(10, 'ease-out', '#000000', '#FFFFFF')

-- Ease-in-out (slow start and end)
local colors = gradient.from_stops_eased(10, 'ease-in-out', '#000000', '#FFFFFF')

-- Custom easing function
local colors = gradient.from_stops_eased(10, function(t)
  return t * t * t  -- Cubic easing
end, '#000000', '#FFFFFF')
```

### Utility Functions

```lua
-- Reverse a gradient
local colors = gradient.from_stops(5, '#000000', '#FFFFFF')
local reversed = gradient.reverse(colors)
-- Result: { "#FFFFFF", ..., "#000000" }

-- Get gradient info
local info = gradient.info(colors)
-- Result: {
--   length = 5,
--   start = "#000000",
--   finish = "#FFFFFF",
--   colors = { ... }
-- }
```

## 📚 API Reference

### `gradient.from_stops(steps, ...)`

Generate gradient from color stops.

**Parameters:**

- `steps` (number): Number of colors to generate (must be positive integer)
- `...` (string): Hex colors or highlight group names

**Returns:**

- `string[]|nil`: Array of hex color strings, or `nil` on error
- `string|nil`: Error message if failed

**Example:**

```lua
local colors, err = gradient.from_stops(7, '#000000', 'Error', '#FFFFFF')
if not colors then
  vim.notify("Failed: " .. err, vim.log.levels.ERROR)
  return
end
```

### `gradient.from_hl_bg_to_fg(steps, hl_group_name)`

Generate gradient from highlight group background to foreground.

**Parameters:**

- `steps` (number): Number of colors to generate
- `hl_group_name` (string): Highlight group name

**Returns:**

- `string[]|nil`: Array of hex color strings, or `nil` on error
- `string|nil`: Error message if failed

### `gradient.pick_color_from_pos(position, ...)`

Get color at specific position in gradient.

**Parameters:**

- `position` (number): Position in gradient (0 to 1)
- `...` (string): Hex colors or highlight group names

**Returns:**

- `string|nil`: Hex color string, or `nil` on error
- `string|nil`: Error message if failed

**Example:**

```lua
local color = gradient.pick_color_from_pos(0.5, '#FF0000', '#0000FF')
-- Returns: "#800080" (purple - midpoint between red and blue)
```

### `gradient.pick_color_between(position, start_color, end_color)`

Interpolate between two colors.

**Parameters:**

- `position` (number): Position between colors (0 to 1)
- `start_color` (string|HexColor): Starting color
- `end_color` (string|HexColor): Ending color

**Returns:**

- `HexColor|nil`: Color object, or `nil` on error
- `string|nil`: Error message if failed

**Example:**

```lua
local color = gradient.pick_color_between(0.5, '#FF0000', '#0000FF')
local hex = color:to_string()  -- "#800080"
```

### `gradient.from_stops_eased(steps, easing, ...)`

Generate gradient with easing function.

**Parameters:**

- `steps` (number): Number of colors to generate
- `easing` (string|function): Easing function name or custom function
  - Built-in: `"linear"`, `"ease-in"`, `"ease-out"`, `"ease-in-out"`
- `...` (string): Hex colors or highlight group names

**Returns:**

- `string[]|nil`: Array of hex color strings, or `nil` on error
- `string|nil`: Error message if failed

**Example:**

```lua
-- Built-in easing
local colors = gradient.from_stops_eased(10, 'ease-out', '#000000', '#FFFFFF')

-- Custom easing (bounce effect)
local colors = gradient.from_stops_eased(10, function(t)
  return 1 - math.abs(math.sin(t * math.pi))
end, '#000000', '#FFFFFF')
```

### `gradient.reverse(gradient_colors)`

Reverse a gradient.

**Parameters:**

- `gradient_colors` (string[]): Array of hex color strings

**Returns:**

- `string[]`: Reversed array

### `gradient.info(gradient_colors)`

Get gradient information.

**Parameters:**

- `gradient_colors` (string[]): Array of hex color strings

**Returns:**

- `table`: Info object with `length`, `start`, `finish`, `colors` fields

## 🎨 Practical Examples

### Statusline gradient

```lua
local gradient = require('gradient')

-- Generate gradient for statusline
local colors = gradient.from_stops(10, 'StatusLine', 'StatusLineNC')

-- Apply to statusline components
for i, color in ipairs(colors) do
  vim.api.nvim_set_hl(0, 'StatusGradient' .. i, { fg = color })
end
```

### Indent guides

```lua
-- Create fading indent guides
local colors = gradient.from_stops_eased(8, 'ease-out', 'Comment', 'Normal')

for i, color in ipairs(colors) do
  vim.api.nvim_set_hl(0, 'IndentGuide' .. i, { fg = color })
end
```

### Diff highlighting

```lua
-- Smooth diff transitions
local add_gradient = gradient.from_stops(5, 'Normal', 'DiffAdd')
local delete_gradient = gradient.from_stops(5, 'Normal', 'DiffDelete')
```

## 🔧 Technical Details

### Color Spaces

- Uses RGB color space for interpolation
- Proper rounding to avoid bias
- Clamped to valid range (0-255)

### Highlight Group Resolution

- Follows `link` chains up to 10 levels deep
- Detects circular references
- Falls back to `Normal` background when needed

### Error Handling

All functions return `(result, error)` tuple:

```lua
local result, err = gradient.from_stops(...)
if not result then
  -- Handle error
  print(err)
end
```

## 📝 Migration from Old Version

The API is backward compatible, but now returns errors instead of throwing:

**Old code (still works):**

```lua
local colors = gradient.from_stops(7, '#000000', '#FFFFFF')
```

**New recommended pattern:**

```lua
local colors, err = gradient.from_stops(7, '#000000', '#FFFFFF')
if not colors then
  vim.notify('Gradient error: ' .. err, vim.log.levels.ERROR)
  return
end
```

**Breaking changes:**

- Constructor signatures changed: Use `HexColor:new("#FF0000")` instead of `HexColor:new({}, "#FF0000")`
- Off-by-one bug fixed: `from_stops(7, ...)` now returns exactly 7 colors (not 8)

## License

[MIT](https://choosealicense.com/licenses/mit/)
