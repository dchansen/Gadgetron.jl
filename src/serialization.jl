

read_string(x, length_type::Type=UInt32) = Base.read(x, length_type) |> Base.read $ x |> String 
function write_string(io::IO, str::String, length_type::Type=UInt32) 
    Base.write(io,length_type(ncodeunits(str)))
    Base.write(io,str)
end 

function unsafe_write(io::IO, obj)
    @assert Base.isbitstype(typeof(obj))
    Base.unsafe_write(io,Ref(obj),Base.sizeof(obj))
end

function unsafe_read(io::IO,::Type{T}) where{T}
    @assert Base.isbitstype(T)
    val = Ref{T}()
    Base.unsafe_read(io,val, Base.sizeof(T))
    return val[] 
end


write(io::IO, val::T) where {T <: Real} = unsafe_write(io,val)
read(io::IO, type::Type{T}) where {T <: Real} = unsafe_real(io,type)

write(io::IO, obj::NTuple{N,T}) where {N,T <: Real } = foreach(x->unsafe_write(io,x),obj)
read(io::IO, ::NTuple{N,T}) where {N,T <: Real } = (unsafe_read(io,T) for i in 1:N ) 


function write(io::IO, obj::Vector{T} ) where {T<: Real}
    Base.write(io,UInt64(length(obj)))
    Base.write(io,obj)
end

function write(io::IO, obj::Vector{T}) where {T}
    Base.write(io,UInt64(length(obj)))
    for k in obj
        write(io,k)
    end
end

function read(io::IO, ::Type{Vector{T}}) where {T<: Real}
    length = Base.read(io,UInt64)
    data = Vector{T}(undef, length)
    Base.read!(io,data)
    return data
end

function read(io::IO, ::Type{Vector{T}}) where {T}
    length = Base.read(io,UInt64)
    data = Vector{T}(undef,length)
    for i=1:length 
        data[i] = read(io,T)
    end
    return data 
end

read(io::IO, ::Type{Set{T}}) where {T} = read(io, Vector{T}) |> Set 
write(io::IO, obj::Set{T}) where {T} = write(io, [x for x in obj])

function read_struct(io::IO, ::Type{T}) where {T}
    types = fieldtypes(T)

    return T( (read(io,field_type) for field_type in types)...)
end    

function write_struct(io::IO, obj::T) where {T}
    names = fieldnames(T)
    for name in names
        write(io, getfield(obj,name))
    end 
end



