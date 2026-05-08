using Test
using XLSXasJSON
using JSONPointer
using OrderedCollections
using JSON

data_path = joinpath(@__DIR__, "data")
include("tables_inteface.jl")

# testdata
@testset "Adobe Spry Examples" begin
    # source: https://opensource.adobe.com/Spry/samples/data_region/JSONDataSetSample.html
    f = joinpath(data_path, "example.xlsx")

    #example1
    jws = JSONWorksheet(f, "Sheet1")
    @test jws[1]["array_any"] == split("100;200;300;400", ";")
    @test jws[1]["array_int"] == [100,200,300,400]
    @test jws[1]["array_float"] == [0.1,0.2,0.3,0.4]

    @test jws[2]["array_any"] == split("500;600;700;800", ";")
    @test jws[2]["array_int"] == [500,600,700,800]
    @test jws[2]["array_float"] == [0.5,0.6,0.7,0.8]

    @test jws[3]["array_any"] == [900]
    @test jws[3]["array_string"] == ["900"]
    @test jws[3]["array_int"] == [900]
    @test jws[3]["array_float"] == [900.0]

    #example5
    jws = JSONWorksheet(f, "Sheet3")
    @test isa(jws[1]["batters"]["batter"], Array)
    @test isa(jws[2]["batters"]["batter"], Array)
    @test isa(jws[3]["batters"]["batter"], Array)

    @test isa(jws[1]["topping"], Array)
    @test isa(jws[2]["topping"], Array)
    @test isa(jws[3]["topping"], Array)

    @test jws[1]["batters"]["batter"][1] == OrderedDict("id"=>1001, "type"=>"Regular")
    @test jws[1]["batters"]["batter"][4] == OrderedDict("id"=>1004, "type"=>"Devil's Food")

    @test jws[1]["topping"][1] == OrderedDict("id"=>5001, "type"=>"None")
    @test jws[2]["topping"][2] == OrderedDict("id"=>5002, "type"=>"Glazed")
    @test jws[3]["topping"][3] == OrderedDict("id"=>5003, "type"=>"Chocolate")

    #example6 - xf_coloriented
    f = joinpath(data_path, "example_coloriented.xlsx")
    jws = JSONWorksheet(f, "Sheet1"; row_oriented = false)
    @test jws[1]["id"] == 1
    @test jws[1]["type"] == "donut"
    @test jws[1]["name"] == "Cake"
    @test jws[1]["image"]["url"] == "images/0001.jpg"
    @test jws[1]["image"]["width"] == 200
    @test jws[1]["image"]["height"] == 2500
    @test jws[1]["thumbnail"]["url"] == "images/thumbnails/0001.jpg"
    @test jws[1]["thumbnail"]["width"] == 32
    @test jws[1]["thumbnail"]["height"] == 32
end

@testset "JSONWorkbook - deleteat!" begin
    xf = joinpath(data_path, "othercase.xlsx")
    jwb = JSONWorkbook(xf)
    @test length(jwb) == 6
    deleteat!(jwb, 1)
    @test length(jwb) == 5

    deleteat!(jwb, :promotion)
    @test length(jwb) == 4
    @test_throws ArgumentError jwb[:promotion]
end

@testset "JSONWorkbook - etc" begin
    xf = joinpath(data_path, "othercase.xlsx")
    jwb = JSONWorkbook(xf)

    @test hassheet(jwb, "Missing")
    @test hassheet(jwb, :Sheet1)
    @test !hassheet(jwb, "Sheet2")
    @test !hassheet(jwb, :Sheet3)
    
    @test XLSXasJSON.getsheet(jwb, :Sheet1) == jwb["Sheet1"]

    @test jwb[5] == jwb["mergeB"]
    @test jwb[end] == jwb["mergeC"]

    @test jwb[3:5] == [jwb[3],jwb[4],jwb[5]]

    names = sheetnames(jwb)
    for (i, jws) in enumerate(jwb) 
        @test sheetnames(jws) == names[i]
    end

end


