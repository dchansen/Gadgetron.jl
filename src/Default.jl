module Default 

export default, Optional

struct default{T}
    value::T
end 


function (def::default)(::Nothing)
    return def.value
end 

function (def::default)(val::Any) 
    return val
end 

Optional{T} = Union{Nothing,T}
end