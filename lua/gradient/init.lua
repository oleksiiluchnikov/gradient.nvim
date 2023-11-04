local gradient = {}

---@class HexValue
---@field value number @ The value of the hexadecimal color (0-255)
---@field is_valid boolean|function @ Determines whether the hexadecimal color value is valid
local HexValue = {}

--- Constructor for HexValue.
---@param obj table @ Optional object to initialize
---@return HexValue
function HexValue:new(obj)
	obj = obj or {}
	setmetatable(obj, self)
	self.__index = self
	return obj
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
---@field red HexValue @ The red component of the hexadecimal color
---@field green HexValue @ The green component of the hexadecimal color
---@field blue HexValue @ The blue component of the hexadecimal color
---@field to_string function @ Converts the HexColor to a string format
---@field to_decimal function @ Converts the HexColor to its decimal representation
---@field to_rgb function @ Gets the RGB components as an array
---@field is_valid function @ Checks if the HexColor is valid
local HexColor = {}

--- Constructor for HexColor.
---@param obj table|nil @ Optional object to initialize
---@return HexColor
function HexColor:new(obj, str)
	obj = obj or {}
	if str then
		if str:len() == 7 then
			str = str .. "FF"
		end
		obj.red = HexValue:new({ value = tonumber(string.sub(str, 2, 3), 16) })
		obj.green = HexValue:new({ value = tonumber(string.sub(str, 4, 5), 16) })
		obj.blue = HexValue:new({ value = tonumber(string.sub(str, 6, 7), 16) })
	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

--- Converts the HexColor to a string format.
---@return string @ The string representation of the hexadecimal color
function HexColor:to_string()
	return string.format("#%s%s%s", self.red:to_string(), self.green:to_string(), self.blue:to_string())
end

--- Converts the HexColor to its decimal representation.
--- Example: #000000 -> 0, #FFFFFF -> 16777215
---@return number @ The decimal representation of the hexadecimal color
function HexColor:to_decimal()
  return tonumber(string.format("%s%s%s", self.red:to_string(), self.green:to_string(), self.blue:to_string()), 16)
end

--- Gets the RGB components as an array.
---@return table @ The array containing red, green, and blue values
function HexColor:to_rgb()
	return { self.red.value, self.green.value, self.blue.value }
end

--- Checks if the HexColor is valid.
---@return boolean @ Returns true if all components of the HexColor are valid
function HexColor:is_valid()
	return self.red:is_valid() and self.green:is_valid() and self.blue:is_valid()
end

---@class DecimalColor
---@field red number
---@field green number
---@field blue number
local DecimalColor = {}

--- Constructor for DecimalColor.
--- @param obj table @ Optional object to initialize
--- @param decimal_color number @ The decimal color
function DecimalColor:new(obj, decimal_color)
	obj = obj or {}
	if decimal_color then
		obj.red = math.floor(decimal_color / 65536)
		obj.green = math.floor((decimal_color - obj.red * 65536) / 256)
		obj.blue = math.floor(decimal_color - obj.red * 65536 - obj.green * 256)
	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

--- Converts the DecimalColor to a string format.
--- @return string @ The string representation of the decimal color
function DecimalColor:to_string()
	return string.format("%d,%d,%d", self.red, self.green, self.blue)
end

--- Converts the DecimalColor to its hexadecimal representation.
--- @return HexColor @ The hexadecimal representation of the decimal color
function DecimalColor:to_hex()
	return HexColor:new({}, string.format("#%02X%02X%02X", self.red, self.green, self.blue))
end

--- Gets the RGB components as an array.
--- @return table @ The array containing red, green, and blue values
function DecimalColor:to_rgb()
	return { self.red, self.green, self.blue }
end

---@class HighlightGroup
---@field fg DecimalColor
---@field bg DecimalColor
local HighlightGroup = {}

--- Constructor for HighlightGroup.
--- @param obj table @ Optional object to initialize
--- @param hl_group_name string @ The highlight group name
--- @return HighlightGroup|nil
function HighlightGroup:new(obj, hl_group_name)
    obj = obj or {}

    if hl_group_name then
      obj = vim.api.nvim_get_hl(0, { name = hl_group_name })
    end

    local function get_complete_group(group)
        if group.link then
            local linked_group = vim.api.nvim_get_hl(0, { name = group.link })
            if not linked_group.link and linked_group.bg and linked_group.fg then
                return linked_group -- Found the linked group with bg and fg colors
            else
                return get_complete_group(linked_group) -- Recursive call for further linked groups
            end
        else
            return group -- No more linked groups, return the current group
        end
    end

    local complete_group = get_complete_group(obj)

    if complete_group and complete_group.bg and complete_group.fg then
        obj = {
            bg = DecimalColor:new({}, complete_group.bg),
            fg = DecimalColor:new({}, complete_group.fg)
        }
        setmetatable(obj, self)
        self.__index = self
        return obj
    else
        error("No complete linked highlight group found for: " .. hl_group_name)
        return
    end
end

---Get a color between two colors
---@param start_color HexColor|string @ The starting color
---@param end_color HexColor|string @ The ending color
---@param position number @ The position between the two colors (0-1)
---@return HexColor|nil @ The color between the two colors
function gradient.pick_color_between(position, start_color, end_color)
	if type(start_color) == "string" then
		start_color = HexColor:new({}, start_color)
	end
	if type(end_color) == "string" then
		end_color = HexColor:new({}, end_color)
	end

	---validate the colors
	if not start_color:is_valid() then
    error("Invalid start color: " .. start_color:to_string())
		return
	end

	if not end_color:is_valid() then
    error("Invalid end color: " .. end_color:to_string())
		return
	end

	if position < 0 or position > 1 then
    error("Invalid position: " .. position .. " Should be between 0 and 1")
		return
	end

	local red = math.ceil(start_color.red.value + (end_color.red.value - start_color.red.value) * position)
	local green = math.ceil(start_color.green.value + (end_color.green.value - start_color.green.value) * position)
	local blue = math.ceil(start_color.blue.value + (end_color.blue.value - start_color.blue.value) * position)

	return HexColor:new({}, string.format("#%02X%02X%02X", red, green, blue))
