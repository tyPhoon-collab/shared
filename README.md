# shared

個人用 dotfiles から切り出した、再利用用の Home Manager 設定です。

このリポジトリは flake ではなく、親の flake から `flake = false` の source input として読み込む前提です。依存関係の固定や `flake.lock` の管理は親リポジトリ側で行います。

## クイックスタート

1. 親 flake の `inputs` に `shared` を追加
2. `extraSpecialArgs` で必要引数を渡す
3. Home Manager モジュールに `(shared + /home.nix)` を import

入力例:

```nix
{
  inputs.shared = {
    url = "path:/path/to/shared";
    flake = false;
  };
}
```

引数の受け渡し例:

```nix
let
  mkFeatures = import (shared + /lib/features.nix);
in
extraSpecialArgs = {
  inherit username homeDirectory shared;
  features = mkFeatures {
    extended = true;
  };
  nixvim = inputs.nixvim;
  yaziPlugins = inputs.yazi-plugins;
};
```

import 例:

```nix
{
  shared,
  ...
}:
{
  imports = [
    (shared + /home.nix)
  ];
}
```

## このリポジトリが持つもの

- `home.nix`: 共有エントリーポイント
- `modules/`: Home Manager / platform 向けモジュール
- `files/`: 各種設定ファイル

扱うのは、複数環境で使い回せる設定だけです。秘密情報やホスト固有の値は含めません。

## ディレクトリ構成

```text
.
├── home.nix
├── files/
│   ├── aerospace/
│   ├── karabiner/
│   ├── nushell/
│   └── wezterm/
└── modules/
    ├── platform/
    ├── programs/
    ├── shell/
    └── system/
```

## 必要な引数

`home.nix` は少なくとも次を受け取ります。

- `username`
- `homeDirectory`
- `features`
- `nixvim`
- `yaziPlugins`

加えて、Home Manager が通常渡す `pkgs` や `lib` を利用します。

## Home Manager のシステム統合

NixOS / nix-darwin に Home Manager を組み込む場合は、共通の既定値として
`lib/home-manager.nix` の `default` を利用できます。

```nix
let
  sharedHomeManager = import (shared + /lib/home-manager.nix);
in
{
  home-manager = sharedHomeManager.default // {
    users.${username} = import ./home.nix;
    extraSpecialArgs = mkExtraArgs username homeDirectory features;
  };
}
```

取り込み側で同じ属性を書いた場合は、取り込み側の値が優先されます。

## feature フラグ

主なフラグは次のとおりです。

| フラグ     | 役割                                       |
| ---------- | ------------------------------------------ |
| `desktop`  | GUI / デスクトップ向け設定を有効化         |
| `fonts`    | `true` で fontconfig と Nerd Font を有効化 |
| `extended` | 追加の CLI ツールを有効化                  |
| `dev`      | 値が大きいほど開発向け設定を拡張           |
| `wsl`      | WSL 向け分岐に使用                         |

既定値:

```nix
features = {
  desktop = false;
  fonts = false;
  extended = false;
  dev = 1;
  wsl = false;
};
```

親側では `lib/features.nix` を import して、必要な差分だけ上書きしてください。

もしくは、すべてのフラグを定義して渡してください。

```nix
let
  mkFeatures = import (shared + /lib/features.nix);
in
{
  features = mkFeatures {
    extended = true;
  };
}
```

## 役割の境界

| shared 側に置く                        | 親リポジトリ側に置く             |
| -------------------------------------- | -------------------------------- |
| 再利用できる shell / editor / CLI 設定 | ユーザー名やホスト固有の識別情報 |
| 公開して問題ない静的ファイル           | マシンごとに変わるポリシー       |
| 汎用的な macOS / Linux 向け設定        | 秘密情報                         |

## 設定の上書き

取り込み側で差分を重ねるためのガイドをモジュール別に分離しています。

- [AeroSpace の上書き](docs/overrides/aerospace.md)
- [Git の上書き](docs/overrides/git.md)
- [Jujutsu の上書き](docs/overrides/jujutsu.md)

共通ルール:

- shared 側は再利用できる既定値のみを持つ
- 個人識別情報（ユーザー名やメールアドレス）は取り込み側で設定する
- ホスト固有・環境固有のポリシーは取り込み側で設定する

`git` と `jujutsu` の個人識別情報は、各利用側の flake で追記してください。

```nix
{
  programs.git = {
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  programs.jujutsu.settings = {
    user.name = "Your Name";
    user.email = "you@example.com";
  };
}
```

## 補足

`modules/system/darwin-defaults.nix` は、必要なら親リポジトリ側で直接 import して使えます。

このモジュールを取り込んで `system.defaults` を適用する場合、`darwin-rebuild` を実行するターミナルや Nix 関連プロセスに Full Disk Access が必要になることがあります。

## 最小例

親 flake から `shared` を読み込んで Home Manager に組み込む最小構成です。

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    shared = {
      url = "path:/path/to/shared";
      flake = false;
    };
    nixvim.url = "github:nix-community/nixvim";
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, shared, ... }:
    let
      mkFeatures = import (shared + /lib/features.nix);
      system = "x86_64-linux";
      username = "user";
      homeDirectory = "/home/user";
      features = mkFeatures { };
      pkgs = import nixpkgs { inherit system; };
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit username homeDirectory features shared;
          nixvim = inputs.nixvim;
          yaziPlugins = inputs.yazi-plugins;
        };
        modules = [
          ({ shared, ... }: {
            imports = [ (shared + /home.nix) ];
          })
        ];
      };
    };
}
```
