-- repl.lua

dofile("miniforth.lua")

for line in io.lines() do
	exec(line)
end


