include("../src/Gadgetron.jl")
using .Gadgetron
using Test

@testset "ImageSerialization" begin 


    img = MRD.Image(MRD.ImageHeader(version=4, acquisition_time_stamp=42), zeros(Float32, 2,3,4,1))
    img2 = MRD.Image(MRD.ImageHeader(version=4, acquisition_time_stamp=42), zeros(Float32, 2,3,4,1))
    @test img.header == img2.header
    @test img.data == img2.data
    @test img.meta == img2.meta
    io = IOBuffer()
    MRD.write(io,img)
    seekstart(io)
    img3 = MRD.read(io,MRD.Image)

    @test img == img3 
end  