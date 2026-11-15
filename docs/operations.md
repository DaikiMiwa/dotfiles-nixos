# 更新・検証・切り戻し

## 最初の適用と配置

配置先は `home/dotfiles.nix` の `dotfiles.repository` で一元管理する。
標準は `~/dotfiles-nixos`。別配置では Home Manager module に絶対パスを指定する。
Neovim の Lua 設定はこの作業ツリーへリンクされるため、その場の編集が反映される。
Nix 管理の Neovim 依存は `home-manager switch` / `nixos-switch` で反映する。

## 通常の変更

リポジトリで `git status --short` を確認し、変更後に次を実行する。

```sh
dotfiles-fmt
dotfiles-check
```

helper をまだ適用していない場合は、リポジトリのルートで次を実行する。
system は WSL: `x86_64-linux`、Apple Silicon: `aarch64-darwin`、Intel: `x86_64-darwin`。

```sh
nix fmt
nix flake check --all-systems --no-build --show-trace
nix build --no-link \
  .#checks.aarch64-darwin.format-nix \
  .#checks.aarch64-darwin.format-lua \
  .#checks.aarch64-darwin.shell-scripts \
  .#checks.aarch64-darwin.cursor-cli \
  .#checks.aarch64-darwin.dotfiles-helpers \
  .#checks.aarch64-darwin.neovim-config
```

`--no-build` は check の評価のみで、formatter やテストを実行しない。
CI は3つの native runner で評価と上記チェックを実行する。全 Home Manager / WSL
システムのビルド、ログインや GUI 操作は CI の保証範囲外なので、適用前に対象環境で build する。
commit 前に `git diff --check` と差分を確認し、意図したファイルのみ stage する。

`shell-scripts` は ShellCheck に加え、WezTerm のキー定義・入力状態遷移と、
独立した tmux socket / PTY を使った検索・ペイン移動・再接続・セッション削除を検証する。
既存の tmux server には接続しない。macOS IME の未確定文字を使う GUI 操作は実機で確認する。

## 依存更新

Nix input は必要なものを指定して `nix flake update nixpkgs home-manager` 等で更新し、
検証する。全 input を更新したい場合だけ `nix flake update` を使う。
設定変更と依存更新を別 commit にして切り戻せるようにする。
CI action も commit SHA を固定し、更新時にリリース内容と3 platform の結果を確認する。
個人リポジトリの方針に合わせ、自動更新 PR は作成しない。

lazy.nvim、Treesitter と parser / queries、LuaSnip と jsregexp、Cursor CLI は Nix 管理。
Neovim 内でこれらを更新・build しない。その他のプラグインは `:Lazy update` 後に
補完・ファイル検索・LaTeX 等を確認し、`lazy-lock.json` を commit する。
他のマシンや切り戻し後は `:Lazy restore` で lock の revision を再現する。
plugin 自体に手編集がある場合は復元が拒否されるので、先に差分を退避する。
plugin cache を編集するより、リポジトリ内の設定や明示した patch で変更を管理する。
Blink は Lua matcher を使用する。Rust matcher が必要になった場合は Nix で binary を
提供してから設定を変更し、起動時の download に依存しない構成を維持する。

Codex / Claude Code は既存方針どおり Homebrew で管理する。これらの更新は
`brew upgrade --cask codex claude-code` で明示的に行い、Nix の更新と別に確認する。
Homebrew の cask は `flake.lock` に固定されない。Nix の rollback では戻らない。

### ccmux（macOS）

ccmux の daemon / integration は `Brewfile` の formula として管理する。
`Ctrl+b a` で開く一覧は、ccmux 1.4.6 のネイティブ UI に自動承認の表示・操作を足した Nix 管理版。
上流ソース・Bun lockfile の依存・UI patch を固定し、Homebrew 本体は変更しない。
新しい Mac ではリポジトリのルートで
`brew bundle --file=Brewfile` を実行し、Home Manager を適用する。
Linux / WSL ではこの Brewfile による導入は行わず、使う場合は別途 ccmux の導入が必要。
Home Manager の switch だけでは ccmux 本体や各 CLI の hook は導入されない。

