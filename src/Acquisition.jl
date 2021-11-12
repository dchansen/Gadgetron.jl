export Acquisition, AcquisitionFlags, EncodingCounters, AcquisitionHeader


module AcquisitionFlags 
import FlagSets
@FlagSets.flagset Flags {_,UInt64} begin 
    :first_in_encode_step1
    :last_in_encode_step1
    :first_in_encode_step2
    :last_in_encode_step2
    :first_in_average
    :last_in_average
    :first_in_slic
    :last_in_slice
    :first_in_contrast
    :last_in_constrat
    :first_in_phase
    :last_in_phase
    :first_in_repetition
    :last_in_repetition
    :first_in_set
    :last_in_set
    :first_in_segment
    :last_in_segment
    :is_noise_measurement
    :is_parallel_calibration
    :is_parallel_calibration_and_imaging
    :is_reverse
    :is_navigation
    :is_phasecorr_data
    :last_in_measurement
    :is_hpfeedback_data
    :is_dummyscan_data
    :is_rtfeedback_data
    :is_surfacecoilcorrectionscan_data
end
end 


struct EncodingCounters
    kspace_encode_step_1::UInt16
    kspace_encode_step_2::UInt16
    average::UInt16
    slice::UInt16
    contrast::UInt16
    phase::UInt16
    repetition::UInt16
    set::UInt16
    segment::UInt16
    user::NTuple{8,UInt16}
end
struct RawAcquisitionHeader
    version::UInt16
    flags::AcquisitionFlags.Flags
    measurement_uid::UInt32
    scan_counter::UInt32
    acquisition_time_stamp::UInt32
    physiology_time_stamp::NTuple{3,UInt32}
    number_of_samples::UInt16
    available_channels::UInt16
    active_channels::UInt16
    channel_mask::NTuple{16,UInt64}
    discard_pre::UInt16
    discard_post::UInt16
    center_sample::UInt16
    encoding_space_ref::UInt16
    trajectory_dimensions::UInt16
    sample_time_us::Float32
    position::NTuple{3,Float32}
    read_dir::NTuple{3,Float32}
    phase_dir::NTuple{3,Float32}
    slice_dir::NTuple{3,Float32}
    patient_table_position::NTuple{3,Float32}
    idx::EncodingCounters
    user_int::NTuple{8,Int32}
    user_float::NTuple{8,Float32}
end

@with_kw struct AcquisitionHeader
    version::UInt16 = 1
    flags::AcquisitionFlags.Flags = AcquisitionFlags.Flags(0)
    measurement_uid::UInt32 = 0
    scan_counter::UInt32 = 0
    acquisition_time_stamp::UInt32 = 0
    physiology_time_stamp::NTuple{3,UInt32} = (0,0,0)
    available_channels::UInt16 = 0
    channel_mask::NTuple{16,UInt64} = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    discard_pre::UInt16 = 0
    discard_post::UInt16 = 0
    center_sample::UInt16 = 0
    encoding_space_ref::UInt16 = 0
    sample_time_us::Float32 = 0
    position::NTuple{3,Float32} = (0,0,0)
    read_dir::NTuple{3,Float32} = (1,0,0)
    phase_dir::NTuple{3,Float32} = (0,1,0)
    slice_dir::NTuple{3,Float32} = (0,0,1)
    patient_table_position::NTuple{3,Float32} = (0,0,0)
    idx::EncodingCounters = EncodingCounters(0,0,0,0,0,0,0,0,0,(0,0,0,0,0,0,0,0))
    user_int::NTuple{8,Int32} = (0,0,0,0,0,0,0,0)
    user_float::NTuple{8,Float32} = (0,0,0,0,0,0,0,0)
end



struct Acquisition
    header::AcquisitionHeader
    data::Array{ComplexF32,2}
    trajectory::Union{Array{Float32},Nothing} 
end

function RawAcquisitionHeader(acq::Acquisition)
    names = fieldnames(AcquisitionHeader)
    fields = Dict((n,getfield(acq.header,n)) for n in names)
    fields[:number_of_samples] = size(acq.data)[1]
    fields[:active_channels] = size(acq.data)[2]
    if acq.trajectory === nothing 
        fields[:trajectory_dimensions] = size(acq.trajectory)[1]
    else
        fields[:trajectory_dimension] = 0
    end

    RawAcquisitionHeader((fieldnames(RawAcquisitionHeader) .|> n -> fields[n])...)

end

@generated function AcquisitionHeader(raw::RawAcquisitionHeader)
    names = fieldnames(AcquisitionHeader)
    args = names .|> s -> Expr(:call,:getfield,:raw,QuoteNode(s))
    :(AcquisitionHeader($(args...)))
end


write(io::IO, header::RawAcquisitionHeader) = fieldnames(RawAcquisitionHeader) .|> getfield $ header .|> write $ io
read(io::IO, ::Type{RawAcquisitionHeader}) = RawAcquisitionHeader((fieldnames(RawAcquisitionHeader) .|> fieldtype $ RawAcquisitionHeader .|> read $ io)...)

function read(io::IO, ::Type{Acquisition})
    header = MRD.read(io::IO, RawAcquisitionHeader)
    if (header.trajectory_dimensions > 0)
        trajectory = Array{Float32,2}(undef, header.trajectory_dimensions, header.number_of_samples)
        Base.read!(io, trajectory)
    else
        trajectory = nothing
    end
    data = Array{ComplexF32,2}(undef, header.number_of_samples, header.active_channels)
    Base.read!(io, data)
    
    return Acquisition(AcquisitionHeader(header), data, trajectory)

end   

function write(io::IO, acq::Acquisition)
    write(io, RawAcquisitionHeader(acq))
    if !isa(acq.trajectory, Nothing)
        Base.write(io, acq.trajectory)
    end
        Base.write(io::IO, acq.data)
end



