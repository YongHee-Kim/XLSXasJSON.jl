const CS = JSON.CommonSerialization
const SC = JSON.StructuralContext

function JSON.show_json(io::SC, s::CS, jws::JSONWorksheet)
    JSON.begin_array(io)
    for (i, row) in enumerate(eachrow(jws))
        JSON.indent(io)
        JSON.begin_object(io)
        for el in pairs(row)
            # isbitstype
            if isa(el[2], Array{T} where T <: AbstractString) || isa(el[2], Array{T} where T <: Number)
                JSON.show_key(io, el[1])
                compact_show_json(io, s, el[2])
            else
                JSON.show_pair(io, s, el)
            end
        end
        JSON.end_object(io)
        i != nrow(jws) && JSON.delimit(io)
    end
    JSON.end_array(io)
end
# removes indent for Vector
function compact_show_json(io, s, x::Array{T}) where T
    JSON.begin_array(io)
    for elt in x
        JSON.delimit(io)
        JSON.show_json(io, s, elt)
    end
    JSON.end_array(io)
end

# change function name to write?
function save_json(jws::JSONWorksheet, filepath = nothing; indent = 2)
    if isa(filepath, Nothing)
        filepath = dirname(xlsxpath(jws))
    end

    p = joinpath(filepath, jsonpath(jws))
    open(p, "w") do io
        write(io, JSON.json(jws, indent))
    end
    @printf("   saved => \"%s\" \n", p)
end
function save_json(jwb::JSONWorkbook, filepath = nothing; args...)
    for s in jwb.sheets
        save_json(s, filepath; args...)
    end
end
