local tabley = setmetatable({}, {__index = table})

function tabley.length (t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function tabley.push_back(t, value)
  table.insert(t, value)
end

function tabley.pop_back(t)
  return table.remove(t)
end

function tabley.push_front(t, value)
  table.insert(t, 1, value)
end

function tabley.pop_front(t)
  return table.remove(t, 1)
end

function tabley.push(t, value)
  table.insert(t, value)
end

function tabley.pop(t)
  return table.remove(t)
end

function tabley.is_empty(t)
	local next = next
	return next(t) == nil
end

function tabley.fast_remove_at(t, index)
	local length = #t
	t[index] = t[length]
	t[length] = nil
end

function tabley.fast_remove(t, fnKeep)
	if type(fnKeep) == "number" then return tabley.fast_remove_at(t, fnKeep) end 

	if tabley.is_empty(t) then return t end

    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;

end

return tabley

