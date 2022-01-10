module Gadgetron
import Sockets 

using PartialFunctions

include("Default.jl")
include("MRD.jl")
include("Types.jl")
include("StreamAlgorithms.jl")


export listen, connect,register_type, MRD, close, Stream


@Base.enum fixed_message_ids::UInt16 FILENAME = 1 CONFIG = 2 HEADER = 3 CLOSE = 4 TEXT = 5 QUERY =6 RESPONSE = 7 ERROR = 8
const message_ids = Dict{UInt16,Type}([(1008,MRD.Acquisition),(1022,MRD.Image),(1026, MRD.Waveform,1026),(1050,Types.AcquisitionBucket),(1023, Types.ReconData)])
const message_types = Dict(value => key for (key,value ) in message_ids)

"""
	register_type!(type::Type, message_id::UInt16)
Registers a type with the Gadgetron system.  Types must implement MRD.write and MRD.read
"""
function register_type!(type::Type, message_id::UInt16)
	message_ids[message_id] = type
	message_types[type] = message_id
end


"""
	MRDChannel
An Abstract channel of MRD data.

# Fields 
- config Configuration of the channel. Currently a string but may change in the future
- header The dataset header 
- channel The channel containing the message 
"""
mutable struct MRDChannel <: AbstractChannel{Any}
	config
	header::MRD.MRDHeader
	channel::AbstractChannel
	function MRDChannel(config, header, channel)
		conn = new(config, header,channel)
		finalizer(close,conn)
	end
end

Base.iterate(m::MRDChannel, state...) = iterate(m.channel, state...)

"""
	MRDRemoteConnection
	An connection to an external endpoint using the MRD protocol
"""
mutable struct MRDRemoteConnection <: AbstractChannel{Any}
	socket::IO 
	inputchannel::Channel
	outputchannel::Channel
	outputtask::Ref{Task}
	"Creates a remote connection from a newly opened socket "
	function MRDRemoteConnection(socket::IO; buffer::Real=Inf, spawn=true)

		input = Channel(buffer, spawn=spawn) do c
			message_id = read_id(socket)
			while message_id != UInt16(CLOSE)
				message_type = message_ids[message_id]
				push!(c, MRD.read(socket, message_type))
				message_id = read_id(socket)
			end
		end

		outputtask = Ref{Task}()
		output = Channel(buffer, spawn=spawn, taskref=outputtask) do c 
			for msg in c 
				message_id = message_types[typeof(msg)]
				write(socket,message_id)
				MRD.write(socket, msg)
			end
		end

		new(socket, input, output, outputtask )
	end 


end

Base.take!(m::MRDRemoteConnection) = take!(m.inputchannel)
Base.fetch(m::MRDRemoteConnection) = fetch(m.inputchannel)
Base.isready(m::MRDRemoteConnection) = isread(m.inputchannel)
Base.wait(m::MRDRemoteConnection) = wait(m.inputchannel)
Base.put!(m::MRDRemoteConnection,v ) = put!(m.outputchannel,v)

"Closes the connection by sending a close message and closing the network socket"
function Base.close(m::MRDRemoteConnection)
	if !isopen(m.outputchannel) return; end
	close(m.outputchannel)
	wait(m.outputtask[])
	if typeof(m.socket) == Sockets.TCPSocket
		if iswritable(m.socket) 
			write(m.socket,CLOSE)
			Sockets.close(m.socket)
		end
	end	
end

Base.iterate(m::MRDRemoteConnection, state...) = iterate(m.inputchannel, state...)

"Creates an MRD channel from a newly opened socket"
MRDChannel(socket; kwargs...) = MRDChannel(read_config(socket),read_header(socket), MRDRemoteConnection(socket; kwargs...))

"Waits for a connection on the given address and port "
listen(addr, port::Integer) = Sockets.listen(Sockets.IPv6(0),addr,port) |> Sockets.accept |> MRDChannel
function listen(port::Integer; kwargs...)
	socket = Sockets.listen(Sockets.IPv6(0),port) |> Sockets.accept
	return MRDChannel(socket; kwargs...)
end


"Waits for a connection on the given adress and port"
function listen(recon_function::Function, port::Integer; kwargs... )
	connection = listen(port; kwargs...)
	try 
		recon_function(connection)
	finally
		close(connection)
	end
end

"Similar to listen, but will keep serving the function"
function serve_forever(recon_function::Function, port::Integer; kwargs...)
	server =Sockets.listen(Sockets.IPv6(0),port)
	while true 
		socket = Sockets.accept(server)
		channel = MRDChannel(socket; kwargs...)
		try
			recon_function(channel)
		finally
			close(channel)
		end
	end
end 

"Connect to an open MRD server "
connect(addr, port::Integer) = Sockets.connect(addr,port) |> MRDChannel

function connect(addr, port::Integer, config::String, header::MRD.MRDHeader) 
	socket = Sockets.connect(addr,port )
	write_config(socket,config)
	write_header(socket, header)
	return MRDChannel(config,header,MRDRemoteConnection(socket))
end

read_id(x) = Sockets.read(x,UInt16)

Base.put!(c::MRDChannel,v) = put!(c.channel,v)
Base.take!(c::MRDChannel) = take!(c.channel)
Base.close(c::MRDChannel) = close(c.channel)
Base.fetch(c::MRDChannel) = fetch(c.channel)
Base.isready(c::MRDChannel) = isread(c.channel)
Base.wait(c::MRDChannel) = wait(c.channel)



"Reads a config message from a socket "
function read_config(socket::IO)
	message_id = read_id(socket)
	@assert message_id == UInt16(CONFIG) "Expected CONFIG message id, received $message_id"
	return MRD.read_string(socket)
end

"Reads a header message form a socket "
function read_header(socket::IO)
	message_id = read_id(socket)
	@assert message_id == UInt16(HEADER) "Expected HEADER message id, received $message_id"
	return MRD.read_string(socket) |> MRD.MRDHeader
end

function write_config(socket::IO, config::String)
	write(socket,CONFIG)
	MRD.write_string(socket,config)
end

function write_header(socket::IO, header::MRD.MRDHeader)
	write(socket,HEADER)
	MRD.write_string(socket, string(header.aml))
end




include("Main.jl")

end
