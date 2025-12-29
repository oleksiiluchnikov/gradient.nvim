-- lua/gradient/init.lua
local gradient = {}

-- Constants
local MAX_LINK_DEPTH = 10 -- Prevent infinite recursion in highlight group links

---@class HexValue
---@field value number @ The value of the hexadecimal color (0-255)
local HexValue = {}
HexValue.__index = HexValue

--- Constructor for HexValue.
---@param value number @ The color value (0-255)
---@return HexValue
function HexValue:new(value)
	if type(value) ~= "number" then
		return nil
	end
	return setmetatable({ value = value }, self)
end

--- Converts the hexadecimal value to a string format.
---@return string @ The hexadecimal string representation
function HexValue:to_string()
	return string.format("%02X", self.value)
end

--- Checks if the hexadecimal value is valid.
---@return boolean @ Returns true if the value is within the range (0-255)
function HexValue:is_valid()
	return self.value >= 0 and self.value <= 255
end

---@class HexColor
---@field red HexValue @ The red component
---@field green HexValue @ The green component
---@field blue HexValue @ The blue component
local HexColor = {}
HexColor.__index = HexColor

--- Constructor for HexColor.
---@param str string @ Hex color string (e.g., "#FF0000" or "#FF0000FF")
---@return HexColor|nil, string|nil @ The HexColor object or nil and error message
function HexColor:new(str)
	if type(str) ~= "string" then
		return nil, "HexColor requires a string argument"
	end

	-- Validate hex color format
	local hex = str:match("^#([0-9A-Fa-f]+)$")
	if not hex or (#hex ~= 6 and #hex ~= 8) then
		return nil, "Invalid hex color format. Expected #RRGGBB or #RRGGBBAA"
	end

	-- Parse RGB components (ignore alpha if present)
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)

	if not r or not g or not b then
		return nil, "Failed to parse hex color components"
	end

	return setmetatable({
		red = HexValue:new(r),
		green = HexValue:new(g),
		blue = HexValue:new(b),
	}, self)
end

--- Converts the HexColor to a string format.
---@return string @ The string representation of the hexadecimal color
function HexColor:to_string()
	return string.format("#%s%s%s", self.red:to_string(), self.green:to_string(), self.blue:to_string())
end

--- Converts the HexColor to its decimal representation.
---@return number @ The decimal representation of the hexadecimal color
function HexColor:to_decimal()
	return self.red.value * 65536 + self.green.value * 256 + self.blue.value
end

--- Gets the RGB components as an array.
---@return number[] @ The array containing red, green, and blue values
function HexColor:to_rgb()
	return { self.red.value, self.green.value, self.blue.value }
end

--- Checks if the HexColor is valid.
---@return boolean @ Returns true if all components are valid
function HexColor:is_valid()
	return self.red:is_valid() and self.green:is_valid() and self.blue:is_valid()
end

---@class DecimalColor
---@field red number
---@field green number
---@field blue number
local DecimalColor = {}
DecimalColor.__index = DecimalColor

--- Constructor for DecimalColor.
---@param decimal_color number @ The decimal color value
---@return DecimalColor|nil, string|nil @ The DecimalColor object or nil and error message
function DecimalColor:new(decimal_color)
	if type(decimal_color) ~= "number" or decimal_color < 0 or decimal_color > 16777215 then
		return nil, "Invalid decimal color value"
	end

	return setmetatable({
		red = math.floor(decimal_color / 65536),
		green = math.floor((decimal_color % 65536) / 256),
		blue = decimal_color % 256,
	}, self)
end

--- Converts the DecimalColor to a string format.
---@return string @ The string representation (R,G,B)
function DecimalColor:to_string()
	return string.format("%d,%d,%d", self.red, self.green, self.blue)
end

--- Converts the DecimalColor to its hexadecimal representation.
---@return HexColor|nil, string|nil @ The hexadecimal representation
function DecimalColor:to_hex()
	return HexColor:new(string.format("#%02X%02X%02X", self.red, self.green, self.blue))
end

