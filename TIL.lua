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
	local dict = Dict()
	local DS = Stack()
	local RS = Stack()
	
	cpu = {i=0; cfa=0}
	cpu.run = 
		function()
			local p = dict[cpu.cfa]
			cfa = cfa + 1
			return p
		end
	cpu.next = 
		function()
			cfa = dict[i]
			i = i + 1
			return cpu.run
		end
	cpu.semi = 
		function()
			i = RS.pop()
			return cpu.next
		end
	cpu.execute =
		function(wa)
			local ca = dict[wa]
			local f = dict[ca]
			if type(f) == "function" then
				f()
			end
		end
	cpu.allot = 
		function(n)
			local a = dict.n
			dict.n += n
			return a
		end
	return cpu
end
