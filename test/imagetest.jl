using Gadgetron
using Test

@testset "ImageSerialization" begin 


    meta = MRD.MetaDict()
    meta["penguin"] = 2.0
    meta["dinosaur"] = [2,3,4]
    img = MRD.Image(MRD.ImageHeader(version=4, acquisition_time_stamp=42), zeros(Float32, 2,3,4,1),meta)
    io = IOBuffer()
    MRD.write(io,img)
    seekstart(io)
    img3 = MRD.read(io,MRD.Image)

    @test img.header == img3.header 
    @test img.data == img3.data 
    @test img.meta == img3.meta
end  

@testset "ImageSize" begin 

    img = MRD.Image(MRD.ImageHeader(),zeros(Float32,1,1,1,1))
    header = MRD.RawImageHeader(img)

    io = IOBuffer()

    MRD.write(io,header)

    @test position(io) == 198
    meta = MRD.MetaDict()
    MRD.write(io,meta)
    @test position(io) == (198+8)

    io = IOBuffer()

end 