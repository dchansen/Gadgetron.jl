export Waveform, WaveformHeader

struct RawWaveformHeader 
    version::UInt16 # Version of the header 
    flags::UInt64 # bit field with flags
    measurement_uid::UInt32 # Unique id for the measurement
    scan_counter::UInt32 # Number of the acquisition after this waverform
    time_stamp::UInt32 # Time stamp of the waveform 
    number_of_samples::UInt16 # Number of samples in the waveform 
    channels::UInt16 # Number of channels per sample 
    sample_time_us::Float32 # Time between samples in micro second 
    waveform_id::UInt16 # Id matchin the types specified in the xml header 
end

struct WaveformHeader 
    version::UInt16 # Version of the header 
    flags::UInt64 # bit field with flags
    measurement_uid::UInt32 # Unique id for the measurement
    scan_counter::UInt32 # Number of the acquisition after this waverform
    time_stamp::UInt32 # Time stamp of the waveform 
    sample_time_us::Float32 # Time between samples in micro second 
    waveform_id::UInt16 # Id matchin the types specified in the xml header 
end

struct Waveform
    header::WaveformHeader
    data::Array{UInt32,2}
end

function Base.:(==)(wav1::Waveform, wav2::Waveform)
    return wav1.header == wav2.header && wav1.data == wav2.data 
end

function RawWaveformHeader(wav::Waveform)
    names = fieldnames(WaveformHeader)
    fields = Dict((n,getfield(wav.header,n)) for n in names)

    fields[:number_of_samples] = size(wav.data)[1]
    fields[:channels] = size(wav.data)[2]
    RawWaveformHeader((fieldnames(RawWaveformHeader) .|> n -> fields[n])...)

end

@generated function WaveformHeader(raw::RawWaveformHeader)
    names = fieldnames(WaveformHeader)
    args = names .|> s -> Expr(:call,:getfield,:raw,QuoteNode(s))
    :(WaveformHeader($(args...)))
end

write(io::IO, header::RawWaveformHeader) = fieldnames(RawWaveformHeader) .|> getfield $ header .|> MRD.unsafe_write $ io
read(io::IO, ::Type{RawWaveformHeader}) = RawWaveformHeader((fieldnames(RawWaveformHeader) .|> fieldtype $ RawWaveformHeader .|> MRD.unsafe_read $ io)...)

function read(io::IO, ::Type{Waveform})
    header = MRD.read(io::IO, RawWaveformHeader)
    data = Array{UInt32,2}(undef, header.number_of_samples, header.channels)
    Base.read!(io, data)
    return Waveform(WaveformHeader(header), data)
end   

function write(io::IO, wav::Waveform)
    write(io, RawWaveformHeader(wav))
    Base.write(io,wav.data)
end



