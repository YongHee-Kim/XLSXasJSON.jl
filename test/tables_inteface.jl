using Test
using XLSXasJSON
using JSONPointer
using Tables

@testset "Tables.jl integration" begin
    f = joinpath(data_path, "example.xlsx")
    jws = JSONWorksheet(f, "Sheet1")

    # Table-level declarations
    @test Tables.istable(jws)
    @test Tables.rowaccess(jws)
    @test Tables.columnaccess(jws)

    # Column names are exposed as Symbols built from the JSON pointer path.
    expected_names = ntuple(i -> Symbol("/" * join(jws.pointer[i].tokens, "/")),
                            length(jws.pointer))
    @test Tables.columnnames(jws) == expected_names

    # Schema reports per-column eltype recovered from the Pointer{T} parameter.
    sch = Tables.schema(jws)
    @test sch isa Tables.Schema
    @test sch.names == expected_names
    @test length(sch.types) == length(jws.pointer)

    # Row access — each row is an AbstractRow exposing the same column names.
    rows = Tables.rows(jws)
    @test length(rows) == length(jws.data)
    @test eltype(rows) <: Tables.AbstractRow
    row1 = first(rows)
    @test Tables.columnnames(row1) == expected_names
    @test Tables.getcolumn(row1, 1) == jws[1, 1]
    @test Tables.getcolumn(row1, expected_names[1]) == jws[1, 1]
    @test Tables.getcolumn(row1, j"/array_int") == jws[1, j"/array_int"]
    # property and indexing support comes from `<: Tables.AbstractRow`
    @test row1[1] == jws[1, 1]

    # Column access — AbstractColumns wrapper supports the full lookup API.
    cols = Tables.columns(jws)
    @test cols isa Tables.AbstractColumns
    @test Tables.columnnames(cols) == expected_names
    @test Tables.getcolumn(cols, 1) == jws[:, 1]
    @test Tables.getcolumn(cols, 2) == jws[:, 2]
    @test Tables.getcolumn(cols, expected_names[3]) == jws[:, 3]

    # Table-level getcolumn supports Int / Symbol / Pointer
    @test Tables.getcolumn(jws, 1) == jws[:, 1]
    @test Tables.getcolumn(jws, 2) == jws[:, 2]
    @test Tables.getcolumn(jws, j"/array_int") == Tables.getcolumn(jws, 3)
    @test Tables.getcolumn(jws, Symbol("/array_float")) == Tables.getcolumn(jws, 4)

    # Matrix materialisation, with the upstream kwarg signature
    @test Tables.matrix(jws) == jws[:, :]
    mat_trans = Tables.matrix(jws; transpose=true)
    for i in eachindex(jws.data)
        @test mat_trans[1, i] == jws[i, 1]
        @test mat_trans[2, i] == jws[i, 2]
        @test mat_trans[3, i] == jws[i, 3]
        @test mat_trans[4, i] == jws[i, 4]
    end
end