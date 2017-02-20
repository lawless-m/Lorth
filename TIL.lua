-- Simple Stack

Stack = function()
	local stack = {n=1} -- n next position to write to
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
				-- UNDERFLOW warn("Stack underflow")
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
			if stack.n > 1 then
				stack.n = stack.n - 1
				local v = stack[stack.n]
				stack[stack.n] = nil
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

--[[

DICT LAYOUT
NFA:   Name Field Address
VOCAB: Vocabulary the word is in
LFA:   Link Field Address (the previous entry's NFA)
CFA:   Contains address of the Javascript code to run
PFA:   Parameter Field Address - the data for this word

NFA:   [NFA + 0]   = $WORD					Name Field Address
VOCAB: [NFA + 1]   = $VOCABULARY
LFA:   [NFA + 2]   = %PREVIOUS_ADDRESS		Link Field Address

IF PRIMARY
CFA:   [NFA + 3]   = CODE ADDRESS			Code Field Address
PFA:   [NFA + 4]   = JS_FUNCTION			Parameter Field Address

IF SECONDARY
CFA:   [NFA + 3]   = CODE ADDRESS OF "colon" Code Field Address
PFA:   [NFA + 4]   = WORD_ADDRESS			 Parameter Field Address
	   [NFA + ...] = WORD_ADDRESS
	   [NFA + N]   = WORD_ADDRESS OF "semi"
]]--

lfa_offset = 2
header_size = 3 -- offset to the first cell after the header 

nfa_to_lfa = function(n)  return n + lfa_offset end
nfa_to_vocab = function(n)  return n + 1 end
nfa_to_cfa = function(n)  return n + header_size end
nfa_to_pfa = function(n)  return n + header_size + 1 end

lfa_to_nfa = function(n)  return n - lfa_offset end
lfa_to_cfa = function(n)  return n + 1 end
lfa_to_pfa = function(n)  return n + 2 end

cfa_to_nfa = function(n)  return n - header_size end
cfa_to_lfa = function(n)  return n - 1 end
cfa_to_pfa = function(n)  return n + 1 end

pfa_to_cfa = function(n)  return n - 1 end
pfa_to_lfa = function(n)  return n - 2 end
pfa_to_vocab = function(n)  return n - header_size end
pfa_to_nfa = function(n)  return n - (header_size + 1) end

Dict = function()
	local dict = Stack()
	dict.entry = 0

	dict.header =
		function(vocab, word)
			local nfa = dict.n
			dict[nfa] = word
			dict[nfa+1] = vocab
			dict[nfa_to_lfa(nfa)] = dict.entry
			return nfa, nfa_to_cfa(nfa), nfa_to_pfa(nfa)
		end

	dict.primary =
		function(vocab, word, fn)
			local nfa, cfa, pfa = dict.header(vocab, word)
			dict[cfa] = pfa
			dict[pfa] = fn
			dict.n = pfa + 1
			dict.entry = nfa
			return nfa
		end
		
	dict.secondary =
		function(vocab, word, words)
			local nfa, cfa, pfa = dict.header(vocab, word)
			dict[cfa] = dict.ca[vocab, 'colon']
			for i = 1,#body do
				dict.push(words[i])
			end
			dict.push('(semi)')
			dict.entry = nfa
			return nfa
		end
		
	dict.cfa = 
		function(vocab, k)
			local nfa = dict.entry
			while nfa do
				if dict[nfa] == k and dict[nfa + 1] == vocab then
					return nfa_to_cfa(nfa)
				end
				nfa = dict[nfa_to_lfa(nfa)]
			end
		end
		
	dict.ca = function(vocab, k) dict[dict.cfa(vocab, k)]	end
		
	dict.forget =
		function()
			local p = dict.n
			dict.n = dict.entry
			dict.entry = dict[nfa_to_lfa[dict.entry]]
			for i = p,dict.n,-1
				dict[i] = "DEAFBEEF" -- should be nil but sentinel better
			end
		end
		
	dict.vocabulary = function(pfa) dict[pfa_to_nfa(pfa) + 1) end
	
	dict.word = function(pfa) dict[pfa_to_nfa(pfa)) end
	
	dict.vocab_word =
		function(pfa)
			local v = dict.vocabulary(pfa)
			if v == nil then return nil end
			local w = dict.word(pfa)
			if w == nil then return nil end
			return {v, w}
		end
		
	return dict
end

Cpu = function()
	cpu = {
		i = 0
		cfa = 0
		pad = ""
		DS = Stack()
		RS = Stack()
		JS = Stack()
		dict = Dict()
		mode = false
		state = false
		vocabulary = "context"
	}
	
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

	-- if terminator is a quote do a special routine to crack out \" into a quote
	if terminator == "\"" then return tokenize_string(rawtext) end
	
	if rawtext == "" or terminator == "" then return nil end
	
	local eot = string.find(rawtext, terminator, 1, true) -1 -- plain text search from start of string
	
	local sot = eot + 2
	while string.sub(rawtext, sot, sot) == terminator do sot = sot + 1 end
	return {string.sub(rawtext, 1, eot), string.sub(rawtext, sot)}
end

function bootstrap(dict)
	dict.primary(
		"compile", 
		";",  --  /* ( -- ) finish the definition of a word */
		function(cpu)
			cpu.dict[cpu.dict.pointer] = cpu.dict.cfa(cpu.vocabulary, "(semi)")
			cpu.dict.pointer = cpu.dict.pointer + 1
			cpu.mode = false
			return cpu.next
		end
		)
	)
		
	dict.primary( --  /* ( -- wa("(value)") )  lookup the word address of (value) for postpone */
		"compile", 
		"`value",
		function(cpu)
			local v = cpu.dict.cfa("context", "(value)")
			cpu.dict.push(v)
			cpu.dict.push(v)
			return cpu.next
		end
		)
	)
	
	dict.primary(
		"context",
		"//", --  /* ( -- ) store the pad in the dictionary */
		function(cpu)
			cpu.dict.push("// " .. cpu.pad)
			cpu.pad = ""
			return cpu.next
		end
		)
	)
	
	dict.primary(
		"context",
		"t", -- /* ( -- true ) */
		function(cpu)
			cpu.DS.push(true)
			return cpu.next
		end
		)
	)
end