module Gadgetron
import Sockets 

using PartialFunctions

include("MRD.jl")
include("Types.jl")
include("StreamAlgorithms.jl")

@Base.enum fixed_message_ids::UInt16 FILENAME = 1 CONFIG = 2 HEADER = 3 CLOSE = 4 TEXT = 5 QUERY =6 RESPONSE = 7 ERROR = 8

export listen, connect,register_type, MRD, close, Stream


const message_ids = Dict{UInt16,Type}([(1008,MRD.Acquisition),(1022,MRD.Image),(1026, MRD.Waveform,1026),(1050,Types.Bucket),(1051, Types.Bundle)])
const message_types = Dict(value => key for (key,value ) in message_ids)


function register_type!(type::Type, message_id::UInt16)
	message_ids[message_id] = type
	message_types[type] = message_id
end


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

mutable struct MRDRemoteConnection <: AbstractChannel{Any}
	socket::IO 
	inputchannel::Channel
	outputchannel::Channel
	outputtask::Ref{Task}
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

function Base.close(m::MRDRemoteConnection) 
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

MRDChannel(socket; kwargs...) = MRDChannel(read_config(socket),read_header(socket), MRDRemoteConnection(socket; kwargs...))

listen(addr, port::Integer) = Sockets.listen(Sockets.IPv6(0),addr,port) |> Sockets.accept |> MRDChannel
function listen(port::Integer; kwargs...)
	socket = Sockets.listen(Sockets.IPv6(0),port) |> Sockets.accept
	return MRDChannel(socket; kwargs...)
end


connect(addr, port::Integer) = Sockets.connect(addr,port) |> MRDChannel

read_id(x) = Sockets.read(x,UInt16)

Base.put!(c::MRDChannel,v) = put!(c.channel,v)
Base.take!(c::MRDChannel) = take!(c.channel)
Base.close(c::MRDChannel) = close(c.channel)
Base.fetch(c::MRDChannel) = fetch(c.channel)
Base.isready(c::MRDChannel) = isread(c.channel)
Base.wait(c::MRDChannel) = wait(c.channel)



function read_config(socket::IO)
	message_id = read_id(socket)
	@assert message_id == UInt16(CONFIG) "Expected CONFIG message id, received $message_id"
	return MRD.read_string(socket)
end

function read_header(socket::IO)
	message_id = read_id(socket)
	@assert message_id == UInt16(HEADER) "Expected HEADER message id, received $message_id"
	return MRD.read_string(socket) |> MRD.MRDHeader
end


include("Main.jl")

end