--- Gets the RGB components as an array.
---@return number[] @ The array containing red, green, and blue values
function DecimalColor:to_rgb()
	return { self.red, self.green, self.blue }
end

---@class HighlightGroup
---@field fg DecimalColor
---@field bg DecimalColor
local HighlightGroup = {}
HighlightGroup.__index = HighlightGroup

--- Constructor for HighlightGroup.
---@param hl_group_name string @ The highlight group name
---@return HighlightGroup|nil, string|nil @ The HighlightGroup object or nil and error message
function HighlightGroup:new(hl_group_name)
	if type(hl_group_name) ~= "string" or hl_group_name == "" then
		return nil, "Highlight group name must be a non-empty string"
	end

	-- Get the highlight group
	local ok, hl_data = pcall(vim.api.nvim_get_hl, 0, { name = hl_group_name })
	if not ok then
		return nil, "Failed to get highlight group: " .. hl_group_name
	end

	-- Resolve links with cycle detection
	local function get_complete_group(group, depth)
		depth = depth or 0

		if depth > MAX_LINK_DEPTH then
			return nil, "Circular or too deep highlight group link detected"
		end

		if group.link then
			local ok_link, linked_group = pcall(vim.api.nvim_get_hl, 0, { name = group.link })
			if not ok_link then
				return nil, "Failed to resolve linked highlight group: " .. group.link
			end

			if linked_group.fg and linked_group.bg then
				return linked_group
			else
				return get_complete_group(linked_group, depth + 1)
			end
		end

		return group
	end

	local complete_group, err = get_complete_group(hl_data)
	if not complete_group then
		return nil, err or "Failed to resolve highlight group"
	end

	if not complete_group.fg then
		return nil, "Highlight group has no foreground color: " .. hl_group_name
	end

	-- Get background, fallback to Normal if needed
	local bg = complete_group.bg
	if not bg then
		local ok_normal, normal = pcall(vim.api.nvim_get_hl, 0, { name = "Normal" })
		if ok_normal and normal.bg then
			bg = normal.bg
		else
			return nil, "Highlight group has no background and Normal group not found"
		end
	end

	local fg_color, fg_err = DecimalColor:new(complete_group.fg)
	if not fg_color then
		return nil, "Invalid foreground color: " .. (fg_err or "unknown error")
	end

	local bg_color, bg_err = DecimalColor:new(bg)
	if not bg_color then
		return nil, "Invalid background color: " .. (bg_err or "unknown error")
	end

	return setmetatable({
		fg = fg_color,
		bg = bg_color,
	}, self)
end

--- Parse various color input formats
---@param arg string|table @ Hex color string or highlight group name
---@return HexColor|nil, string|nil @ The HexColor or nil and error message
local function parse_color_arg(arg)
	if type(arg) == "string" then
		-- Check if it's a hex color
		if arg:match("^#[0-9A-Fa-f]+$") then
			return HexColor:new(arg)
		else
			-- Try as highlight group
			local hl_group, err = HighlightGroup:new(arg)
			if not hl_group then
				return nil, err or "Invalid color or highlight group: " .. arg
			end
			return hl_group.fg:to_hex()
		end
	elseif type(arg) == "table" and arg.to_string then
		-- Already a color object
		return arg
	end

	return nil, "Invalid color argument type"
end

--- Parse varargs into HexColor array
---@param args any[] @ The varargs as table
---@return HexColor[]|nil, string|nil @ Array of HexColors or nil and error message
local function hex_colors_from_vararg(args)
	local colors = {}

	for i, arg in ipairs(args) do
		local color, err = parse_color_arg(arg)
		if not color then
			return nil, string.format("Argument %d: %s", i, err or "Invalid color")
		end
		table.insert(colors, color)
	end

	if #colors == 0 then
		return nil, "No colors provided"
	end

	return colors
end