```sh
ccmux setup --agent codex --agent claude --agent opencode
ccmux setup --agent codex --agent claude --agent opencode --status
```

setup は既存設定に hook を追加する。実行前に `~/.codex/config.toml`、
`~/.codex/hooks.json`、`~/.claude/settings.json` の存在するものをローカルに退避する。
認証情報を含み得るため、退避ファイルもリポジトリには置かない。
hook / plugin を読み込ませるため、起動済みの CLI は会話を保持して再起動・resume する。
Codex に hook の信頼確認が表示された場合は、追加した ccmux hook を確認する。

| 操作 | キー |
| --- | --- |
| プレビュー付きの一覧を開く | `Ctrl+b` → `a` |
| 選択行の自動承認 ON / OFF | 一覧で `F2` または `Ctrl+t` |
| 行メニューから自動承認を切り替える | 一覧で `m` または行を右クリック → `Auto: OFF → ON` / `ON → OFF` |
| 予備の自動承認設定画面 | `Ctrl+b` → `Shift+a` |
| 一覧を閉じる | 一覧の選択中に `q` |
| 対象のペインへ移動し、一覧を閉じる | `j` / `k` で選択 → `Enter` |
| プレビューへ入力を送り、承認・回答する | 対象を選択 → `Tab` でプレビューに入る |
| サイドバーを表示・非表示 | `Ctrl+b` → `Shift+s` |

プレビューへの入力は対象エージェントへの実際の入力になる。通常は `Enter` で元の
ペインへ移動して、承認内容を読んで操作する。一覧には承認・質問待ちの項目が上部にまとまる。
元のペインへ移動せず承認する場合は、`j/k` でグループ見出しではなくエージェント行を選び、
`Tab` でプレビューへ入って画面に表示された承認キーを送る。`Tab` / `Esc` で一覧操作へ戻る。
承認キーは CLI と画面によって異なるため、`y` + `Enter` を固定で送らない。
ccmux 1.4.6 の通知側の対応は Codex 通常承認が `Enter`、Claude Code 通常承認が `1`、
Claude Code 計画承認が `2`。これは通知用の対応表で、プレビュー入力自体はそのまま転送される。
CLI のバージョンや現在の選択位置もあるため、プレビューの表示に従って操作する。

### セッションごとの自動承認

`Ctrl+b a` の一覧に各行の `AUTO:ON` / `AUTO:OFF` が表示される。
エージェント行を選んで `F2`（または `Ctrl+t`）で切り替える。
`m` / 右クリックの行メニューからも変更できる。グループ見出しは一括変更しない。
プレビューに入力中は `Tab` で一覧側へ戻ってから操作する。
`AUTO:?` は状態をまだ取得できていない表示。変更失敗は toast に表示し、成功扱いにしない。
一覧を表示するだけでは設定は変わらない。
ここでのセッションは ccmux の一覧に出るエージェント単位。同じ tmux セッション内でも独立する。
`Ctrl+b Shift+a` の予備画面では対象を確認して `Enter` で切り替え、`Ctrl+r` で再読み込み、`Esc` で閉じる。
既定はすべて OFF。ON にした時点ですでに承認待ちなら、その承認も送信対象になる。
対象ペインを開いている間はステータスバーの `AUTO` で有効状態を確認できる。

ON のセッションについて1秒間隔で ccmux の状態を確認し、`permission` / `plan_approval` に限り、
ccmux 1.4.6 の `POST /notification-action` に `approve` を渡す。
ccmux 自身が CLI と現在の承認画面に応じたキーを選ぶ。
質問待ち・通常入力・作業中には送らず、CLI の権限・sandbox 設定も変更しない。
未対応の画面・CLI・バージョンや古い状態は ccmux 側で拒否される。その場合は手動で操作する。

