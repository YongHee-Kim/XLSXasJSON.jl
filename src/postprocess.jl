_isnullish(v) = v === missing || v === nothing

function _all_null(d::AbstractDict)
    for v in values(d)
        _isnullish(v) || return false
    end
    return true
end

function _prune_null_objects!(v)
    if isa(v, AbstractDict)
        for (k, child) in v
            v[k] = _prune_null_objects!(child)
        end
        return v
    elseif isa(v, AbstractVector) && !isempty(v) && all(x -> isa(x, AbstractDict), v)
        filter!(d -> !_all_null(d), v)
        for d in v
            _prune_null_objects!(d)
        end
        return v
    elseif isa(v, AbstractVector)
        for i in eachindex(v)
            v[i] = _prune_null_objects!(v[i])
        end
        return v
    end
    return v
end

"""
    omit_null_objects!(jws::JSONWorksheet)

Walk every row and drop elements of object arrays whose every field is `missing`
or `nothing`. Recurses into nested dicts and arrays. Mixed arrays (some elements
dicts, some not) are left untouched. Returns `jws`.
"""
function omit_null_objects!(jws::JSONWorksheet)
    for row in jws.data
        for p in keys(row)
            row[p] = _prune_null_objects!(row[p])
        end
    end
    return jws
end
