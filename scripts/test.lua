-- tests/test_gradient.lua
local gradient = require("gradient")

local PASSED = 0
local FAILED = 0
local tests = {}

local function assert_eq(actual, expected, msg)
	if type(actual) == "table" and type(expected) == "table" then
		if #actual ~= #expected then
			error(string.format("%s\nExpected length %d, got %d", msg or "", #expected, #actual))
		end
		for i = 1, #actual do
			if actual[i] ~= expected[i] then
				error(
					string.format(
						"%s\nAt index %d: expected %s, got %s",
						msg or "",
						i,
						tostring(expected[i]),
						tostring(actual[i])
					)
				)
			end
		end
	elseif actual ~= expected then
		error(string.format("%s\nExpected: %s\nGot: %s", msg or "", tostring(expected), tostring(actual)))
	end
end

local function test(name, fn)
	tests[#tests + 1] = { name = name, fn = fn }
end

local function run_tests()
	print(string.format("\n🧪 Running %d tests...\n", #tests))

	for _, t in ipairs(tests) do
		local success, err = pcall(t.fn)
		if success then
			PASSED = PASSED + 1
			print(string.format("✅ %s", t.name))
		else
			FAILED = FAILED + 1
			print(string.format("❌ %s", t.name))
			print(string.format("   Error: %s", err))
		end
	end

	print(string.format("\n%s %d passed, %d failed\n", FAILED == 0 and "✅" or "❌", PASSED, FAILED))
	return FAILED == 0
end

-- Tests

test("from_stops: basic 2-color gradient", function()
	local colors, err = gradient.from_stops(5, "#000000", "#FFFFFF")
	assert_eq(err, nil, "Should not error")
	assert_eq(#colors, 5, "Should generate 5 colors")
	assert_eq(colors[1], "#000000", "First color should be black")
	assert_eq(colors[5], "#FFFFFF", "Last color should be white")
end)

test("from_stops: 3-color gradient", function()
	local colors = gradient.from_stops(7, "#000000", "#FF0000", "#FFFFFF")
	assert_eq(#colors, 7, "Should generate exactly 7 colors")
	assert_eq(colors[1], "#000000")
	assert_eq(colors[7], "#FFFFFF")
end)

test("from_stops: single color", function()
	local colors = gradient.from_stops(5, "#FF0000")
	assert_eq(#colors, 5)
	for i = 1, 5 do
		assert_eq(colors[i], "#FF0000", "All colors should be red")
	end
end)

test("from_stops: steps=1 with multiple colors (no division by zero)", function()
	local colors, err = gradient.from_stops(1, "#000000", "#FFFFFF")
	assert_eq(err, nil, "Should not error")
	assert_eq(#colors, 1, "Should generate exactly 1 color")
	assert_eq(colors[1], "#000000", "Should return first color stop")
end)

test("from_stops_eased: steps=1 with multiple colors (no division by zero)", function()
	local colors, err = gradient.from_stops_eased(1, "ease-in", "#000000", "#FF0000", "#FFFFFF")
	assert_eq(err, nil, "Should not error")
	assert_eq(#colors, 1, "Should generate exactly 1 color")
	assert_eq(colors[1], "#000000", "Should return first color stop")
end)

test("from_stops: invalid steps", function()
	local colors, err = gradient.from_stops(0, "#000000", "#FFFFFF")
	assert_eq(colors, nil)
	assert_eq(type(err), "string")

	colors, err = gradient.from_stops(-5, "#000000", "#FFFFFF")
	assert_eq(colors, nil)

	colors, err = gradient.from_stops(2.5, "#000000", "#FFFFFF")
	assert_eq(colors, nil)
end)

test("from_stops: invalid hex colors", function()
	local colors, err = gradient.from_stops(5, "#ZZZZZZ", "#FFFFFF")
	assert_eq(colors, nil)
	assert_eq(type(err), "string")

	colors, err = gradient.from_stops(5, "#FFF", "#FFFFFF")
	assert_eq(colors, nil)

	colors, err = gradient.from_stops(5, "not-a-color", "#FFFFFF")
	assert_eq(colors, nil)
end)

test("pick_color_between: basic interpolation", function()
	local color = gradient.pick_color_between(0.5, "#000000", "#FFFFFF")
	assert_eq(type(color.to_string), "function")
	local hex = color:to_string()
	assert_eq(hex, "#808080", "Midpoint should be gray")
end)

test("pick_color_between: edge cases", function()
	local color = gradient.pick_color_between(0, "#000000", "#FFFFFF")
	assert_eq(color:to_string(), "#000000")

	color = gradient.pick_color_between(1, "#000000", "#FFFFFF")
	assert_eq(color:to_string(), "#FFFFFF")
end)

test("pick_color_between: invalid position", function()
	local color, err = gradient.pick_color_between(-0.1, "#000000", "#FFFFFF")
	assert_eq(color, nil)
	assert_eq(type(err), "string")

	color, err = gradient.pick_color_between(1.1, "#000000", "#FFFFFF")
	assert_eq(color, nil)
end)

test("pick_color_from_pos: multiple stops", function()
	local color = gradient.pick_color_from_pos(0.5, "#000000", "#FF0000", "#FFFFFF")
	assert_eq(type(color), "string")
	assert_eq(color:sub(1, 1), "#")
end)

test("pick_color_from_pos: single color", function()
	local color = gradient.pick_color_from_pos(0.5, "#FF0000")
	assert_eq(color, "#FF0000")
end)

test("from_stops_eased: ease-in", function()
	local colors = gradient.from_stops_eased(5, "ease-in", "#000000", "#FFFFFF")
	assert_eq(#colors, 5)
	assert_eq(colors[1], "#000000")
	assert_eq(colors[5], "#FFFFFF")
end)

test("from_stops_eased: ease-out", function()
	local colors = gradient.from_stops_eased(5, "ease-out", "#000000", "#FFFFFF")
	assert_eq(#colors, 5)
end)

test("from_stops_eased: custom function", function()
	local colors = gradient.from_stops_eased(5, function(t)
		return t * t
	end, "#000000", "#FFFFFF")
	assert_eq(#colors, 5)
end)

test("from_stops_eased: invalid easing", function()
	local colors, err = gradient.from_stops_eased(5, "invalid-easing", "#000000", "#FFFFFF")
	assert_eq(colors, nil)
	assert_eq(type(err), "string")
end)

test("reverse: basic", function()
	local colors = { "#000000", "#808080", "#FFFFFF" }
	local reversed = gradient.reverse(colors)
	assert_eq(reversed, { "#FFFFFF", "#808080", "#000000" })
end)

test("info: basic", function()
	local colors = { "#000000", "#808080", "#FFFFFF" }
	local info = gradient.info(colors)
	assert_eq(info.length, 3)
	assert_eq(info.start, "#000000")
	assert_eq(info.finish, "#FFFFFF")
end)

-- Run tests
local all_passed = run_tests()

if all_passed then
	print("✅ All tests passed!\n")
else
	print("❌ Some tests failed\n")
	os.exit(1)
end
