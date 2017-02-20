-- Simple Stack

function Stack()
	local stack = {n=0}
	stack.trunc = 
		function(i) 
			local k
			if i then 
				for k = stack.n,i,-1 do
					stack[k] = nil
				end
				stack.n = i-1
			end
		end
	stack.top = 
		function()
			local v
			if stack.n > 0 then
				v = stack[stack.n]
			else
				-- UNDERFLOW warn("Stack underflow")
				v = nil
			end
			return v
		end

	stack.push = 
		function(v)
			stack.n = stack.n + 1
			stack[stack.n] = v
		end
	stack.pop = 
		function()
			if n > 0 then
				local v = stack[n]
				stack[stack.n] = nil
				stack.n = stack.n - 1
				return v
			end
			-- WARN UNDERFLOW
			return nil	
		end
	
	return setmetatable(stack, {"__tostring" = 
		function()
			local str = ""
			local i
			for i = 1,stack.n do
				str = str .. i .. ":" .. stack[i] .. "\n"
			end
			return str		
		end
		})

end

Word = function()
	local word = {
		name = "",
		vocab = "",
		code = nil
		data = Stack()
	}
	return word
end

Dict = function()
	local words = Stack()
	local dict = {here=0}
	dict.find = 
		function(t)
			for i = words.n,1,-1
				if words[i] and words[i].name == then
					return i
				end
			end
			return nil
		end
	dict.add = function(w) words.push(w); dict.here = words.n; end
	dict.drop = function(w) words.trunc(dict.find(w)); dict.here = words.n end
	
	return dict
end

Cpu = function()
	cpu = {i=0; cfa=0; pad=""; DS=Stack(); RS=Stack(); dict=Dict()}
	cpu.run = 
		function()
			local p = cpu.dict[cpu.cfa]
			cpu.cfa = cpu.cfa + 1
			return p
		end
	cpu.next = 
		function()
			cpu.cfa = cpu.dict[cpu.i]
			cpu.i = cpu.i + 1
			return cpu.run
		end
	cpu.semi = 
		function()
			cpu.i = cpu.RS.pop()
			return cpu.next
		end
	cpu.execute =
		function(wa)
			local ca = cpu.dict[wa]
			local f = cpu.dict[ca]
			if type(f) == "function" then
				f()
			end
		end
	cpu.allot = 
		function(n)
			local a = cpu.dict.n
			cpu.dict.n += n
			return a
		end
	return cpu
	
	cpu.inner =
		function(pointer, input)
			local n = cpu.dict.n
			cpu.pad = input
			cpu.i = pointer
			local f = cpu.next
			while type(f) == "function" do
				f = f(cpu)
			end
			if cpu.pad != "" then
				cpu.dict.n = n
			end
			return cpu.pad
		end
			
	cpu.parse =
		function(input)
			cpu.dict[-100] = cpu.dict.cfa(cpu.vocabulary, "outer")
			cpu.dict[-99] = nil
			cpu.inner(-100, input)
			cpu.dict[-100] = nil
			cpu.dict[-99] = nil
		end
end

function tokenize_string(rawtext)
	local qot = string.find(rawtext, "\"", 1, true)
	if qot == nil then
		return {rawtext, ""}
	end
	local eot = string.find(rawtext, "\\", 1, true)
	if eot == nil or qot < eot then -- normal tokenize
		eot = string.find(rawtext, "\"", 1, true) - 1
		return {string.sub(rawtext, 1, eot), string.sub(rawtext, eot+2)}
	end
	
	local out = string.sub(rawtext, 1, eot-1) .. string.sub(rawtext, eot+1, eot+1)
	t = tokenize_string(string.sub(rawtext, eot+2))
	return {out .. t[1], t[2]}
end

function tokenize(terminator, rawtext) 
	-- split at the terminator, return text before the terminator and text after the terminator stops repeating (e.g. ("-", "ab--cd-") returns {"ab", "cd-"}

	-- if terminator is a quote do a special routine
	if terminator == "\"" then return tokenize_string(rawtext) end
	
	-- should work on returning just the slice integers not the strings
	
	if rawtext == "" or terminator == "" then return nil end
	
	local eot = string.find(rawtext, terminator, 1, true) -1 -- plain text search from start of string
	
	local sot = eot + 2
	while string.sub(rawtext, sot, sot) == terminator do sot = sot + 1 end
	return {string.sub(rawtext, 1, eot), string.sub(rawtext, sot)}
end