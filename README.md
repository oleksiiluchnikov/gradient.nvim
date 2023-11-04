# 🌈 Gradient

**Gradient** is a versatile utility designed to generate smooth color transitions
in hexadecimal format within Neovim. This plugin allows users to create
seamless color progressions between **specified colors** or **highlight groups**,
offering an array of hex color values that represent a smooth gradient.

## ✨ Features

- **Generate gradients from:**
  - hex colors or hl_group names with as many steps and stops as you want
  - hl_group background to foreground
  
- Pick color from position in gradient.

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'oleksiiluchnikov/gradient.nvim',
}
```

## 🚀 Usage

Gradient offers a variety of functions to generate and manipulate gradients.

### API

Generate gradient from hex colors or hl_group names:
```lua
---@param steps number @ number of steps
---@param ... string @ Hex colors values or hl_group names
---@return string[] @ An array of hex color values strings representing the gradient
function gradient.from_stops(steps, ...)
```

Generate gradient from hl_group background to foreground:
```lua
---@param steps number @ number of steps
---@param hl_group_name string @ hl_group name
---@return string[] @ An array of hex color values strings representing the gradient
function gradient.from_hl_bg_to_fg(steps, hl_group_name)
```

Pick color from position in gradient:
```lua
---@param position number @ Position in gradient (0 to 1). e.g. 0.42
---@param ... string @ Hex colors values or hl_group names
---@return string @ Hex color value string representing the color at the position
function gradient.pick_color_from_pos(position, ...)
```

Explore a variety of usage examples to effortlessly implement and manipulate
gradients within your Neovim environment.

### Example

```lua
local gradient = require('gradient')

---@type string[]
local from_hex = gradient.from_stops(7, '#000000', '#ff0000', '#ffffff')
assert(from_hex == { "#000000", "#490000", "#920000", "#DB0000", "#FF2525", "#FF6E6E", "#FFB7B7", "#FFFFFF" })

---@type string[]
local from_hex_and_hl = gradient.from_stops(7, '#000000', 'Error')
assert(from_hex_and_hl == { "#000000", "#220F0E", "#431E1C", "#652D2A", "#863C38", "#A84B46", "#C95A54", "#EA6962" })

---@type string[]
local from_hl_bg_to_fg = gradient.from_hl_bg_to_fg(7, 'Error')
assert(from_hl_bg_to_fg == { "#0D0C17", "#2D1A22", "#4D272D", "#6C3438", "#8C4242", "#AB4F4D", "#CB5C58", "#EA6962" })

---@type string
local from_position = gradient.pick_color_from_pos(0.6, '#000000', '#ff0000')
assert(from_position == "#990000")
```

## License

[MIT](https://choosealicense.com/licenses/mit/)
