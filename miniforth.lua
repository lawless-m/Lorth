-- miniforth5.lua - 2007jul02, Edrx
-- For Lua-5.1 (because of string.match)
-- http://angg.twu.net/miniforth/miniforth5.lua.html
-- http://angg.twu.net/miniforth/miniforth3.abs.txt.html
-- (find-a2ps (buffer-file-name))

-- The article is here:
--    http://angg.twu.net/miniforth-article.html
-- file:///home/edrx/TH/L/miniforth-article.html
--     (find-angg     "TH/miniforth-article.blogme")

-- Important: this program is not totally self-contained (yet).
-- It invokes some functions from my LUA_INIT file:
-- http://angg.twu.net/LUA/lua50init.lua.html
--  (find-angg        "LUA/lua50init.lua")

-- Output:
-- (find-sh "lua51 ~/miniforth/miniforth5.lua")
-- (find-miniforthsh "lua51 miniforth5.lua | tee miniforth5.out")
-- http://angg.twu.net/miniforth/miniforth5.out.html
--  (find-angg        "miniforth/miniforth5.out")

-- These definitions for "split" and "eval" are standard,
-- do not include them in the printed text.
split = function (str, pat)
    local A = {}
    local f = function (word) table.insert(A, word) end
    string.gsub(str, pat or "([^%s]+)", f)
    return A
  end
eval = function (str) return assert(loadstring(str))() end


---  ____            _     ___ 
--- |  _ \ __ _ _ __| |_  |_ _|
--- | |_) / _` | '__| __|  | | 
--- |  __/ (_| | |  | |_   | | 
--- |_|   \__,_|_|   \__| |___|
---                            
-- Part I: The outer interpreter.

-- Global variables that hold the input:
subj = "5 DUP * ."      -- what we are interpreting (example)
pos  = 1                -- where are are (1 = "at the beginning")

-- Low-level functions to read things from "pos" and advance "pos".
-- Note: the "pat" argument in "parsebypattern" is a pattern with
-- one "real" capture and then an empty capture.
parsebypattern = function (pat)
    local capture, newpos = string.match(subj, pat, pos)
    if newpos then pos = newpos; return capture end
  end
parsespaces     = function () return parsebypattern("^([ \t]*)()") end
parseword       = function () return parsebypattern("^([^ \t\n]+)()") end
parsenewline    = function () return parsebypattern("^(\n)()") end
parserestofline = function () return parsebypattern("^([^\n]*)()") end
parsewordornewline = function () return parseword() or parsenewline() end

-- A "word" is a sequence of one or more non-whitespace characters.
-- The outer interpreter reads one word at a time and executes it.
-- Note that `getwordornewline() or ""' returns a word, or a newline, or "".
getword          = function () parsespaces(); return parseword() end
getwordornewline = function () parsespaces(); return parsewordornewline() end

-- The dictionary.
-- Entries whose values are functions are primitives.
-- We will only introduce non-primitives in part II.
_F = {}
_F["%L"] = function () eval(parserestofline()) end

-- The "processor". It can be in any of several "modes".
-- Its initial behavior is to run modes[mode]() - i.e.,
-- modes.interpret() - until `mode' becomes "stop".
mode  = "interpret"
modes = {}
run = function () while mode ~= "stop" do modes[mode]() end end

-- Initially the processor knows only this mode, "interpret"...
-- Note that "word" is a global variable.
interpretprimitive = function ()
    if type(_F[word]) == "function" then _F[word](); return true end
  end
interpretnonprimitive = function () return false end   -- stub
interpretnumber       = function () return false end   -- stub
p_s_i = function () end  -- print state, for "interpret" (stub)
modes.interpret = function ()
    word = getwordornewline() or ""
    p_s_i()
    local _ = interpretprimitive() or
              interpretnonprimitive() or
              interpretnumber() or
              error("Can't interpret: "..word)
  end

-- Our first program in MiniForth.
-- First it defines a behavior for newlines (just skip them),
-- for "" (change mode to "stop"; note that `word' becomes "" on
-- end of text), and for "[L ___ L]" blocks (eval "___" as Lua code).
-- Then it creates a data stack - DS - and four words - "5", "DUP",
-- "*", "." - that operate on it.
--
subj = [==[
%L _F["\n"] = function () end
%L _F[""]   = function () mode = "stop" end
%L _F["[L"] = function () eval(parsebypattern("^(.-)%sL]()")) end
[L
  DS = { n = 0 }
  push = function (stack, x) stack.n = stack.n + 1; stack[stack.n] = x end
  pop  = function (stack) local x = stack[stack.n]; stack[stack.n] = nil;
                          stack.n = stack.n - 1; return x end
  _F["5"]   = function () push(DS, 5) end
  _F["DUP"] = function () push(DS, DS[DS.n]) end
  _F["*"]   = function () push(DS, pop(DS) * pop(DS)) end
  _F["."]   = function () io.write(" "..pop(DS)) end
L]
]==]

-- Now run it. There's no visible output.
pos = 1
mode = "interpret"
run()

-- At this point the dictionary (_F) has eight words.





