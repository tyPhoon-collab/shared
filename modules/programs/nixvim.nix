{
  lib,
  nixvim,
  pkgs,
  features,
  ...
}:
{
  imports = [
    nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Vimオプション
    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      smartindent = true;
      wrap = false;
      clipboard = "unnamedplus";
      ignorecase = true;
      smartcase = true;
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      scrolloff = 8;
      updatetime = 250;
      timeoutlen = 300;
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      clipboard = lib.mkIf (!pkgs.stdenv.isDarwin) "osc52";

      # netrw (標準ファイラー) を完全に無効化
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    extraConfigLua = ''
      local ime_group = vim.api.nvim_create_augroup("macos-ime-reset", { clear = true })

      local function to_eisuu()
        if vim.fn.executable("macism") == 1 then
          vim.fn.jobstart({ "macism", "com.apple.keylayout.ABC" }, { detach = true })
        end
      end

      vim.api.nvim_create_autocmd("InsertLeave", {
        group = ime_group,
        callback = to_eisuu,
      })

      vim.api.nvim_create_autocmd("CmdlineEnter", {
        group = ime_group,
        callback = to_eisuu,
      })
    '';

    # Keymaps
    keymaps = [
      # Basic
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>w<CR>";
        options.desc = "Save";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>q<CR>";
        options.desc = "Quit";
      }
      {
        mode = "n";
        key = "<leader>Q";
        action = "<cmd>qa!<CR>";
        options.desc = "Force Quit All";
      }

      # Snacks Picker
      {
        mode = "n";
        key = "<leader>ff";
        action.__raw = "function() Snacks.picker.files() end";
        options.desc = "Find Files";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action.__raw = "function() Snacks.picker.grep() end";
        options.desc = "Live Grep";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action.__raw = "function() Snacks.picker.buffers() end";
        options.desc = "Buffers";
      }
      {
        mode = "n";
        key = "<leader>fh";
        action.__raw = "function() Snacks.picker.help() end";
        options.desc = "Help Tags";
      }
      {
        mode = "n";
        key = "<leader><leader>";
        action.__raw = "function() Snacks.picker.files() end";
        options.desc = "Find Files";
      }
      {
        mode = "n";
        key = "<leader>/";
        action.__raw = "function() Snacks.picker.grep() end";
        options.desc = "Live Grep";
      }
      {
        mode = "n";
        key = "<leader>un";
        action.__raw = "function() Snacks.picker.notifications() end";
        options.desc = "Notification History";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<leader>t";
        action.__raw = "function() Snacks.terminal() end";
        options.desc = "Toggle Terminal";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<leader>T";
        action.__raw = ''function() Snacks.terminal(nil, { count = 2, win = { position = "right" } }) end'';
        options.desc = "Toggle Terminal Right";
      }

      # Buffer Navigation
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<CR>";
        options.desc = "Prev Buffer";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<CR>";
        options.desc = "Next Buffer";
      }

      # Window Navigation
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-Left>";
        action = "<cmd>wincmd h<CR>";
        options.desc = "Focus Left";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-Down>";
        action = "<cmd>wincmd j<CR>";
        options.desc = "Focus Down";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-Up>";
        action = "<cmd>wincmd k<CR>";
        options.desc = "Focus Up";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<A-Right>";
        action = "<cmd>wincmd l<CR>";
        options.desc = "Focus Right";
      }

      # Flash
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "s";
        action.__raw = "function() require('flash').jump() end";
        options.desc = "Flash";
      }
      {
        mode = [
          "n"
          "x"
          "o"
        ];
        key = "S";
        action.__raw = "function() require('flash').treesitter() end";
        options.desc = "Flash Treesitter";
      }

      # Search
      {
        mode = "n";
        key = "<leader>sw";
        action.__raw = "function() Snacks.picker.grep_word() end";
        options.desc = "Search Current Word";
      }
      {
        mode = "n";
        key = "<leader>st";
        action.__raw = "function() Snacks.picker.todo_comments() end";
        options.desc = "Todo Comments";
      }
    ];

    # カラースキーム
    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
    };

    plugins = {
      # LSP
      lsp = {
        enable = features.dev >= 1;
        servers =
          (lib.genAttrs [ "lua_ls" "nixd" "marksman" ] (name: {
            enable = features.dev >= 1;
          }))
          // (lib.genAttrs [ "ts_ls" "pyright" "yamlls" ] (name: {
            enable = features.dev >= 2;
          }))
          // {
            rust_analyzer = {
              enable = features.dev >= 2;
              installCargo = false;
              installRustc = false;
            };
          };
        keymaps = {
          silent = true;
          lspBuf = {
            K = "hover";
          };
          diagnostic = {
            "<leader>cd" = "open_float";
            "[d" = "goto_prev";
            "]d" = "goto_next";
          };
          extra = [
            {
              mode = "n";
              key = "gd";
              action.__raw = "function() Snacks.picker.lsp_definitions() end";
              options.desc = "Goto Definition";
            }
            {
              mode = "n";
              key = "grr";
              action.__raw = "function() Snacks.picker.lsp_references() end";
              options.desc = "References";
            }
            {
              mode = "n";
              key = "gri";
              action.__raw = "function() Snacks.picker.lsp_implementations() end";
              options.desc = "Goto Implementation";
            }
            {
              mode = "n";
              key = "grt";
              action.__raw = "function() Snacks.picker.lsp_type_definitions() end";
              options.desc = "Goto Type Definition";
            }
          ];
        };
      };

      # 補完
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "buffer"; }
          ];
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.close()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          };
        };
      };

      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      # Snacks
      snacks = {
        enable = true;
        settings =
          (lib.genAttrs
            [
              "indent"
              "input"
              "notifier"
              "picker"
              "quickfile"
              "scope"
              "scroll"
              "statuscolumn"
              "terminal"
              "toggle"
              "words"
            ]
            (name: {
              enabled = true;
            })
          )
          // {
            dashboard = {
              enabled = true;
              sections = [
                { section = "header"; }
                {
                  section = "keys";
                  gap = 1;
                  padding = 1;
                }
                {
                  icon = " ";
                  title = "Recent Files";
                  section = "recent_files";
                  indent = 2;
                  padding = 1;
                }
                {
                  icon = " ";
                  title = "Projects";
                  section = "projects";
                  indent = 2;
                  padding = 1;
                }
                # { section = "startup"; } # lazy.nvim dependency (startup stats) disabled
              ];
            };
          };
      };

      # Copilot (Level 2 only)
      copilot-lua = {
        enable = features.dev >= 2;
        settings = {
          suggestion = {
            enabled = true;
            auto_trigger = false;
            keymap.accept = "<C-l>";
          };
          filetypes."*" = true;
        };
      };
    }
    // (lib.genAttrs
      [
        "lualine"
        "bufferline"
        "web-devicons"
        "gitsigns"
        "flash"
        "nvim-autopairs"
        "todo-comments"
        "trouble"
        "yazi"
      ]
      (name: {
        enable = true;
      })
    );

  };
}
