

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


write(io::IO, val::T) where {T <: Number} = unsafe_write(io,val)
read(io::IO, type::Type{T}) where {T <: Number} = unsafe_read(io,type)

write(io::IO, obj::NTuple{N,T}) where {N,T <: Real } = foreach(x->unsafe_write(io,x),obj)
read(io::IO, ::Type{NTuple{N,T}}) where {N,T <: Real } = NTuple{N,T}(unsafe_read(io,T) for i in 1:N ) 

write(io::IO, obj::NTuple{N,T}) where {N,T} = foreach(x->MRD.write(io,x),obj)
read(io::IO, ::Type{NTuple{N,T}}) where {N,T} = NTuple{N,T}(MRD.read(io,T) for i in 1:N ) 

function write(io::IO, obj::Vector{T} ) where {T<: Number}
    Base.write(io,UInt64(length(obj)))
    Base.write(io,obj)
end

function write(io::IO, obj::Vector{T}) where {T}
    Base.write(io,UInt64(length(obj)))
    for k in obj
        write(io,k)
    end
end

function read(io::IO, ::Type{Vector{T}}) where {T<: Number}
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

function read(io::IO, ::Type{Array{T}}) where {T <: Number}
    dims = MRD.read(io, Vector{UInt64})
    data = Array{T}(undef, dims...)
    Base.read!(io,data)
    return data 
end
function read(io::IO, ::Type{Array{T}}) where {T}
    dims = MRD.read(io, Vector{UInt64})
    data = Array{T}(undef, dims...)
    for i in 1:length(data)
        data[i] = MRD.read(io, T)
    end
    return data 
end

function write(io::IO, arr::Array{T,N}) where {T <: Number, N}
    MRD.write(io, convert(Vector{UInt64},[size(arr)...]))
    Base.write(io,arr)
end
function write(io::IO, arr::Array{T,N}) where {T ,N}
    MRD.write(io, convert(Vector{UInt64},[size(arr)...]))
    for elem in arr
        MRD.write(io,elem)
    end
end

    
function read_optional(io::IO, ::Type{T}) where {T}
    exists = Base.read(io, UInt8) |> Bool
    if exists 
        return MRD.read(io, T)
    end
    return nothing 
end

read(io::IO, ::Type{Optional{T}}) where {T} = read_optional(io,T)
    

read(io::IO, ::Type{Set{T}}) where {T} = read(io, Vector{T}) |> Set 
write(io::IO, obj::Set{T}) where {T} = write(io, [x for x in obj])

is_optional(::Type{T}) where {T} = return typeof(T) == Union && Nothing <: T 
    
 

function read_struct(io::IO, ::Type{T}) where {T}
    types = fieldtypes(T)

    function read_field(field_type)
        if is_optional(field_type)
            return MRD.read_optional(io,field_type.b)
        end
        return MRD.read(io,field_type)
    end

    return T( (read_field(field_type) for field_type in types)...)
end    

function write_struct(io::IO, obj::T) where {T}
    names = fieldnames(T)
    for name in names
        MRD.write(io, getfield(obj,name))
    end 
end



