
"""
    parse_column_header(token_string)::Pointer

Parse an Excel column header into a `JSONPointer.Pointer`.

A leading `/` is added if missing, so both `"a/b"` and `"/a/b"` are accepted.
A trailing `{jsontype}` suffix declares an array element type and produces a
`Pointer{Array{T, 1}}`, where `T` is resolved by [`jsontype_to_juliatype`](@ref).
Without the suffix, a plain (JSON)`Pointer` is returned.

# Examples
```julia
parse_column_header("a/b")           # Pointer
parse_column_header("/a/b")          # Pointer
parse_column_header("a/b{integer}")  # Pointer{Array{Int, 1}}
```
"""
function parse_column_header(token_string::AbstractString)::Pointer
    if !startswith(token_string, JSONPointer.TOKEN_PREFIX)
        token_string = "/" * token_string
    end
    if endswith(token_string, "}")
        x = split(token_string, "{")
        p = Pointer(x[1])
        T = jsontype_to_juliatype(x[2][1:end-1])

        return Pointer{Array{T, 1}}(p.tokens)
    else 
        return Pointer(token_string)
    end
end
parse_column_header(token) = parse_column_header(string(token))

function jsontype_to_juliatype(t)
    if t == "string"
        return String
    elseif t == "number"
        return Float64
    # JSON does not have distinct types for integers and floating-point values
    # but Excel does, and distinguishing integer is useful for many things.
    elseif t == "integer" 
        return Int
    elseif t == "object"
        return OrderedDict{String,Any}
    elseif t == "array"
        return Vector{Any}
    elseif t == "boolean"
        return Bool
    elseif t == "null"
        return Missing
    else
        error(
            "You specified a type that JSON doesn't recognize! Instead of " *
            "`::$t`, you must use one of `::string`, `::number`, " *
            "`::object`, `::array`, `::boolean`, or `::null`."
        )
    end
end

function pointer_to_colname(p::Pointer{T})::String where T
    col = "/" * join(p.tokens, "/")
    t = juliatype_to_jsontype(T)
    if t == "array"
        col *= "::$t"
        t2 = juliatype_to_jsontype(eltype(T))
        if !isempty(t2)
            col *= "{$t2}"
        end
    elseif !isempty(t) 
        col *= "::$t"
    end
    return col
end

function juliatype_to_jsontype(T)
    if T <: OrderedDict
        t = "object"
    elseif T <: Array
        t = "array"
    elseif T == String
        t = "string"
    elseif T == Float64
        t = "number"
    elseif T == Int
        t = "integer"
    elseif T == Bool
        t = "boolean"
    elseif T == Missing
        t = "null"
    elseif T == Nothing
        t = "null"
    elseif T == Any 
        t = ""
    else
        @warn("cannot find jsontype from $T, returning empty string")
        t = ""
    end
    return t
end