--- Interpolate between two colors
---@param start_color HexColor @ The starting color
---@param end_color HexColor @ The ending color
---@param position number @ Position between colors (0-1)
---@return HexColor @ The interpolated color
local function interpolate_colors(start_color, end_color, position)
	-- Use proper rounding instead of ceil
	local function round(x)
		return math.floor(x + 0.5)
	end

	local r = round(start_color.red.value + (end_color.red.value - start_color.red.value) * position)
	local g = round(start_color.green.value + (end_color.green.value - start_color.green.value) * position)
	local b = round(start_color.blue.value + (end_color.blue.value - start_color.blue.value) * position)

	-- Clamp to valid range
	r = math.max(0, math.min(255, r))
	g = math.max(0, math.min(255, g))
	b = math.max(0, math.min(255, b))

	return HexColor:new(string.format("#%02X%02X%02X", r, g, b))
end

--- Generate gradient colors
---@param steps number @ Number of steps
---@param hex_colors HexColor[] @ Array of color stops
---@return string[] @ Array of hex color strings
local function generate_colors(steps, hex_colors)
	local generated_gradient = {}

	-- Single color case
	if #hex_colors == 1 then
		for _ = 1, steps do
			table.insert(generated_gradient, hex_colors[1]:to_string())
		end
		return generated_gradient
	end

	local num_segments = #hex_colors - 1

	-- Generate colors (fixed off-by-one bug)
	for i = 0, steps - 1 do
		local t = i / (steps - 1)
		local segment_idx = math.min(math.floor(t * num_segments), num_segments - 1)
		local segment_t = (t * num_segments) - segment_idx

		local start_color = hex_colors[segment_idx + 1]
		local end_color = hex_colors[segment_idx + 2]

		local color = interpolate_colors(start_color, end_color, segment_t)
		table.insert(generated_gradient, color:to_string())
	end

	return generated_gradient
end

-- Public API

---Get a color between two colors
---@param position number @ Position between colors (0-1)
---@param start_color HexColor|string @ The starting color
---@param end_color HexColor|string @ The ending color
---@return HexColor|nil, string|nil @ The interpolated color or nil and error message
function gradient.pick_color_between(position, start_color, end_color)
	-- Validate position
	if type(position) ~= "number" or position < 0 or position > 1 then
		return nil, "Position must be a number between 0 and 1"
	end

	-- Parse colors
	if type(start_color) == "string" then
		local color, err = HexColor:new(start_color)
		if not color then
			return nil, "Invalid start color: " .. (err or "unknown error")
		end
		start_color = color
	end

	if type(end_color) == "string" then
		local color, err = HexColor:new(end_color)
		if not color then
			return nil, "Invalid end color: " .. (err or "unknown error")
		end
		end_color = color
	end

	-- Validate color objects
	if not start_color:is_valid() then
		return nil, "Invalid start color values"
	end

	if not end_color:is_valid() then
		return nil, "Invalid end color values"
	end

	return interpolate_colors(start_color, end_color, position)
end

---Get a color at position from multiple color stops
---@param position number @ Position in gradient (0-1)
---@param ... string|HexColor @ Color stops (hex strings or highlight group names)
---@return string|nil, string|nil @ Hex color string or nil and error message
function gradient.pick_color_from_pos(position, ...)
	-- Validate position
	if type(position) ~= "number" or position < 0 or position > 1 then
		return nil, "Position must be a number between 0 and 1"
	end

	-- Parse colors
	local hex_colors, err = hex_colors_from_vararg({ ... })
	if not hex_colors then
		return nil, err or "Invalid color arguments"
	end

	-- Single color case
	if #hex_colors == 1 then
		return hex_colors[1]:to_string()
	end

	-- Find which segment the position falls into
	local num_segments = #hex_colors - 1
	local segment_idx = math.min(math.floor(position * num_segments), num_segments - 1)
	local segment_t = (position * num_segments) - segment_idx

	local start_color = hex_colors[segment_idx + 1]
	local end_color = hex_colors[segment_idx + 2]

	local color = interpolate_colors(start_color, end_color, segment_t)
	return color:to_string()
end

