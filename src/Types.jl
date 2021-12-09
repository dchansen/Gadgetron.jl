module Types 

using ..Default : Optional
include("AcquisitionBucket.jl")

struct SamplingLimit 
    min::UInt16
    center::UInt16
    max::UInt16
end

struct SamplingDescription
    encoded_fov::NTuple{Float32,3}
    recon_fov::NTuple{Float32,3}
    encoded_matrix::NTuple{UInt16,3}
    recon_matrix::NTuple{UInt16,3}
    sampling_limits::NTuple{SamplingLimit,3}
end 

struct ReconBuffer 
    data::Array{ComplexF32}
    trajectory::Optional{Array{Float32}}
    density::Optional{Array{Float32}}
    header:: Array{MRD.AcquisitionHeader}
    sampling_description::SamplingDescription 

end


struct ReconBit
    data::ReconBuffer
    ref::Optional{ReconBuffer}
end

struct ReconData
    bits::Vector{ReconBit}
end

Base.getindex(rd::ReconData,i::Int) = rd.bits[i]
Base.setindex(rd::ReconData,val::ReconBit,i::Int) = rd.bits[i] = val 
Base.firstindex(rd::ReconData) = firstindex(rd.bits)
Base.lastindex(rd::ReconData) = lastindex(rd.bits)

end