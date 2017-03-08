-- Simple Stack

function warn(msg)
	-- io.stderr:write(msg)
	io.write("WARN: " .. msg .. "\n")
	io.flush()
end



function write_dict(dict, fn)
	fid = io.open(fn, "w+")
	fid:write(tostring(dict))
	fid:close()
end

dofile("trace.lua")
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
	base(Cpus[#Cpus])
	-- HA base.nr had the wring code Cpus[#Cpus].input_file_byline("base.nr")
	write_dict(Cpus[#Cpus].dict, "def.dict.txt")
	-- Cpus[#Cpus].thread = coroutine.create(Cpus[#Cpus].inner)
	
	return #Cpus
end