@testset "JSONWorkbook - writer" begin
    f = joinpath(data_path, "example.xlsx")
    jwb = JSONWorkbook(f)

    #write to IO
    b = replace("""[{"color":"red","value":"#f00"},{"color":"green","value":"#0f0"},{"color":"blue","value":"#00f"},{"color":"cyan","value":"#0ff"},{"color":"magenta","value":"#f0f"},{"color":"yellow","value":"#ff0"},{"color":"black","value":"#000"}]""", "\n"=>"")
    io = IOBuffer()

    XLSXasJSON.write(io, jwb["Sheet2"]; indent=0) 
    @test String(take!(io)) == b

    XLSXasJSON.write(io, jwb["Sheet2"]; indent=2) 
    a = String(take!(io))
    @test replace(a, r"\t|\n| " => "") ==  b

    XLSXasJSON.write(data_path, jwb)

    # cannot test equality if data contains missing value
    prefix = split(basename(f), ".")[1]
    for s in sheetnames(jwb)[1:2]
        file = joinpath(data_path, "$(prefix)_$(s).json")
        json_data = JSON.parsefile(file; dicttype=OrderedDict)
        for i in 1:length(jwb[s])
            @test jwb[s][i] == json_data[i]
        end
    end

    # wirte to XLSX
    f2 = joinpath(data_path, "example2.xlsx")
    XLSXasJSON.write_xlsx(f2, jwb)
    jwb2 = JSONWorkbook(f2)

    @test sheetnames(jwb) == sheetnames(jwb2)
    for s in sheetnames(jwb)
        @test jwb[s].pointer == jwb2[s].pointer
    end

    f = joinpath(data_path, "example.xlsx")
end

@testset "JSONWorksheet - merge" begin
    xf = joinpath(data_path, "othercase.xlsx")
    jwb = JSONWorkbook(xf)
   
    ws1 = jwb[:mergeA]
    ws2 = jwb[:mergeB]

    @test_throws AssertionError merge(ws1, ws2, "/Something")

    new_sheet = merge(ws1, ws2, "/Key")
    @test collect(keys(new_sheet[1])) == ["Key", "Address", "Name", "Property"]
    @test_throws KeyError jwb[:mergeA][1]["Property"][1]["A"]

    jwb[:mergeA] = new_sheet
    @test keys(jwb[:mergeA][1]) == keys(new_sheet[1])

    @test jwb[:mergeA][1]["Address"]["State"] == "Some"
    @test jwb[:mergeA][1]["Address"]["TEL"] == [555,1111,2222]
    @test jwb[:mergeA][1]["Property"][1]["A"] == "Out"
    @test jwb[:mergeA][1]["Property"][2]["A"] == "think"

    ws3 = jwb[:mergeC]
    new_sheet = merge(ws1, ws3, "/Key")

    @test length(new_sheet) == 6
    @test ws1[1]["Address"]["TEL"] == [555,1111,2222] 
    @test new_sheet[1]["Key"] == ws1[1]["Key"]
    @test new_sheet[2]["Address"] == ws1[2]["Address"]

    @test new_sheet[1]["Address"]["TEL"] == ws3[2]["Address"]["TEL"]
    @test new_sheet[3]["Address"]["TEL"] == ws3[1]["Address"]["TEL"]

end

@testset "JSONWorksheet - append!" begin
    xf = joinpath(data_path, "append.xlsx")
    jwb = JSONWorkbook(xf)

    ws1 = jwb["Sheet1"]
    ws2 = jwb["Sheet2"]
    ws3 = jwb["Sheet3"]
    
    @test_throws AssertionError append!(ws1, ws3)

    @test length(ws1) == 1
    @test length(ws2) == 2
    
    append!(ws1, ws2)
    @test length(ws1) == 3
    @test length(ws2) == 2

    @test ws1[2] == ws2[1]
    @test ws1[3] == ws2[2]
end 

@testset "JSONWorksheet - squeeze" begin
    col1 = rand(100)
    col2 = map(i -> join(rand(20), ";"), 1:100)

    data = ["/a/b/1" "/a/c::array{number}"; col1 col2]

    jws = JSONWorksheet("foo.xlsx", "Sheet1", data,; squeeze = true)
    @test length(jws) == 1
    @test jws[1]["a"]["b"][1] == data[2:end, 1]
    @test length(jws[1]["a"]["c"]) == 100
end

