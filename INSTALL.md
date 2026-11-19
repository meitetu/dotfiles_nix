# NixOS インストール手順 — dotfiles_nix

Arch から NixOS へ移行する手順書。
設定は `https://github.com/meitetu/dotfiles_nix` に置いてある。

---

## 0. 事前に必要なもの

- NixOS ISO (Ventoy の USB に入っている)
- dotfiles_nix の USB コピー (このフォルダ)
- ネットワーク (有線推奨。ISO 起動後は Wi-Fi も可)

### インストール先

**必ず自分のディスクを確認すること。** 以下は例:

| デバイス | 用途 | 消える |
| :--- | :--- | :--- |
| `/dev/nvme0n1` または `/dev/sdX` | NixOS インストール先 | **全部消える** |
| `/dev/sdY` | データ用 (NTFS) | 残す |

> 現在の Arch 環境は `/dev/sdc` (Crucial CT525MX300SSD1) にあり、
> `/boot` が vfat、`/home` が btrfs、ルートが別パーティション。
> この SSD ごと消して NixOS を入れる想定。

---

## 1. NixOS ISO で起動

1. Ventoy の USB を挿して PC を起動
2. BIOS/UEFI のブートメニューで USB を選択
3. Ventoy のメニューから `nixos-graphical-*.iso` を選択
4. NixOS のインストーラが起動する

---

## 2. ネットワーク

### 有線

そのまま繋がる。

### Wi-Fi

```bash
# 対話式で接続
sudo nmcli device wifi connect "SSID" password "パスワード"

# 確認
ping -c 3 nixos.org
```

---

## 3. ディスクを準備

### パーティション構成 (UEFI + systemd-boot)

| パーティション | サイズ | 形式 | マウント |
| :--- | :--- | :--- | :--- |
| 1 | 1GB | vfat (EF00) | `/boot` |
| 2 | 残り全部 | ext4 (8300) | `/` |

### 実行例 (`/dev/nvme0n1` を自分のディスクに置き換える)

```bash
# デバイス名を必ず確認
lsblk -o NAME,SIZE,TYPE,MODEL

# パーティション作成
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart root ext4 1GiB 100%

# フォーマット
sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2

# マウント
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/BOOT /mnt/boot
```

> btrfs にしたい場合は `mkfs.btrfs -L nixos /dev/...` にして、
> `hosts/akari/default.nix` の `fsType` を `"btrfs"` に変更する。
> サブボリュームを使うなら `fileSystems` の設定も追加すること。

---

## 4. 設定ファイルを配置

```bash
# USB がマウントされている場所を探す
ls /run/media/nixos/

# 例: USB の dotfiles_nix をホームへコピー
cp -r /run/media/nixos/Ventoy/dotfiles_nix ~/dotfiles_nix
cd ~/dotfiles_nix
```

---

## 5. ハードウェア設定を生成

```bash
sudo nixos-generate-config --root /mnt

# 生成されたファイルをリポジトリへコピー
cp /mnt/etc/nixos/hardware-configuration.nix hosts/akari/hardware-configuration.nix
```

`hosts/akari/default.nix` の冒頭に 1 行追加する:

```nix
{
  config, lib, pkgs, ...
}:
{
  imports = [ ./hardware-configuration.nix ];   # ← これを追加

  # ... 以下既存の設定
}
```

> `hosts/akari/default.nix` の `fileSystems` は仮の値。
> `hardware-configuration.nix` を import したら、そちらが優先されるので
> 重複警告が出たら `hosts/akari/default.nix` 側の `fileSystems` を削除する。

---

## 6. ユーザー名と git の設定を確認

```bash
# ユーザー名を変えたい場合
grep -rn "meitetu" hosts/ modules/ | head -20
```

最低限ここを確認:

| ファイル | 項目 |
| :--- | :--- |
| `hosts/akari/default.nix` | `networking.hostName`, `users.users.*` |
| `hosts/akari/home.nix` | `home.username`, `home.homeDirectory`, git の name/email |
| `flake.nix` | `home-manager.users.meitetu`, `homeConfigurations."meitetu"` |

---

## 7. インストール

```bash
cd ~/dotfiles_nix

# ビルド確認 (失敗したらここでエラーが出る)
sudo nixos-rebuild build --flake .#akari

# インストール
sudo nixos-install --flake .#akari --root /mnt
```

`nixos-install` の最後に root パスワードの設定を求められる。

---

## 8. 再起動

```bash
sudo reboot
```

再起動後、GDM のログイン画面から **Hyprland** を選んでログイン。

---

## 9. 初回ログイン後の作業

### 顔認証の登録

```bash
gaze add-face default
gaze auth --verbose     # 動作確認
```

`sudo` と `hyprlock` で顔認証が効くようになる。パスワードはフォールバックとして残る。

### 壁紙

```bash
mkdir -p ~/.local/share/wallpapers
# 好きな画像を置く
cp /path/to/image.jpg ~/.local/share/wallpapers/akari.jpg

# 反映
akari-wallpaper --restore
```

### 日本語入力の確認

```bash
fcitx5-remote -o    # 有効化
# Super + Space などで切替できるか確認
```

---

## 10. トラブルシューティング

### `nixos-install` が失敗する

```bash
# エラーの詳細を見る
sudo nixos-install --flake .#akari --root /mnt --show-trace
```

### ネットワークが繋がらない (インストーラ内)

```bash
sudo systemctl restart NetworkManager
nmcli device status
```

### ログイン後にバーが出ない

```bash
# 手動起動してログを見る
akari-ctl shell-start
tail -50 /tmp/akari-quickshell.log
```

### Hyprland が起動しない

```bash
# 設定の構文チェック
hyprctl version
cat /tmp/hypr/*.log
```

### 顔認証が動かない

```bash
systemctl status gazed
gaze doctor
gaze config          # カメラの設定を確認
```

---

## 11. Arch に戻りたいとき

NixOS を入れた SSD を消すので、事前にバックアップを取っておくこと。

必要なデータ:

| データ | 場所 |
| :--- | :--- |
| ドキュメント | `~/Documents` |
| 画像 | `~/Pictures` |
| SSH 鍵 | `~/.ssh` |
| GPG 鍵 | `~/.gnupg` |
| ブラウザプロファイル | `~/.mozilla`, `~/.config/*/` |
| Steam ゲーム | `~/.steam`, `~/.local/share/Steam` |

---

## 参考

- NixOS マニュアル: https://nixos.org/manual/nixos/stable/
- Home Manager: https://nix-community.github.io/home-manager/
- Gaze (顔認証): https://gaze.gundulabs.com/