---Generate a gradient from color stops
---@param steps number @ Number of colors to generate
---@param ... string|HexColor @ Color stops (hex strings or highlight group names)
---@return string[]|nil, string|nil @ Array of hex color strings or nil and error message
function gradient.from_stops(steps, ...)
	-- Validate steps
	if type(steps) ~= "number" or steps < 1 or steps ~= math.floor(steps) then
		return nil, "Steps must be a positive integer"
	end

	-- Parse colors
	local hex_colors, err = hex_colors_from_vararg({ ... })
	if not hex_colors then
		return nil, err or "Invalid color arguments"
	end

	return generate_colors(steps, hex_colors)
end

---Generate gradient from highlight group background to foreground
---@param steps number @ Number of colors to generate
---@param highlight_group_name string @ Highlight group name
---@return string[]|nil, string|nil @ Array of hex color strings or nil and error message
function gradient.from_hl_bg_to_fg(steps, highlight_group_name)
	-- Validate steps
	if type(steps) ~= "number" or steps < 1 or steps ~= math.floor(steps) then
		return nil, "Steps must be a positive integer"
	end

	-- Get highlight group
	local hl_group, err = HighlightGroup:new(highlight_group_name)
	if not hl_group then
		return nil, err or "Failed to get highlight group"
	end

	local bg_hex = hl_group.bg:to_hex()
	local fg_hex = hl_group.fg:to_hex()

	return generate_colors(steps, { bg_hex, fg_hex })
end

---Create a gradient with easing function
---@param steps number @ Number of colors to generate
---@param easing string|function @ Easing function name or custom function
---@param ... string|HexColor @ Color stops
---@return string[]|nil, string|nil @ Array of hex color strings or nil and error message
function gradient.from_stops_eased(steps, easing, ...)
	if type(steps) ~= "number" or steps < 1 or steps ~= math.floor(steps) then
		return nil, "Steps must be a positive integer"
	end

	-- Easing functions
	local easing_functions = {
		linear = function(t)
			return t
		end,
		["ease-in"] = function(t)
			return t * t
		end,
		["ease-out"] = function(t)
			return t * (2 - t)
		end,
		["ease-in-out"] = function(t)
			return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
		end,
	}

	local ease_fn
	if type(easing) == "function" then
		ease_fn = easing
	elseif type(easing) == "string" then
		ease_fn = easing_functions[easing]
		if not ease_fn then
			return nil, "Unknown easing function: " .. easing
		end
	else
		return nil, "Easing must be a string or function"
	end

	local hex_colors, err = hex_colors_from_vararg({ ... })
	if not hex_colors then
		return nil, err or "Invalid color arguments"
	end

	local generated_gradient = {}

	if #hex_colors == 1 then
		for _ = 1, steps do
			table.insert(generated_gradient, hex_colors[1]:to_string())
		end
		return generated_gradient
	end

	local num_segments = #hex_colors - 1

	for i = 0, steps - 1 do
		local t = ease_fn(i / (steps - 1))
		local segment_idx = math.min(math.floor(t * num_segments), num_segments - 1)
		local segment_t = (t * num_segments) - segment_idx

		local start_color = hex_colors[segment_idx + 1]
		local end_color = hex_colors[segment_idx + 2]

		local color = interpolate_colors(start_color, end_color, segment_t)
		table.insert(generated_gradient, color:to_string())
	end

	return generated_gradient
end

---Reverse a gradient
---@param gradient_colors string[] @ Array of hex color strings
---@return string[] @ Reversed array
function gradient.reverse(gradient_colors)
	local reversed = {}
	for i = #gradient_colors, 1, -1 do
		table.insert(reversed, gradient_colors[i])
	end
	return reversed
end

---Get gradient info
---@param gradient_colors string[] @ Array of hex color strings
---@return table @ Gradient info (length, start, end, etc.)
function gradient.info(gradient_colors)
	if not gradient_colors or #gradient_colors == 0 then
		return { length = 0 }
	end

	return {
		length = #gradient_colors,
		start = gradient_colors[1],
		finish = gradient_colors[#gradient_colors],
		colors = gradient_colors,
	}
end

return gradient
