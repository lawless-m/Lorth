
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
nfa_to_voa = function(n)  return n + 1 end
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
pfa_to_voa = function(n)  return n - header_size end
pfa_to_nfa = function(n)  return n - (header_size + 1) end

-- not just arithmetic, this walks the dict
function nfa_to_efa(dict, nfa)
	if type(nfa) ~= "number" then
		warn("NFA not a number")
		return
	end
	
	local efa = dict.n
	local k = dict.entry
	
	while k > 0 do
		if k == nfa then
			return efa - 1
		end
		k, efa = dict[nfa_to_lfa(k)], k
	end
end
	
function fn_to_nfa(dict, fn)
	if type(fn) ~= "function" then
		warn("fn not a function")
		return
	end
		
	local nfa = dict.entry
	local cfa
	while nfa > 0 do
		cfa = nfa_to_cfa(nfa)
		if fn == dict[dict[cfa]] then
			return nfa
		end
		nfa = dict[nfa_to_lfa(nfa)]
		if nfa == nil then nfa = 0 end
	end
	trace("fn not found")
end
	
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
	local dict = Stack("DICT")
	dict.entry = 0
	dict.dumpi = 0

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
			fn = load("trace(\"" .. vocab .. "/" .. word .. "\");" .. "cpu=...;" .. fntxt)
			if fn == nil then
				warn(fntxt)
				warn("Compile failed")
			end
			dict[pfa] = fn
			dict[pfa+1] = fntxt
			dict.n = pfa + 2
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
			while nfa > 0 do
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
		
	
	dict.stringify =
		function() 
			local s = "dict.entry: " .. dict.entry .. "\n"
			s = s .. "dict.n: " .. dict.n .. "\n"
			local nfa = dict.entry
			local efa = dict.n-1
		
			while nfa > 0 do
				local w = Word(dict, nfa, efa)
				if w then
					s = s .. tostring(w)
					efa, nfa = nfa-1, dict[w.lfa]
				end
			end

			return s
		
		end
		
	setmetatable(dict, {__tostring=dict.stringify})
	
	return dict
end
