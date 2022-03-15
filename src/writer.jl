function write(file::AbstractString, jws::JSONWorksheet; kwargs...)
    open(file, "w") do io
        write(io, jws; kwargs...)
    end
end
function write(io::IO, jws::JSONWorksheet; pretty = true, drop_null = false)
    if pretty
        JSON3.pretty(io, Tables.rows(jws))
    else
        JSON3.write(io, Tables.rows(jws))
    end
    # drop null array such as [null, null, ....] 
    if drop_null
        replace!(io, r"(\"[\w]*\":null,)|(,?\"[\w]*\":null)" => "")
    end
    return io
end

function write(path::String, jwb::JSONWorkbook; kwargs...)
    f = splitext(basename(xlsxpath(jwb)))[1]
    for s in sheetnames(jwb)
        write(joinpath(path, "$(f)_$(s).json"), jwb[s]; kwargs...)
    end
end

function write_xlsx(file::String, jwb::JSONWorkbook; delim = ";", anchor_cell = "A1")
    XLSX.openxlsx(file, mode="w") do xf

        for (i, s) in enumerate(sheetnames(jwb))
            jws = jwb[i]
            if i == 1 
                sheet = xf[1]
                XLSX.rename!(sheet, s)
            else
                sheet = XLSX.addsheet!(xf, s)
            end

            colnames = pointer_to_colname.(jws.pointer)
            columns = []
            for p in jws.pointer
                data = get.(jws.data, Ref(p), missing)
                if eltype(data) <: Array
                    data = join.(data, delim)
                end 
                push!(columns, data)
            end
            
            XLSX.writetable!(sheet, columns, colnames, anchor_cell=XLSX.CellRef(anchor_cell))
        end
    end
end