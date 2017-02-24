
function trace(msg)
	print(msg)
end

function tokenize_bySpc(rawtext) 
  i = 1
	for tok,pad in string.gmatch(rawtext, " *([^ ]+) +(.*)")  do
		return tok, pad
  end
  return rawtext
end

tokenize_bySpc("   a b")

tokenize_bySpc(": d !! ;")

tokenize_bySpc(":")



