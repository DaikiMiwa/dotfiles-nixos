# Cursor Server を NixOS-WSL で動かす

## 概要

Cursor の Anysphere Remote WSL 拡張は、Cursor Server のインストール時に
Ubuntu などの FHS 準拠ディストリビューションを前提としたシェルスクリプトを
実行する。NixOS ではコマンドが通常 `/nix/store` とシステムプロファイルに
配置されるため、拡張が `wsl.exe --exec` で作る最小環境からコマンドを
見つけられず、次のエラーになることがある。

```text
Failed to install Cursor server. Installer script returned code 1. Retrying.
Error installing Cursor server Failed to install code server. Exited with code 1
```

このリポジトリでは、Cursor のインストールスクリプトが必要とするコマンドを
`systemd.tmpfiles.rules` で `/usr/bin` にリンクし、`programs.nix-ld` で
配布済みの Node.js バイナリを実行できるようにしている。

## 原因

調査時の環境は次のとおり。

- NixOS-WSL
- Cursor 3.13.10
- Anysphere Remote WSL 1.0.13
- Cursor commit `4f02290ccd9304f0e6bf8ee85f6e9106f02ac1f0`
- Server real commit `4f02290ccd9304f0e6bf8ee85f6e9106f02ac1f7`

Remote WSL 拡張は、概ね次の順でサーバーを導入する。

1. Server のtarballをダウンロードする。
2. `tar` で展開する。
3. `find ... | wc -l` でtarballと展開先のエントリー数を比較する。
4. `setsid cursor-server ...` でServerをバックグラウンド起動する。
5. ログに `Extension host agent listening on <port>` が出るまで待つ。

今回、二つの独立した不足があった。

### `find` がない

Remote WSL 1.0.13付属の `wslDownload.sh` は、展開後に次の検証を行う。

```bash
FILE_COUNT=$(tar -tf "$SERVER_TAR_FILE" | wc -l)
EXTRACTED_COUNT=$(find "$SERVER_DIR" | wc -l)
```

`PATH=/usr/bin:/bin` から `find` が見つからないと
`EXTRACTED_COUNT` が正しくならず、展開済みファイルを破損扱いして終了する。

### `setsid` がない

tarballの展開に成功しても、外側のインストールスクリプトはServerを次のように
起動する。

```bash
setsid "$SERVER_SCRIPT" \
  --start-server \
  --host=127.0.0.1 \
  --port=0 \
  ...
```

`setsid` が見つからない場合、Serverは一度も起動しない。拡張はログから
listenポートを取得できず、最終的にexit code 1を返す。

今回のログでは、最初の試行が約1秒、Windows側でtarballをダウンロードした
再試行が展開後約5秒で失敗していた。これはServerのlistenを待つ時間と
一致していた。

## 対応

`nixos/configuration.nix` で次の機能を有効にする。

```nix
programs.nix-ld.enable = true;
```

さらに、Remote WSL が最小PATHから呼ぶコマンドを `/usr/bin` にリンクする。
今回の直接原因に対応する重要なリンクは次の二つ。

```nix
systemd.tmpfiles.rules = [
  "d /usr/bin 0755 root root -"
  "L+ /usr/bin/find - - - - ${pkgs.findutils}/bin/find"
  "L+ /usr/bin/setsid - - - - ${pkgs.util-linux}/bin/setsid"
];
```

実際の構成では、同じスクリプトが使用する `awk`、`grep`、`tar`、`wc`、
`ps`、`sed` なども宣言している。Cursorの更新でスクリプトの使用コマンドが
増えた場合は、同じ考え方で明示的に追加する。

設定を適用する。

```bash
sudo nixos-rebuild switch --flake .#nixos-wsl
```

最小PATHで直接確認する。

```bash
env -i HOME="$HOME" PATH=/usr/bin:/bin /bin/bash --noprofile --norc -c \
  'command -v find; command -v setsid; setsid --version | head -n 1'
```

期待する出力例：

```text
/usr/bin/find
/usr/bin/setsid
setsid from util-linux 2.41.4
```

Cursorを完全に終了してから、WindowsのPowerShellでWSLを停止し、再接続する。

```powershell
wsl --shutdown
```

不完全なServerが残って再インストールされない場合は、Cursorを終了した状態で
既存ディレクトリを削除せず退避する。

```bash
mv ~/.cursor-server ~/.cursor-server.backup
```

## 検証結果

修正後、Remote WSL 1.0.13に付属する実際の `wslDownload.sh` を
同じcommit、`PATH=/usr/bin:/bin`、一時ディレクトリで実行した。

- 124 MiBのtarballを取得
- 8,962エントリーを検証
- 8,962エントリーを展開
- インストーラーはexit code 0

続けて、外側のインストールスクリプトと同じ引数でServerを起動した。

```text
Server bound to 127.0.0.1:37203 (IPv4)
Extension host agent listening on 37203
```

これにより、ダウンロード、整合性確認、展開、Node.js実行、`setsid`による
Server起動までを確認した。

## 別問題として扱うログ

次のエラーは、現在のCursorが `resources/app/bin/code` を同梱していないことに
よるCursor側の既知問題。Serverインストールがその後も進んでいるなら、
今回のexit code 1の直接原因ではない。

```text
Failed to patch code.sh launcher: Error: ENOENT:
no such file or directory, open
'C:\Users\...\Programs\cursor\resources\app\bin\code'
```

また、次の端末サイズ警告もServerインストール失敗の直接原因ではない。

```text
your 131072x1 screen size is bogus. expect trouble
```

`.wslconfig` の `bestEffortDnsParsing` 警告が出る場合は、このキーを
`[wsl2]` ではなく `[experimental]` に置くか、不要なら削除する。

```ini
[wsl2]
dnsTunneling=true

[experimental]
bestEffortDnsParsing=true
```

## 今後の切り分け

Cursor更新後に再発した場合は次の順で調べる。

1. Remote WSL拡張のバージョンと`dist/scripts/`を確認する。
2. ログに出たtarball URLを手動で取得・検証する。
3. インストールスクリプトを一時ディレクトリと最小PATHで実行する。
4. スクリプトが呼ぶ各コマンドを
   `env -i PATH=/usr/bin:/bin /bin/bash --noprofile --norc` から確認する。
5. Serverログに `Extension host agent listening on` があるか確認する。
6. 不足コマンドをNixOS構成へ宣言的に追加する。
