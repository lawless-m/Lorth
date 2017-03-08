
dofile("trace.lua")
dofile("tokenize.lua")


function tokenize(pattern, rawtext) 
	-- split at the terminator, return text before the terminator and text after the terminator stops repeating (e.g. ("-", "ab--cd-") returns {"ab", "cd-"}
	
	trace("TOK: p=\"" .. pattern .. "\", r=\"" .. rawtext .. "\"" )
	
	if pattern == " " and rawtext ~= "" then 
		return tokenize_bySpc(rawtext)
	end
	
	-- if terminator is a quote do a special routine to crack out \" into a quote
	if pattern == "\"" then return tokenize_string(rawtext) end
	if pattern == "" or terminator == "" then return "", "" end
	
	-- ANYTHING ELSE DOESN'T necessarily WORK
	
	return "", ""
end

print(tokenize("\"", "hello \" emit"))



