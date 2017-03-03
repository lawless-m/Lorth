-- Simple Stack

function warn(msg)
	-- io.stderr:write(msg)
	io.write("WARN: " .. msg .. "\n")
	io.flush()
end

tracef = io.open("trace.txt", "w+")
--tracef:close()

function trace(msg)
	--tracef = io.open("trace.txt", "a+")
	tracef:write("TRACE: " .. msg .. "\n")
	tracef:flush()
end

function write_dict(dict, fn)
	fid = io.open(fn, "w+")
	fid:write(tostring(dict))
	fid:close()
end

dofile("tokenize.lua")
dofile("Stack.lua")
dofile("Dict.lua")
dofile("Word.lua")
dofile("Cpu.lua")
dofile("bootstrap.lua")


Cpus = {}

Spawn = function()
	Cpus[#Cpus+1] = Cpu()
	bootstrap(Cpus[#Cpus].dict)
	write_dict(Cpus[#Cpus].dict, "def.dict.txt")
	-- Cpus[#Cpus].thread = coroutine.create(Cpus[#Cpus].inner)
	
	return #Cpus
end

