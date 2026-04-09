local function utf8_chars(str)
    local chars = {}
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(chars, c)
    end
    return chars
end

local non_connecting = {
    ["ا"]=true, ["د"]=true, ["ذ"]=true, ["ر"]=true,
    ["ز"]=true, ["ژ"]=true, ["و"]=true, ["ﻻ"]=true
}

local marks = {
    ["ً"]=true, ["ٌ"]=true, ["ٍ"]=true,
    ["َ"]=true, ["ُ"]=true, ["ِ"]=true,
    ["ّ"]=true, ["ْ"]=true
}

local forms = {
    ["ا"]={"ﺍ","ﺎ","ﺎ","ﺍ"}, ["آ"]={"ﺁ","ﺁ","ﺁ","ﺁ"}, ["ب"]={"ﺏ","ﺑ","ﺒ","ﺐ"},
    ["پ"]={"ﭖ","ﭘ","ﭙ","ﭗ"}, ["ت"]={"ﺕ","ﺗ","ﺘ","ﺖ"}, ["ث"]={"ﺙ","ﺛ","ﺜ","ﺚ"},
    ["ج"]={"ﺝ","ﺟ","ﺠ","ﺞ"}, ["چ"]={"ﭺ","ﭼ","ﭽ","ﭻ"}, ["ح"]={"ﺡ","ﺣ","ﺤ","ﺢ"},
    ["خ"]={"ﺥ","ﺧ","ﺨ","ﺦ"}, ["د"]={"ﺩ","ﺩ","ﺩ","ﺪ"}, ["ذ"]={"ﺫ","ﺫ","ﺫ","ﺬ"},
    ["ر"]={"ﺭ","ﺭ","ﺭ","ﺮ"}, ["ز"]={"ﺯ","ﺯ","ﺯ","ﺰ"}, ["ژ"]={"ﮊ","ﮊ","ﮊ","ﮋ"},
    ["س"]={"ﺱ","ﺳ","ﺴ","ﺲ"}, ["ش"]={"ﺵ","ﺷ","ﺸ","ﺶ"}, ["ص"]={"ﺹ","ﺻ","ﺼ","ﺺ"},
    ["ض"]={"ﺽ","ﺿ","ﻀ","ﺾ"}, ["ط"]={"ﻁ","ﻃ","ﻄ","ﻂ"}, ["ظ"]={"ﻅ","ﻇ","ﻈ","ﻆ"},
    ["ع"]={"ﻉ","ﻋ","ﻌ","ﻊ"}, ["غ"]={"ﻍ","ﻏ","ﻐ","ﻎ"}, ["ف"]={"ﻑ","ﻓ","ﻔ","ﻒ"},
    ["ق"]={"ﻕ","ﻗ","ﻘ","ﻖ"}, ["ک"]={"ﮎ","ﮐ","ﮑ","ﮏ"}, ["گ"]={"ﮒ","ﮔ","ﮕ","ﮓ"},
    ["ل"]={"ﻝ","ﻟ","ﻠ","ﻞ"}, ["م"]={"ﻡ","ﻣ","ﻤ","ﻢ"}, ["ن"]={"ﻥ","ﻧ","ﻨ","ﻦ"},
    ["ه"]={"ﻩ","ﻫ","ﻬ","ﻪ"}, ["ی"]={"ﯼ","ﯾ","ﯿ","ﯽ"}, ["و"]={"ﻭ","ﻭ","ﻭ","ﻭ"},
    ["ﻻ"]={"ﻻ","ﻻ","ﻼ","ﻼ"}
}

local function is_persian(c)
    return forms[c] ~= nil
end

local function is_mark(c)
    return marks[c] ~= nil
end

local function process_persian_word(chars)
    local letters = {}
    for i=1,#chars do
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
    for i=1,#letters do
        local current = letters[i]
        local c = current.char
        local prev = letters[i-1] and letters[i-1].char
        local nextc = letters[i+1] and letters[i+1].char
        local connect_prev = prev and is_persian(prev) and not non_connecting[prev]
        local connect_next = nextc and is_persian(nextc) and not non_connecting[c]
        local form_index = 1
        if connect_prev and connect_next then
            form_index = 3
        elseif connect_prev then
            form_index = 4
        elseif connect_next then
            form_index = 2
        end
        local shaped = forms[c] and forms[c][form_index] or c
        for _, m in ipairs(current.marks) do
            shaped = shaped .. m
        end
        table.insert(result, 1, shaped)
    end
    return table.concat(result)
end

local function fixPersian(text)
    text = text:gsub("لا", "ﻻ")
    local chars = utf8_chars(text)
    local final = {}
    local buffer = {}
    local in_persian = false
    for i=1,#chars do
        local c = chars[i]
        if is_persian(c) or is_mark(c) then
            table.insert(buffer, c)
            in_persian = true
        else
            if in_persian then
                table.insert(final, process_persian_word(buffer))
                buffer = {}
                in_persian = false
            end
            table.insert(final, c)
        end
    end
    if #buffer > 0 then
        table.insert(final, process_persian_word(buffer))
    end
    return table.concat(final)
end

local function reverse_words(text)
    local words = {}
    for w in text:gmatch("%S+") do
        table.insert(words, w)
    end
    local result = {}
    for i=#words,1,-1 do
        table.insert(result, words[i])
    end
    return table.concat(result, " ")
end

minetest.register_on_chat_message(function(name, message)
    if message:match("[\216-\219]") then
        local fixed = fixPersian(message)
        fixed = reverse_words(fixed)
        minetest.chat_send_all("<"..name.."> "..fixed)
        return true
    end
    return false
end)