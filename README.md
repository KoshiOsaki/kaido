# KAIDO

期限を怪獣との距離で見る macOS アプリ。走っている Claude Code / Codex のセッションが
道を歩く魔物になり、後ろから追ってくる怪獣が現在時刻。追い越されると GAME OVER。

常に最前面の 822×171px の帯で、作業中ずっと出しておく前提の寸法。

## インストール

```sh
curl -fsSL https://raw.githubusercontent.com/KoshiOsaki/kaido/main/install.sh | bash
```

`/Applications/KAIDO.app` に入る。起動は `open -a KAIDO`。

- **macOS 11 以降**（Apple Silicon / Intel）
- **python3** が必要（`xcode-select --install` で入る）
- 署名していないので、`.dmg` をブラウザで落とすと Gatekeeper の警告が出る。
  上の curl 経由なら警告は出ない

更新はメニューの **KAIDO →「アップデートを確認」**。起動時にも1回だけ確認し、
新しい版があればその項目が「アップデート v… をインストール」に変わる。押すと
入れ替えて再起動する。上の curl をもう一度実行しても同じ。消すときは
`/Applications/KAIDO.app` を捨てる。

## 使う

盤面に魔物が並ぶには、**herdr / cmux / tmux のいずれかの上で Claude Code か Codex が
動いている**必要がある。期限は「初めて見た時刻 +3h」が自動で配られるので、登録作業は無い。

| 操作 | |
| --- | --- |
| 魔物にホバー | 詳細と操作ボタン |
| 魔物を左右にドラッグ | 期限をその時刻へ動かす |
| `a` / `s` / `d` / `f` | 再開 / +1h / 後回し / 完了 |
| ⌘⇧T / ⌘⇧A | 常に最前面 / すべての Space に表示 |
| ⌘⇧L | 後で一覧 |

怪獣は 19:00 に寝て翌朝 8:00 に起きる。就寝中に期限が来るものは翌朝 9:00 から
30分刻みで並べ直される。

## 連携

どれも任意で、設定しなければその欄が `-` になるだけ。設定は
`~/.local/state/postpone-desk/kaido.conf` に1行1設定で置く。

```
slack_user_id=U01234567
google_client_id=...
google_client_secret=...
google_refresh_token=...
ics_url=https://calendar.google.com/calendar/ical/.../basic.ics
```

### GitHub — 今日マージした PR 数

`gh` が認証済みなら何もしなくてよい（`brew install gh` → `gh auth login`）。

### Google カレンダー — 道が塞がっている区間

非公開カレンダーは API キーでは読めないので、OAuth の refresh token を1回だけ取る。
GCP コンソールで Google Calendar API を有効化し、**デスクトップアプリ**の OAuth
クライアントを作って JSON を落としてから:

```sh
python3 /Applications/KAIDO.app/Contents/Resources/core/google-auth.py \
  ~/Downloads/client_secret_*.json
```

ブラウザで同意すると `kaido.conf` に3行が書かれる。scope は読み取りのみ。
非公開カレンダーの ICS URL があるなら、代わりに `ics_url=` の1行でよい。

### Slack — 今日自分が送ったメッセージ数

Claude Code の Slack プラグインを入れて認証し（`/plugin` → slack）、Slack の
プロフィール →「その他」→「メンバー ID をコピー」で得た ID を
`kaido.conf` に `slack_user_id=U…` として書く。

そのうえで、メニューの **KAIDO →「Slack 送信数を同期 (claude -p)」** を on にする。
**既定は off**。数え方が `claude -p` を1時間に1回起こして Slack MCP に検索させる
方式で、Claude のセッションを消費するため、明示的に on にしたときだけ走る
（走るのは 10-18 時のみ）。

## ライセンス

オープンソースではない。**使うのは無料**（個人・業務とも）だが、**販売と再配布は禁止**。
詳細は [`LICENSE`](LICENSE)。ソースコードは公開していない。
