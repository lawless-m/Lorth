-- repl.lua

dofile("TIL.lua")

io.write("Lorth, a Forth for Lua based on Miniforth\n> ")
for line in io.lines() do
	io.write("\n> ")
	exec(line)
end