end

---Get a color between multiple colors
---@param position number @ The position between the two colors (0-1)
---@vararg HexColor|string @ The colors
---@return string|nil @ The hexadecimal color
function gradient.pick_color_from_pos(position, ...)

	if position < 0 or position > 1 then
    error("Invalid position: " .. position .. " Should be between 0 and 1")
		return
	end

	---Create a table of colors
	---@type HexColor[]|nil
	local hex_colors = gradient.handle_varargs({ ... })
  if not hex_colors then
    error("Invalid arguments" .. vim.inspect({ ... }))
  end

	if #hex_colors == 1 then
		return hex_colors[1]:to_string()
	end

	local step_size = 1 / (#hex_colors - 1)
	local start_index = math.floor(position / step_size)
	if start_index >= #hex_colors then
		return hex_colors[#hex_colors]:to_string()
	end

	local end_index = start_index + 1
	local start_color = hex_colors[start_index + 1]
	if end_index >= #hex_colors then
		return start_color:to_string()
	end
	local end_color = hex_colors[end_index + 1]
	local position_in_step = (position - start_index * step_size) / step_size
	local color = gradient.pick_color_between(position_in_step, start_color, end_color)

	if color then
		return color:to_string()
	end
end

--- Generate a gradient table of colors
---@param steps number @ Number of steps in the gradient
---@param ... HexColor|string @ Colors in hex format
---@return table|nil @ Table of colors
function gradient.from_stops(steps, ...)
	local args = { ... }

  local hex_colors = gradient.handle_varargs(args)
  if not hex_colors then
    error("Invalid arguments" .. vim.inspect(args))
  end

	---@type string[] -- Color hex values e.g. {"#000000", "#808080", "#ffffff"}
	return gradient.generate(steps, hex_colors)
end

--- Generate a gradient table of colors
--- @param steps number @ Number of steps in the gradient
--- @param hex_colors HexColor[] @ Colors in hex format
--- @return table @ Table of colors
function gradient.generate(steps, hex_colors)
	---@type string[] -- Color hex values e.g. {"#000000", "#808080", "#ffffff"}
	local generated_gradient = {}

	if #hex_colors == 1 then
		for _ = 1, steps do
			table.insert(generated_gradient, hex_colors[1]:to_string())
		end
		return generated_gradient
	end

	local step_size = 1 / (#hex_colors - 1)

	for i = 0, steps do
		local position = i / steps
		local start_index = math.floor(position / step_size)
		local end_index = start_index + 1

		if end_index >= #hex_colors then
			table.insert(generated_gradient, hex_colors[#hex_colors]:to_string())
		else
			local start_color = hex_colors[start_index + 1]
			local end_color = hex_colors[end_index + 1]
			local position_in_step = (position - start_index * step_size) / step_size

			---@type string
			local color = gradient.pick_color_between(position_in_step, start_color, end_color):to_string()
			table.insert(generated_gradient, color)
		end
	end

	return generated_gradient
end

--- Generate a gradient table from background to foreground
---@param steps number @ Number of steps in the gradient
---@param highlight_group_name string @ The highlight group to use
---@return table|nil @ Table of colors
function gradient.from_hl_bg_to_fg(steps, highlight_group_name)
	local hl_group = HighlightGroup:new({}, highlight_group_name)
	if hl_group == nil then
    error("Highlight group not found: " .. highlight_group_name)
		return
	end

	return gradient.from_stops(steps, hl_group.bg:to_hex(), hl_group.fg:to_hex())
end

---Handle the varargs input to determine the type of input
---@param args table @ The varargs input
---@return table|nil @ The table of colors
function gradient.handle_varargs(args)
	local colors = {}

	local function is_hex_color(str)
		return str:match("^#[0-9A-Fa-f]+$")
	end

	local function is_hl_group_name(str)
		return str:match("%S+$")
	end

	for _, arg in ipairs(args) do
		if type(arg) == "string" then -- it is hex color or highlight group name
			if is_hex_color(arg) then -- it is hex color
				table.insert(colors, HexColor:new({}, arg))
			elseif is_hl_group_name(arg) then -- it is highlight group
				local hl_group = HighlightGroup:new({}, arg)
				if hl_group == nil then
          error("Highlight group not found: " .. arg)
					return
				end

				table.insert(colors, hl_group.fg:to_hex())
			else
        error("Invalid argument: " .. arg)
				return
			end
		elseif type(arg) == "table" then
			table.insert(colors, arg)
		end
	end

	return colors
end


function gradient.test_all_methods()
	local hex_color = HexColor:new({}, "#000000")
	assert(hex_color:to_string() == "#000000", "HexColor:to_string() failed")
	assert(hex_color:to_decimal() == 0, "HexColor:to_decimal() failed")
	assert(hex_color:to_rgb()[1] == 0, "HexColor:to_rgb() failed")
	assert(hex_color:is_valid() == true, "HexColor:is_valid() failed")

	local decimal_color = DecimalColor:new({}, 0)
	assert(decimal_color:to_string() == "0,0,0", "DecimalColor:to_string() failed")
	assert(decimal_color:to_hex():to_string() == "#000000", "DecimalColor:to_hex() failed")
	assert(decimal_color:to_rgb()[1] == 0, "DecimalColor:to_rgb() failed")
end

return gradient
