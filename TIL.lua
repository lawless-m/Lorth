-- Simple List

List = function()
	local list = {n=0}
	list["append"] = function(v) list.n = list.n+1; list[list.n] = v; end
	list["tostring"] = 
		function()
			local str = ""
			for i = 1,list.n do
				str = str .. i .. ":" .. list[i] .. "\n"
			end
			return str
		end
	end

-- STACKS
-- ok we will need stacks, here we go

Stack = function()
	local stk = List()
	stk["top"] = 
		function()
			local v
			if stk.n > 0 then
				v = stk[stk.n]
			else
				warn("Stack underflow")
				v = nil
			end
			return v
		end

	stk["pop"] = 
		function()
			local v = stk.top()
			if stk.n > 0 then
				stk[stk.n] = nil
				stk.n = stk.n - 1
			end
			return v
		end

	stk["push"] = 
		function(v) 
			stk.append(v)
		end

	return stk
end

Word = function()
	local word = {
		name = "",
		vocab = "",
		code = nil
		data = List()
	}
	return word
end

Dict = function()
	local dict = {
		words = List()
	}
	dict["find"] = 
		function(t)
			for i = dict.words.n,-1,1
				if dict.words.name == then
					return i
				end
			end
			return nil
		end
	return dict
end

DS = newStack()
RS = newStack()

