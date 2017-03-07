
Stack = function(nm)
	if nm == nil then
		nm = ""
	end
	local stack = {n=1, name=nm} -- n next position to write to
	stack.trunc = 
		function(i) 
			local k
			if i then 
				while stack.n > i do
					stack[stack.n] = nil
					stack.n = stack.n -1
				end
			end
		end
	stack.top = 
		function()
			local v
			if stack.n > 1 then
				v = stack[stack.n]
			else
				warn("TOP: Stack underflow, " .. stack.name)
				v = nil
			end
			return v
		end

	stack.push = 
		function(v)
			stack[stack.n] = v
			stack.n = stack.n + 1
		end
	stack.pop = 
		function()
			local v
			if stack.n > 1 then
				stack.n = stack.n - 1
				v = stack[stack.n]
				stack[stack.n] = nil
			else
				v = nil
			end
			return v
		end
		
	stack.stringify = 
		function()
			local str = "Stack " .. stack.name .. "\n"
			local i
			for i = 1,#stack do
				if type(stack[i]) == "string" then
					str = str .. " " .. i .. ":\"" .. tostring(stack[i]) .. "\"\n"
				else
					str = str .. " " .. i .. ":" .. tostring(stack[i]) .. "\n"
				end
			end
			return str		
		end
		
	return setmetatable(stack, {__tostring = stack.stringify})

end
