using Gadgetron
using Test

@testset "AcquisitionSerialization" begin 

    acq = MRD.Acquisition(MRD.AcquisitionHeader(),zeros(ComplexF32,192,12))

    io = IOBuffer()
    MRD.write(io,acq )
    seekstart(io)
    acq2 = MRD.read(io,MRD.Acquisition)

    @test acq.header == acq2.header 
    @test acq.data == acq2.data 
    @test acq == acq2
end  

