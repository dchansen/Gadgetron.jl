include("../MRD.jl")
import .MRD
using Test 
using AcuteML
import EzXML
using Maybe 

example_header = """<?xml version="1.0" encoding="utf-8"?>
<ismrmrdHeader xmlns="http://www.ismrm.org/ISMRMRD" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.ismrm.org/ISMRMRD ismrmrd.xsd">
   <experimentalConditions>
      <H1resonanceFrequency_Hz>32130323</H1resonanceFrequency_Hz>
   </experimentalConditions>
   <encoding>
      <encodedSpace>
         <matrixSize>
            <x>64</x>
            <y>64</y>
            <z>1</z>
         </matrixSize>
         <fieldOfView_mm>
            <x>300</x>
            <y>300</y>
            <z>40</z>
         </fieldOfView_mm>
      </encodedSpace>
      <reconSpace>
         <matrixSize>
            <x>64</x>
            <y>64</y>
            <z>1</z>
         </matrixSize>
         <fieldOfView_mm>
            <x>300</x>
            <y>300</y>
            <z>40</z>
         </fieldOfView_mm>
      </reconSpace>
      <trajectory>radial</trajectory>
      <encodingLimits>
      </encodingLimits>
   </encoding>
</ismrmrdHeader>
"""


function print_to_string(object)
   io = IOBuffer()
   print(io,object)
   seekstart(io)
   return String(take!(io))
end

@testset "HeaderSerialization" begin 

   header = MRD.MRDHeader(example_header)

    header_xml = EzXML.parsexml(string(header.aml))
    reference_xml = EzXML.parsexml(example_header)
   

   @test print_to_string(header_xml) == print_to_string(reference_xml)

end

@testset "HeaderMaybe" begin 

   header = MRD.MRDHeader(example_header)
   enc = @?  header.encoding[2]
   @test enc === nothing 

   systemInfo = @? header.encoding[1].acquisitionSystemInformation
   @test systemInfo === nothing

   noise = @? header.encoding[1].acquisitionSystemInformation.relativeNoiseBandwidth
   @test noise === nothing 

end