@testset "JSONWorksheet - getindex with index" begin
    data = ["/a" "/b" "/c::array" "/d/1/5/b";
            1     "a"  "A;100;B"  "new"
            2     "b"  "C;200;D"  "test"]

    jws = JSONWorksheet("foo.xlsx", "Sheet1", data)

    @test jws[1, 1] == 1
    @test jws[2, 1] == 2
    @test jws[1, 2] == "a"
    @test jws[2, 2] == "b"
    @test jws[1, 3] == ["A", "100", "B"]
    @test jws[2, 3] == ["C", "200", "D"]

    @test jws[1:2, 1] == [1, 2]
    @test jws[1:end, 1] == [1, 2]

    @test jws[1, 1:2] == [1 "a"]
    @test jws[1, 1:3] == permutedims([1,  "a",  ["A", "100", "B"]])
    @test jws[1, :] == jws[1, 1:end]
    @test jws[2, :] == jws[2, 1:4]
    @test jws[:, :] == jws[1:2, 1:4] == jws[1:end, 1:end]
    @test size(jws[:]) == size(jws.data)

    @test jws[1:2, 1:2] == data[2:3, 1:2]

    @test_throws BoundsError jws[3, 1]
    @test_throws BoundsError jws[1, 5]
end


@testset "JSONWorksheet - haskey with a pointer" begin
    data = ["/a/b" "/a/c/1" "/a/d/f" "/a/c/2::array";
    1     "a"      4       "A;100;B"
    2     "b"     "k"      "C;200;D"]

    jws = JSONWorksheet("foo.xlsx", "Sheet1", data)

    @test haskey(jws, j"/a")
    @test haskey(jws, j"/a/b")
    @test haskey(jws, j"/a/c/1")
    @test haskey(jws, j"/a/d")
    @test haskey(jws, j"/a/d/f")
    @test haskey(jws, j"/a/c/2")

    @test !haskey(jws, j"/x")
    @test !haskey(jws, j"/a/1")
    @test !haskey(jws, j"/a/c/5")
    @test !haskey(jws, j"/a/d/f/k")
end

@testset "JSONWorksheet - getindex with a pointer" begin

    data = ["/a/b" "/a/c/1" "/a/d/f" "/a/c/2::array";
                1     "a"      4       "A;100;B"
                2     "b"     "k"      "C;200;D"]

    jws = JSONWorksheet("foo.xlsx", "Sheet1", data)
    x = jws[1, j"/a"]
    @test x["b"] == 1
    @test x["c"] == ["a", ["A", "100", "B"]]
    @test x["d"] == OrderedDict("f" => 4)

    @test jws[1, j"/a/c"] == ["a", ["A", "100", "B"]]

    @test jws[:, j"/a/b"] == [1, 2]

    @test haskey(jws, j"/a/b")
    @test haskey(jws, j"/a")
    @test haskey(jws, j"/a/c/2")

    @test haskey(jws, j"/a/1") == false
    @test haskey(jws, j"/aa") == false
    @test haskey(jws, j"/a/c/3") == false
end

@testset "JSONWorksheet - setindex!" begin
    data = ["/a" "/b" "/c::array";
            1     "a"  "A;100;B"
            2     "b"  "C;200;D"]
    jws = JSONWorksheet("foo.xlsx", "Sheet1", data)

    @test_throws ArgumentError jws[j"/d"] = [1]

    @test !haskey(jws, j"/d")
    jws[j"/d"] = [100, 200]
    @test jws[:, j"/d"] == [100, 200]
    @test haskey(jws, j"/d")

    jws[j"/a"] = ["a", "b"]
    @test jws[:, j"/a"] == ["a", "b"]

    jws[2, j"/a"] = ["change", "world"]
    @test jws[2, j"/a"] == ["change", "world"]

    jws[end, j"/b"] = "hooray"
    @test jws[end, j"/b"] == "hooray"

    @test_throws ArgumentError jws[j"/c::array"] = [1, 2]
end

@testset "JSONWorksheet - etc" begin 
    f = joinpath(data_path, "example.xlsx")

    #example1
    jws = JSONWorksheet(f, "Sheet1")

    @test xlsxpath(jws) == f
    @test firstindex(jws) == 1
    @test first(jws) == jws[1]
    @test last(jws) == jws[end]

    jws = JSONWorksheet(f, "Sheet2")
    sort!(jws, j"/color")
    @test jws[1][j"/color"] == "black"

end

