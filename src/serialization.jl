

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



write(io::IO, obj::Tuple{Vararg{Real,N}}) where {N} = unsafe_write(io, obj)
read(io::IO, ::Type{Tuple{Vararg{Real,N}}}) where {N} = unsafe_read(io, Tuple{Vararg{Real,N}})

