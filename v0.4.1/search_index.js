var documenterSearchIndex = {"docs":
[{"location":"api/#API-Reference","page":"API Reference","title":"API Reference","text":"","category":"section"},{"location":"api/","page":"API Reference","title":"API Reference","text":"XLSXasJSON.JSONWorkbook\nXLSXasJSON.JSONWorksheet\nXLSXasJSON.merge\n","category":"page"},{"location":"api/#XLSXasJSON.JSONWorkbook","page":"API Reference","title":"XLSXasJSON.JSONWorkbook","text":"JSONWorkbook(file::AbstractString; start_line = 1)\n\nstart_line of each sheets are considered as JSONPointer for data structure.  And each sheets are pared to Array{OrderedDict, 1} \n\nConstructors\n\nJSONWorkbook(\"Example.xlsx\")\n\nArguments\n\narguments are applied to all Worksheets within Workbook.\n\nrow_oriented : if 'true'(the default) it will look for colum names in '1:1', if false it will look for colum names in 'A:A' \nstart_line : starting index of position of columnname.\nsqueeze : squeezes all rows of Worksheet to a singe row.\ndelim : a String or Regrex that of deliminator for converting single cell to array.\n\n\n\n\n\n","category":"type"},{"location":"api/#XLSXasJSON.JSONWorksheet","page":"API Reference","title":"XLSXasJSON.JSONWorksheet","text":"JSONWorksheet\n\nconstruct 'Array{OrderedDict, 1}' for each row from Worksheet\n\nConstructors\n\nJSONWorksheet(\"Example.xlsx\", \"Sheet1\")\nJSONWorksheet(\"Example.xlsx\", 1)\n\n\nArguments\n\nrow_oriented : if 'true'(the default) it will look for colum names in '1:1', if false it will look for colum names in 'A:A' \nstart_line : starting index of position of columnname.\nsqueeze : squeezes all rows of Worksheet to a singe row.\ndelim : a String or Regrex that of deliminator for converting single cell to array.\n\n\n\n\n\n","category":"type"},{"location":"api/#Base.merge","page":"API Reference","title":"Base.merge","text":"merge(a::JSONWorksheet, b::JSONWorksheet, bykey::AbstractString)\n\nConstruct a merged JSONWorksheet from the given JSONWorksheets. If the same Pointer is present in another collection, the value for that key will be the       value it has in the last collection listed.\n\n\n\n\n\n","category":"function"},{"location":"#XLSXasJSON.jl","page":"Home","title":"XLSXasJSON.jl","text":"","category":"section"},{"location":"#Introduction","page":"Home","title":"Introduction","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"XLSXasJSON.jl is a Julia package to convert Excel spread sheet to json encoded file. Designated row or colum must be standardized JSONPointer token, ramaning rows will passed to json encoded file.","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can read whole workbook, or specify sheet you want to read from Excel file. each rows on excel sheets are pared to Array{OrderedDict, 1} in Julia. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Please report bugs or make a feature request to opening an issue","category":"page"},{"location":"#Tutorial","page":"Home","title":"Tutorial","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"tutorial.md\"\n]\nDepth = 1","category":"page"},{"location":"tutorial/#Tutorial","page":"Tutorial","title":"Tutorial","text":"","category":"section"},{"location":"tutorial/#Installation","page":"Tutorial","title":"Installation","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"From a Julia session, run:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"julia> using Pkg\njulia> Pkg.add(\"XLSXasJSON\")","category":"page"},{"location":"tutorial/#Usage-Exmple","page":"Tutorial","title":"Usage Exmple","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"If you are familiar with a JSONPointer you can get start right away with example datas in the test.","category":"page"},{"location":"tutorial/#JSONWorkbook","page":"Tutorial","title":"JSONWorkbook","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"By default, first rows of each sheets are considered as JSONPointer for data structure. And each sheets are pared to Array{OrderedDict, 1} ","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"    using XLSXasJSON\n\n    p = joinpath(dirname(pathof(XLSXasJSON)), \"../test/data\")\n    xf = joinpath(p, \"example.xlsx\")\n    jwb = JSONWorkbook(xf)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You can access worksheet via jwb[1] or jwb[\"sheetname\"]","category":"page"},{"location":"tutorial/#JSONWorksheet","page":"Tutorial","title":"JSONWorksheet","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"    using XLSXasJSON\n\n    p = joinpath(dirname(pathof(XLSXasJSON)), \"../test/data\")\n    xf = joinpath(p, \"example.xlsx\")\n    jws = JSONWorksheet(xf, :Sheet1)","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You can access rows of data with jws[1, :] ","category":"page"},{"location":"tutorial/#Writing-JSON-File","page":"Tutorial","title":"Writing JSON File","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"    using XLSXasJSON\n\n    p = joinpath(dirname(pathof(XLSXasJSON)), \"../test/data\")\n    xf = joinpath(p, \"example.xlsx\")\n    jwb = JSONWorkbook(xf)\n\n    # Writing whole sheet\n    XLSXasJSON.write(pwd(), jwb)\n    # Writing singsheet\n    XLSXasJSON.write(\"Sheet1.json\", jwb[1]; indent = 2)","category":"page"},{"location":"tutorial/#Arguments","page":"Tutorial","title":"Arguments","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"row_oriented : if 'true'(the default) it will look for colum names in '1:1', if false it will look for colum names in 'A:A' \nstart_line : starting index of position of columnname.\nsqueeze : squeezes all rows of Worksheet to a singe row.\ndelim : a String or Regrex that of deliminator for converting single cell to array.","category":"page"},{"location":"tutorial/#JSONPointer-Exmples","page":"Tutorial","title":"JSONPointer Exmples","text":"","category":"section"},{"location":"tutorial/#Basic","page":"Tutorial","title":"Basic","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"A simple, row oriented key","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"/color\nred","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"produces","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"[{\n  \"color\": \"red\"\n}]","category":"page"},{"location":"tutorial/#Dict","page":"Tutorial","title":"Dict","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Nested names looks like:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"/color/name color/value\nred #f00","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"and produces","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"[{\n  \"color\": {\n    \"name\": \"red\",\n    \"value\": \"#f00\"\n    }\n}]","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"It can has as many nests as you want","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"/a/b/c/d/e/f\nIt can be done","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"and produces","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"[{\n    \"a\": {\n      \"b\": {\n        \"c\": {\n          \"d\": {\n            \"e\": {\n              \"f\": \"It can be done\"\n            }\n          }\n        }\n      }\n    }\n  }]\n","category":"page"},{"location":"tutorial/#Array","page":"Tutorial","title":"Array","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Sometimes it's convinient to put array values in seperate column in XLSX ","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"/color/name color/rgb/1 color/rgb/2 color/rgb/3\nred 255 0 0","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"[{\n  \"color\": {\n    \"name\": \"red\",\n    \"rgb\": [255, 0, 0]\n    }\n}]","category":"page"},{"location":"tutorial/#Type-Declarations","page":"Tutorial","title":"Type Declarations","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"You can declare Type with :: operator the same way as in Julia.","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"The value of array will be splitted with deliminator ';'.\nInstead Julia type, only JSON types can be used  ","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"/array::array /array_int::array{integer} /array_float::array{number}\n100;200;300 100;200;300 100;200;300","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"and produces","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"[{\n  \"array\": [\n    \"100\",\n    \"200\",\n    \"300\"\n  ],\n  \"array_int\": [\n    100,\n    200,\n    300\n  ],\n  \"array_float\": [\n    100.0,\n    200.0,\n    300.0\n  ]\n}]","category":"page"},{"location":"tutorial/#All-of-the-above","page":"Tutorial","title":"All of the above","text":"","category":"section"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"Now you know all the rules necessary to create any json data structure you want with just a column name. This is a more complete row-oriented example:","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"/a/b /a/b2::array{integer} /a/b3/1,Type /a/b3/1/Amount /a/b3/2/Type /a/b3/2/Amount /a/b3/3/Type /a/b3/3/Amount::array\nFooood 100;200;300 Cake 50 Chocolate 19 Ingredient Salt;100","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"would produce","category":"page"},{"location":"tutorial/","page":"Tutorial","title":"Tutorial","text":"[\n  {\n    \"a\": {\n      \"b\": \"Fooood\",\n      \"b2\": [\n        100,\n        200,\n        300\n      ],\n      \"b3\": [\n        {\n          \"Type\": \"Cake\",\n          \"Amount\": 50\n        },\n        {\n          \"Type\": \"Chocolate\",\n          \"Amount\": 19\n        },\n        {\n          \"Type\": \"Ingredient\",\n          \"Amount\": [\n            \"Salt\",\n            \"100\"\n          ]\n        }\n      ]\n    }\n  }\n]\n","category":"page"}]
}
