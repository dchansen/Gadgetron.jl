

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

write(io::IO, obj::Tuple{Vararg{Real,N}}) where {N} = unsafe_write(io, obj)
read(io::IO, ::Type{Tuple{Vararg{Real,N}}}) where {N} = unsafe_read(io, Tuple{Vararg{Real,N}})


function write(io::IO, obj::Vector{T} ) where {T<: Real}
    Base.write(io,UInt64(length(obj)))
    Base.write(io,obj)
end

function read(io::IO, ::Type{Vector{T}}) where {T<: Real}
    length = Base.read(io,UInt64)
    data = zeros(T, length)
    Base.read!(io,data)
    return data
end





