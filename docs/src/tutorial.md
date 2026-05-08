
# Tutorial

## Installation

From a Julia session, run:

```julia
julia> using Pkg
julia> Pkg.add("XLSXasJSON")
```

## Usage Example
If you are familiar with [JSONPointer](https://tools.ietf.org/html/rfc6901) you can get started right away with the example data in the test folder.

### JSONWorkbook
By default, the first row of each sheet is treated as a JSONPointer that defines the data structure, and the remaining rows are parsed into `Array{OrderedDict, 1}`.

```julia
using XLSXasJSON

p = joinpath(dirname(pathof(XLSXasJSON)), "../test/data")
xf = joinpath(p, "example.xlsx")
jwb = JSONWorkbook(xf)
```
You can access a worksheet via `jwb[1]` or `jwb["sheetname"]`.


### JSONWorksheet
```julia
using XLSXasJSON

p = joinpath(dirname(pathof(XLSXasJSON)), "../test/data")
xf = joinpath(p, "example.xlsx")
jws = JSONWorksheet(xf, "Sheet1")
```

You can access rows or cells in several ways:

```julia
jws[1]              # first row, as an OrderedDict
jws[1, :]           # entire first row
jws[:, 1]           # first column
jws[1, j"/a/b"]     # value at JSONPointer /a/b in row 1
jws[:, j"/a/b"]     # column at JSONPointer /a/b
```

The `j"..."` string macro builds a JSONPointer for nested access — it's the cleanest way to address values inside nested objects without juggling integer column indices.

### Constructor Arguments

Both `JSONWorkbook` and `JSONWorksheet` accept the same keyword arguments:

- `row_oriented` : if `true` (the default) column names are read from row 1; if `false`, from column A.
- `start_line` : starting row (or column) where column names live. Defaults to `1`.
- `squeeze` : squeezes all rows of a worksheet into a single row.
- `delim` : a `String` or `Regex` delimiter used to split a single cell into an array.

### Column-oriented sheets

For sheets where pointers run down the first column instead of across the first row, pass `row_oriented = false`:

```julia
xf = joinpath(p, "example_coloriented.xlsx")
jws = JSONWorksheet(xf, "Sheet1"; row_oriented = false)
```

### Per-sheet options

When sheets in the same workbook need different settings, pass a `Dict` of per-sheet keyword arguments instead of a single set of kwargs:

```julia
JSONWorkbook(xf,
    ["Sheet1", "Sheet2"],
    Dict(
        "Sheet1" => (row_oriented = true,),
        "Sheet2" => (row_oriented = false, start_line = 2),
    ),
)
```

### Writing JSON

```julia
jwb = JSONWorkbook(xf)

# Write every sheet to <path>/<basename>_<sheetname>.json
XLSXasJSON.write(pwd(), jwb)

# Write a single sheet, controlling formatting
XLSXasJSON.write("Sheet1.json", jwb[1]; indent = 2)
```

`write` accepts three formatting options, all forwarded to `JSON.jl`:

- `indent` (default `2`) : number of spaces for pretty printing. Pass `0` for a compact, single-line JSON.
- `omit_null` (default `false`) : when `true`, fields whose value is `null` are dropped from the output. Recurses into nested objects and arrays.
- `omit_empty` (default `false`) : when `true`, fields whose value is empty (empty `Dict`, `Array`, `String`, etc.) are dropped from the output.

### Writing back to XLSX

`write_xlsx` round-trips a `JSONWorkbook` back to an Excel file, joining array values with a delimiter:

```julia
XLSXasJSON.write_xlsx("out.xlsx", jwb; delim = ";", anchor_cell = "A1")
```

## JSONPointer Examples

#### Basic
A simple, row oriented key

| /color|
| -----|
| red|

produces

```json
[{
  "color": "red"
}]
```

#### Dict
Nested names look like:

| /color/name|color/value|
| ----------|-----------|
| red       |#f00       |

and produces

```json
[{
  "color": {
    "name": "red",
    "value": "#f00"
    }
}]
```

It can have as many levels of nesting as you want:

| /a/b/c/d/e/f|
| ---------------|
| It can be done|

and produces

```json
[{
    "a": {
      "b": {
        "c": {
          "d": {
            "e": {
              "f": "It can be done"
            }
          }
        }
      }
    }
  }]

```
#### Array
Sometimes it's convenient to put array values in separate columns in XLSX:

| /color/name|color/rgb/1|color/rgb/2|color/rgb/3|
| ----|-----|-----|-----|
| red     |255   |0 |0  |

```json
[{
  "color": {
    "name": "red",
    "rgb": [255, 0, 0]
    }
}]
```

#### Type Declarations
You can declare a type with the `::` operator, the same way as in Julia.
- The value of `array` is split using the delimiter `;`.
- Only JSON types are supported (not Julia types).

| /array::array    |/array_int::array{integer}|/array_float::array{number}|
| ------------| ------------ | ------------|
| 100;200;300 |100;200;300   |100;200;300  |

and produces

```json
[{
  "array": [
    "100",
    "200",
    "300"
  ],
  "array_int": [
    100,
    200,
    300
  ],
  "array_float": [
    100.0,
    200.0,
    300.0
  ]
}]
```

#### All of the above

Now you know all the rules necessary to create any JSON data structure you want with just a column name.
This is a more complete row-oriented example:

| /a/b | /a/b2::array{integer} | /a/b3/1/Type | /a/b3/1/Amount | /a/b3/2/Type | /a/b3/2/Amount | /a/b3/3/Type | /a/b3/3/Amount::array |
|------------------|-------------|------|---|------------|---|-----------|-----------|
| Fooood | 100;200;300 | Cake | 50 | Chocolate | 19 | Ingredient | Salt;100 |

would produce
```json
[
  {
    "a": {
      "b": "Fooood",
      "b2": [
        100,
        200,
        300
      ],
      "b3": [
        {
          "Type": "Cake",
          "Amount": 50
        },
        {
          "Type": "Chocolate",
          "Amount": 19
        },
        {
          "Type": "Ingredient",
          "Amount": [
            "Salt",
            "100"
          ]
        }
      ]
    }
  }
]

```

## More operations

`JSONWorksheet` and `JSONWorkbook` support a range of additional operations beyond the basics shown above:

- Workbook helpers: `sheetnames(jwb)`, `hassheet(jwb, name)`, `xlsxpath(jwb)`, `length(jwb)`, and iteration with `for sheet in jwb`.
- Worksheet helpers: `keys(jws)`, `haskey(jws, j"/some/ptr")`, `size(jws)`.
- Mutation: `setindex!` (`jws[i, j"/a"] = value`, `jws[j"/a"] = column_vector`), `append!(a, b)`, `sort!(jws, key)`, and `deleteat!(jwb, i)`.
- Combining sheets: `XLSXasJSON.merge(a, b, key)` joins two worksheets on a shared pointer.
- Tables.jl: `JSONWorksheet` implements the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface, so `Tables.rows(jws)` and `Tables.matrix(jws)` work directly with downstream packages.
