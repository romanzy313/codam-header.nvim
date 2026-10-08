-- Run from the repository root: nvim --headless -u NONE -l tests/asciiart.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local config = require "codamheader.config"
local default = vim.deepcopy(config.opts.asciiart)
local designs = {
    { "ART ONE", "ONE", "AAA", "AUTHOR ART",       "BBB", "CREATED ART",       "UPDATED ART" },
    { "ART TWO", "TWO", "CCC", "OTHER AUTHOR ART", "DDD", "OTHER CREATED ART", "OTHER UPDATED ART" },
}

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
    assert(#art == 7)
    for _, row in ipairs(art) do
        assert(vim.fn.strdisplaywidth(row) == 25)
    end
    config.set { asciiart = art }
    new_buffer("/tmp/readme-art-" .. index .. ".c")
    vim.cmd "Stdheader"
    local before = vim.api.nvim_buf_get_lines(0, 0, 11, false)
    for _, row in ipairs(before) do
        assert(vim.fn.strdisplaywidth(row) == 80)
    end
    config.set { asciiart = default }
    timestamp = "2026/10/08 15:00:00"
    vim.api.nvim_buf_set_name(0, "/tmp/readme-art-renamed-" .. index .. ".c")
    vim.api.nvim_exec_autocmds("BufWritePre", { buffer = 0 })
    local after = vim.api.nvim_buf_get_lines(0, 0, 11, false)
    assert(after[4]:find("readme-art-renamed-" .. index .. ".c", 1, true))
    assert(after[9]:find(timestamp, 1, true))
    for i = 1, 7 do
        assert(vim.fn.strdisplaywidth(after[i + 2]) == 80)
        assert(after[i + 2]:sub(- #art[i] - 5, -6) == art[i])
    end
end

os.date = date
print "Passed: random artwork, removed designs, rename/save updates, single-design compatibility, and buffer options"
