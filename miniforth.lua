
-- fixed for 5.3 : lawless-m

-- based on miniforth5.lua - 2007jul02, Edrx
-- For Lua-5.1 (because of string.match)
-- http://angg.twu.net/miniforth/miniforth5.lua.html
-- The article is here:
--    http://angg.twu.net/miniforth-article.html


-- find these !!

-- It invokes some functions from my LUA_INIT file:
-- http://angg.twu.net/LUA/lua50init.lua.html
--  (find-angg        "LUA/lua50init.lua")


-- These definitions for "split" and "eval" are standard,
-- do not include them in the printed text.
split = function (str, pat)
    local A = {}
    local f = function (word) table.insert(A, word) end
    string.gsub(str, pat or "([^%s]+)", f)
    return A
  end
eval = function (str) return assert(load(str))() end

-- at least stop it crashing
warn= function(msg) io.stderr:write("\nWARN: %s\n\n", msg) end

---             _       _       _        _       
---  _ __  _ __(_)_ __ | |_ ___| |_ __ _| |_ ___ 
--- | '_ \| '__| | '_ \| __/ __| __/ _` | __/ _ \
--- | |_) | |  | | | | | |_\__ \ || (_| | ||  __/
--- | .__/|_|  |_|_| |_|\__|___/\__\__,_|\__\___|
--- |_|                                          
--
-- In this block "d" is as a shorthand for "dump"...

-- this stuff is for inspection during development

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



---- END OF PRINTSTATE


---  _ __ ___   ___ _ __ ___   ___  _ __ _   _ 
--- | '_ ` _ \ / _ \ '_ ` _ \ / _ \| '__| | | |
--- | | | | | |  __/ | | | | | (_) | |  | |_| |
--- |_| |_| |_|\___|_| |_| |_|\___/|_|   \__, |
---                                      |___/ 

-- global stuff


-- stacks
RS = { n = 0 }
DS = { n = 0}

-- required stack manipulation, 
push = function (stack, x) stack.n = stack.n + 1; stack[stack.n] = x end
pop  = function (stack) local x = stack[stack.n]; stack[stack.n] = nil; stack.n = stack.n - 1; return x end


-- the cells
memory = { n = 0 }

-- Processor modes
modes = {}

-- The dictionaries

_F = {} -- primitives
_H = {} -- HEADs

-- _F dictionary pointer
here = 1

---  ____            _     ___ 
--- |  _ \ __ _ _ __| |_  |_ _|
--- | |_) / _` | '__| __|  | | 
--- |  __/ (_| | |  | |_   | | 
--- |_|   \__,_|_|   \__| |___|
---                            
-- Part I: The outer interpreter.
  

-- Global variables that hold the input:
subj = ""  -- what we are interpreting
pos  = 1   -- where are are (1 = "at the beginning")

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



-- (find-sh "lua51 ~/miniforth/miniforth5.lua")

-- The "processor". It can be in any of several "modes".
-- Its initial behavior is to run modes[mode]() - i.e.,
-- modes.interpret() - until `mode' becomes "stop".
mode  = "interpret"
run = function () while mode ~= "stop" do modes[mode]() end end

-- Initially the processor knows only this mode, "interpret"...
-- Note that "word" is a global variable.
interpretprimitive = function ()
    if type(_F[word]) == "function" then _F[word](); return true end
  end
  
interpretnumber = function ()
    if word and tonumber(word) then push(DS, tonumber(word)); return true end
  end

interpretnonprimitive = function ()
    if type(_F[word]) == "number" then
      push(RS, "interpret")
      push(RS, _F[word])
      mode = "head"
      return true
    end
  end 
  
modes.interpret = function ()
    word = getwordornewline() or ""
    p_s_i() -- this is a debug tool, should be removed
    local _ = interpretprimitive() or
              interpretnonprimitive() or
              interpretnumber() or
              warn("Can't interpret: "..word)
  end

compile  = function (...) for k,a in pairs({...}) do compile1(a) end end
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
    warn("Can't run forth instr: "..mytostring(instr))
  end

-- all adding Lua code to the dictionary
_F["%L"] = function () eval(parserestofline()) end
_F["\n"] = function () end
_F[""]   = function () mode = "stop" end
_F["[L"] = function () eval(parsebypattern("^(.-)%sL]()")) end


_F["DUP"] = function () push(DS, DS[DS.n]) end
_F["."]   = function () io.write(" "..pop(DS)) end
			  

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
              warn("Can't compile: "..(word or EOT))
  end

---                        _                   
---  _ __  _   _ _ __ ___ | |__   ___ _ __ ___ 
--- | '_ \| | | | '_ ` _ \| '_ \ / _ \ '__/ __|
--- | | | | |_| | | | | | | |_) |  __/ |  \__ \
--- |_| |_|\__,_|_| |_| |_|_.__/ \___|_|  |___/
---                                            
-- How to interpret arbritrary numbers.
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