許可はペイン・エージェント ID・プロセス PID・識別できた会話 ID に結び付ける。
デタッチ・設定再読み込みでは保持し、別プロセスや別会話として検出された場合は OFF に戻す。
tmux server 再起動後も既定の OFF から開始する。
会話 ID を取得できない CLI はプロセス内の会話変更を区別できないため、会話を切り替える前に OFF にする。

同じ待機世代には1回だけ送信し、送信結果が不明でも連打・再送しない。
拒否された待機も同じ世代では自動再試行しないため、必要ならプレビューで手動承認する。
OFF 操作は実行中の1要求が完了するまで待ち、OFF が反映された後に新たな要求は送らない。
監視は最初に ON にしたときに起動し、tmux server が終了すると停止する。
再接続・設定再読み込みでも ON があれば再起動する。CLI と監視 daemon の socket が異なる場合は送信しない。

状態確認は `tmux-agent-autoapprove status`。
CLI 操作では `tmux-agent-autoapprove on <ccmux-session-id>` / `off <ccmux-session-id>` も使える。
`toggle <ccmux-session-id>` は現在値をロック内で反転し、`status --json` は一覧 UI 用の状態を返す。
送信履歴と worker log は `~/.local/state/dotfiles/agent-auto-approve/` 配下（XDG_STATE_HOME 対応）に保存する。
履歴には承認対象のコマンドや会話本文を保存しない。履歴を削除すると重複抑制も消えるので、監視中は削除しない。
ccmux の内部 API に依存するため、更新時は ON / OFF・承認キー・世代チェックを再検証する。
一覧 UI の更新は `home/ccmux-picker/package.nix` のソース・依存 hash と `ui.patch` を揃えて行う。
通常の native checks は UI のビルドと状態表示・切り替えの Bun tests も実行する。
開きっぱなしの一覧は更新されないため、Home Manager 適用後に閉じて `Ctrl+b a` で開き直す。

サイドバーは既定で左側36列に常駐する。接続・新規セッション・設定再読み込み時に不足分を
補い、すでに表示されている場合は重複作成しない。`Ctrl+b Shift+s` で明示的に隠した状態は
その tmux server 内で保持され、もう一度同じキーで表示する。
サイドバー切り替えは全セッション・全ウィンドウが対象で、新しいウィンドウにも追従する。
一覧を閉じてもエージェントや監視 daemon は終了しない。

監視 daemon はサイドバー / 一覧を開くと自動起動する。
daemon が動いている間は、一覧を隠してもバーに待機 / 未読件数とウィンドウの印を表示する。
macOS の通知から承認する機能は別途通知設定が必要で、今回の導入では有効化していない。

状態が合わない場合は `ccmux setup --status` と `ccmux debug` を確認し、CLI の hook と
バージョンを確認する。ccmux 更新は `brew upgrade ccmux`、必要に応じて setup を再実行し、
`ccmux daemon restart` で再読み込みする。Homebrew が依存する tmux なども更新し得る。
削除時は先にサイドバーを閉じ、`ccmux setup --uninstall --agent codex --agent claude --agent opencode`
で ccmux 所有の連携を外し、daemon を停止する。Codex の hooks feature flag は自動削除されない。

Intel Mac は選択した CLI にも stable Nixpkgs を使い、CI の Intel runner で検証する。
上流の対応終了後も動くと推測して input を進めない。Intel を維持する間は最後に成功した
lock を保存し、サポート対象 input を超える更新時は Linux / Apple Silicon の input と
Intel の input を分離する。OS の対応終了はこのリポジトリだけでは解消できない。

## 適用後

macOS は `home-manager build --flake .#daiki.miwa-aarch64-darwin` 成功後に同じ出力へ switch。
WSL は `sudo nixos-rebuild build --flake .#nixos-wsl` 成功後に `nixos-switch`。
Intel は macOS の出力名を `daiki.miwa-x86_64-darwin` に替える。
新しいシェルで `command -v nvim cursor-agent dotfiles-check` を確認する。
Cursor の旧 local installer が優先される場合、そのリンクを退避して PATH を再確認する。
認証設定は削除しない。

