memSuffixes = { "B", "kB", "MB", "GB" }
siSuffixes = { "", "k", "M", "G" }

function round( x )
    return math.floor( x + 0.5 )
end

function fix( x )
    if x % 1 == 0 then
        return math.floor( x )
    else
        return x
    end
end

function log10( n )
    return math.log( n ) / math.log( 10 )
end

function nround( x, n )
    if x > 10 ^ n then
        return round( x )
    else
        local adj = 10 ^ (n - math.floor( log10( x ) ) - 1)
        if x < 1 then
            adj = adj / 10
        end
        return fix( round( x * adj ) / adj )
    end
end

function unit( n, i, mul, suff )
    if n > 1000 then
        return unit( n / mul, i + 1, mul, suff )
    else
        local u = suff[ i ];
        if u ~= "" then
            return nround( n, 3 ) .. "\\," .. u
        else
            return nround( n, 3 )
        end
    end
end

function mem( n )
    return unit( n, 1, 1024, memSuffixes )
end

function si( n )
    return unit( n, 1, 1000, siSuffixes )
end

function speedup( x, y )
    return "$" .. nround( x / y, 3 ) .. "\\times$"
end

function minimum( arr )
    local min = arr[ 1 ]
    for i, v in ipairs( arr ) do
        if v < min then
            min = v
        end
    end
    return min
end

function wmoptline( name, array, mod )
    local str = "\\texttt{" .. name .. "}"
    local base = array[1]
    local best = minimum( array )

    if mod == nil then
        mod = ""
    end
    if mod ~= "" then
        str = str .. "\\dg"
    end

    for i, v in ipairs( array ) do
        str = str .. " & "

        if v ~= 0 then
            if v == best then str = str .. "\\textbf{" end
                str = str .. " " .. si( v )
            if v == best then str = str .. "}" end
        else
            str = str .. "--"
        end

        if i ~= 1 and v ~= 0 and base ~= 0 then
            str = str .. " & " .. speedup( base, v )
        elseif i ~= 1 then
            str = str .. " & -- "
        end
    end
    return str
end

function wmtauline( name, array, mod, sp )
    local str = "\\texttt{" .. name .. "}"
    local base = array[1]
    local best = minimum( array )

    if mod == nil then
        mod = ""
    end
    if mod ~= "" then
        str = str .. "\\dg"
    end

    for i, v in ipairs( array ) do
        str = str .. " & "
        if v == best then str = str .. "\\textbf{" end

        str = str .. " " .. si( v )

        if v == best then str = str .. "}" end
    end
    str = str .. " & " .. speedup( base, best )
    return str
end