---  ____            _     ___ ___ 
--- |  _ \ __ _ _ __| |_  |_ _|_ _|
--- | |_) / _` | '__| __|  | | | | 
--- |  __/ (_| | |  | |_   | | | | 
--- |_|   \__,_|_|   \__| |___|___|
---                                
-- Part II: add to miniforth several features of a real Forth.

---             _       _       _        _       
---  _ __  _ __(_)_ __ | |_ ___| |_ __ _| |_ ___ 
--- | '_ \| '__| | '_ \| __/ __| __/ _` | __/ _ \
--- | |_) | |  | | | | | |_\__ \ || (_| | ||  __/
--- | .__/|_|  |_|_| |_|\__|___/\__\__,_|\__\___|
--- |_|                                          
--
-- In this block "d" is as a shorthand for "dump"...

format = string.format
d = {}
d.q = function (obj)
    if type(obj) == "string" then return format("%q", obj) end
    if type(obj) == "number" then return format("%s", obj) end
  end
d.qw = function (obj, w) return format("%-"..w.."s", d.q(obj)) end
d.o  = function (obj)    return string.gsub(d.q(obj),     "\\\n", "\\n") end
d.ow = function (obj, w) return string.gsub(d.qw(obj, w), "\\\n", "\\n") end
d.arr = function (array) return "{ "..table.concat(array, " ").." }" end
d.RS = function (w) return format("RS=%-"..w.."s", d.arr(RS)) end
d.DS = function (w) return format("DS=%-"..w.."s", d.arr(DS)) end
d.PS = function (w) return format("PS=%-"..w.."s", d.arr(PS)) end
d.mode = function (w) return format("mode=%-"..w.."s", mode) end
d.v = function (varname) return varname.."="..d.o(_G[varname]) end

d.subj   = function () print((string.gsub(subj, "\n$", ""))) end
d.memory = function () print(" memory ="); PP(memory) end

d.base = function () return d.RS(9)..d.mode(11)..d.DS(11) end

p_s_i = function () print(d.base()..d.v("word")) end
p_s_c = function () print(d.base()..d.v("here").." "..d.v("word")) end
p_s_f = function () print(d.base()..d.v("instr")) end
p_s_h = function () print(d.base()..d.v("head")) end
p_s_lit   = function () print(d.base()..d.v("data")) end
p_s_pcell = function () print(d.base()..d.v("pdata")) end

t = 0
d.t = function (w) return format("t=%-"..w.."d", t) end
d.tick = function () t = t + 1; return "" end

_F["."] = function () io.write(" "..pop(DS)) end  -- original
_F["."] = function () print(" "..pop(DS)) end     -- better for when we're always printing the mode

-- (find-sh "lua51 ~/miniforth/miniforth5.lua")




---                                            
---  _ __ ___   ___ _ __ ___   ___  _ __ _   _ 
--- | '_ ` _ \ / _ \ '_ ` _ \ / _ \| '__| | | |
--- | | | | | |  __/ | | | | | (_) | |  | |_| |
--- |_| |_| |_|\___|_| |_| |_|\___/|_|   \__, |
---                                      |___/ 

-- The return stack, the memory, and "here".
RS     = { n = 0 }
memory = { n = 0 }
here = 1

compile  = function (...) for i = 1,arg.n do compile1(arg[i]) end end
compile1 = function (x)
    memory[here] = x; here = here + 1
    memory.n = math.max(memory.n, here)
  end

---  _                         _       _                  
--- (_)_ __  _ __   ___ _ __  (_)_ __ | |_ ___ _ __ _ __  
--- | | '_ \| '_ \ / _ \ '__| | | '_ \| __/ _ \ '__| '_ \ 
--- | | | | | | | |  __/ |    | | | | | ||  __/ |  | |_) |
--- |_|_| |_|_| |_|\___|_|    |_|_| |_|\__\___|_|  | .__/ 
---                                                |_|    
-- The bytecode of a Forth word starts with the head
-- "DOCOL" and ends with the Forth instruction "EXIT".
-- We store heads in the memory as strings, and the
-- table _H converts the name of a head into its code.

_H = {}
_H["DOCOL"] = function ()
    -- RS[RS.n] = RS[RS.n] + 1
    mode = "forth"
  end
_F["EXIT"] = function ()
    pop(RS)
    if type(RS[RS.n]) == "string" then mode = pop(RS) end
    -- if mode == nil then mode = "stop" end    -- hack
  end

-- Modes for the inner interpreter.
-- Remember that heads are always strings,
-- Forth instructions that are strings are primitives (-> "_F[str]()"), and
-- Forth instructions that are numbers are calls to non-primitives.
modes.head = function ()
    head = memory[RS[RS.n]]
    p_s_h()
    RS[RS.n] = RS[RS.n] + 1
    _H[head]()
  end
modes.forth = function ()
    instr = memory[RS[RS.n]]
    p_s_f()
    RS[RS.n] = RS[RS.n] + 1
    if type(instr) == "number" then push(RS, instr); mode = "head"; return end
    if type(instr) == "string" then _F[instr](); return end
    error("Can't run forth instr: "..mytostring(instr))
  end

-- This was a stub. Now that we know how to execute non-primitives,
-- replace it with the real definition.
interpretnonprimitive = function ()
    if type(_F[word]) == "number" then
      push(RS, "interpret")
      push(RS, _F[word])
      mode = "head"
      return true
    end
  end

-- ":" starts a definition, and switches from "interpret" to "compile".
-- ";" closes a definition, and switches from "compile" to "interpret".
_F[":"] = function ()
    _F[getword()] = here
    compile("DOCOL")
    mode = "compile"
  end
_F[";"] = function ()
    compile("EXIT")
    mode = "interpret"
  end
IMMEDIATE = {}
IMMEDIATE[";"] = true

-- Define a new mode: "compile".
compileimmediateword = function ()
    if word and _F[word] and IMMEDIATE[word] then
      if type(_F[word]) == "function" then   -- primitive
        _F[word]()
      else
        push(RS, mode)
        push(RS, _F[word])
        mode = "head"
      end
      return true
    end
  end
compilenonimmediateword = function ()
    if word and _F[word] and not IMMEDIATE[word] then
      if type(_F[word]) == "function" then
        compile1(word)	    -- primitive: compile its name (string)
      else
        compile1(_F[word])  -- non-primitive: compile its address (a number)
      end
      return true
    end
  end
compilenumber = function ()
    if word and tonumber(word) then
      compile1("LIT"); compile1(tonumber(word)); return true
    end
  end
modes.compile = function ()
    word = getword()
    p_s_c()
    local _ = compileimmediateword() or
              compilenonimmediateword() or
              compilenumber() or
              error("Can't compile: "..(word or EOT))
  end

---                        _                   
---  _ __  _   _ _ __ ___ | |__   ___ _ __ ___ 
--- | '_ \| | | | '_ ` _ \| '_ \ / _ \ '__/ __|
--- | | | | |_| | | | | | | |_) |  __/ |  \__ \
--- |_| |_|\__,_|_| |_| |_|_.__/ \___|_|  |___/
---                                            
-- How to interpret arbritrary numbers.
-- In our simplest examples the "5" worked because it was in the dictionary.
-- As the bootstrap code didn't define a data stack (DS), and
-- "interpretnumber" uses DS, it was cleaner to define it there as a stub.
-- Now we replace the stub by the real definition.
interpretnumber = function ()
    if word and tonumber(word) then push(DS, tonumber(word)); return true end
  end

