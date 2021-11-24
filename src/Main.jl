module External 
using  ArgParse 
using Logging 
using ..Gadgetron
import Dates 

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
	func_expr = Expr(:.,loaded_module,QuoteNode(Symbol(target)))
	@debug "Created expression $func_expr"


	return Meta.eval(func_expr)
end

function log_formatter(level, _module , group, id, file, line)
	timestamp = Dates.format(Dates.now(),"m-d H:M:S.s")
	prefix = "$timestamp $level [$file:$line] "
	suffix = ""

	return (:default, prefix, suffix )
end

function main()
	args = parse_commandline()

	Base.global_logger(ConsoleLogger(stdout,Logging.Info ))

	@info  "Starting external Julia module $(args[:module]) in state: [ACTIVE]"
	@info "Connection to parent on port $(args[:port])"


	func = load_function(args[:module],args[:target])
	connection = Gadgetron.connect("localhost",args[:port])

	try
		Base.invokelatest(func,connection)
	finally
		close(connection)
	end 

end

Base.precompile(Tuple{typeof(main)})   


end 