
struct MetaDict <: Base.AbstractDict{String, Vector{T} where {T}}
    data::Dict{String,Vector{T} where {T}}
end 
MetaDict() = MetaDict(Dict())
Base.length(meta::MetaDict) = Base.length(meta.data)

function Base.iterate(meta::MetaDict, state...)  
    vi = iterate(meta.data,state...)
    if vi === nothing return nothing end 
    ((key,value),newstate) = vi
    return (Pair(key, Internal.lift(value)),newstate)
end


module Internal 
    lift(x) = length(x) == 1 ? x[1] : x
end

Base.get(collection::MetaDict,key::String, default) = get(collection.data,key,default) |> Internal.lift 
Base.setindex!(collection::MetaDict, value::Vector{T}, key::String) where {T} = setindex!(collection.data, value, key)
Base.setindex!(collection::MetaDict, value::T, key::String) where {T} = setindex!(collection.data, [value], key)

function push!(collection::MetaDict, key::String, values...) 
    vec = get!(collection.data, key, [])  
    Base.push!(vec, values...)
end 




function read(io::IO, ::Type{MetaDict})
    function parse_node(string)

        val = tryparse(Int64, string)
        if val !== nothing 
                return val
        end 
        val = tryparse(Float64, string)
        if val !== nothing
            return val
        end
        return string 
    end

    
    meta_string = read_string(io, UInt64)
    if isempty(meta_string) 
        return MetaDict() 
    end 

    meta = MetaDict()
    meta_xml = EzXML.parsexml(meta_string)
    r = EzXML.root(meta_xml)

    for meta_node in EzXML.eachelement(r)
        name = EzXML.findfirst("name", meta_node).content
        values = map(x -> parse_node(x.content), EzXML.findall("value", meta_node))
        meta[name] = values
    end

    return meta 

end

function write(io::IO, meta::MetaDict)
    if isempty(meta) 
        MRD.write_string(io,"",UInt64)
        return
    end

    doc = EzXML.XMLDocument()
    base = EzXML.ElementNode("ismrmrdMeta")


    for (key,values) in meta.data
        meta_node = EzXML.ElementNode("meta")
        EzXML.addelement!(meta_node,"name",key)
        values .|> string .|> EzXML.addelement! $ (meta_node,"value")
        EzXML.link!(base,meta_node)
    end 

    EzXML.setroot!(doc,base)
    buffer = IOBuffer()
    EzXML.print(buffer,doc)
    seekstart(buffer)
    xml_string = buffer |> take! |> String 
    MRD.write_string(io,xml_string,UInt64)

end