
struct AcquisitionBucketStats
    kspace_encode_step_1::Set{UInt16}
    kspace_encode_step_2::Set{UInt16}
    contrast::Set{UInt16}
    slice::Set{UInt16}
    phase::Set{UInt16}
    repetition::Set{UInt16}
    segment::Set{UInt16}
    average::Set{UInt16}
    set::Set{UInt16}
end 


struct AcquisitionBucket

    data::Vector{MRD.Acquisition}
    datastats::Vector{AcquisitionBucketStats}
    ref::Vector{MRD.Acquisition}
    refstats::Vector{AcquisitionBucketStats}
    waveforms::Vector{MRD.Waveform}
end 

module AcqBuckInternal 

using Gadgetron.MRD
struct bundle_meta
    count::UInt64
    header_bytes::UInt64
    data_bytes::UInt64
    trajectory_bytes::UInt64
end 

struct waveform_meta 
    count::UInt64
    header_bytes::UInt64
    data_bytes::UInt64
end 

struct bucket_meta
    data::bundle_meta
    reference::bundle_meta
    data_stats::UInt64
    reference_stats::UInt64
    waveforms::waveform_meta
end 


function read_data_as_array(io::IO, data_type::Type{T},shape) where {T}
    res = Matrix{T}(undef, shape...)
    Base.read!(io,res)
    return res 
end

function read_waveforms(io::IO, meta::waveform_meta)
    headers = [MRD.read(io,MRD.RawWaveformHeader) for i in 1:meta.count]
    data_arrays = [ read_data_as_array(io,UInt32,(header.number_of_samples, header.channels)) for header in headers ]

    return [MRD.Waveform(MRD.WaveformHeader(header),data) for (header,data) in zip(headers,data_arrays)]
end

function read_acquisitions(io::IO, meta::bundle_meta)
    headers = [MRD.read(io,MRD.RawAcquisitionHeader) for i in 1:meta.count]

    trajectories = [read_data_as_array(io,Float32,(head.number_of_samples,head.trajectory_dimensions)) for head in headers]

    acqs = [read_data_as_array(io,ComplexF32,(head.active_channels,head.number_of_samples)) for head in headers]

    return [MRD.Acquisition(MRD.AcquisitionHeader(header),data,trajectory) for (header,data,trajectory) in zip(headers,acqs,trajectories)]
end
end 

MRD.read(io::IO, ::Type{AcquisitionBucketStats}) = MRD.read_struct(io, AcquisitionBucketStats)

function MRD.read(io::IO, ::Type{AcquisitionBucket}) 
    meta = MRD.unsafe_read(io, AcqBuckInternal.bucket_meta)

    AcquisitionBucket(
        AcqBuckInternal.read_acquisitions(io,meta.data),
        MRD.read(io,Vector{AcquisitionBucketStats}),
        AcqBuckInternal.read_acquisitions(io,meta.reference),
        MRD.read(io, Vector{AcquisitionBucketStats}),
        AcqBuckInternal.read_waveforms(io,meta.waveforms)
    )
end 
