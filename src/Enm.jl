using OrderedCollections: LittleDict

macro enm(name, varargs...)
	modname = esc(name )
	names = map(string, varargs)
	basetype = Int32
	if isa(name,Expr) && name.head == :(::) && length(name.args) == 2 && isa(name.args[1],Symbol)
		modname = esc(name.args[1])
		basetype = name.args[2]
	end

	ex = quote
		module $modname 
		@enum $(:Enm)::$(basetype) $(varargs...)
		__str_to_enum = LittleDict(zip(map(string,instances($(esc(:Enm)))),instances($(esc(:Enm)))))
		$(esc(:Enm))(x::String) = __str_to_enum[x]

		end
	end
	ex.head = :toplevel
	return ex
end
