using Gadgetron
using Test 


@testset  "Meta" begin 

	meta = MRD.MetaDict()
	meta["Pie"] = 5

	@test meta["Pie"] == 5

	meta["Penguin"] = [1,2,"Pie"]

	@test meta["Penguin"] == [1,2,"Pie"]

	MRD.push!(meta, "Pie", 6, 7)
	@test meta["Pie"] == [5,6,7]
end

@testset "MetaSerialization" begin 

	xmlstring = b"<?xml version=\"1.0\"?>
<ismrmrdMeta>
  <meta>
    <name>pi</name>
    <value>3.14159265</value>
  </meta>
  <meta>
    <name>extra</name>
    <value>Hello, World!</value>
  </meta>
  <meta>
    <name>extra</name>
    <value>654321</value>
  </meta>
  <meta>
    <name>extra</name>
    <value>1.234</value>
    <value>67890</value>
    <value>foobar</value>
  </meta>
  <meta>
    <name>when</name>
    <value>2015-03-21, Sat March 2015</value>
    <value>1426933800</value>
  </meta>
</ismrmrdMeta>"
	buffer = IOBuffer()

  MRD.write_string(buffer,String(xmlstring),UInt64)
  Base.seekstart(buffer)
  
	meta = MRD.read(buffer,MRD.MetaDict)
	@test meta["pi"] == 3.14159265

  @test meta["extra"][2] == 67890

  @test isempty(meta) == false 
  
  buffer = IOBuffer()
  MRD.write(buffer,meta)
  seekstart(buffer)
  meta2 = MRD.read(buffer,MRD.MetaDict)
  @test meta == meta2
  
end