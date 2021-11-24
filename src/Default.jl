module Default 

export default

struct default{T}
    value::T
end 


function (def::default)(::Nothing)
    return def.value
end 

function (def::default)(val::Any) 
    return val
end 
end