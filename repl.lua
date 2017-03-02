-- repl.lua

dofile("TIL.lua")

cpuN = Spawn()

io.write("L> ")
io.flush()
for line in io.lines() do
	if line == "EXIT" then
		os.exit(true, true)
	elseif line == "DICT" then
		print(Cpus[cpuN].dict)
	elseif line == "DS" then
		print(Cpus[cpuN].DS)
	elseif line == "RS" then
		print(Cpus[cpuN].RS)
	elseif line == "JS" then
		print(Cpus[cpuN].JS)
	else
		Cpus[cpuN].input(line)

	end	
	
	io.write("L> ")
	io.flush()
end

