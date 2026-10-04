local function utf8_chars(str)
    local chars = {}
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, c)
    end
    return chars
end

local non_connecting = {
    ["ا"] = true, ["آ"] = true, ["د"] = true, ["ذ"] = true,
    ["ر"] = true, ["ز"] = true, ["ژ"] = true, ["و"] = true,
    ["ء"] = true, ["ؤ"] = true, ["ة"] = true, ["ى"] = true
}

local marks = {
    ["ً"] = true, ["ٌ"] = true, ["ٍ"] = true,
    ["َ"] = true, ["ُ"] = true, ["ِ"] = true,
    ["ّ"] = true, ["ْ"] = true, ["ٓ"] = true,
    ["ٔ"] = true, ["ٰ"] = true
}

local forms = {
    ["ا"] = {"ﺍ", "ﺍ", "ﺎ", "ﺎ"},
    ["آ"] = {"ﺁ", "ﺁ", "ﺂ", "ﺂ"},
    ["ب"] = {"ﺏ", "ﺑ", "ﺒ", "ﺐ"},
    ["پ"] = {"ﭖ", "ﭘ", "ﭙ", "ﭗ"},
    ["ت"] = {"ﺕ", "ﺗ", "ﺘ", "ﺖ"},
    ["ث"] = {"ﺙ", "ﺛ", "ﺜ", "ﺚ"},
    ["ج"] = {"ﺝ", "ﺟ", "ﺠ", "ﺞ"},
    ["چ"] = {"ﭺ", "ﭼ", "ﭽ", "ﭻ"},
    ["ح"] = {"ﺡ", "ﺣ", "ﺤ", "ﺢ"},
    ["خ"] = {"ﺥ", "ﺧ", "ﺨ", "ﺦ"},
    ["د"] = {"ﺩ", "ﺩ", "ﺪ", "ﺪ"},
    ["ذ"] = {"ﺫ", "ﺫ", "ﺬ", "ﺬ"},
    ["ر"] = {"ﺭ", "ﺭ", "ﺮ", "ﺮ"},
    ["ز"] = {"ﺯ", "ﺯ", "ﺰ", "ﺰ"},
    ["ژ"] = {"ﮊ", "ﮊ", "ﮋ", "ﮋ"},
    ["س"] = {"ﺱ", "ﺳ", "ﺴ", "ﺲ"},
    ["ش"] = {"ﺵ", "ﺷ", "ﺸ", "ﺶ"},
    ["ص"] = {"ﺹ", "ﺻ", "ﺼ", "ﺺ"},
    ["ض"] = {"ﺽ", "ﺿ", "ﻀ", "ﺾ"},
    ["ط"] = {"ﻁ", "ﻃ", "ﻄ", "ﻂ"},
    ["ظ"] = {"ﻅ", "ﻇ", "ﻈ", "ﻆ"},
    ["ع"] = {"ﻉ", "ﻋ", "ﻌ", "ﻊ"},
    ["غ"] = {"ﻍ", "ﻏ", "ﻐ", "ﻎ"},
    ["ف"] = {"ﻑ", "ﻓ", "ﻔ", "ﻒ"},
    ["ق"] = {"ﻕ", "ﻗ", "ﻘ", "ﻖ"},
    ["ک"] = {"ﮎ", "ﮐ", "ﮑ", "ﮏ"},
    ["گ"] = {"ﮒ", "ﮔ", "ﮕ", "ﮓ"},
    ["ل"] = {"ﻝ", "ﻟ", "ﻠ", "ﻞ"},
    ["م"] = {"ﻡ", "ﻣ", "ﻤ", "ﻢ"},
    ["ن"] = {"ﻥ", "ﻧ", "ﻨ", "ﻦ"},
    ["ه"] = {"ﻩ", "ﻫ", "ﻬ", "ﻪ"},
    ["و"] = {"ﻭ", "ﻭ", "ﻮ", "ﻮ"},
    ["ی"] = {"ﯼ", "ﯾ", "ﯿ", "ﯽ"},
    ["ئ"] = {"ﺉ", "ﺋ", "ﺌ", "ﺊ"}
}

local persian_digits = {
    ["۰"] = true, ["۱"] = true, ["۲"] = true, ["۳"] = true, ["۴"] = true,
    ["۵"] = true, ["۶"] = true, ["۷"] = true, ["۸"] = true, ["۹"] = true
}

local function is_persian(c)
    return forms[c] ~= nil
end

local function is_mark(c)
    return marks[c] ~= nil
end

local function is_digit(c)
    return persian_digits[c] or c:match("%d") ~= nil
end

local function shape_word(chars)
    local letters = {}
    for i = 1, #chars do
        local c = chars[i]
        if is_mark(c) then
            if #letters > 0 then
                table.insert(letters[#letters].marks, c)
            end
        else
            table.insert(letters, {char = c, marks = {}})
        end
    end

    local result = {}
    for i = 1, #letters do
        local current = letters[i]
        local c = current.char
        local form = forms[c]

        if form then
            local prev = letters[i - 1] and letters[i - 1].char
            local nextc = letters[i + 1] and letters[i + 1].char
            local connect_prev = prev and is_persian(prev) and not non_connecting[prev]
            local connect_next = nextc and is_persian(nextc) and not non_connecting[c]

            local idx = 1
            if connect_prev and connect_next then
                idx = 3
            elseif connect_prev then
                idx = 4
            elseif connect_next then
                idx = 2
            end

            local shaped = form[idx]
            for _, m in ipairs(current.marks) do
                shaped = shaped .. m
            end
            table.insert(result, 1, shaped)
        else
            local shaped = c
            for _, m in ipairs(current.marks) do
                shaped = shaped .. m
            end
            table.insert(result, 1, shaped)
        end
    end

    return table.concat(result)
end

local function fix_text(text)
    local chars = utf8_chars(text)
    local parts = {}
    local i = 1
    local n = #chars

    while i <= n do
        local c = chars[i]

        if is_persian(c) or is_mark(c) then
            -- RTL letter run
            local buf = {}
            while i <= n and (is_persian(chars[i]) or is_mark(chars[i])) do
                table.insert(buf, chars[i])
                i = i + 1
            end
            table.insert(parts, {type = "rtl", text = shape_word(buf)})
        elseif is_digit(c) then
            -- Number run (Persian or Latin digits) - keep original order
            local buf = {}
            while i <= n and is_digit(chars[i]) do
                table.insert(buf, chars[i])
                i = i + 1
            end
            table.insert(parts, {type = "ltr", text = table.concat(buf)})
        else
            -- Other characters (space, punctuation, English letters...)
            local buf = {}
            while i <= n and not is_persian(chars[i]) and not is_mark(chars[i]) and not is_digit(chars[i]) do
                table.insert(buf, chars[i])
                i = i + 1
            end
            table.insert(parts, {type = "ltr", text = table.concat(buf)})
        end
    end

    -- Reverse the order of parts for overall RTL flow,
    -- but keep internal content of each part as-is (especially numbers)
    local final = {}
    for j = #parts, 1, -1 do
        table.insert(final, parts[j].text)
    end
    return table.concat(final)
end

minetest.register_on_chat_message(function(name, message)
    if message:find("[\216-\219]") then
        local fixed = fix_text(message)
        if fixed ~= message then
            minetest.chat_send_all("<" .. name .. "> " .. fixed)
            return true
        end
    end
    return false
end)

minetest.log("action", "[persian_chat_fix] Loaded")
