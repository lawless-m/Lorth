
function tokenize_string(rawtext)
	local qot = string.find(rawtext, "\"", 1, true)
	if qot == nil then
		return rawtext, ""
	end
	local eot = string.find(rawtext, "\\", 1, true)
	if eot == nil or qot < eot then -- normal tokenize
		eot = string.find(rawtext, "\"", 1, true) - 1
		return string.sub(rawtext, 1, eot), string.sub(rawtext, eot+2)
	end
	
	local out = string.sub(rawtext, 1, eot-1) .. string.sub(rawtext, eot+1, eot+1)
	t = tokenize_string(string.sub(rawtext, eot+2))
	return out .. t[1], t[2]
end

function tokenize_bySpc(rawtext) 
	for tok,pad in string.gmatch(rawtext, " *([^ ]+) +(.*)")  do
		return tok, pad
	end
	tok = string.match(rawtext, " *([^ ]+)")
	if tok == nil then
		return "", ""
	end
	return tok, ""
end


function tokenize(pattern, rawtext) 
	-- split at the terminator, return text before the terminator and text after the terminator stops repeating (e.g. ("-", "ab--cd-") returns {"ab", "cd-"}
	
	trace("TOKENIZE Term>>" .. pattern .. "<< raw>>" .. rawtext .. "<<")
	
	if pattern == " " and rawtext ~= "" then 
		return tokenize_bySpc(rawtext)
	end
	
	-- if terminator is a quote do a special routine to crack out \" into a quote
	if pattern == "\"" then return tokenize_string(rawtext) end
	if pattern == "" or terminator == "" then return "", "" end
	
	-- ANYTHING ELSE DOESN'T WORK
	
	return "", ""
end
