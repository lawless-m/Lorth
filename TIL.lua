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
		
	return setmetatable(stack, {__tostring = 
		function()
			local str = ""
			local i
			for i = 1,stack.n do
				str = str .. i .. ":" .. tostring(stack[i]) .. "\n"
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


-------------------------
--- DEBUGGIUNG

	
function locate_fn(cpu, addr)
	if addr == nil then
		return nil, nil
	end
	local dict = cpu.dict
	local nfa = dict.entry
	while nfa > 0 do
		if dict[nfa+4] == addr then
			return dict[nfa], dict[nfa+1]
		end
		nfa = dict[nfa_to_lfa(nfa)]
	end
end
	

----------

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
		function(vocab, word, fntxt)
			local nfa, cfa, pfa = dict.header(vocab, word)
			dict[cfa] = pfa -- cell with the function pointer to execute
			fn = load("cpu=...;" .. fntxt)
			if fn == nil then
				print(fntxt)
				error("Compile failed")
			end
			dict[pfa] = fn
			--dict[pfa+1] = fntxt
			dict.n = pfa + 1
			dict.entry = nfa
			return nfa
		end
		
	dict.secondary =
		function(vocab, word, words)
			local nfa, cfa, pfa = dict.header(vocab, word)
			dict[cfa] = dict.ca(vocab, "colon")
			dict.n = pfa
			for i = 1,#words do
				dict.push(words[i])
			end
			dict.push(dict.cfa("context", "(semi)"))
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
		
	dict.ca = function(vocab, k) return dict[dict.cfa(vocab, k)]	end
		
	dict.forget =
		function()
			local p = dict.n
			dict.n = dict.entry
			dict.entry = dict[nfa_to_lfa[dict.entry]]
			for i = p,dict.n,-1 do
				dict[i] = "DEAFBEEF" -- should be nil but sentinel better
			end
		end
		
	dict.vocabulary = function(pfa) return dict[pfa_to_nfa(pfa) + 1] end
	
	dict.word = function(pfa) return dict[pfa_to_nfa(pfa)] end
	
	dict.vocab_word =
		function(pfa)
			local v = dict.vocabulary(pfa)
			if v == nil then return nil end
			local w = dict.word(pfa)
			if w == nil then return nil end
			return {v, w}
		end
		
	dict.word_totable =
		function(prev_nfa)
			return {
				
				word = dict[nfa],
				vocab = dict[nfa+1],
				lfa = dict[nfa_to_lfa(nfa)],
				cf = 0
			}
		end
		
	--[[setmetatable(dict, {__tostring=
		function() 
		
		return "HEY" 
		
		end})
		]]--
		
	return dict
end

Cpu = function()
	cpu = {
		thread = nil,
		i = 0,
		cfa = 0,
		pad = "",
		DS = Stack(),
		RS = Stack(),
		JS = Stack(),
		dict = Dict(),
		mode = false,
		state = false,
		vocabulary = "context",
	}
	
	cpu.run = 
		function()
			local cp = cpu.dict[cpu.cfa] -- cell containing function to run
			if cp == nil then
				return nil
			end
			cpu.cfa = cpu.cfa + 1
			return cpu.dict[cp] -- should be a function
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
			cpu.dict.n = cpu.dict.n + n
			return a
		end
	
	cpu.inner =
		function()
			local n, f
			local d_w, d_v
			fns = {}
			fns[cpu.run] = "run"
			fns[cpu.next] = "next"
			fns[cpu.execute] = "execute"
			fns[cpu.semi] = "semi"
			printfn = function(fa)
					if fns[fa] == nil then
						d_w, d_v = locate_fn(cpu, fa)
						print(fa, d_v .. "/" .. d_w)
					else
						print(fa, fns[fa])
					end
				end
			while cpu.i ~= "exit" do
				if cpu.pad ~= "" then
					n = cpu.dict.n
					f = cpu.next
					while type(f) == "function" do
						f = f(cpu)
					end
					if cpu.pad ~= "" then
						cpu.dict.n = n
					end
				end
				coroutine.yield()
			end
		end
			
	cpu.input =
		function(input)
			cpu.dict[-100] = cpu.dict.cfa("context", "outer")
			cpu.dict[-99] = nil
			cpu.i = -100
			cpu.pad = cpu.pad .. " " .. input
			coroutine.resume(cpu.thread)
			cpu.dict[-100] = nil
			cpu.dict[-99] = nil
			
		end
		
	return cpu
end

function tokenize_string(rawtext)
	local qot = string.find(rawtext, "\"", 1, true)
	if qot == nil then
		return rawtext, ""
	end
	local eot = string.find(rawtext, "\\", 1, true)
	if eot == nil or qot < eot then -- normal tokenize
		eot = string.find(rawtext, "\"", 1, true) - 1
		return string.sub(rawtext, 1, eot), string.sub(rawtext, eot+2)
	end
	
	local out = string.sub(rawtext, 1, eot-1) .. string.sub(rawtext, eot+1, eot+1)
	t = tokenize_string(string.sub(rawtext, eot+2))
	return out .. t[1], t[2]
end

function tokenize(terminator, rawtext) 
	-- split at the terminator, return text before the terminator and text after the terminator stops repeating (e.g. ("-", "ab--cd-") returns {"ab", "cd-"}
	
	-- if terminator is a quote do a special routine to crack out \" into a quote
	if terminator == "\"" then return tokenize_string(rawtext) end
	
	if rawtext == "" or terminator == "" then return nil end
	
	local pfx = 1
	local eot = 1

	while eot ~= nil and eot <= pfx do
		eot = string.find(rawtext, terminator, pfx, true) -- plain text search from start of string
		pfx = pfx + 1
	end
	if eot == nil then
		return string.sub(rawtext, pfx-1), ""
	end
	eot = eot - 1
	local sot = eot + 2
	while string.sub(rawtext, sot, sot) == terminator do sot = sot + 1 end
	return string.sub(rawtext, pfx, eot), string.sub(rawtext, sot)
end


function bootstrap(dict)
	local cfa = function(w) return dict.cfa("context", w) end
	
	dict.primary(
		"context",
		"DUMP", -- print out the dictionary
		[[
			--print(cpu.dict)
			print("DUMP DICT")
			return cpu.next
		]]
	)
	
	
	dict.primary(
		"context",
		"DUMS", -- print out the dictionary
		[[
			print(cpu.DS)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"colon", -- /* execute a wordlist */
		[[
			cpu.RS.push(cpu.i)
			cpu.i = cpu.cfa
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"(semi)", -- /* ( -- ) execute semi */
		[[
			return cpu.semi
		]]
	)

	dict.primary(
		"compile", 
		";",  --  /* ( -- ) finish the definition of a word */
		[[
			cpu.dict[cpu.dict.pointer] = cpu.dict.cfa(cpu.vocabulary, "(semi)")
			cpu.dict.pointer = cpu.dict.pointer + 1
			cpu.mode = false
			return cpu.next
		]]
	)
		
	dict.primary( --  /* ( -- wa("(value)") )  lookup the word address of (value) for postpone */
		"compile", 
		"`value",
		[[
			local v = cpu.dict.cfa("context", "(value)")
			cpu.dict.push(v)
			cpu.dict.push(v)
			return cpu.next
		]]
	)

	
	dict.primary(
		"context",
		"//", --  /* ( -- ) store the pad in the dictionary */
		[[
			cpu.dict.push("// " .. cpu.pad)
			cpu.pad = ""
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"t", -- /* ( -- true ) */
		[[
			cpu.DS.push(true)
			return cpu.next
		]]
	)
	
	
	dict.primary(
		"context",
		"f", -- /* ( -- false ) */
		[[
			cpu.DS.push(false)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"=", -- /* ( b a - (b == a) ) equality */
		[[
			cpu.DS.push(cpu.DS.pop() == cpu.DS.pop())
			return cpu.next
		]]
	
	)
	
	dict.primary(
		"context",
		"here", -- /* ( - DP )  push dictionary pointer */
		[[
			cpu.DS.push(cpu.DS.n)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"there", -- /* (NEWDP - ) pop to the dictionary pointer */
		[[
			cpu.DS.n = (cpu.DS.pop())
			return cpu.next
		]]
	)

	dict.primary(
		"context",
		"dup", -- /* ( a -- a a ) duplicate the tos */
		[[
			cpu.DS.push(cpu.DS.top())
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"tuck", -- /* ( b a -- a b a ) copy tos to 3rd place, could just be : tuck swap over ; */
		[[
			local a = cpu.DS.pop()
			local b = cpu.DS.pop()
			cpu.DS.push(a)
			cpu.DS.push(b)
			cpu.DS.push(a)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"context", -- /* ( -- "context" ) push "context" */
		[[
			cpu.DS.push("context")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"compile", -- /* ( -- "compile" ) push "compile" */
		[[
			cpu.DS.push("compile")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"execute", -- /* ( -- wa ) run the word with its address on the tos */
		[[
			cpu.cfa = cpu.DS.pop()
			return cpu.run
		]]
	)
	
	dict.primary(
		"context",
		"token", -- /* ( token -- ) extract everything in cpu.pad until the terminator, and put it in the dictionary */
		[[
			cpu.token, cpu.pad = tokenize(cpu.DS.pop(), cpu.pad)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"token?", -- /* ( token -- ( true | false ) ) extract everything in cpu.pad until the terminator, put it in the dictionary and report if you found anything */
		[[
			local term = cpu.DS.pop()
			if cpu.pad == "" then
				cpu.DS.push(false)
				return cpu.next
			end
			cpu.token, cpu.pad = tokenize(term, cpu.pad)
			cpu.DS.push(true)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<token", -- push the token to the DS
		[[
			cpu.DS.push(cpu.token)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"(value)", --  /* ( -- n ) push the contents of the next cell */
		[[
			cpu.DS.push(cpu.dict[cpu.i])
			cpu.i = cpu.i + 1
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		",", -- /* ( val -- ) store tos in the next cell */
		[[
			cpu.dict.push(cpu.DS.pop())
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"drop", -- /* ( a -- ) drop the tos */
		[[
			cpu.DS.pop()
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"ca", -- /* ( "word" -- ca|undefined ) push code address or nil on tos */
		[[
			cpu.DS.push(cpu.dict.ca(cpu.vocabulary, cpu.DS.pop()))
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"search", -- /* ( -- (false wa) | true ) search the dictionary for "word" push the wa and a flag for (not found) */
		[[
			local wa = cpu.dict.cfa(cpu.vocabulary, cpu.token)
			if wa then
				cpu.DS.push(wa)
				cpu.DS.push(false)
			else
				cpu.DS.push(true)
			end
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<mode", -- /* ( -- mode ) push the current mode */
		[[
			cpu.DS.push(cpu.mode)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		">mode", --  /* ( mode -- ) set the current mode */
		[[
			cpu.mode = (cpu.DS.pop() == true)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<state", -- /* ( -- state ) push the current state */
		[[
			cpu.DS.push(cpu.state)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		">state", -- /* ( state -- ) set the current state */
		[[
			cpu.state = (cpu.DS.pop() == true)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		">vocabulary", -- /* ( vocabulary -- ) set the current vocabulary */
		[[
			cpu.vocabulary = cpu.DS.pop()
			return cpu.next		
		]]
	)
	
	dict.primary(
		"context",
		"not", -- /* ( v -- !v ) clean boolean not */
		[[
			if cpu.DS.pop() then
				cpu.DS.push(false)
			else
				cpu.DS.push(true)
			end
		]]
	)
	
	dict.primary(
		"context",
		">entry", -- /* ( -- ) write to cpu.dict.entry */
		[[
			cpu.dict.entry = cpu.DS.pop()
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<entry", --/* ( -- daddr ) push cpu.dict.entry  */
		[[
			cpu.DS.push(cpu.dict.entry)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"cfa", -- /* ( NFA -- CFA) push Code Field Address for the given Name Field Address , just arithmetic */
		[[
			cpu.DS.push(nfa_to_cfa(cpu.DS.pop()))
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"dp++", --  /* ( -- ) increment the dictionary pointer */
		[[
			cpu.dict.n = cpu.dict.n + 1
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"?number", -- /* ( -- flag (maybe value) ) depending on the mode, push a flag and the value or store it in the dictionary */
		[[
			local n = tonumber(cpu.token)
			
			if n == nil then
				cpu.DS.push(true)
				return cpu.next
			end
			
			if cpu.mode then
				cpu.dict.push(cpu.dict.cfa(cpu.vocabulary, "(value)"))
				cpu.dict.push(n)
			else
				cpu.DS.push(n)
			end
			cpu.DS.push(false)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"tokenerror", --  { /* ( -- ) report an unrecognised word error */
		[[
			io.stderr.write(">>" .. cpu.token .. "<< error, unrecognised word (inside the >><<)")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"spc", --  /* ( -- " " ) push a space character */
		[[
			cpu.DS.push(" ")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		",vocab", -- /* ( -- ) store the current vocabulary in the dictionary */
		[[
			cpu.dict.push(cpu.vocabulary)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"(if!rjmp)", --  /* ( flag -- ) if flag is false, jump by the delta in next cell, or just skip over */
		[[
			if cpu.DS.pop() then
				cpu.i = cpu.i + 1
			else
				cpu.i = cpu.i + cpu.dict[cpu.i]
			end
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"(rjmp)", -- /* ( -- ) unconditional jump by the delta in the next cell */
		[[
			cpu.i = cpu.i + cpu.dict[cpu.i]
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<cfa*", -- /* push the currrent value of cpu.cfa and exit (points to PFA in create)  */
		[[
			cpu.DS.push(cpu.cfa)
			return cpu.semi
		]]
	)
	
	dict.secondary(
		"context",
		"?search", --  /*  ( -- flag ) search the dictionaries for the word in the pad flag is not found */
		{
			cfa("search"), 
			cfa("dup"), 
			cfa("(if!rjmp)"), 
			17, 
				cfa("<mode"), 
				cfa("(if!rjmp)"), 
				14, 
					cfa("drop"), 
					cfa("compile"), 
					cfa(">vocabulary"), 
					cfa("search"), 
					cfa("context"), 
					cfa(">vocabulary"), 
					cfa("dup"), 
					cfa("not"), 
					cfa("(if!rjmp)"), 
					4, 
						cfa("(value)"),
						true,
						cfa(">state"),
		}
	)
	
	dict.secondary(
		"context",
		"?execute", -- /* ( -- ) execute the word if it's immediate (i think)  */
		{
			cfa("<state"),
			cfa("<mode"),
			cfa("(value)"),
			false,
			cfa(">state"),
			cfa("="),
			cfa("(if!rjmp)"),
			4,
				cfa("execute"),
				cfa("(rjmp)"),
				2,
			cfa(","),		
		}
	)
	
	dict.secondary(
		"context",
		"<word", -- /* read space delimeted word from the pad */
		{
			cfa("spc"),
			cfa("token"),
			cfa("<token"),
		}
	)
	
	dict.secondary(
		"context",
		"create", -- /* ( -- ) create a dictionary entry for the next word in the pad */
		{
			cfa("<entry"),
			cfa("here"),
			cfa(">entry"),
			cfa("<word"),
			cfa(","),
			cfa(",vocab"),
			cfa(","),
			cfa("(value)"),
			"<cfa*",
			cfa("ca"),
			cfa(","),
		}
	)
	
	dict.secondary(
		"context",
		"outer", -- /* ( -- ) tokenize the pad and do whatever it says */
		{
			cfa("spc"),
			cfa("token?"),
			cfa("(if!rjmp)"),
			13,
				cfa("?search"),
				cfa("(if!rjmp)"),
				7,
					cfa("?number"),
					cfa("(if!rjmp)"),
					5,
						cfa("tokenerror"),
						cfa("(rjmp)"),
						4,
					cfa("?execute"),
					cfa("(rjmp)")
					-15,
		}
	)
	
	dict.secondary(
		"context",
		":", -- /* ( -- ) create a word entry */
		{
			cfa("(value)"),
			"colon",
			cfa("create"),
			cfa("<entry"),
			cfa("cfa"),
			cfa("there"),
			cfa("ca"),
			cfa(","),
			cfa("t"),
			cfa(">mode"),
		}
	)
	
	
	dict.secondary(
		"context",
		"does>", -- /* ( -- ) fill dictionary with runtime info */
		{
			cfa("(value)"),
			"(does>)",
			cfa("<entry"),
			cfa("cfa"),
			cfa("there"),
			cfa("ca"),
			cfa(","),
			cfa("dp++"),
			cfa("t"),
			cfa(">mode"),
		}
	)
	
	-- now we should be able to just parse raw text
end

function write_dict(dict, fn)
	fid = io.open(fn, "w+")
	fid:write(tostring(dict))
	fid:close()
end


Cpus = {}

Spawn = function()
	Cpus[#Cpus+1] = Cpu()
	bootstrap(Cpus[#Cpus].dict)
	write_dict(Cpus[#Cpus].dict, "def.dict.txt")
	Cpus[#Cpus].thread = coroutine.create(Cpus[#Cpus].inner)
	return #Cpus
end