@testset "Asserts" begin
    xf = joinpath(data_path, "assert.xlsx")
    @test_throws AssertionError JSONWorksheet(xf, "dup")
    @test_throws AssertionError JSONWorksheet(xf, "dup2")
    @test_throws AssertionError JSONWorksheet(xf, "dup3")

    @test_throws Exception JSONWorksheet(xf, "dict_array")
    @test_throws Exception JSONWorksheet(xf, "array_dict")

    @test_throws AssertionError JSONWorksheet(xf, "start_line")
    @test JSONWorksheet(xf, "start_line";start_line=2) isa JSONWorksheet
    @test_throws AssertionError JSONWorksheet(xf, "empty")
end

@testset "missingdata" begin
    xf = joinpath(data_path, "othercase.xlsx")
    jws = JSONWorksheet(xf, "Missing")

    @test size(jws) == (5, 4)
    @test ismissing(jws[4]["Data"]["A"])
    @test all(broadcast(el -> ismissing(el["AllNull"]), jws))
    @test collect(keys(jws[1])) == ["Key", "Data", "AllNull"]
end

@testset "Static Type" begin
    xf = joinpath(data_path, "othercase.xlsx")
    jws = JSONWorksheet(xf, "promotion")
    @test isa(jws[1]["t1"]["A"], Integer)
    @test isa(jws[1]["t1"]["B"], Bool)

    @test isa(jws[1]["t2"]["A"], Integer)
    @test isa(jws[1]["t2"]["B"], Float64)

    @test isa(jws[1]["t3"]["A"], Integer)
    @test isa(jws[1]["t3"]["B"], Bool)
    @test isa(jws[1]["t3"]["C"], Float64)

    data = ["/a::number" "/b::number" "/c::array{number}";
            1.     10   "1.5;2.2"
            2.     20   "3;55"]
    jws = JSONWorksheet("foo.xlsx", "Sheet1", data)

    @test jws[:, j"/a"] == [1, 2]
    @test jws[:, j"/b"] == [10, 20]
    @test jws[:, j"/c"] == [[1.5,2.2], [3.0,55.0]]
end

@testset "JSONWorkbook - setindex! by Int" begin
    xf = joinpath(data_path, "othercase.xlsx")
    jwb = JSONWorkbook(xf)

    src = jwb["mergeB"]
    jwb[1] = src
    @test jwb[1] === src
end

@testset "juliatype_to_jsontype" begin
    f = XLSXasJSON.juliatype_to_jsontype
    @test f(OrderedDict{String, Any}) == "object"
    @test f(Vector{Any})               == "array"
    @test f(Array{Int, 2})             == "array"
    @test f(String)                    == "string"
    @test f(Float64)                   == "number"
    @test f(Int)                       == "integer"
    @test f(Bool)                      == "boolean"
    @test f(Missing)                   == "null"
    @test f(Nothing)                   == "null"
    @test f(Any)                       == ""

    # fallback path: emits a warning and returns ""
    local result
    @test_logs (:warn, r"cannot find jsontype") begin
        result = f(Symbol)
    end
    @test result == ""
end

