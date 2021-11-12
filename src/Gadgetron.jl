

module Gadgetron
import Sockets 

using PartialFunctions

include("MRD.jl")
include("Types.jl")

@Base.enum fixed_message_ids::UInt16 FILENAME = 1 CONFIG = 2 HEADER = 3 CLOSE = 4 TEXT = 5 QUERY =6 RESPONSE = 7 ERROR = 8

export listen, register_type, MRD


const message_ids = Dict{UInt16,Type}([(1008,MRD.Acquisition),(1022,MRD.Image),(1026, MRD.Waveform,1026),(1050,Types.Bucket),(1051, Types.Bundle)])
const message_types = Dict(value => key for (key,value ) in message_ids)


function register_type!(type::Type, message_id::UInt16)
	message_ids[message_id] = type
	message_types[type] = message_id
end


struct Connection
	socket::IO
	config
	header
end


Connection(socket) = Connection(socket,read_config(socket),read_header(socket))

listen(addr, port::Integer) = Sockets.listen(Sockets.IPv6(0),addr,port) |> Sockets.accept |> Connection
listen(port::Integer) = Sockets.listen(Sockets.IPv6(0),port) |> Sockets.accept |> Connection

read_id(x) = Sockets.read(x,UInt16)


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


	

function Base.iterate(connection::Connection, state=nothing)
	message_id = read(connection.socket,UInt16)
	if message_id == CLOSE 
		return nothing
	end

	message_type = message_ids[message_id]
	message = MRD.read(connection.socket,message_type)
	return (message,nothing)
end

function push!(connection::Connection, message )
	message_id = message_types[typeof(message)]
	write(connection.socket,message_id)
	write(connection.socket,message)
end


end