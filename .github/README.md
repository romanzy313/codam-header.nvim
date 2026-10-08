<h1 align="center">Codam Header for Neovim</h1>

This extension provides the Codam header integration in Neovim. The original 42
re-write is found at
[42-header.nvim](https://github.com/Diogo-ss/42-header.nvim).

```bash
# ************************************************************************** #
#                                                                            #
#                                                        ::::::::            #
#   neovim-codam-header                                :+:    :+:            #
#                                                     +:+                    #
#   By: fras <fras@student.codam.nl>                 +#+                     #
#                                                    +#+                     #
#   Created: 2024/05/20 16:33:33 by fras          #+#    #+#                 #
#   Updated: 2024/05/26 00:33:49 by fras          ########   odam.nl         #
#                                                                            #
# ************************************************************************** #
```

## ✨ Features

- Command: `Stdheader`
- Auto update on save (optional)
- Supports `commentstring`

## 🎈 Setup

<details open>
  <summary>📦 vim.pack (Recommended)</summary>

Requires Neovim 0.12 or newer. Add this to your `init.lua` using Neovim's
[built-in package manager](https://neovim.io/doc/user/pack/#vim.pack):

```lua
vim.pack.add {
  { src = "https://github.com/f-ras/codam-header.nvim" },
}

require("codamheader").setup {
  default_map = true, -- Default mapping <F1> in normal mode.
  auto_update = true, -- Update header when saving.
  user = "username", -- Your user.
  mail = "your@email.com", -- Your mail.
  -- Add other options here.
}
```

</details>

<details>
  <summary>📦 Packer.nvim</summary>

```lua
use {
  "f-ras/codam-header.nvim",
  cmd = { "Stdheader" },
  config = function()
    require "codamheader"setup {
      default_map = true, -- Default mapping <F1> in normal mode.
      auto_update = true, -- Update header when saving.
      user = "username", -- Your user.
      mail = "your@email.com", -- Your mail.
    -- add other options.
    }
  end,
}
```

</details>

<details>
  <summary>💤 Lazy.nvim (lame)</summary>

Create a file 'codam-header.lua' in ~/.config/nvim/plugins/ with the following
content:

```lua
return {
  "f-ras/codam-header.nvim",
  cmd = { "Stdheader" },
  keys = { "<F1>" },
  opts = {
    default_map = true, -- Default mapping <F1> in normal mode.
    auto_update = true, -- Update header when saving.
    user = "username", -- Your user.
    mail = "your@email.com", -- Your mail.
    -- add other options.
  },
  config = function(_, opts)
    require("codamheader").setup(opts)
  end,
}
```

</details>

## ⚙ Options

```lua
{
  ---Max header size (not recommended change).
  --length = 80,
  ---Header margin (not recommended change).
  --margin = 5,
  ---Activate default mapping (e.g. F1).
  default_map = true,
  ---Enable auto-update of headers.
  auto_update = true,
  ---Header author.
  user = "username",
  ---Header email.
  mail = "your@mail.com",
  ---ASCII art: single design, or an array of designs.
  --asciiart = { "---", "---", ... },
}
```

To choose randomly when inserting a new header, supply multiple designs. Here is
some interesting ones:

```lua
asciiart = {
    {
        "       ::::::::          ",
        "     :+:    :+:          ",
        "    +:+                  ",
        "   +#+                   ",
        "  +#+                    ",
        "#+#    #+#               ",
        "########   odam.nl       ",
    },
    {
        "    :::     ::::::::     ",
        "   :+:     :+:    :+:    ",
        "  +:+ +:+        +:+     ",
        " +#+  +:+      +#+       ",
        "+#++:++#+    +#+         ",
        "      #+#   #+#          ",
        "      ###  ##########    ",
    },
    {
        " +---------------------+ ",
        " | $ cc -Wall -Wextra  | ",
        " | $ ./a.out           | ",
        " | Hello, 42!          | ",
        " | $ echo $?           | ",
        " | 42                  | ",
        " +---------------------+ ",
    },
    {
        "      +-----42-----+     ",
        "      |   comply   |     ",
        "      |     |      |     ",
        "      |    with    |     ",
        "      |     v      |     ",
        "      | norminette |     ",
        "      +------------+     ",
    },
    {
        "          .     *        ",
        "   *    .---.        .   ",
        "       / 42  \\   *       ",
        "   .   \\     /           ",
        "        '---'    .       ",
        "     *    |    *         ",
        "      CODAM ORBIT        ",
    },
    {
        "                         ",
        "       ⠊⢉⠆               ",
        "       ⠴⠥⠄               ",
        "           en            ",
        "            ⡠⢺⠀⡎⠉⡆       ",
        "            ⠉⠹⠁⠣⠤⠃       ",
        "                         ",
    },
    {
        "   :::            ###",
        ":::++++++         ###",
        ":::::::::         ###",
        ":::   ++++++      ###",
        ":::      ###      ###",
        ":::      ++++++   ###",
        ":::         #########",
        "::::::      ++++++###",
        ":::+++         ######",
        "   :::            ###",
        "                     ",
        "                     ",
        "      +++++++++######",
        "      ::::::###+++###",
        ":::   +++++++++######",
        "::::::      +++      ",
        ":::++++++   :::      ",
        "   ::::::++++++      ",
        "      +++###+++      ",
        "         +++###      ",
        "            +++      ",
    },
}
```