-- "compilenumber", above, defines the behavior of numbers in compile mode.
-- It compiles first a "LIT" - a Forth primitive that eats bytecode - and
-- then the value of the number. Now we define how "LIT" works.
_F["LIT"] = function ()
    push(DS, memory[RS[RS.n]])
    RS[RS.n] = RS[RS.n] + 1
  end

_F["LIT"] = function () mode = "lit" end
modes.lit = function ()
    data = memory[RS[RS.n]]
    p_s_lit()
    push(DS, memory[RS[RS.n]])
    RS[RS.n] = RS[RS.n] + 1
    mode = "forth"
  end

_F["+"] = function () push(DS, pop(DS) + pop(DS)) end



---                  _                                              
---  _ __  _   _ ___| |__      _ __      _ __   ___  _ __     _ __  
--- | '_ \| | | / __| '_ \    | '_ \    | '_ \ / _ \| '_ \   | '_ \ 
--- | |_) | |_| \__ \ | | |   | | | |_  | |_) | (_) | |_) |  | | | |
--- | .__/ \__,_|___/_| |_|___|_| |_( ) | .__/ \___/| .__/___|_| |_|
--- |_|                  |_____|    |/  |_|         |_| |_____|     

push_1 = function (S, a)
    S[S.n], S[S.n+1], S.n =
    a,      S[S.n],   S.n+1
  end
push_2 = function (S, a)
    S[S.n-1], S[S.n],   S[S.n+1], S.n =
    a,        S[S.n-1], S[S.n],   S.n+1
  end
pop_1 = function (S)
    local a = S[S.n-1]; S[S.n-1], S[S.n], S.n =
                        S[S.n],   nil,    S.n-1
    return a
  end
pop_2 = function (S)
    local a = S[S.n-2]; S[S.n-2], S[S.n-1], S[S.n], S.n =
                        S[S.n-1], S[S.n],   nil,    S.n-1
    return a
  end



---                 _ _ 
---  _ __   ___ ___| | |
--- | '_ \ / __/ _ \ | |
--- | |_) | (_|  __/ | |
--- | .__/ \___\___|_|_|
--- |_|                 

pcellread = function () return memory[PS[PS.n]] end
pcell     = function ()
    local p = memory[PS[PS.n]]
    PS[PS.n] = PS[PS.n] + 1
    return p
  end
_F["R>P"] = function () push(PS, pop_1(RS)) end
_F["P>R"] = function () push_1(RS, pop(PS)) end
_F["PCELL"] = function () mode = "pcell" end
modes.pcell = function ()
    pdata = memory[PS[PS.n]]
    p_s_pcell()
    push(DS, memory[PS[PS.n]])
    PS[PS.n] = PS[PS.n] + 1
    mode = "forth"
  end
