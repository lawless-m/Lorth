
Cpu = function()
	cpu = {
		thread = nil,
		i = 0,
		cfa = 0,
		pad = "",
		DS = Stack("DS"),
		RS = Stack("RS"),
		JS = Stack("JS"),
		dict = Dict("CPUDICT"),
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
			--while cpu.i ~= "exit" do
				if cpu.pad ~= "" then				
					n = cpu.dict.n
					f = cpu.next
					while type(f) == "function" do
						w = Word(cpu.dict, fn_to_nfa(cpu.dict, f))
						trace("CPU " .. tostring(cpu))
						trace("Word " .. tostring(w))
						
						f = f(cpu)

						trace("")
					end
					if cpu.pad ~= "" then
						cpu.dict.n = n
					end
				end
			--coroutine.yield()
			--end
		end
			
	cpu.input =
		function(input)
		    cpu.dict[-100] = cpu.dict.cfa("context", "outer")
			cpu.dict[-99] = nil
			cpu.i = -100
			-- should somehow make it this
		    --	cpu.i = 275 -- cpu.dict.cfa("context", "outer")
			if cpu.pad == "" then
				cpu.pad = input
			else
				cpu.pad = cpu.pad .. " " .. input
			end
			--coroutine.resume(cpu.thread)
			cpu.inner()	
		
		end
		
	setmetatable(cpu, {__tostring=function()
		return "i:" .. cpu.i .. "\n" ..
			"cfa: " .. tostring(cpu.cfa) .. "\n" ..
			"pad: \"" .. cpu.pad .. "\"\n" .. tostring(cpu.DS) .. tostring(cpu.RS) .. tostring(cpu.JS) .. 
			"dict.entry: " .. cpu.dict.entry .. "\n" ..
			"dict.n: " .. cpu.dict.n .. "\n" ..
			"mode: " .. tostring(cpu.mode) .. "\n" ..
			"state: " .. tostring(cpu.state) .. "\n" ..
			"vocab: " .. cpu.vocabulary
		end})
		
	return cpu
end