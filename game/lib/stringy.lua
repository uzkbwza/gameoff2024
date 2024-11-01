local stringy = setmetatable({}, {__index = string})

function stringy.endswith(s, e)
	local result = string.match(s, e.."$")
  return result ~= nil
end

function stringy.strip_whitespace(s)
	local result = string.gsub(s, "^%s*(.-)%s*$", "%1")
	return result
end

function stringy.split(string, substr)
	if substr == nil then
		substr = "%s"
	end
	local t = {}
	for str in string.gmatch(string, "([^"..substr.."]+)") do
		table.insert(t, str)
	end
	return t
end

function stringy.join(t, separator)
	local stringy = ""
	local len = #t
	for i, v in ipairs(t) do
		stringy = stringy..v
		if i < len then
			stringy = stringy..separator
		end
	end
end

return stringy
