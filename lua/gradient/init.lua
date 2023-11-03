local M = {}

---Calculate the interpolation between two color values
---@param color_value_a string @ The starting color value in hex format. e.g. "FF"
---@param color_value_b string @ The ending color value in hex format. e.g. "00"
---@param position number @ The position between the two colors (0-1)
local function calculate_interpolation(color_value_a, color_value_b, position)
    local interpolated_value = math.floor(tonumber("0x" .. color_value_a) * (1 - position) + tonumber("0x" .. color_value_b) * position + 0.5)
    return string.format("%02X", interpolated_value)
end

---Get a color between two colors
---@param start_color string @ The starting color in hex format. e.g. "#FFFFFF"
---@param end_color string @ The ending color in hex format. e.g. "#000000"
---@param position number @ The position between the two colors (0-1)
local function calculate_color_between(start_color, end_color, position)
    local red_component = calculate_interpolation(string.sub(start_color, 2, 3), string.sub(end_color, 2, 3), position)
    local green_component = calculate_interpolation(string.sub(start_color, 4, 5), string.sub(end_color, 4, 5), position)
    local blue_component = calculate_interpolation(string.sub(start_color, 6, 7), string.sub(end_color, 6, 7), position)
    return "#" .. red_component .. green_component .. blue_component
end

---Get a color from a gradient of colors
---@param position number @ The position within the gradient (0-1)
---@param ... string @ Colors in hex format
---@return string|nil @ Hex color value
function M.get_color(position, ...)
    local colors = {...}
    local num_colors = #colors
    if num_colors == 0 then
        vim.notify("No colors provided", vim.log.levels.ERROR)
        return
    elseif num_colors == 1 then
        return colors[1]
    elseif num_colors == 2 then
        return calculate_color_between(colors[1], colors[2], position)
    else
        local section = math.floor((num_colors - 1) * position)
        local remainder = (num_colors - 1) * position - section
        return calculate_color_between(colors[section + 1], colors[section + 2], remainder)
    end
end

--- Generate a gradient table of colors
---@param steps number @ Number of steps in the gradient
---@param ... string @ Colors in hex format
---@return table @ Table of colors
function M.get(steps, ...)
    local gradient_colors = {}

    local n = 1 / steps
    for i = 0, 1, n do
        table.insert(gradient_colors, M.get_color(i, ...))
    end

    return gradient_colors
end

return M
