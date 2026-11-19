# AI 引き継ぎメモ

このリポジトリを引き継ぐ AI エージェント向けの文書。
作業を再開するときに最初にこれを読むこと。

---

## このリポジトリは何か

`meitetu` の NixOS + Home Manager による dotfiles。
元は Arch Linux 上の **Hyprland + Quickshell** カスタムテーマ「Akari Hoshizaki」で、
それを NixOS へ移行するためにリポジトリ化したもの。

- リポジトリ: `https://github.com/meitetu/dotfiles_nix`
- ユーザー名: `meitetu`
- ホスト名: `akari`
- 元テーマ名: Akari Hoshizaki (ASTERISM Edition)
- デザイン: Material 3 / ダーク / コーラルピンク `#FF4E7A` + エメラルド差し色

---

## 現在の状態

| 項目 | 状態 |
| :--- | :--- |
| flake 評価 | ✅ `nixosConfigurations.akari` 生成成功 |
| Home Manager | ✅ ビルド成功 |
| 実機インストール | ❌ 未実施 (このセッション時点) |
| 顔認証 (Gaze) | ✅ PAM 設定生成確認済み、実機未登録 |

**NixOS 実機にはまだ入っていない。** 作業再開時はまず実機の状態を確認すること。

---

## 構成

```
flake.nix                    エントリポイント (nixosConfigurations / homeConfigurations / modules)
hosts/akari/
  default.nix                NixOS システム設定 (configuration.nix 相当)
  home.nix                   ユーザー設定 + 有効化するモジュール
modules/akari/
  default.nix                NixOS モジュール (programs.akari.*)
  home.nix                   Home Manager モジュール (programs.akari.*)
  bin/                       akari-ctl / akari-wofi / akari-wallpaper / akari-screenshot /
                             akari-unminimize / akari-idle / akari-polkit / akari-dpms
  config/
    hypr/                    hyprland.lua + modules/ (theme, monitors, env, autostart,
                             layout, rules, keybinds) + hyprlock.conf + hypridle.conf
    quickshell/akari/        shell.qml, bar/, osd/, panel/, overlays/, dashboard/, services/
    kitty/ wofi/ cava/ btop/ fastfetch/ fcitx5/ fontconfig/
  local-share/fcitx5/        akari-star テーマ
modules/zsh/                 .zshrc, plugins.toml (sheldon)
modules/nvim/                config/ (lazy.nvim + catppuccin + mason)
modules/starship/            starship.toml
```

---

## 重要な設計判断 (理由つき)

### 1. `configuration.nix` という名前を使っていない

`hosts/akari/default.nix` がその役割。flake 構成の慣習に合わせている。
ユーザーが「configuration.nix は?」と聞いたときはこれを案内する。

### 2. `modules/akari` と `modules/akari/home.nix` が二重にある

- `modules/akari/default.nix` … NixOS モジュール (`programs.akari.*`)
- `modules/akari/home.nix` … Home Manager モジュール (`programs.akari.*`)

同じオプション名だがスコープが違う。**`flake.nix` の両方で import が必要**:

- `nixosConfigurations.akari.modules` に `./modules/akari` を直接追加
  (`nixosModules` output を経由すると `config` が解決されない)
- `home-manager.sharedModules` に **4つとも** 追加
  (`./modules/akari/home.nix`, `./modules/zsh`, `./modules/nvim`, `./modules/starship`)
- 単体の `homeConfigurations` にも同じ 4つ + `hosts/akari/home.nix`

### 3. 顔認証は外部 flake から取る

nixpkgs に `gaze` パッケージが**存在しない**。`howdy` は IR カメラ前提で別物。
公式の `github:GunduLabs/gaze` flake を使う。

```nix
inputs.gaze.url = "github:GunduLabs/gaze";
inputs.gaze.inputs.nixpkgs.follows = "nixpkgs";
```

`inputs.nixpkgs.follows` は **nixpkgs unstable のときだけ** 設定する
(Gaze は edition 2024 で、stable の古い rustc ではビルドが壊れる)。

`gazed` は ONNX Runtime 1.21 以上を要求する。古い nixpkgs だと起動時に落ちる。

### 4. hyprlock の PAM は `simultaneous`

```nix
security.pam.services.hyprlock.gaze = { enable = true; simultaneous = true; };
```

ロック画面では顔認証とパスワード入力が同時に走る。`programs.hyprlock.enable = true` も必須。

### 5. Steam は unfree なので gaming オプションに隔離

```nix
nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (lib.getName pkg) [ "steam" "steam-unwrapped" ];
```

`programs.akari.gaming = true` で Steam / PrismLauncher / protonup-qt が入る。

### 6. 壁紙はリポジトリに入れない

著作権のある作品のため。`.gitignore` で画像を除外している。
`programs.akari.wallpaper` オプションで各自指定する。

元の Arch 環境では `/mnt/WD1TB/ピクチャ/149545359_p0.jpg` を参照していたが、
ポータブルなパス (`~/.local/share/wallpapers/akari.jpg`) に変更済み。
`AKARI_DEFAULT_WALL` 環境変数でも上書きできる。

---

## ハマりどころ (実際に踏んだもの)

### Nix 関連

