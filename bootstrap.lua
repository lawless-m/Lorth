

function bootstrap(dict)
	local cfa = function(w) return dict.cfa("context", w) end
	
	dict.primary(
		"context",
		"!!", -- first entry in the DICT, used for debugging
		[[
			warn("!!")
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
			cpu.dict[cpu.dict.n] = cpu.dict.cfa(cpu.vocabulary, "(semi)")
			cpu.dict.n = cpu.dict.n + 1
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
			cpu.DS.push(cpu.dict.n)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"there", -- /* (NEWDP - ) pop to the dictionary pointer */
		[[
			cpu.dict.n = cpu.DS.pop()
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
			local top = cpu.DS.pop()
			if top then
				cpu.DS.push(cpu.dict.ca(cpu.vocabulary, top))
			else
				cpu.DS.push(nil)
			end
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
			local nfa = cpu.DS.pop()
			local cfa = nfa_to_cfa(nfa)
			cpu.DS.push(cfa)
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
			warn(">>" .. cpu.token .. "<< error, unrecognised word (inside the >><<)")
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
		"<cfa*", -- /* push the currrent value of cpu.cfa and exit (points to PFA in create) 		*/
		[[
			cpu.DS.push(cpu.cfa)
			return cpu.semi
		]]
	)
	
	dict.secondary(
		"context",
		"X?search", --  /*  ( -- flag ) search the dictionaries for the word in the pad flag is not found */
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
	
	dict.primary(
		"context",
		"?search",
		[[
			local wa = cpu.dict.cfa(cpu.vocabulary, cpu.token)
			if wa then
				cpu.DS.push(wa)
				cpu.DS.push(false)
				return cpu.next
			end
		
			if cpu.mode == false then
				cpu.DS.push(true)
				return cpu.next
			end
				
			wa = cpu.dict.cfa("compile", cpu.token)
			if wa then
				cpu.DS.push(wa)
				cpu.DS.push(false)
				cpu.state = true
				return cpu.next
			end
			
			cpu.DS.push(true)
			return cpu.next
			
			
		]]
	)
	
	dict.secondary(
		"context",
		"?execute", -- /* ( -- ) execute the word if it's immediate */
		-- if cpu.state == cpu.mode
			-- cpu.state = false
			-- execute
		   -- else
			-- cpu.state = false
			-- end
		{
			cfa("<state"), -- cpu.DS.push(cpu.state)
			cfa("<mode"), -- cpu.DS.push(cpu.mode)
			cfa("(value)"), -- cpu.DS.push(false)
			false,
			cfa(">state"), -- cpu.state = cpu.DS.pop() # i.e. false
			cfa("="), -- cpu.DS.push(cpu.DS.pop() == cpu.DS.pop())
			cfa("(if!rjmp)"),
			4,
				cfa("execute"),
				cfa("(rjmp)"),
				2,
			cfa(","), -- why does it write to the dictionary ?
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
			cfa("<entry"), -- cpu.DS.push(cpu.dict.entry)
			cfa("here"), -- cpu.DS.push(cpu.dict.n)
			cfa(">entry"), -- cpu.dict.entry = cpu.DS.pop()
			cfa("<word"), -- cpu.DS.push(" ");cpu.token, cpu.pad = tokenize(cpu.DS.pop(), cpu.pad); cpu.DS.push(cpu.token);
			cfa(","), -- cpu.dict.push(cpu.DS.pop())
			cfa(",vocab"), -- cpu.dict.push(cpu.vocabulary)
			cfa(","), -- cpu.dict.push(cpu.DS.pop())
			cfa("(value)"), -- cpu.DS.push(cpu.dict[cpu.i]); cpu.i = cpu.i + 1
			"<cfa*", -- cpu.dict[cpu.i] from above
			cfa("ca"), -- local top = cpu.DS.pop() ;if top then 	cpu.DS.push(cpu.dict.ca(cpu.vocabulary, top)) else 		cpu.DS.push(nil) end
			cfa(","), -- cpu.dict.push(cpu.DS.pop())
		}
	)
	
	dict.primary(
		"context",
		"XXcreate", -- /* ( -- ) create a dictionary entry for the next word in the pad */
		[[
			local e = cpu.dict.entry
			cpu.dict.entry = cpu.dict.n
			cpu.token, cpu.pad = tokenize(" ", cpu.pad)
			cpu.dict.push(cpu.token)
			cpu.dict.push(cpu.vocabulary)
			cpu.dict.push(e)
			cpu.dict.push(cpu.cfa)
			return cpu.next
		]]
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
					cfa("(rjmp)"),
					-15,
		}
	)
	
	dict.primary( -- push the cfa of colon
		"context",
		"(colon)",
		[[
			cpu.DS.push(cpu.dict.cfa("context", "colon"))
			return cpu.next
		]]
		
	)
	
	dict.secondary(
		"context",
		":", -- /* ( -- ) create a word entry */
		{
			cfa("(value)"),
			"colon", -- cpu.DS.push("colon")
			cfa("create"),
			cfa("<entry"), -- cpu.DS.push(cpu.dict.entry) -- NFA of word	we just created
			cfa("cfa"), -- get cfa of "colon"
			cfa("there"), -- cpu.DS.n = cpu.DS.pop()
			cfa("ca"),
			cfa(","), -- cpu.dict.push(cpu.DS.pop())
			cfa("t"), -- cpu.DS.push(true)
			cfa(">mode") -- cpu.mode = cpu.DS.pop()
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
