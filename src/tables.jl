# Tables.jl interface for `JSONWorksheet`.
#
# Reference: https://tables.juliadata.org/stable/implementing-the-interface/
#
# `JSONWorksheet` is naturally row-oriented (`jws.data` is a Vector of
# `PointerDict`s), so row access is the primary path. We additionally synthesise
# column access for column-oriented sinks (DataFrames, CSV.jl, ...).
#
# Column names are exposed as `Symbol`s built from the JSON Pointer path
# (`/a/b` -> `Symbol("/a/b")`). Schema element types come from the `Pointer{T}`
# parameter when available.

# --- Table-level declarations -------------------------------------------------

Tables.istable(::Type{<:JSONWorksheet}) = true
Tables.rowaccess(::Type{<:JSONWorksheet}) = true
Tables.columnaccess(::Type{<:JSONWorksheet}) = true

Tables.rows(jws::JSONWorksheet) = [JSONWorksheetRow(jws, i) for i in 1:length(jws.data)]
Tables.columns(jws::JSONWorksheet) = JSONWorksheetColumns(jws)

Tables.columnnames(jws::JSONWorksheet) =
    ntuple(i -> _column_symbol(jws.pointer[i]), length(jws.pointer))

function Tables.schema(jws::JSONWorksheet)
    types = ntuple(i -> _pointer_eltype(jws.pointer[i]), length(jws.pointer))
    Tables.Schema(Tables.columnnames(jws), types)
end

Tables.getcolumn(jws::JSONWorksheet, i::Int) = jws[:, i]
Tables.getcolumn(jws::JSONWorksheet, p::Pointer) = jws[:, p]
function Tables.getcolumn(jws::JSONWorksheet, nm::Symbol)
    for p in jws.pointer
        _column_symbol(p) === nm && return jws[:, p]
    end
    return jws[:, JSONPointer.Pointer(string(nm))]
end

function Tables.matrix(jws::JSONWorksheet; transpose::Bool=false)
    m = jws[:, :]
    transpose && return permutedims(m)
    m isa AbstractVector && return reshape(m, :, 1)
    return m
end

_column_symbol(p::Pointer) = Symbol("/" * join(p.tokens, "/"))
_pointer_eltype(::Pointer{T}) where {T} = T

# --- AbstractRow wrapper ------------------------------------------------------
#
# Subtyping `Tables.AbstractRow` provides automatic `getindex`, `propertynames`,
# `getproperty`, iteration, and `show`. Note: `getproperty` on an `AbstractRow`
# is overridden to dispatch through `getcolumn`, so internal field access must
# go through `getfield`.

struct JSONWorksheetRow <: Tables.AbstractRow
    parent::JSONWorksheet
    index::Int
end

function Tables.getcolumn(row::JSONWorksheetRow, i::Int)
    par = getfield(row, :parent)
    par[getfield(row, :index), i]
end
function Tables.getcolumn(row::JSONWorksheetRow, p::Pointer)
    par = getfield(row, :parent)
    par[getfield(row, :index), p]
end
function Tables.getcolumn(row::JSONWorksheetRow, nm::Symbol)
    par = getfield(row, :parent)
    idx = getfield(row, :index)
    for p in par.pointer
        _column_symbol(p) === nm && return par[idx, p]
    end
    return par[idx, JSONPointer.Pointer(string(nm))]
end
Tables.columnnames(row::JSONWorksheetRow) =
    Tables.columnnames(getfield(row, :parent))

# --- AbstractColumns wrapper --------------------------------------------------

struct JSONWorksheetColumns <: Tables.AbstractColumns
    parent::JSONWorksheet
end

Tables.getcolumn(c::JSONWorksheetColumns, i::Int) =
    Tables.getcolumn(getfield(c, :parent), i)
Tables.getcolumn(c::JSONWorksheetColumns, p::Pointer) =
    Tables.getcolumn(getfield(c, :parent), p)
Tables.getcolumn(c::JSONWorksheetColumns, nm::Symbol) =
    Tables.getcolumn(getfield(c, :parent), nm)
Tables.columnnames(c::JSONWorksheetColumns) =
    Tables.columnnames(getfield(c, :parent))
Tables.schema(c::JSONWorksheetColumns) =
    Tables.schema(getfield(c, :parent))
