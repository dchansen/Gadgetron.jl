
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
    datastats::AcquisitionBucketStats
    ref::Vector{MRD.Acquisition}
    refstats::AcquisitionBucketStats
    waveforms::Vector{MRD.Waveform}
end 

module AcqBuckInternal 
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


function read_data_as_aray(io::IO, data_type::Type,shape)
    res = zeros(data_type, shape)
    Base.read(io,res)
    return res 
end

function read_waveforms(io::IO, meta::waveform_meta)
    headers = [MRD.read(io,MRD.RawWaveformHeader) for i in 1:meta.count]
    data_arrays = [ read_data_as_aray(io,UInt32,(header.number_of_samples, header.channels)) for header in headers ]

    return [MRD.Waveform(MRD.WaveformHeader(header),data) for (header,data) in zip(headers,data_arrays)]
end

function read_acquisitions(io::IO, meta::waveform_meta)
    headers = [MRD.read(io,MRD.RawAcquisitionHeader) for i in 1:meta.count]
    data_arrays = [ read_data_as_aray(io,UInt32,(header.number_of_samples, header.channels)) for header in headers ]

    trajectories = [read_data_as_aray(io,Float32,(head.number_of_samples,head.trajectory_dimensions)) for head in headers]

    acqs = [read_data_as_aray(io,ComplexF32,(head.active_channels,head.number_of_samples) for head in headers)]

    return [MRD.Acquisition(MRD.AcquisitionHeader(header),data,trajectory) for (header,data,trajectory) in zip(headers,data_arrays,trajectories)]
end


end 