| 症状 | 原因 / 対処 |
| :--- | :--- |
| `Path 'flake.nix' is not tracked by Git` | 未追跡ファイルは Nix から見えない。`git add -N <file>` |
| `attribute 'xdg.dataFile' already defined` | `lib.mkMerge` でまとめる |
| `services.networkmanager does not exist` | 正しくは `networking.networkmanager` |
| `noto-fonts-emoji` が無い | `noto-fonts-color-emoji` に改名済み |
| `hyprland-qtutils` が無い | 廃止。`hyprland-guiutils` は Hyprland の PATH に同梱 |
| `polkit-kde-agent-1` が無い | `kdePackages.polkit-kde-agent-1` |
| `dolphin` が無い | KDE アプリは `kdePackages.*` 配下 |
| `fcitx5-configtool` が無い | `qt6Packages.fcitx5-configtool` |
| `unrar` / `steam` が unfree | 削除 or `allowUnfreePredicate` |
| `programs.git.extraConfig` が無効 | `programs.git.settings` (新API) |
| `programs.git.userName` が無効 | `programs.git.settings.user.name` |
| `programs.zsh.initExtraFirst` が無効 | `initContent` + `lib.mkBefore` |
| `.config/zsh/.zshrc` が衝突 | Home Manager が `dotDir` に自分で書く。自前配置しない |
| `programs.neovim.withRuby` 警告 | `withRuby = false` を明示 (stateVersion < 26.05) |

### Arch 側 (元環境) で起きたこと

| 症状 | 対処 |
| :--- | :--- |
| `niri msg action spawn-sh` が動かない | `--` セパレータが必要: `spawn-sh -- "cmd"` |
| niri でウィンドウが 2 枚並ばない | `default-column-width { proportion 0.5; }` |
| niri でワークスペースが 2 個まで | **niri の仕様** (動的ワークスペース)。バグではない |
| niri でカーソルが点滅 | `hide-after-inactive-ms 0` → `60000` |
| Hyprland のロック画面クラッシュ表示 | `hyprctl eval 'hl.clear_crashed_lockscreen()'` |

**niri 対応は全て撤回済み。** `config/niri/`, `NiriService.qml` は削除した。
`Compositor.qml` は Hyprland 専用に簡素化されている。

---

## ユーザーの好み・指示の傾向

- 日本語。キャラクター口調のエージェント設定あり (`AGENTS.md` 参照)
- **技術的な正確さを最優先**。ごまかしや推測を嫌う
- 動かないものを「動いた」と言うと強く指摘される。**必ず実機で検証してから報告**
- スクリーンショットで見た目を確認することを好む
- 破壊的操作の前には必ず確認を取る
- 「アイコンが文字化け」と言われても実際は正常なことがある。**拡大して確認してから判断**
- 一度に複数のタスクを頼むことが多い。抜け漏れを嫌う

### 作業スタイル

- 設定を書いたら **必ず `nix flake check` か `nix build` で評価する**
- 評価が通っても実機で動くとは限らない。可能なら実機確認
- 既存の設定を壊さないよう、変更前にバックアップを取る

---

## 再開時のチェックリスト

### 1. 環境確認

```bash
# NixOS に入ったか
cat /etc/os-release

# flake が評価できるか
cd ~/dotfiles_nix   # or /etc/nixos
nix flake show

# 現在の世代
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -5
```

### 2. 状態確認

```bash
# 顔認証
systemctl status gazed
gaze doctor

# シェル環境
pgrep -x Hyprland
pgrep -x quickshell
hyprctl layers | grep akari

# サービス
systemctl status NetworkManager
systemctl --user status wireplumber
```

### 3. よくある「まだ終わってない」項目

- [ ] `hosts/akari/hardware-configuration.nix` の生成と import
- [ ] `hosts/akari/home.nix` の git email が `meitetu@example.com` のまま → 本人のものに変更
- [ ] 壁紙 (`~/.local/share/wallpapers/akari.jpg`) が未設定
- [ ] `gaze add-face default` 未実行
- [ ] README の `OWNER` プレースホルダ (akari-theme 側の話。dotfiles_nix では解消済み)

---

## ビルド検証コマンド

```bash
cd ~/dotfiles_nix

# 構文・評価のみ (速い)
nix flake show
nix eval .#nixosConfigurations.akari.config.system.build.toplevel.drvPath

# Home Manager 単体
nix eval .#homeConfigurations.meitetu.activationPackage.drvPath

# 実際にビルド
nix build .#homeConfigurations.meitetu.activationPackage --no-link

# システム全体 (重い)
sudo nixos-rebuild build --flake .#akari
```

---

## ファイルを変更したら

1. `nix fmt` (nixfmt-rfc-style) で整形
2. 評価を通す
3. コミット (ユーザー名は `meitetu`)

```bash
git add -A
git -c user.name="meitetu" -c user.email="meitetu@users.noreply.github.com" commit -m "..."
git push origin main
```

---

## 参考リンク

- NixOS マニュアル: https://nixos.org/manual/nixos/stable/
- Home Manager オプション検索: https://nix-community.github.io/home-manager/options.xhtml
- nixpkgs パッケージ検索: https://search.nixos.org/packages
- Gaze (顔認証): https://gaze.gundulabs.com/
- Quickshell: https://quickshell.org/
- Hyprland Wiki: https://wiki.hypr.land/
