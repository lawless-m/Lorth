-- repl.lua

dofile("TIL.lua")

C = Cpu()
bootstrap(C.dict)

print(C.dict)
