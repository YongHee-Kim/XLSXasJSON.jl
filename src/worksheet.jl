"""
    JSONWorksheet

construct 'Array{OrderedDict, 1}' for each row from Worksheet

# Constructors
```julia
JSONWorksheet("Example.xlsx", "Sheet1")
JSONWorksheet("Example.xlsx", 1)

```
# Arguments
- `row_oriented` : if 'true'(the default) it will look for colum names in '1:1', if `false` it will look for colum names in 'A:A' 
- `start_line` : starting index of position of columnname.
- `squeeze` : squeezes all rows of Worksheet to a singe row.
- `delim` : a String or Regrex that of deliminator for converting single cell to array.

"""
mutable struct JSONWorksheet
    source::String
    pointer::Array{Pointer,1}
    data::Array{T,1} where T 
    sheetname::String
end
function JSONWorksheet(source, sheet, arr; 
                        delim=";", squeeze=false)
    arr = dropemptyrange(arr)
    @assert !isempty(arr) "'$(source)!$(sheet)' don't have valid column names, try change optional argument'start_line'"

    pointer = _column_to_pointer.(arr[1, :])
    real_keys = map(el -> el.tokens, pointer)
    # TODO more robust key validity check
    if !allunique(real_keys) 
        throw(AssertionError("column names must be unique, check for duplication $(arr[1, :])"))
    end

    if squeeze
        data = squeezerow_to_jsonarray(arr, pointer, delim)
    else 
        data = eachrow_to_jsonarray(arr, pointer, delim)
    end
    JSONWorksheet(normpath(source), pointer, data, String(sheet))
end
function JSONWorksheet(xf::XLSX.XLSXFile, sheet;
                       start_line=1, 
                       row_oriented=true, 
                       delim=";", squeeze=false)
    ws = isa(sheet, Symbol) ? xf[String(sheet)] : xf[sheet]
    sheet = ws.name
    # orientation handling
    ws = begin
        rg = XLSX.get_dimension(ws)
        if row_oriented
            rg = XLSX.CellRange(XLSX.CellRef(start_line, rg.start.column_number), rg.stop)
            dt = ws[rg]
        else
            rg = XLSX.CellRange(XLSX.CellRef(rg.start.row_number, start_line), rg.stop)
            dt = permutedims(ws[rg])
        end
    end

    JSONWorksheet(xf.source, sheet, ws; delim=delim, squeeze=squeeze)
end
function JSONWorksheet(source, sheet; kwargs...)
    xf = XLSX.readxlsx(source)
    x = JSONWorksheet(xf, sheet; kwargs...)
    applicable(close, xf) && close(xf)
    return x
end

function eachrow_to_jsonarray(data::Array{T,2}, pointers, delim) where T
    json = Array{PointerDict,1}(undef, size(data, 1) - 1)
    Threads.@threads for i in 1:length(json)
        json[i] = row_to_jsonarray(data[i + 1, :], pointers, delim)
    end
    return json
end

function row_to_jsonarray(row, pointers, delim)
    x = PointerDict()
    for (col, p) in enumerate(pointers)
        x[p] = collect_cell(p, row[col], delim)
    end
    return x
end

function squeezerow_to_jsonarray(data::Array{T,2}, pointers, delim) where T
    arr_pointer = map(p -> begin 
        U = Vector{eltype(p)}; Pointer{U}(p.tokens)
    end, pointers)

    squzzed_json = PointerDict()
    @inbounds for (col, p) in enumerate(pointers)
        val = map(i -> collect_cell(p, data[i + 1, :][col], delim), 1:size(data, 1) - 1)
        squzzed_json[arr_pointer[col]] = val
    end
    return [squzzed_json]
end

@inline function dropemptyrange(arr::Array{T,2}) where T
    cols = falses(size(arr, 2))
    @inbounds for c in 1:size(arr, 2)
        # There must be a column name, or it's a commet line
        if !ismissing(arr[1, c])
            for r in 1:size(arr, 1)
                if !ismissing(arr[r, c])
                    cols[c] = true
                    break
                end
            end
        end
    end

    arr = arr[:, cols]
    rows = falses(size(arr, 1))
    @inbounds for r in 1:size(arr, 1)
        for c in 1:size(arr, 2)                
            if !ismissing(arr[r, c])
                rows[r] = true
                break
            end
        end
    end
    return arr[rows, :]
