-- repl.lua

dofile("TIL.lua")

cpuN = Spawn()

io.write("> ")
io.flush()
for line in io.lines() do
	print(">>" .. line .. "<<")
	if line == "RESET" then
		Cpus[cpuN] = nil
		cpuN = Spawn()
	end
	Cpus[cpuN].input(line)
	io.write("> ")
	io.flush()
end

