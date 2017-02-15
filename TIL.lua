-- STACKS
-- ok we will need stacks, here we go

newStack = function()
	local stk = {depth=0}
	stk["top"] = 
		function()
			local v
			if stk.depth > 0 then
				v = stk[stk.depth]
			else
				warn("Stack underflow")
				v = nil
			end
			return v
		end

	stk["pop"] = 
		function()
			local v = stk.top()
			if stk.depth > 0 then
				stk[stk.depth] = nil
				stk.depth = stk.depth - 1
			end
			return v
		end
	
	stk["push"] = 
		function(v) 
			stk.depth = stk.depth + 1; 
			stk[stk.depth] = v 
		end
	
	return stk
end

DS = newStack()
RS = newStack()

