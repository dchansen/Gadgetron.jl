module Stream

export Map, TakeWhile, SplitBy, Enumerate

struct Map 
    closure 
    kwparams
    buffer_size 
    Map(closure; buffer_size = 0,  kwparams...) = new(closure,kwparams, buffer_size)
end

function (m::Map)(iterable  )
    Channel(m.buffer_size;m.kwparams...) do c
        for var in iterable 
            push!(c, m.closure(var))
        end
    end
end

struct TakeWhile 
    predicate 
    kwparams
    buffer_size 
    TakeWhile(predicate; buffer_size = 0,  kwparams...) = new(predicate,kwparams, buffer_size )
end

function (tw::TakeWhile)(channel_like )
    Channel(tw.buffer_size; tw.kwparams...) do c
        try 
            while tw.predicate(fetch(channel_like))
                push!(c,take!(channel_like))
            end
        catch e 
            if isa(e, InvalidStateException) && e.state === :closed
                return
            else
                rethrow()
            end
        end
    end
end


struct SplitBy 
    predicate 
    kwparams
    buffer_size 
    keepend 
    keepempty 
    SplitBy(predicate; keepend=false, keepempty=false, buffer_size = 0,  kwparams...) = new(predicate,kwparams, buffer_size, keepend, keepempty)
end

function (sb::SplitBy)(iterable)
    Channel(sb.buffer_size; sb.kwparams...) do c
        buffer = []
        for msg in iterable
            if sb.predicate(msg) 
                if sb.keepend push!(buffer,msg) end
                if !isempty(buffer) || sb.keepempty
                    push!(c,buffer)
                    buffer = []
                end 
            else
                push!(buffer,msg)
            end
        end 
        if !isempty(buffer) push!(c,buffer) end 
    end 
end 



struct Enumerate
    from::Int 
    buffer_size 
    kwparams
    Enumerate(from::Int=1 ;buffer_size=0, kwparams...) = new(from,buffer_size,kwparams)
end

function (en::Enumerate)(iterable)
    Channel() do c 
        counter = Int(en.from)
        for item in iterable
            push!(c,(counter,item))
            counter += 1
        end 
    end 
end

end