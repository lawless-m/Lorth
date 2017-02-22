-- repl.lua

dofile("TIL.lua")

cpuN = Spawn()

io.write("> ")
io.flush()
for line in io.lines() do
	print(">>" .. line .. "<<")
	if line == "DICT" then
		print(Cpus[cpuN].dict)
	elseif line == "DS" then
		print(Cpus[cpuN].DS)
	elseif line == "RS" then
		print(Cpus[cpuN].RS)
	else
		Cpus[cpuN].input(line)
	end	
	io.write("> ")
	io.flush()
end

