module Types 
struct Bucket 
end



struct SamplingLimit
	min::UInt16
	center::UInt16
	max::UInt16
end

struct SamplingDescription
	encoded_FOV::NTuple{Float32,3}
	recon_FOV::NTuple{Float32,3}
	encoded_matrix::NTuple{UInt16,3}
	recon_matrix::NTuple{UInt16,3}
	sampling_limits::NTuple{SamplingLimit,3}
end 

struct ReconBuffer 
	data::Array{ComplexF32}
	trajectory::Optional{Array{Float32}}
	density::Optiona{Array{Float32}}
	headers::Vector{MRD.AcquisitionHeader}
	sampling::SamplingDescription
end 


struct ReconBit
	data::ReconBuffer
	reference::Optional{ReconBuffer}
end
end