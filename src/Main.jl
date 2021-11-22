module External 
using  ArgParse 
using Logging 

function parse_commandline()
	s = ArgParseSettings()

	@add_arg_table! s begin 
	"port"
		help="Port to use for connection"
		required=true
		arg_type = Int 
	"module"
		help="Either the name of a module or a Julia file"
		required = true
	"target"
		help="Function name to call with connection (module only)"
		required= false 
	end
	return parse_args(s; as_symbols=true)
end 

function load_function(module_name, target)

	is_julia_file = module_name[end-2:end] == ".jl"
	if is_julia_file
		throw(ErrorException("Using julia files directly is currently unsupported"))
	end
	loaded_module = Base.require(Main,Symbol(module_name))
	func = Expr(:.,loaded_module,Symbol(target))

	return func 
end

function main()
	args = parse_commandline()


	@debug "Starting external Julia module $(args[:module]) in state: [ACTIVE]"
	@debug "Connection to parent on port $(args[:port])"

	Base.global_logger(ConsoleLogger(stdout,Debug))

	try
		connection = Gadgetron.connect("localhost",args[:port])
		func = load_function(args[:module],args[:target])
		func(connection)
	finally
		close(connection)
	end 

end


end 