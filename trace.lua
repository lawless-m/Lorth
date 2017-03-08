tracef = io.open("trace.txt", "w+")
--tracef:close()

function trace(msg)
	--tracef = io.open("trace.txt", "a+")
	tracef:write("TRACE: " .. msg .. "\n")
	tracef:flush()
end