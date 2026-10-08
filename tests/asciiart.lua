-- Run from the repository root: nvim --headless -u NONE -l tests/asciiart.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local config = require "codamheader.config"
local default = vim.deepcopy(config.opts.asciiart)
local designs = {
    { "ART ONE", "ONE", "AAA", "AUTHOR ART",       "BBB", "CREATED ART",       "UPDATED ART" },
    { "ART TWO", "TWO", "CCC", "OTHER AUTHOR ART", "DDD", "OTHER CREATED ART", "OTHER UPDATED ART" },
}

-- Conflicting editor globals must not override setup options.
local global_user, global_mail = vim.g.user, vim.g.mail
vim.g.user = "global-user"
vim.g.mail = "global@example.com"

require("codamheader").setup {
    default_map = false,
    user = "tester",
    mail = "tester@example.com",
    asciiart = designs,
}
assert(vim.deep_equal(config.opts.asciiart, designs))

local random = math.random
local date = os.date
local timestamp = "2026/10/08 12:00:00"
os.date = function()
    return timestamp
end
local calls = 0
math.random = function(count)
    calls = calls + 1
    assert(count == #designs)
    return calls
end

local function new_buffer(name)
    vim.cmd "enew!"
    vim.api.nvim_buf_set_name(0, name)
    vim.bo.filetype = "c"
    vim.bo.commentstring = "// %s"
    vim.bo.textwidth = 0
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "int main(void) { return 0; }" })
end

