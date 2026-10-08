---@tag codamheader.header

---@brief [[
---
---This module manages the header.
---
---@brief ]]

local M = {}
local config = require "codamheader.config"

---Get left and right comment symbols from the buffer.
---@return string, string
function M.comment_symbols()
    if vim.bo.filetype == "c" or vim.fn.expand "%:e" == "h" then
        return "/*", "*/"
    end

    local str = vim.api.nvim_buf_get_option(0, "commentstring")

    -- Checks the buffer has a valid commentstring.
    if str:find "%%s" then
        local left, right = str:match "(.*)%%s(.*)"

        if right == "" then
            right = left
        end

        return vim.trim(left), vim.trim(right)
    end

    return "#", "#" -- Default comment symbols.
end

---Generate a formatted text line for the header.
---@param text string: The text to include in the line.
---@param ascii string: The ASCII art for the line.
---@return string: The formatted header line.
function M.gen_line(text, ascii)
    local max_length = config.opts.length - config.opts.margin * 2 - vim.fn.strdisplaywidth(ascii)

    -- Keep a separator so text can be updated without knowing the artwork.
    text = (text):sub(1, ascii ~= "" and max_length - 2 or max_length)

    local left, right = M.comment_symbols()
    local left_margin = (" "):rep(config.opts.margin - #left)
    local right_margin = (" "):rep(config.opts.margin - #right)
    local spaces = (" "):rep(max_length - #text)

    return left .. left_margin .. text .. spaces .. ascii .. right_margin .. right
end

local function frame_lines()
    local left, right = M.comment_symbols()
    local fill_line = left .. " " .. string.rep("*", config.opts.length - #left - #right - 2) .. " " .. right
    return fill_line, M.gen_line("", "")
end

-- Discover the existing header's height from its closing border, not the configured art.
local function read_header()
    local fill_line, empty_line = frame_lines()
    local lines = vim.api.nvim_buf_get_lines(0, 0, 9, false)
    local prefix = config.opts.margin + 1
    if lines[1] ~= fill_line or lines[2] ~= empty_line
        or not lines[6] or lines[6]:sub(prefix, prefix + 3) ~= "By: "
        or not lines[8] or lines[8]:sub(prefix, prefix + 8) ~= "Created: "
        or not lines[9] or lines[9]:sub(prefix, prefix + 8) ~= "Updated: " then
        return nil
    end

    local remaining = vim.api.nvim_buf_get_lines(0, 9, -1, false)
    for _, line in ipairs(remaining) do
        local previous = lines[#lines]
        table.insert(lines, line)
        if previous == empty_line and line == fill_line then
            return lines
        end
    end
end

local function replace_text(line, text)
    local content = line:sub(config.opts.margin + 1)
    local old_text, suffix = content:match "^(.-)  +(.*)$"
    if not old_text then
        return line
    end
    local width = #content - #suffix
    text = text:sub(1, width - 2)
    return line:sub(1, config.opts.margin) .. text .. (" "):rep(width - #text) .. suffix
end

local function update_fields(header)
    header[4] = replace_text(header[4], vim.fn.expand "%:t")
    header[9] = replace_text(header[9], "Updated: " .. os.date "%Y/%m/%d %H:%M:%S" .. " by " .. config.opts.user)
    return header
end

---Generate a complete header, preserving any existing artwork.
---@return table: A table containing all lines of the header.
function M.gen_header()
    local existing = read_header()
    if existing then
        return update_fields(existing)
    end

    local fill_line, empty_line = frame_lines()
    local date = os.date "%Y/%m/%d %H:%M:%S"

    local ascii = config.opts.asciiart
    if type(ascii[1]) == "table" then
        ascii = ascii[math.random(#ascii)]
    end

    local text = {
        [2] = vim.fn.expand "%:t",
        [4] = "By: " .. config.opts.user .. " <" .. config.opts.mail .. ">",
        [6] = "Created: " .. date .. " by " .. config.opts.user,
        [7] = "Updated: " .. date .. " by " .. config.opts.user,
    }
    local header = { fill_line, empty_line }
    for i = 1, math.max(7, #ascii) do
        table.insert(header, M.gen_line(text[i] or "", ascii[i] or ""))
    end
    table.insert(header, empty_line)
    table.insert(header, fill_line)
    return header
end

---Checks if there is a valid header in the current buffer.
---@return boolean: `true` if the header exists, `false` otherwise.
function M.has_header()
    return read_header() ~= nil
end

---Insert a header into the current buffer.
---@param header table: The header to insert.
function M.insert_header(header)
    if not vim.api.nvim_buf_get_option(0, "modifiable") then
        vim.notify("The current buffer cannot be modified.", vim.log.levels.WARN, { title = "Codam Header" })
        return
    end
    -- If the first line is not empty, the blank line will be added after the header.
    if vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] ~= "" then
        table.insert(header, "")
    end

    vim.api.nvim_buf_set_lines(0, 0, 0, false, header)
end

---Update the filename and timestamp without replacing the existing artwork.
function M.update_header()
    local header = read_header()
    if not header then
        return
    end
    update_fields(header)
    vim.api.nvim_buf_set_lines(0, 3, 4, false, { header[4] })
    vim.api.nvim_buf_set_lines(0, 8, 9, false, { header[9] })
end

---Inserts or updates the header in the current buffer.
function M.stdheader()
    if not M.has_header() then
        M.insert_header(M.gen_header())
    else
        M.update_header()
    end
end

return M
