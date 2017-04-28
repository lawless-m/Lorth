

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
		"//", --  /* ( -- ) store the pad in the dictionary  - for NOP'ing comments*/
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
			cpu.push(true)
			return cpu.next
		]]
	)
	
	
	dict.primary(
		"context",
		"f", -- /* ( -- false ) */
		[[
			cpu.push(false)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"=", -- /* ( b a - (b == a) ) equality */
		[[
			cpu.push(cpu.pop() == cpu.pop())
			return cpu.next
		]]
	
	)
	
	dict.primary(
		"context",
		"here", -- /* ( - DP )  push dictionary pointer */
		[[
			cpu.push(cpu.dict.n)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"there", -- /* (NEWDP - ) pop to the dictionary pointer */
		[[
			cpu.dict.n = cpu.pop()
			return cpu.next
		]]
	)

	dict.primary(
		"context",
		"dup", -- /* ( a -- a a ) duplicate the tos */
		[[
			cpu.push(cpu.DS.top())
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"tuck", -- /* ( b a -- a b a ) copy tos to 3rd place, could just be : tuck swap over ; */
		[[
			local a = cpu.pop()
			local b = cpu.pop()
			cpu.push(a)
			cpu.push(b)
			cpu.push(a)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"context", -- /* ( -- "context" ) push "context" */
		[[
			cpu.push("context")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"compile", -- /* ( -- "compile" ) push "compile" */
		[[
			cpu.push("compile")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"execute", -- /* ( -- wa ) run the word with its address on the tos */
		[[

			cpu.cfa = cpu.pop()

			return cpu.run
		]]
	)
	
	dict.primary(
		"context",
		"token", -- /* ( token -- ) split cpu.pad with the pattern in ToS
		[[

			local pattern = cpu.pop()
			trace("PAT \"" .. pattern .. "\"")
			local w
			w, cpu.pad = tokenize(pattern, cpu.pad)
			trace("w \"" .. tostring(w) .. "\"")
			cpu.push(w)
			trace("TOP w " .. tostring(cpu.DS.top()))
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"token?", -- /* ( token -- ( true | false ) ) extract everything in cpu.pad until the terminator, put it in the dictionary and report if you found anything */
		[[
			local pattern = cpu.pop()
			local w
			if cpu.pad == "" then
				cpu.push(false)
				return cpu.next
			end
			w, cpu.pad = tokenize(pattern, cpu.pad)
			cpu.push(w)
			cpu.push(true)
			return cpu.next
		]]
	)
	
	
	dict.primary(
		"context",
		"(value)", --  /* ( -- n ) push the contents of the next cell */
		[[
			cpu.push(cpu.dict[cpu.i])
			cpu.i = cpu.i + 1
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		",", -- /* ( val -- ) store tos in the next cell */
		[[

			cpu.dict.push(cpu.pop())

			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"drop", -- /* ( a -- ) drop the tos */
		[[
			cpu.pop()
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"ca", -- /* ( "word" -- ca|undefined ) push code address or nil on tos */
		[[
			local top = cpu.pop()
			if top then
				cpu.push(cpu.dict.ca(cpu.vocabulary, top))
			else
				warn("NOT FOUND: " .. tostring(cpu.vocabulary) .. " / " .. tostring(top))
				cpu.push(nil)
			end
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"search", -- /* ( -- (false wa) | true ) search the dictionary for "word" push the wa and a flag for (not found) */
		[[
			trace("TOP s " .. tostring(cpu.DS.top()))
			local wa = cpu.dict.cfa(cpu.vocabulary, cpu.DS.top())
			if wa then
				cpu.pop()
				cpu.push(wa)
				cpu.push(false)
			else
				cpu.push(true)
			end
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<mode", -- /* ( -- mode ) push the current mode */
		[[
			cpu.push(cpu.mode)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		">mode", --  /* ( mode -- ) set the current mode */
		[[
			cpu.mode = (cpu.pop() == true)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<state", -- /* ( -- state ) push the current state */
		[[
			cpu.push(cpu.state)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		">state", -- /* ( state -- ) set the current state */
		[[
			cpu.state = (cpu.pop() == true)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		">vocabulary", -- /* ( vocabulary -- ) set the current vocabulary */
		[[
			cpu.vocabulary = cpu.pop()
			return cpu.next		
		]]
	)
	
	dict.primary(
		"context",
		"not", -- /* ( v -- !v ) clean boolean not */
		[[
			if cpu.pop() then
				cpu.push(false)
			else
				cpu.push(true)
			end
		]]
	)
	
	dict.primary(
		"context",
		">entry", -- /* ( -- ) write to cpu.dict.entry */
		[[
			cpu.dict.entry = cpu.pop()
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<entry", --/* ( -- daddr ) push cpu.dict.entry  */
		[[
			cpu.push(cpu.dict.entry)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"cfa", -- /* ( NFA -- CFA) push Code Field Address for the given Name Field Address , just arithmetic */
		[[
			cpu.push(nfa_to_cfa(cpu.pop()))
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
			local n = tonumber(cpu.DS.top())
			if n == nil then
				cpu.push(true)
				return cpu.next
			end
			cpu.pop()
			if cpu.mode then
				cpu.dict.push(cpu.dict.cfa(cpu.vocabulary, "(value)"))
				cpu.dict.push(n)
			else
				cpu.push(n)
			end
			cpu.push(false)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"tokenerror", --  { /* ( -- ) report an unrecognised word error */
		[[
			warn("\"" .. tostring(cpu.pop()) .. "\" error, unrecognised word")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"spc", --  /* ( -- " " ) push a space character */
		[[
			cpu.push(" ")
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"chr",
		[[
			cpu.push(string.char(cpu.pop()))
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
			if cpu.pop() then
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
			cpu.push(cpu.cfa)
			return cpu.semi
		]]
	)
	
	dict.primary(
		"context",
		"wa", -- /* ( "word" -- wa|undefined ) push word address or undefined on tos */
		[[
			cpu.push(cpu.dict.cfa(cpu.vocabulary, cpu.pop()));
			return cpu.next;
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
		"?search", -- (token -- (wa|token) (F|T) )
		[[
			trace("TOP ?s " .. tostring(cpu.DS.top()))
			local wa = cpu.dict.cfa(cpu.vocabulary, cpu.DS.top())
			trace("TOP " .. tostring(cpu.DS.top()))
			if wa then
				cpu.pop()
				cpu.push(wa)
				cpu.push(false)
				trace("WA " .. tostring(wa))
				return cpu.next
			end
		
			if cpu.mode == false then
				cpu.push(true)
				return cpu.next
			end
				
			wa = cpu.dict.cfa("compile", cpu.DS.top())
			if wa then
				cpu.pop()
				cpu.push(wa)
				cpu.push(false)
				cpu.state = true
				trace("COMPILE wa " .. tostring(wa))
				return cpu.next
			end
			trace("NOPE")
			cpu.push(true)
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
			cfa("<state"), -- cpu.push(cpu.state)
			cfa("<mode"), -- cpu.push(cpu.mode)
			cfa("(value)"), -- cpu.push(false)
			false,
			cfa(">state"), -- cpu.state = cpu.pop() # i.e. false
			cfa("="), -- cpu.push(cpu.pop() == cpu.pop())
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
		"<word", -- /* read space delimited word from the pad */
		{
			cfa("spc"),
			cfa("token"),
		}
	)
	
	dict.secondary(
		"context",
		"create", -- /* ( -- ) create a dictionary entry for the next word in the pad */
		{
			cfa("<entry"), -- cpu.push(cpu.dict.entry)
			cfa("here"), -- cpu.push(cpu.dict.n)
			cfa(">entry"), -- cpu.dict.entry = cpu.pop()
			cfa("<word"), -- cpu.push(" "); w, cpu.pad = tokenize(cpu.pop(), cpu.pad); cpu.push(w);
			cfa(","), -- cpu.dict.push(cpu.pop())
			cfa(",vocab"), -- cpu.dict.push(cpu.vocabulary)
			cfa(","), -- cpu.dict.push(cpu.pop())
			cfa("(value)"), -- cpu.push(cpu.dict[cpu.i]); cpu.i = cpu.i + 1
			"<cfa*", -- cpu.dict[cpu.i] from above
			cfa("ca"), -- local top = cpu.pop() ;if top then 	cpu.push(cpu.dict.ca(cpu.vocabulary, top)) else 		cpu.push(nil) end
			cfa(","), -- cpu.dict.push(cpu.pop())
		}
	)
	
	dict.primary(
		"context",
		"XXcreate", -- /* ( -- ) create a dictionary entry for the next word in the pad */
		[[
			local e = cpu.dict.entry
			local w
			cpu.dict.entry = cpu.dict.n
			w, cpu.pad = tokenize(" ", cpu.pad)
			cpu.dict.push(w)
			cpu.dict.push(cpu.vocabulary)
			cpu.dict.push(e)
			cpu.dict.push(cpu.cfa)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"pad?", -- is anything on the pad
		[[
			cpu.push(cpu.pad ~= "")
			return cpu.next
		]]
	)
	
	dict.secondary(
		"context",
		"rtoken",
		{}
	)
	
	dict.secondary(
		"context",
		"outer", -- /* ( -- ) tokenize the pad and do whatever it says */
		{
			cfa("pad?"),
			cfa("(if!rjmp)"),
			14,
				cfa("<word"),
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
					-15, -- maybe wrong
		}
	)
	
	dict.primary( -- push the cfa of colon
		"context",
		"(colon)",
		[[
			cpu.push(cpu.dict.cfa("context", "colon"))
			return cpu.next
		]]
		
	)
	
	dict.secondary(
		"context",
		":", -- /* ( -- ) create a word entry */
		{
			cfa("(value)"),
			"colon", -- cpu.push("colon")
			cfa("create"),
			cfa("<entry"), -- cpu.push(cpu.dict.entry) -- NFA of word	we just created
			cfa("cfa"), -- get cfa of "colon"
			cfa("there"), -- cpu.DS.n = cpu.pop()
			cfa("ca"),
			cfa(","), -- cpu.dict.push(cpu.pop())
			cfa("t"), -- cpu.push(true)
			cfa(">mode") -- cpu.mode = cpu.pop()
		}
	)
	
	dict.primary( -- could be secondary
		"context",
		"immediate", -- /* ( -- ) set the vocabulary of the last defined word to "compile" */
		[[
			cpu.dict[cpu.dict.entry + 1] = "compile"
			return cpu.next
		]]	
	)
	
	
	dict.primary(
		"context",
		"does>",
		[[
		
			return cpu.next
		]]
	)
		
	dict.primary(
		"context",
		"!", --  /* ( adr val -- ) write val to cell at adr */
		[[
			local v = cpu.pop()
			local a = cpu.pop()
			cpu.dict[a] = v
			return cpu.next
		]]
	)	
	
	dict.primary(
		"context",
		"(if!jmp)",
		[[
			if cpu.pop() == true then
				cpu.i = cpu.i + 1
			else
				cpu.i = cpu.dict[cpu.i]
			end
			return cpu.next
		]]
	)
	
	
	dict.primary(
		"context",
		"(jmp)",
		[[
			cpu.i = cpu.dict[cpu.i]
			return cpu.next
		]]
	)
		
	dict.primary(
		"context",
		"+1",
		[[
			cpu.push(cpu.pop()+1)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"swap", -- swaps top two data stack entries
		[[
			local a = cpu.pop()
			local b = cpu.pop()
			cpu.push(a)
			cpu.push(b)
			return cpu.next
		]]
		
	)
	
	dict.primary(
		"context",
		">J", -- pop DS to JS
		[[
			cpu.JS.push(cpu.pop())
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"<J", -- pop JS to DS
		[[
			cpu.pop(cpu.JS.pop())
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		">",
		[[
			local a = cpu.pop()
			local b = cpu.pop()
			cpu.push(b > a)
			return cpu.next
		]]
	)
	
	dict.primary(
		"context",
		"(loop)", -- very similar to (+loop) why not "1 (+loop)"
		[[
			local tos = cpu.JS.n-1
			local term = cpu.JS[tos-1]
			local count = cpu.JS[tos] + 1
			if count < term then
				cpu.i = cpu[cpu.i]
				cpu.JS[tos] = count
			else
				cpu.JS.pop()
				cpu.JS.pop()
				cpu.i = cpu.i + 1
			end
			return cpu.next		
		]]
	)
		
	dict.primary(
		"context",
		"(+loop)",
		[[
			local tos = cpu.JS.n-1
			local term = cpu.JS[tos-1]
			local count = cpu.JS[tos] + cpu.pop()
			if count < term then
				cpu.i = cpu[cpu.i]
				cpu.JS[tos] = count
			else
				cpu.JS.pop()
				cpu.JS.pop()
				cpu.i = cpu.i + 1
			end
			return cpu.next		
		]]
	)
	
	
	dict.primary( 
		"context",
		"(do)", -- could be just "swap <J <J"
		[[
			local index = cpu.pop()
			local term = cpu.pop()
			cpu.JS.push(term)
			cpu.JS.push(index)			
			return cpu.next		
		]]
	)
	
	-- now we should be able to just parse raw text
end


function base(cpu)

	cpu.dict.primary(
		"context",
		"emit",
		[[
			print(cpu.pop())
			return cpu.next
		]]
	)

	-- take the next token, look up its word address and insert it into the dictionary as a (value)
	cpu.input(": postpone <word wa `value , , ; immediate")

	cpu.input(": quote 34 chr ;")

	-- push the buffer up to "
	cpu.input(": \" quote token ;")

	-- store the buffer up to "
	cpu.input(": .\" \" postpone (value) , , ; immediate")

	
	
	-- store the jmp, push the address of the jmp target, move the dp past it
	cpu.input(": if postpone (if!jmp) , here dp++ ; immediate")

	-- ( whereToStoreTarget -- )  this is the ultimate jump target, store it
	cpu.input(": then here ! ; immediate")

	-- ( whereToStoreTarget -- newWhereToStoreTarget)
	cpu.input(": else postpone (jmp) , here tuck +1 ! dp++  ; immediate")


	cpu.input(": begin here ; immediate")
	cpu.input(": until postpone (if!jmp) , , ; immediate")

	cpu.input(": while postpone (if!jmp) , here dp++ ; immediate")
	cpu.input(": repeat swap postpone (jmp) , , here !  ; immediate")

	
	cpu.input(": do postpone (do) , here 0 >J ; immediate")
	cpu.input(": loop postpone (loop) , , <J dup 0 > if begin <J here ! -1 dup 0 = until then drop ; immediate")
	cpu.input(": +loop postpone (+loop) , , ; immediate")

	cpu.input(": (leave) <J drop <J drop ;")
	cpu.input(": leave postpone (leave) , postpone (jmp) , <J +1 here  >J >J dp++ ; immediate")

	-- needs does> @ ;
	cpu.input(": constant create , does> @ ;")
	cpu.input(": variable create 0 ,  ;")

	return [[
	cpu.input(": ;code  .\" $$\" token (js) drop postpone (;code) , , ; immediate")

	cpu.input(": ;js .\" $$\" token <token  .\" ; return cpu.next;\" + (js) if here swap , dup -1 swap ! f >mode then ; immediate")
	cpu.input(": . ;js  var k = cpu.d.pop(); cpu.d.push(cpu.d.pop()[k]) $$")
	cpu.input(": last ;js var k = cpu.d.pop(); cpu.d.push(cpu.d.pop().lastIndexOf(k)) $$")
	cpu.input(": slice ;js var t = cpu.d.pop(); var e = cpu.d.pop(); var s = cpu.d.pop(); cpu.d.push(t.slice(s, e)); $$")
	cpu.input(": {} ;js cpu.d.push({}) $$")
	cpu.input(": [] ;js cpu.d.push([]) $$")
	cpu.input(": <= ;js cpu.d.pop()[cpu.d.pop()] = cpu.d.pop(); $$")
	--  ( value key object -- )
	cpu.input(": << ;js var v = cpu.d.pop(); cpu.d.pop().push(v); $$")
	cpu.input(": >> ;js cpu.d.push(cpu.d.pop().pop());  $$")
	cpu.input(": length ;js cpu.d.push(cpu.d.pop().length); $$")
	cpu.input(": >0 ;js cpu.d.push(cpu.d.pop() > 0) $$")
	cpu.input(": last @ dup length -1 . ;")

	cpu.input(": :: context >vocabulary create t >mode ;")
	]]
end