@testset "Index" begin
    Index = XLSXasJSON.Index

    # constructors and basic accessors
    empty_idx = Index()
    @test length(empty_idx) == 0
    @test names(empty_idx) == String[]
    @test keys(empty_idx) == String[]

    idx = Index(["a", "b", "c", "d"])
    @test length(idx) == 4
    @test names(idx) == ["a", "b", "c", "d"]
    @test keys(idx) == ["a", "b", "c", "d"]

    # `names` returns a copy — mutating the result must not affect the index
    n = names(idx)
    push!(n, "x")
    @test length(idx) == 4

    # copy / equality
    idx2 = copy(idx)
    @test idx2 == idx
    @test isequal(idx2, idx)
    @test idx2 !== idx
    @test idx != Index(["a", "b", "c"])

    # uniqueness assertion in constructor
    @test_throws AssertionError Index(["a", "a"])

    # haskey
    @test haskey(idx, "a")
    @test !haskey(idx, "z")
    @test haskey(idx, 1)
    @test haskey(idx, 4)
    @test !haskey(idx, 0)
    @test !haskey(idx, 5)
    @test_throws ArgumentError haskey(idx, true)

    # getindex with Bool is rejected
    @test_throws ArgumentError idx[true]

    # getindex with Integer
    @test idx[1] == 1
    @test idx[4] == 4
    @test_throws BoundsError idx[0]
    @test_throws BoundsError idx[5]

    # getindex with AbstractVector{Int}
    @test idx[[1, 2]] == [1, 2]
    @test idx[Int[]] == Int[]
    @test_throws BoundsError idx[[0, 1]]
    @test_throws BoundsError idx[[1, 5]]
    @test_throws ArgumentError idx[[1, 1]]

    # getindex with AbstractRange{Int}
    @test idx[1:2] == 1:2
    @test idx[1:1:2] == [1, 2]
    @test idx[2:1] == 2:1   # empty range
    @test_throws BoundsError idx[0:2]
    @test_throws BoundsError idx[1:5]

    # getindex with Colon
    @test idx[:] == Base.OneTo(4)

    # getindex with AbstractVector{<:Integer} — non-Int integers route through
    @test idx[Int8[1, 2]] == [1, 2]

    # getindex with AbstractVector{Bool}
    @test idx[[true, false, true, false]] == [1, 3]
    @test_throws BoundsError idx[[true, false]]

    # catch-all AbstractVector branch
    @test idx[Any[]] == Int[]
    @test idx[Any[1, 2]] == [1, 2]
    @test idx[Any["a", "b"]] == [1, 2]
    @test_throws ArgumentError idx[Any[1, true]]
    @test_throws ArgumentError idx[Any[1.5, 2.5]]
    @test_throws ArgumentError idx[Any[:a, :b]]

    # getindex with Regex
    @test idx[r"^a$"] == [1]
    @test idx[r"."] == [1, 2, 3, 4]
    @test idx[r"z"] == Int[]

    # getindex with AbstractString — fuzzymatch / lookupname paths
    @test idx["a"] == 1
    @test idx["d"] == 4
    @test_throws ArgumentError idx["zzz"]                 # no candidates
    @test_throws ArgumentError idx["A"]                   # wrong-case fuzzy candidate
    @test idx[AbstractString["a", "c"]] == [1, 3]
    @test_throws ArgumentError idx[AbstractString["a", "a"]]
end

@testset "jsontype_to_juliatype" begin
    @test XLSXasJSON.jsontype_to_juliatype("string")  == String
    @test XLSXasJSON.jsontype_to_juliatype("number")  == Float64
    @test XLSXasJSON.jsontype_to_juliatype("integer") == Int
    @test XLSXasJSON.jsontype_to_juliatype("object")  == OrderedDict{String,Any}
    @test XLSXasJSON.jsontype_to_juliatype("array")   == Vector{Any}
    @test XLSXasJSON.jsontype_to_juliatype("boolean") == Bool
    @test XLSXasJSON.jsontype_to_juliatype("null")    == Missing

    @test_throws ErrorException XLSXasJSON.jsontype_to_juliatype("unknown")
    @test_throws ErrorException XLSXasJSON.jsontype_to_juliatype("Int")
    @test_throws ErrorException XLSXasJSON.jsontype_to_juliatype("")

    # exercised through parse_column_header for the array-element branches
    p_obj = XLSXasJSON.parse_column_header("/a{object}")
    @test p_obj isa JSONPointer.Pointer{Array{OrderedDict{String,Any}, 1}}

    p_arr = XLSXasJSON.parse_column_header("/a{array}")
    @test p_arr isa JSONPointer.Pointer{Array{Vector{Any}, 1}}

    p_bool = XLSXasJSON.parse_column_header("/a{boolean}")
    @test p_bool isa JSONPointer.Pointer{Array{Bool, 1}}

    p_null = XLSXasJSON.parse_column_header("/a{null}")
    @test p_null isa JSONPointer.Pointer{Array{Missing, 1}}

    @test_throws ErrorException XLSXasJSON.parse_column_header("/a{notatype}")
end

@testset "Deliminator for a Array in a cell" begin
    data = ["/a::array{number}" "/b::array{integer}" "/c::array";
            "1;2;3"     "4;5;6"   "abc;가나다"
            "1,2,3"     "4,5,6"   "abc,가나다,"]

    jws = JSONWorksheet("foo.xlsx", "Sheet1", data; delim = r";|,")

    @test  jws[1]["a"] == [1.0, 2.0, 3.0]
    @test  jws[2]["a"] == [1.0, 2.0, 3.0]
    @test  jws[1]["b"] == [4, 5, 6]
    @test  jws[2]["b"] == [4, 5, 6]
    @test  jws[1]["c"] == ["abc", "가나다"]
    @test  jws[2]["c"] == ["abc", "가나다"]

end

