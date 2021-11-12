
include("MetaDict.jl")

export Image, ImageHeader, ImageFlags

@enm ImageType::UInt16 magnitude = 1 phase = 2 real = 3 imag = 4 complex = 5
@enm TypeIndex::UInt16 ushort = 1 short = 2 uint = 3 int = 4 float = 5 double = 6 cxfloat =
    7 cxdouble = 8

datatype_to_type = Base.Dict{TypeIndex.Enm,Type}([
    (TypeIndex.ushort, UInt16),
    (TypeIndex.short, Int16),
    (TypeIndex.uint, UInt32),
    (TypeIndex.int, Int32),
    (TypeIndex.float, Float32),
    (TypeIndex.double, Float64),
    (TypeIndex.cxfloat, ComplexF32),
    (TypeIndex.cxdouble, ComplexF64),
])
type_to_datatype = Base.Dict(value => key for (key, value) in datatype_to_type)
is_mrd_datatype(X) = X ∈ keys(type_to_datatype)



module ImageFlags
import FlagSets
FlagSets.@flagset Flags {_, UInt64} begin
    :is_navigation_data
    72057594037927936 --> :user1
    :user2
    :user3
    :user4
    :user5
    :user6
    :user7
    :user8
end
end


@with_kw struct ImageHeader
    version::UInt16 = 1
    flags::ImageFlags.Flags = ImageFlags.Flags(0)
    measurement_uid::UInt32 = 0
    field_of_view::NTuple{3,Float32} = (0, 0, 0)
    position::NTuple{3,Float32} = (0, 0, 0)
    read_dir::NTuple{3,Float32} = (1, 0, 0)
    phase_dir::NTuple{3,Float32} = (0, 1, 0)
    slice_dir::NTuple{3,Float32} = (0, 0, 1)
    patient_table_position::NTuple{3,Float32} = (0, 0, 0)
    average::UInt16 = 0
    slice::UInt16 = 0
    contrast::UInt16 = 0
    phase::UInt16 = 0
    repetition::UInt16 = 0
    set::UInt16 = 0
    acquisition_time_stamp::UInt16 = 0
    physiology_time_stamp::NTuple{3,UInt32} = (0, 0, 0)
    image_type::ImageType.Enm = ImageType.magnitude
    image_index::UInt16 = 0
    image_series_index::UInt16 = 0
    user_int::NTuple{8,Int32} = (0, 0, 0, 0, 0, 0, 0, 0)
    user_float::NTuple{8,Float32} = (0, 0, 0, 0, 0, 0, 0, 0)
end


struct Image{T}
    header::ImageHeader
    data::Array{T,4}
    meta::MetaDict
    function Image{T}(header, data, meta = MetaDict()) where {T}
        is_mrd_datatype(T) || error("Only MRD standard types supported")
        ndims(data) <= 4 || error("Images have a maximum of 4 dimensions")
        data = reshape(data, Val(4))
        new(header, data, meta)
    end

end


struct RawImageHeader

    version::UInt16
    data_type::TypeIndex.Enm
    flags::ImageFlags.Flags
    measurement_uid::UInt32
    matrix_size::NTuple{3,UInt16}
    field_of_view::NTuple{3,Float32}
    channels::UInt16
    position::NTuple{3,Float32}
    read_dir::NTuple{3,Float32}
    phase_dir::NTuple{3,Float32}
    slice_dir::NTuple{3,Float32}
    patient_table_position::NTuple{3,Float32}
    average::UInt16
    slice::UInt16
    contrast::UInt16
    phase::UInt16
    repetition::UInt16
    set::UInt16
    acquisition_time_stamp::UInt16
    physiology_time_stamp::NTuple{3,UInt32}
    image_type::ImageType.Enm
    image_index::UInt16
    image_series_index::UInt16
    user_int::NTuple{8,Int32}
    user_float::NTuple{8,Float32}
end

function RawImageHeader(image::Image{T}) where {T}
    channels = UInt16(size(image.data)[4])
    matrix_size = Tuple{UInt16,UInt16,UInt16}(size(image.data)[1:3])
    data_type = type_to_datatype[T]
    hdr = image.header

    RawImageHeader(
        hdr.version,
        data_type,
        hdr.flags,
        hdr.measurement_uid,
        matrix_size,
        hdr.field_of_view,
        channels,
        hdr.position,
        hdr.read_dir,
        hdr.phase_dir,
        hdr.slice_dir,
        hdr.patient_table_position,
        hdr.average,
        hdr.slice,
        hdr.contrast,
        hdr.phase,
        hdr.repetition,
        hdr.set,
        hdr.acquisition_time_stamp,
        hdr.physiology_time_stamp,
        hdr.image_type,
        hdr.image_index,
        hdr.image_series_index,
        hdr.user_int,
        hdr.user_float,
    )

end


@generated function ImageHeader(raw::RawImageHeader)
    names = fieldnames(ImageHeader)
    args = names .|> s -> Expr(:call,:getfield,:raw,QuoteNode(s))
    :(ImageHeader($(args...)))
end


function ImageHeader(acq::AcquisitionHeader; kwargs...)
    names = (:version, :measurement_uid, :position, :read_dir, :phase_dir, :slice_dir, :patient_table_position, :acquisition_time_stamp, :physiology_time_stamp, :usr_int, :usr_float )

    fields_acq = (n => getfield(acq,n) for n in names)

    names_idx = (:average,:slice, :contract,:phase,:repetition, :set)
    fields_idx = (n => getfield(acq.idx,n) for n in names_idx)

    fields = merge(fields_acq,fields_idx,kwargs)

    return ImageHeader(fields...)
end 

write(io::IO, header::RawImageHeader) = fieldnames(ImageHeader) .|> getfield $ header .|> write $ io

function write(io::IO, img::Image)
    write(io, RawImageHeader(img))
    Base.write(io, img.data)
end

read(io::IO, ::Type{RawImageHeader}) = RawImageHeader((fieldnames(ImageHeader) .|> fieldtype $ RawImageHeader .|> read $ io)...)

function read(io::IO, ::Type{Image})
    header = MRD.read(io, RawImageHeader) 
    meta = MRD.read(io, MetaDict)
    data_type = datatype_to_type[header.data_type]
    
    data = Array{data_type,4}(undef, header.matrix_size[0], header.matrix_size[1], header.matrix_size[2], header.channels)
    Base.read!(io, data)
    return Image(ImageHeader(header), data, meta)

end
