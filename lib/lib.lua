-- 千位分隔符格式化
-- true_format(1234567)  -->  "1,234,567"
-- true_format(-3500)    -->  "-3,500"
-- true_format(0)        -->  "0"
local function true_format(n)
    if not n then return "0" end

    local num = tonumber(n)
    if not num then return tostring(n) end

    -- 取整数部分，避免小数干扰
    num = math.floor(math.abs(num))
    local str = tostring(num)

    -- 每三位插一个逗号
    local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()

    -- 去掉可能出现在开头的逗号
    formatted = formatted:gsub("^,", "")

    -- 补回负号
    if tonumber(n) < 0 then
        formatted = "-" .. formatted
    end

    return formatted
end

-- 挂到全局，方便和其他文件共用
true_format = true_format