Neovim は Nix wrapper を使う。Homebrew の `nvim` が優先されている場合は
PATH を確認して Home Manager のものを使う。初回起動には残りの lazy 管理 plugin の
取得が必要。既存の lazy.nvim / Treesitter / LuaSnip の cache は、今回の構成では使わない。
tmux は設定を reload し、Herdr は再起動して確認する。

tmux / WezTerm の日本語入力連携は、Home Manager 適用後に WezTerm が設定を
再読み込みしたことを確認し、tmux 内で `tmux source-file ~/.config/tmux/tmux.conf` を実行する。
日本語の未確定文字がある状態で `Ctrl+b` → `w` / `m` / `[` を確認し、
コピー中の `h/j/k/l`・`v`・`y` と、`/` 検索の日本語入力・確定・キャンセルも確認する。
日本語入力のまま `Ctrl+b` → `m` / `a` / `A` / `w` を開き、中の `j/k`・`y/n`・Enter・Esc が効くことと、
閉じた後に日本語入力へ戻っていることを確認する。
上部の `PREFIX` / `COPY` / `KEYS` / `SEARCH` 表示と、通常入力に戻った後の IME 動作も確認する。
デタッチ後は `Ctrl+b` が単独でアプリへ届くことを確認する。

Neovim の起動経路変更後は、新しい zsh で `command -v nvim` が Nix store 内の
wrapper を指すことを確認する。Git・GitHub CLI のエディタ指定も wrapper の絶対パスになる。
起動済みの Neovim は開き直す。リサイズ時に元のタブ・ウィンドウを維持すること、
Nix の保存時整形、`?` / Ctrl-K と補完キーを確認する。
Ctrl-H はスニペット外で1文字削除し、スニペット内では前のフィールドへ戻ることを確認する。
Python の型検査は通常 Basedpyright、プロジェクトの `pyrefly.toml` で Pyrefly に切り替える。
選択はバッファの LSP 起動時に決まるため、設定ファイルを追加・削除した後は Neovim を開き直す。
Ruff はどちらの場合も lint 用に起動する。

tmux の履歴上限50000行は、新しいウィンドウ・ペインから有効になる。
既存のペインで失われた履歴は復元されない。
tmux-continuum は status-right の background hook で15分ごとにセッションを保存する。
設定再読み込み後は `tmux show-option -gv status-right` に `continuum_save.sh` があることを確認する。
保存は `~/.tmux/resurrect/`（既定）、手動保存は prefix + Ctrl-S、復元は prefix + Ctrl-R。
自動保存は最初の導入から約15分後に始まる。複数 tmux server の場合、continuum は
別 server の保存との競合を避けるため一部 server の自動保存を止める場合がある。

以前の WSL の自動 Docker prune timer は、設定を適用する前にユーザーとして停止する。
Home Manager のユーザー systemd manager が既に loaded な timer を保持する場合にも備える。

```sh
systemctl --user disable --now docker-prune.timer
sudo nixos-rebuild switch --flake .#nixos-wsl
systemctl --user daemon-reload
systemctl --user is-active docker-prune.timer
```

最後のコマンドが `inactive` または unit 不在なら削除自動化は停止している。
今後は `docker system df` / `docker ps -a` で確認し、必要なバックアップ後に手動で整理する。
NixOS-WSL のシステム設定が変わった場合は必要に応じて Windows 側で `wsl --shutdown` する。

## 切り戻し

WSL は `sudo nixos-rebuild switch --rollback`。Home Manager は
`home-manager generations` で直前の世代を選び、そのパスの `activate` を実行する。
作業ツリーへリンクした Lua は世代を戻すだけでは戻らないため、問題の commit を
`git revert <commit>` し、検証・適用する。必要なら `:Lazy restore` を実行する。
14 日より古い WSL の世代は GC 対象なので、適用直後に切り戻せることを確認する。

失敗を記録するときは対象 commit、実行コマンド、エラー本文、対象 platform を残す。
