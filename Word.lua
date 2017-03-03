

Word = function(dict, nfa, efa)
	print("NFA " .. tostring(nfa) .. " EFA " .. tostring(efa))
	if type(nfa) ~= "number" then
		return
	end
	
	if efa == nil then
		 efa = nfa_to_efa(dict, nfa)
	end

	if type(efa) ~= "number" then
		return
	end
	
	local word = {
		nfa = nfa,
		voa = nfa_to_voa(nfa),
		lfa = nfa_to_lfa(nfa),
		cfa = nfa_to_cfa(nfa),
		pfa = nfa_to_pfa(nfa),
		efa = efa,
	}
	
	if type(word.voa) ~= "number" or type(word.lfa) ~= "number" or type(word.cfa) ~= "number" or type(word.pfa) ~= "number" then
		return
	end
	
	word.label = dict[word.voa] .. " / " .. dict[word.nfa]
		
	setmetatable(word, {__tostring=
		function()
			s = "---------\n".. word.nfa .. " NFA " .. word.label .. "\n"	
			s = s .. word.lfa .. " LFA " .. tostring(dict[word.lfa]) .. "\n"	
			if type(dict[word.pfa]) == "function" then
				s = s .. word.cfa .. " CFA " .. tostring(dict[word.cfa]) .. "\n"	
				s = s .. word.pfa .. " PFA " .. tostring(dict[word.pfa]) .. "\n"
				s = s .. word.pfa+1 .. " LUA " .. tostring(dict[word.pfa+1]) .. "\n"
			else
				infa = pfa_to_nfa(dict[word.cfa])
				if type(infa) == "number" then
					ivoc = tostring(dict[nfa_to_voa(infa)])
					infa = tostring(dict[infa])
				end
				s = s .. word.cfa .. " CFA " .. tostring(dict[word.cfa]) .. " - " .. ivoc .. " / " .. infa .. "\n"	
				
				for j = word.pfa, word.efa do
					if pword == "context / (value)" or pword == "context / (if!rjmp)" or pword == "context / (rjmp)" then
						s = s .. j .. " P " .. tostring(dict[j]) .. "\n"	
						pword = nil
					elseif type(dict[j]) == "number" then
						icfa = dict[j]
						if type(icfa) == "number" then
							infa = cfa_to_nfa(icfa)
							ivoc = tostring(dict[nfa_to_voa(infa)])
							infa = tostring(dict[infa])
							pword = ivoc .. " / " .. infa
							s = s .. j .. " P " .. tostring(dict[j]) .. " - " .. pword .. "\n"	
						else
							s = s .. j .. " P " .. tostring(dict[j]) .. "\n"	
							pword = nil
						end
					else
						s = s .. j .. " P " .. tostring(dict[j]) .. "\n"	
						pword = nil
					end
					j = j + 1
				end
			end
			return s
		end
	})
	
	return word
end
