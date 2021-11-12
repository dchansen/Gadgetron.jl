
@traitdef IsBits{X}
@traitimpl IsBits{X} <- Base.isbitstype(X)

@traitfn function write(io::IO, object::X) where {X; IsBits{X}}
        Base.unsafe_write(io, Ref(object), Base.sizeof(object))
end

@traitfn function read(io::IO, ::Type{X}) where {X; IsBits{X}}
    val = Ref{X}()
    Base.unsafe_read(io, val, Base.sizeof(X))
    return val[]
end


read_string(x, length_type::Type=UInt32) = Base.read(x, length_type) |> Base.read $ x |> String 
function write_string(io::IO, str::String, length_type::Type=UInt32) 
    Base.write(io,length_type(length(str)))
    Base.write(io,str)
end 