# dotfiles

macOS 向けの個人用 dotfiles です。

## 構成

| ディレクトリ/ファイル | 説明 |
|---|---|
| `zsh/` | zsh 設定（`.zshrc` / `.zprofile`、個人設定は `~/.zshrc.local` に分離） |
| `nvim/` | Neovim 設定（lazy.nvim によるプラグイン管理） |
| `tmux.conf` | tmux 設定（Tokyo Night テーマ、vim 風キーバインド） |
| `ghostty/` | Ghostty ターミナル設定 |
| `setup.sh` | シンボリックリンク作成スクリプト |

## セットアップ

```bash
git clone https://github.com/ShinyaAzuma/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup.sh
./setup.sh
```

`setup.sh` により以下のシンボリックリンクが作成されます：

- `~/dotfiles/zsh/zshrc` → `~/.zshrc`
- `~/dotfiles/zsh/zprofile` → `~/.zprofile`
- `~/dotfiles/nvim` → `~/.config/nvim`
- `~/dotfiles/tmux.conf` → `~/.tmux.conf`
- `~/dotfiles/ghostty` → `~/.config/ghostty`

## 主な特徴

### zsh

`zsh/zshrc` と `zsh/zprofile` をリポジトリで管理しています。

本リポジトリは公開のため、**氏名・メールアドレス・ GitHub アカウント名は `~/.zshrc.local` に分離**し、リポジトリには含めていません。`setup.sh` が未作成時のみ `zsh/zshrc.local.example` をコピーするので、自分の値に書き換えてください。

| 変数 | 用途 |
|---|---|
| `GIT_WORK_NAME` / `GIT_WORK_EMAIL` | `gitMain` が設定する作業用アカウント |
| `GIT_PRIV_NAME` / `GIT_PRIV_EMAIL` | `gitPri` が設定する個人アカウント |
| `GH_WORK_USER` | `ghpr` / `ghprw` が集計対象にする GitHub アカウント |

既存の `~/.zshrc` / `~/.zprofile` が実体ファイルの場合、`setup.sh` が `*.bak.<日時>` として退避してからリンクします。

#### /usr/local/bin を PATH 末尾へ

macOS の既定 PATH は `/usr/local/bin` を `/usr/bin` より前に置きます。Rosetta 2 が使えなくなった環境では旧 x86_64 Homebrew のバイナリが実行不能なため、`git` や `jq` がシステム標準を影で潰します。`zsh/zshrc` の末尾で `/usr/local/bin` を PATH 末尾へ回して回避しています（ディレクトリ自体は残す）。全ての PATH 追記より後で評価する必要があるため、この処理は必ずファイル末尾に置いてください。

#### テスト

```bash
zsh zsh/test/zshrc_test.zsh   # 個人情報の分離と振る舞いの回帰
zsh zsh/test/path_test.zsh    # PATH 解決の回帰
```

### Neovim
- lazy.nvim によるプラグイン管理
- LSP / Treesitter / fzf / oil.nvim など

### tmux
- プレフィックスキー: `Ctrl+t`
- vim 風ペイン移動 (`h/j/k/l`)
- Lazygit ポップアップ (`prefix + g`)
- Claude Code ポップアップ (`prefix + a`)
- プロジェクトランチャー (`prefix + o`) — sesh + zoxide + fzf で最近/よく開くプロジェクトを曖昧検索して起動・復帰
- セッション永続化 — tmux-resurrect / tmux-continuum で再起動後も前回のセッションを自動復元（15分ごと自動保存）
- Tokyo Night テーマ (TPM)

### プロジェクトランチャー（sesh + zoxide + fzf）

`prefix + o` で、実行中の tmux セッション・`zoxide` の訪問履歴・`sesh/sesh.toml` の定義をまとめて曖昧検索し、選んだプロジェクトを tmux セッションとして起動（既存なら復帰）します。

| 依存 | 役割 |
|---|---|
| `zoxide` | 訪れたディレクトリを頻度順に記憶（「最近のプロジェクト」の元データ） |
| `fzf` | 曖昧検索 UI |
| `sesh` | 候補を tmux セッションとして起動／復帰 |

```bash
brew install sesh zoxide fzf
```

`zoxide` は `.zshrc` で `eval "$(zoxide init zsh)"` を読み込む必要があります（`zsh/zshrc` に含まれています）。
ランチャー内のキー: `^a` 全候補 / `^t` tmux セッション / `^x` zoxide 履歴 / `^d` 選択セッションを kill。

### Ghostty
- フォント: MesloLGS NF
- テーマ: Tokyo Night
- 半透明背景 (opacity: 0.92)
- ネイティブ分割（旧 tmux `ide` の代替。GPU 描画で軽量・使い捨て前提。永続化が必要なものは tmux/sesh 側で管理）

#### 分割キーバインド

| キー | 動作 |
|---|---|
| `cmd+d` / `cmd+shift+d` | 右に分割 / 下に分割 |
| `cmd+alt+h/j/k/l` | ペイン移動（vim 風） |
| `cmd+ctrl+h/j/k/l` | ペインのリサイズ |
| `cmd+ctrl+=` | サイズ均等化 |
| `cmd+shift+enter` | ズーム（全画面トグル） |
| `cmd+w` | ペインを閉じる |

`cmd` 系のため tmux prefix (`Ctrl+t`) と衝突しません。

## claude-log-scan

Claude Code のログに紛れ込んだ secret を検出し、その部分だけをマスクする。

Claude Code は会話のトランスクリプトを `~/.claude/projects/**/*.jsonl` に平文で
残す。コマンド出力や読んだファイルの中身もそのまま入るので、`.env` を cat した
だけでアクセスキーがディスク上に半永久的に居座る。

```sh
claude-log-scan                 # 検出して報告するだけ（既定）
claude-log-scan --apply         # 検出箇所を [MASKED:<rule>] に置換
claude-log-scan --high-only     # 確度の高いルールのみ
claude-log-scan --json          # 機械可読な出力
```

検査対象は `~/.claude/projects`（トランスクリプト）、`~/.claude/history.jsonl`
（入力履歴）、`~/.claude/shell-snapshots`、`~/.claude/file-history`、
`/tmp/claude-$UID`（スクラッチパッド）。バイナリと巨大ファイルは読まない。

マスクは値を `[MASKED:<rule>]` に置換するだけなので、jsonl の JSON としての
妥当性は保たれ（置換後に全行を検証し、壊れるなら中止する）、`--resume` や
履歴検索は壊れない。何度かけても結果は変わらない。書き込み中のセッションを
壊さないよう、5分以内に更新されたファイルは置換しない。

報告には伏せ字しか出さないので、ログを残しても secret は漏れない。

`?` 付きの検出は値の形からの推測。コードの識別子（`cdk.Duration.days(30)`、
`env.vars.SECRET_KEY`、`someCamelCaseName`）や貼り付けた画像の base64 を
誤検出しないよう絞ってあるが、代わりに英単語ベースの覚えやすいパスワードは
取りこぼす。

launchd で毎日 12:30 に検査し、見つかった時だけ通知する（マスクは手動）。

```sh
python3 -m unittest tests.test_claude_log_scan   # テスト
```