end

function collect_cell(p::Pointer{T}, cell, delim) where T
    if ismissing(cell) 
        val = JSONPointer._null_value(p)
    else
        if T <: AbstractArray
            if isa(cell, AbstractString)
                val = split(cell, delim)
                isempty(val[end]) && pop!(val)
                if eltype(T) <: Real 
                    val = parse.(eltype(T), val)
                elseif eltype(T) <: AbstractString 
                    val = string.(val)
                end
            else 
                val = cell
                if eltype(T) <: Real
                    if isa(cell, AbstractString) 
                        val = parse(eltype(T), cell)
                    end
                elseif eltype(T) <: AbstractString
                    if !isa(cell, AbstractString)
                        val = string(cell)
                    end
                end
                val = convert(T, [val])
            end
        else 
            val = cell
        end
    end
    return val
end

# data(jws::JSONWorksheet) = getfield(jws, :data)
xlsxpath(jws::JSONWorksheet) = getfield(jws, :source)
sheetnames(jws::JSONWorksheet) = getfield(jws, :sheetname)
Base.keys(jws::JSONWorksheet) = jws.pointer
function Base.haskey(jws::JSONWorksheet, key::Pointer) 
    t = key.tokens
    for el in getfield.(keys(jws), :tokens)
        if el == key.tokens
            return true 
        elseif length(el) > length(t) 
            if el[1:length(t)] == t
                return true 
            end
        end
    end
    return false
end

Base.iterate(jws::JSONWorksheet) = iterate(Tables.rows(jws))
Base.iterate(jws::JSONWorksheet, i) = iterate(Tables.rows(jws), i)

Base.size(jws::JSONWorksheet) = (length(jws.data), length(jws.pointer))
function Base.size(jws::JSONWorksheet, d)
    d == 1 ? length(jws.data) : 
    d == 2 ? length(jws.pointer) : throw(DimensionMismatch("only 2 dimensions of `JSONWorksheets` object are measurable"))
end
Base.length(jws::JSONWorksheet) = length(Tables.rows(jws))


########################################################################
##
## getindex() definitions
##
########################################################################
Base.getindex(jws::JSONWorksheet, i) = getindex(jws.data, i)
Base.getindex(jws::JSONWorksheet, ::Colon, ::Colon) = getindex(jws, eachindex(jws.data), eachindex(jws.pointer))
Base.getindex(jws::JSONWorksheet, row_ind, ::Colon) = getindex(jws, row_ind, eachindex(jws.pointer))

function Base.getindex(jws::JSONWorksheet, row_ind::Integer, col_ind::Integer)
    p = keys(jws)[col_ind]

    jws[row_ind, p]
end
function Base.getindex(jws::JSONWorksheet, row_ind::Integer, col_ind::AbstractArray)
    pointers = keys(jws)[col_ind]
    
    permutedims(map(p -> jws[row_ind, p], pointers))
end
@inline function Base.getindex(jws::JSONWorksheet, row_inds::AbstractArray, col_ind::AbstractArray)
    pointers = keys(jws)[col_ind]
    rows = jws[row_inds]

    # v = vcat(map(el -> jws[el, col_ind], row_inds)...)
    v = Array{Any,2}(undef, length(rows), length(pointers))
    @inbounds for (r, _row) in enumerate(rows)
        for (c, _col) in enumerate(pointers)
            v[r, c] = if haskey(_row, _col)
                _row[_col]
            else 
                missing 
            end
        end
    end

    return v
end

function Base.getindex(jws::JSONWorksheet, row_ind::Integer, col_ind::Pointer)
    row = jws[row_ind]
    return row[col_ind]
end
@inline function Base.getindex(jws::JSONWorksheet, row_inds, p::Pointer)
    map(row -> row[p], jws[row_inds])
