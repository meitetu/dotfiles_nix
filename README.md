# dotfiles_nix

NixOS + Home Manager で管理する個人 dotfiles。
Akari Hoshizaki テーマ (Hyprland + Quickshell) を含む。

## 構成

```
.
├── flake.nix                  # エントリポイント
├── hosts/
│   └── akari/
│       ├── default.nix        # NixOS システム設定
│       └── home.nix           # ユーザー設定
├── modules/
│   ├── akari/                 # デスクトップテーマ
│   │   ├── default.nix        # NixOS モジュール
│   │   ├── home.nix           # Home Manager モジュール
│   │   ├── bin/               # akari-ctl などのスクリプト
│   │   ├── config/            # Hyprland / Quickshell / kitty / wofi ...
│   │   └── local-share/       # fcitx5 テーマ
│   ├── zsh/                   # zsh + sheldon + starship
│   ├── nvim/                  # Neovim (lazy.nvim + catppuccin)
│   └── starship/              # プロンプト
└── assets/                    # 壁紙など (git 管理外)
```

## 含まれるもの

| モジュール | 内容 |
| :--- | :--- |
| `modules/akari` | Hyprland / Quickshell シェル / システムモニター / M3 テーマ |
| `modules/zsh` | sheldon プラグイン + starship プロンプト |
| `modules/nvim` | lazy.nvim + catppuccin + mason (LSP 自動管理) |
| `modules/starship` | プロンプト定義 |

## インストール (NixOS)

### 1. NixOS をインストール

公式 ISO からインストールし、`hardware-configuration.nix` を生成します。

```bash
nixos-generate-config --root /mnt
```

`/mnt/etc/nixos/hardware-configuration.nix` を
`hosts/akari/hardware-configuration.nix` にコピーし、
`hosts/akari/default.nix` の先頭に次の1行を追加してください。

```nix
imports = [ ./hardware-configuration.nix ];
```

このファイルはマシン固有なので `.gitignore` で除外しています。

### 2. 自分の環境に合わせる

`hosts/akari/default.nix` を編集します。

```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/nixos";  # 自分のディスクに変更
  fsType = "ext4";
};

networking.hostName = "akari";

users.users.meitetu = { ... };          # ユーザー名を変更する場合
```

`hosts/akari/home.nix`:

```nix
home.username = "meitetu";
home.homeDirectory = "/home/meitetu";

programs.git.settings.user = {
  name = "meitetu";
  email = "your@email.com";
};
```

### 3. ビルド

```bash
sudo nixos-rebuild switch --flake .#akari
```

### 4. 顔認証の登録

```bash
gaze add-face default
gaze auth --verbose
```

## オプション

`programs.akari` (NixOS モジュール):

| オプション | 既定値 | 内容 |
| :--- | :--- | :--- |
| `enable` | `false` | デスクトップ環境一式を有効化 |
| `wallpaper` | `null` | 壁紙 (`/etc/akari/wallpaper.jpg` に配置) |
| `everydayApps` | `true` | 日常アプリ一式 |
| `faceAuth` | `true` | Gaze による顔認証 (sudo / polkit / hyprlock) |
| `gaming` | `false` | Steam / PrismLauncher / protonup-qt |

## 壁紙

著作権のある作品はリポジトリに含めていません。
`assets/wallpaper.jpg` に自分の画像を置き、`hosts/akari/default.nix` で指定してください。

```nix
programs.akari.wallpaper = ../../assets/wallpaper.jpg;
```

## キーバインド (抜粋)

| キー | 動作 |
| :--- | :--- |
| `Super + Return` | kitty |
| `Super + R` / `Space` | Wofi ランチャー |
| `Super + N` / `A` | クイック設定パネル |
| `Super + Shift + M` | システムモニター |
| `Super + F1` / `G` | ショートカット一覧 |
| `Super + L` | ロック画面 (顔認証対応) |

## Arch から移行する場合

`modules/akari/install.sh` はシンボリックリンクで配置する Arch 向けスクリプトです。
NixOS では使わず、`nixos-rebuild` が設定を配置します。

既存の Arch 環境の設定を NixOS に持っていく際の対応表:

| Arch | NixOS (このリポジトリ) |
| :--- | :--- |
| `~/.config/hypr/*` | `modules/akari/config/hypr/` |
| `~/.config/quickshell/akari` | `modules/akari/config/quickshell/akari` |
| `~/.config/nvim` | `modules/nvim/config` |
| `~/.config/sheldon/plugins.toml` | `modules/zsh/plugins.toml` |
| `~/.config/starship.toml` | `modules/starship/starship.toml` |
| fcitx5 (mozc UT) | `modules/akari/default.nix` の `i18n.inputMethod` |
| gaze-bin (AUR) | `gaze` flake input |

## ライセンス

MIT (アートワークを除く)
