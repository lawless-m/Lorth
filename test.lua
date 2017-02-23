
function trace(msg)
	print(msg)
end

function tokenize(terminator, rawtext) 
	-- split at the terminator, return text before the terminator and text after the terminator stops repeating (e.g. ("-", "ab--cd-") returns {"ab", "cd-"}
	
	trace("TOKENIZE Term>>" .. terminator .. "<< raw>>" .. rawtext .. "<<")
	
	-- if terminator is a quote do a special routine to crack out \" into a quote
	if terminator == "\"" then return tokenize_string(rawtext) end
	
	if rawtext == "" or terminator == "" then return nil end
	
	local pfx = 1
	local eot = 1

	while eot ~= nil and eot <= pfx do
		eot = string.find(rawtext, terminator, pfx, true) -- plain text search from start of string
		pfx = pfx + 1
	end
	if eot == nil then
		trace("TOK:\"" .. string.sub(rawtext, pfx-1) .. "\" PAD:\"\"")
		return string.sub(rawtext, pfx-1), ""
	end
	eot = eot - 1
	local sot = eot + 2
	while string.sub(rawtext, sot, sot) == terminator do sot = sot + 1 end
	trace("TOK:\"" .. string.sub(rawtext, pfx, eot) .. "\" PAD:\"" .. string.sub(rawtext, sot) .. "\"")
	return string.sub(rawtext, pfx, eot), string.sub(rawtext, sot)
end

tokenize(" ", "   a b")

tokenize(" ", ": d !! ;")

