# gradient

Util to get gradient between colors in hex format in Neovim.

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'oleksiiluchnikov/gradient'
}
```

## 🚀 Usage

### API

```lua
---@param steps number @ number of steps
---@param ... string @ colors in hex format
---@return string[]
function gradient.get(steps, ...)
```

```lua
---@param position number @ position in gradient
---@param ... string @ colors in hex format
---@return string
function gradient.get_color(position, ...)
```

### Example

```lua
local gradient = require('gradient')

---@type string[]
local colors = gradient.get(7, '#000000', '#ff0000', '#ffffff')
-- { 
--   "#000000",
--   "#490000",
--   "#920000",
--   "#DB0000",
--   "#FF2424",
--   "#FF6D6D",
--   "#FFB6B6",
--   "#FFFFFF"
-- }

---@type string
local color_by_position = gradient.get_color(0.6, '#000000', '#ff0000')
-- "#990000"
```


## License

[MIT](https://choosealicense.com/licenses/mit/)