@testset "omit_null_objects!" begin
    # Object arrays produced by indexed-pointer column headers.
    # Row 1: both elements have data         -> both kept
    # Row 2: second element entirely missing -> dropped, leaves a 1-element array
    # Row 3: both elements entirely missing  -> empty array, the column itself stays
    data = Any[
        "/Key" "/ExpectedReward/1/Id" "/ExpectedReward/1/Count" "/ExpectedReward/2/Id" "/ExpectedReward/2/Count";
        1      "Id.Item.A"                     1                          "Id.Item.B"                     2;
        2      "Id.Item.X"                     5                          missing                         missing;
        3      missing                         missing                    missing                         missing
    ]
    jws = JSONWorksheet("foo.xlsx", "Sheet1", data)

    XLSXasJSON.omit_null_objects!(jws)

    @test length(jws[1]["ExpectedReward"]) == 2
    @test jws[1]["ExpectedReward"][1]["Id"] == "Id.Item.A"
    @test jws[1]["ExpectedReward"][2]["Id"] == "Id.Item.B"

    @test length(jws[2]["ExpectedReward"]) == 1
    @test jws[2]["ExpectedReward"][1]["Id"] == "Id.Item.X"
    @test jws[3]["ExpectedReward"] == []

    # Returns the worksheet (for chaining) and is idempotent.
    @test XLSXasJSON.omit_null_objects!(jws) === jws
    XLSXasJSON.omit_null_objects!(jws)
    @test length(jws[2]["ExpectedReward"]) == 1

    # Partial-null elements are preserved (matches the user-supplied semantics
    # that only fully-null objects are dropped).
    data2 = Any[
        "/Items/1/Key" "/Items/1/Value" "/Items/2/Key" "/Items/2/Value";
        "A"            1                missing        2
    ]
    jws2 = JSONWorksheet("foo.xlsx", "Sheet1", data2)
    XLSXasJSON.omit_null_objects!(jws2)
    @test length(jws2[1]["Items"]) == 2
    @test jws2[1]["Items"][2]["Value"] == 2
    @test ismissing(jws2[1]["Items"][2]["Key"])

    # Arrays of primitives must NOT be filtered, even when elements are missing.
    # Mixed arrays (some elements dicts, some not) are left untouched.
    data3 = Any[
        "/Key" "/Tags{string}";
        1       "alpha;beta"
    ]
    jws3 = JSONWorksheet("foo.xlsx", "Sheet1", data3)
    jws3.data[1][JSONPointer.Pointer("/Numbers")] = Any[missing, 7]
    jws3.data[1][JSONPointer.Pointer("/Mixed")] = Any[
        OrderedDict{String,Any}("k" => missing),
        42,
    ]

    XLSXasJSON.omit_null_objects!(jws3)

    @test jws3[1]["Tags"] == ["alpha", "beta"]
    @test isequal(jws3[1]["Numbers"], [missing, 7])
    @test length(jws3[1]["Mixed"]) == 2
    @test jws3[1]["Mixed"][2] == 42
end

@testset "write omit_null / omit_empty" begin
    data = Any[
        "/Key" "/Value" "/Tags{string}";
        "A"    1        ""
    ]
    jws = JSONWorksheet("foo.xlsx", "Sheet1", data)
    jws[1][JSONPointer.Pointer("/Note")] = nothing
    jws[1][JSONPointer.Pointer("/Extras")] = OrderedDict{String,Any}()

    default = sprint(io -> XLSXasJSON.write(io, jws; indent = 0))
    @test occursin("\"Note\":null", default)
    @test occursin("\"Extras\":{}", default)

    only_null = sprint(io -> XLSXasJSON.write(io, jws; indent = 0, omit_null = true))
    @test !occursin("\"Note\"", only_null)
    @test occursin("\"Extras\":{}", only_null)
    @test occursin("\"Key\":\"A\"", only_null)

    only_empty = sprint(io -> XLSXasJSON.write(io, jws; indent = 0, omit_empty = true))
    @test !occursin("\"Extras\"", only_empty)
    @test !occursin("\"Tags\"", only_empty)
    @test occursin("\"Note\":null", only_empty)

    both = sprint(io -> XLSXasJSON.write(io, jws; indent = 0, omit_null = true, omit_empty = true))
    @test !occursin("\"Note\"", both)
    @test !occursin("\"Extras\"", both)
    @test !occursin("\"Tags\"", both)
    @test occursin("\"Key\":\"A\"", both)
end

