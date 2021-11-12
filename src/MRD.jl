module MRD 
import FlagSets
using SimpleTraits
export Acquisition, AcquisitionHeader, EncodingCounters, write, read, Image, ImageHeader, MetaDict, AcquisitionFlags, ImageFlags
import EzXML
using PartialFunctions
using Parameters
using Setfield

include("Enm.jl")
include("serialization.jl")
include("MRDHeader.jl")
include("Acquisition.jl")
include("Image.jl")
include("Waveform.jl")

end