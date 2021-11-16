include("../src/Gadgetron.jl")
using .Gadgetron
using Test

@testset "ImageSerialization" begin 


    img = MRD.Image(MRD.ImageHeader(version=4, acquisition_time_stamp=42), zeros(Float32, 2,3,4,1))
end  