end
@inline function Base.getindex(jws::JSONWorksheet, row_inds, col_ind::Integer)
    p = keys(jws)[col_ind]

    getindex(jws, row_inds, p)
end

function Base.setindex!(jws::JSONWorksheet, value::Vector, p::Pointer) 
    if length(jws) != length(value)
        throw(ArgumentError("New column must have the same length as old columns"))
    end
    @inbounds for (i, row) in enumerate(jws)
        row[p] = value[i]
    end
    if !haskey(jws, p)
        push!(jws.pointer, p)
    end
    return jws
end
function Base.setindex!(jws::JSONWorksheet, value, i::Integer, p::Pointer) 
    jws[i][p] = value
end

Base.firstindex(jws::JSONWorksheet) = firstindex(jws.data)
Base.lastindex(jws::JSONWorksheet) = lastindex(jws.data) 
function Base.lastindex(jws::JSONWorksheet, i::Integer) 
    i == 1 ? lastindex(jws.data) : 
    i == 2 ? lastindex(jws.pointer) : 
    throw(DimensionMismatch("JSONWorksheet only has two dimensions"))
end

"""
    merge(a::JSONWorksheet, b::JSONWorksheet, bykey::AbstractString)

Construct a merged JSONWorksheet from the given JSONWorksheets.
If the same Pointer is present in another collection, the value for that key will be the      
value it has in the last collection listed.
"""
function Base.merge(a::JSONWorksheet, b::JSONWorksheet, key::AbstractString)
    merge(a::JSONWorksheet, b::JSONWorksheet, Pointer(key))
end
function Base.merge(a::JSONWorksheet, b::JSONWorksheet, key::Pointer)    
    @assert haskey(a, key) "$key is not found in the JSONWorksheet(\"$(a.sheetname)\")"
    @assert haskey(b, key) "$key is not found in the JSONWorksheet(\"$(b.sheetname)\")"
    
    pointers = unique([a.pointer; b.pointer])
    
    keyvalues_a = map(el -> el[key], a.data)
    keyvalues_b = map(el -> el[key], b.data)
    ind = indexin(keyvalues_b, keyvalues_a)

    data = deepcopy(a.data)
    for (i, _b) in enumerate(b.data)
        j = ind[i]
        if isnothing(j)
            _a = deepcopy(_b)
            for p in a.pointer 
                _a[p] = JSONPointer._null_value(p)
            end 
            push!(data, _a) 
        else 
            _a = data[j]
        end
        for p in b.pointer 
            _a[p] = _b[p]
        end
    end
    JSONWorksheet(a.source, pointers, data, a.sheetname)
end
function Base.append!(a::JSONWorksheet, b::JSONWorksheet)
    ak = map(el -> el.tokens, keys(a)) 
    bk = map(el -> el.tokens, keys(b))
    
    if sort(ak) != sort(bk)
        throw(AssertionError("""Column names must be same for append!
         $(setdiff(collect(ak), collect(bk)))"""))
    end

    append!(a.data, b.data)
end

function Base.sort!(jws::JSONWorksheet, key; kwargs...)
    sort!(jws, Pointer(key); kwargs...)
end
function Base.sort!(jws::JSONWorksheet, pointer::Pointer; kwargs...)
    sorted_idx = sortperm(map(el -> el[pointer], Tables.rows(jws)); kwargs...)
    jws.data = Tables.rows(jws)[sorted_idx]
    return jws
end

function Base.summary(io::IO, jws::JSONWorksheet)
    @printf("%d×%d %s - %s!%s\n", size(jws)..., "JSONWorksheet", 
        basename(xlsxpath(jws)), sheetnames(jws))
end
function Base.show(io::IO, jws::JSONWorksheet)
    # By default, we align the columns to the left unless they are numbers, checks first row to determine datatype
    alignment = fill(:l, size(jws, 2))
    
    for i in 1:size(jws, 2)
        if isa(jws[1, i], Number)
            alignment[i] = :r
        end
    end
        
    summary(io, jws)
    pretty_table(io, Tables.matrix(jws);
        header = pointer_to_colname.(Tables.columnnames(jws)), 
        alignment = alignment)
end