local function check_art(lines, art)
    for i = 1, 7 do
        assert(#lines[i + 2] == 80)
        assert(lines[i + 2]:sub(- #art[i] - 5, -6) == art[i], "art changed at row " .. i)
    end
end

for index, art in ipairs(designs) do
    timestamp = "2026/10/08 12:00:00"
    new_buffer("/tmp/codam-art-" .. index .. ".c")
    vim.cmd "Stdheader"
    local before = vim.api.nvim_buf_get_lines(0, 0, 11, false)
    check_art(before, art)
    assert(before[6]:find("By: " .. config.opts.user .. " <tester@example.com>", 1, true))
    assert(before[8]:find("by " .. config.opts.user, 1, true))
    assert(calls == index)

    config.set { asciiart = { { "REMOVED", "", "", "", "", "", "" } }, user = "newuser" }
    -- Reopen the contents in another buffer: preservation must not rely on cached state.
    new_buffer("/tmp/reopened-art-" .. index .. ".c")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, before)
    vim.api.nvim_buf_set_lines(0, 11, -1, false, { "", "int main(void) { return 0; }" })
    timestamp = "2026/10/08 13:00:00"
    vim.api.nvim_buf_set_name(0, "/tmp/renamed-art-" .. index .. ".h")
    vim.cmd "Stdheader"
    timestamp = "2026/10/08 14:00:00"
    vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
    local after = vim.api.nvim_buf_get_lines(0, 0, 11, false)
    assert(vim.api.nvim_buf_line_count(0) == 13, "duplicated header")
    assert(calls == index, "random selection during update")
    assert(after[4]:find("renamed-art-" .. index .. ".h", 1, true))
    assert(after[9]:find("by newuser", 1, true))
    assert(after[9]:find(timestamp, 1, true))
    check_art(after, art)
    for _, i in ipairs { 1, 2, 3, 5, 6, 7, 8, 10, 11 } do
        assert(before[i] == after[i])
    end
    assert(vim.bo.commentstring == "// %s" and vim.bo.textwidth == 0)
    config.set { asciiart = designs }
end

math.random = random
config.set { asciiart = default }
new_buffer "/tmp/codam-default.c"
vim.cmd "Stdheader"
local before = vim.api.nvim_buf_get_lines(0, 0, 11, false)
config.set { asciiart = designs }
vim.cmd "Stdheader"
assert(vim.deep_equal(before, vim.api.nvim_buf_get_lines(0, 0, 11, false)))

new_buffer "/tmp/no-header.c"
vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
assert(vim.api.nvim_buf_line_count(0) == 1)

-- README designs, including Braille, must align by display columns rather than bytes.
local file = assert(io.open(".github/README.md", "r"))
local readme = file:read "*a"
file:close()
local examples = assert(loadstring("return " .. assert(readme:match "```lua\nasciiart = (%b{})")))()
for index, art in ipairs(examples) do
    local size = math.max(7, #art) + 4
    config.set { asciiart = art }
    new_buffer("/tmp/readme-art-" .. index .. ".c")
    vim.cmd "Stdheader"
    local before = vim.api.nvim_buf_get_lines(0, 0, size, false)
    assert(#before == size)
    assert(vim.api.nvim_buf_line_count(0) == size + 2)
    for _, row in ipairs(before) do
        assert(vim.fn.strdisplaywidth(row) == 80)
    end
    config.set { asciiart = default }
    timestamp = "2026/10/08 15:00:00"
    vim.api.nvim_buf_set_name(0, "/tmp/readme-art-renamed-" .. index .. ".c")
    vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
    local after = vim.api.nvim_buf_get_lines(0, 0, size, false)
    assert(vim.api.nvim_buf_line_count(0) == size + 2)
    assert(after[4]:find("readme-art-renamed-" .. index .. ".c", 1, true))
    assert(after[9]:find(timestamp, 1, true))
    for i = 1, #art do
        assert(vim.fn.strdisplaywidth(after[i + 2]) == 80)
        assert(after[i + 2]:sub(- #art[i] - 5, -6) == art[i])
    end
end

local header = require "codamheader.utils.header"
local function artwork(height)
    local art = {}
    for i = 1, height do
        local row = string.format("row %04d ⠿", i)
        art[i] = row .. (" "):rep(25 - vim.fn.strdisplaywidth(row))
    end
    return art
end

-- Exercise heights above and below the metadata height, with no upper cap.
for _, height in ipairs { 0, 1, 3, 7, 8, 16, 1024 } do
    local art = artwork(height)
    timestamp = "2026/10/08 12:00:00"
    config.set { asciiart = art }
    new_buffer("/tmp/height-" .. height .. ".c")
    vim.cmd "Stdheader"
    local size = math.max(7, height) + 4
    local before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(#before == size + 2)
    assert(header.has_header())
    for i = 1, height do
        assert(before[i + 2]:sub(- #art[i] - 5, -6) == art[i])
    end

    -- Reload with a different configured height and keep every original line.
    config.set { asciiart = { { "DIFFERENT DESIGN" } } }
    new_buffer("/tmp/reopened-height-" .. height .. ".h")
    vim.bo.filetype = "cpp"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, before)
    timestamp = "2026/10/08 13:00:00"
    local generated = header.gen_header()
    assert(#generated == size)
    vim.cmd "Stdheader"
    timestamp = "2026/10/08 14:00:00"
    vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
    -- Caller-supplied replacement art must also be ignored by the update helper.
    header.update_header { "REPLACEMENT ART" }
    local after = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(#after == #before, "height changed during update")
    assert(after[4]:find("reopened-height-" .. height .. ".h", 1, true))
    assert(after[9]:find(timestamp, 1, true))
    for i, row in ipairs(before) do
        if i ~= 4 and i ~= 9 then
            assert(after[i] == row, "artwork or source changed at line " .. i)
        end
    end
    for i = 1, height do
        assert(after[i + 2]:sub(- #art[i] - 5, -6) == art[i])
    end
    for i = 1, size do
        assert(vim.fn.strdisplaywidth(after[i]) == 80)
    end
end

-- A mixed-height pool chooses only at insertion; saves without headers choose nothing.
config.set { asciiart = { artwork(2), artwork(32) } }
local selections = 0
math.random = function(count)
    assert(count == 2)
    selections = selections + 1
    return 2
end
new_buffer "/tmp/mixed-heights.c"
vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
assert(selections == 0)
vim.cmd "Stdheader"
assert(vim.api.nvim_buf_line_count(0) == 38)
vim.cmd "Stdheader"
vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
assert(selections == 1)
assert(vim.api.nvim_buf_line_count(0) == 38)
math.random = random

vim.g.user, vim.g.mail = global_user, global_mail
os.date = date
print "Passed: unlimited artwork height, preservation, random selection, Unicode, metadata updates, and buffer options"