-- MATH primitives - unary minus - always a problem :)

_F["+"] = function () push(DS, pop(DS) + pop(DS)) end
_F["-"] = function () push(DS, pop(DS) - pop(DS)) end
_F["*"]   = function () push(DS, pop(DS) * pop(DS)) end
_F["/"]   = function () local a = pop(DS); b = pop(DS); if b == 0 warn("div by zero") end; DS[DS.n] = a / b end
_F["NEG"] = function () DS[DS.n] = -DS[DS.n]

_F["ABS"]   = function () DS[DS.n] = math.abs(DS[DS.n]) end
_F["ACOS"]   = function () DS[DS.n] = math.acos(DS[DS.n]) end
_F["ASIN"]   = function () DS[DS.n] = math.asin(DS[DS.n]) end
_F["ATAN"]   = function () DS[DS.n] = math.atan(DS[DS.n]) end
_F["ATAN2"]   = function () DS[DS.n] = local x = pop(DS); DS[DS.n] = math.atan(DS[DS.n], x) end
_F["CEIL"]   = function () DS[DS.n] = math.ceil(DS[DS.n]) end
_F["COS"]   = function () DS[DS.n] = math.cos(DS[DS.n]) end
_F["DEG"]   = function () DS[DS.n] = math.deg(DS[DS.n]) end
_F["EXP"]   = function () DS[DS.n] = math.exp(DS[DS.n]) end
_F["FLOOR"]   = function () DS[DS.n] = math.floor(DS[DS.n]) end
_F["FMOD"]   = function () DS[DS.n] = local y = pop(DS); math.fmod(DS[DS.n], y) end
_F["HUGE"]   = function () DS[DS.n] = math.huge end
_F["LN"]   = function () DS[DS.n] = math.log(DS[DS.n]) end
_F["LOG"]   = function () local base = pop(DS); DS[DS.n] = math.log(DS[DS.n], base) end
_F["MAX"]   = function () local t = pop(DS); DS[DS.n] = math.max(t, DS[DS.n]) end
_F["MAXINT"]   = function () DS[DS.n] = math.maxinteger end
_F["MIN"]   = function () local t = pop(DS); DS[DS.n] = math.min(t, DS[DS.n]) end
_F["MININT"]   = function () DS[DS.n] = math.mininteger end
_F["MODF"]   = function () DS[DS.n] = math.modf(DS[DS.n]) end
_F["PI"]   = function () DS[DS.n] = math.pi end
_F["RAD"]   = function () DS[DS.n] = math.rad(DS[DS.n]) end
_F["RANDOM"]   = function () DS[DS.n] = math.random() end
_F["RANDOMN"]   = function () n = pop(DS); DS[DS.n] = math.random(DS[DS.n], n) end
_F["RANDOMSEED"]   = function () math.randomseed(pop(DS)) end
_F["SIN"]   = function () DS[DS.n] = math.sin(DS[DS.n]) end
_F["SQRT"]   = function () DS[DS.n] = math.sqrt(DS[DS.n]) end
_F["TAN"]   = function () DS[DS.n] = math.tan(DS[DS.n]) end
_F["TOINTEGER"]   = function () DS[DS.n] = math.tointeger(DS[DS.n]) end
_F["TYPE"]   = function () DS[DS.n] = math.type(DS[DS.n]) end
_F["ULT"]   = function () n = pop(DS); DS[DS.n] = math.ult(DS[DS.n], n) end

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



  ---  ___
--- / _ \ 
---|  __/
--- \___| XEC
--- too hard to make the whole word :)

-- This makes it callable
exec = function(input)
	subj = input
	pos = 1
	mode = "interpret"
	run()
end
