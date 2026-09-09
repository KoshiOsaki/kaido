#!/bin/bash
# KAIDO を /Applications に入れる。
#
#   curl -fsSL https://raw.githubusercontent.com/KoshiOsaki/kaido-install/main/install.sh | bash
#
# curl 経由で落とすと com.apple.quarantine が付かないので、未署名でも
# Gatekeeper の警告なしで起動できる (ブラウザで .dmg を落とすと警告が出る)。
set -euo pipefail

REPO="${KAIDO_REPO:-KoshiOsaki/kaido-install}"
DEST="${KAIDO_DEST:-/Applications}"
APP="KAIDO.app"

die() { echo "error: $*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "macOS 専用です"

# コアが Python なので python3 が要る。Xcode Command Line Tools に入っている。
PYTHON="$(command -v python3 || true)"
[ -n "$PYTHON" ] || die "python3 が見つかりません。'xcode-select --install' を実行してから再度お試しください"

case "$(uname -m)" in
  arm64) ASSET="KAIDO-macos-arm64.zip" ;;
  x86_64) ASSET="KAIDO-macos-x64.zip" ;;
  *) die "未対応の CPU です: $(uname -m)" ;;
esac

echo "==> 最新リリースを調べています ($REPO)"
API="https://api.github.com/repos/$REPO/releases/latest"
URL="$(curl -fsSL "$API" | "$PYTHON" -c '
import json, sys
want = sys.argv[1]
rel = json.load(sys.stdin)
for a in rel.get("assets", []):
    if a["name"] == want:
        print(a["browser_download_url"])
        break
' "$ASSET")" || die "リリース情報を取得できませんでした"
[ -n "$URL" ] || die "$ASSET がリリースに見つかりません"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> ダウンロード: $ASSET"
curl -fsSL "$URL" -o "$TMP/$ASSET"

echo "==> 展開"
# unzip ではなく ditto。.app の拡張属性・シンボリックリンクを壊さない
ditto -x -k "$TMP/$ASSET" "$TMP/x"
[ -d "$TMP/x/$APP" ] || die "$APP がアーカイブに入っていません"

if [ -d "$DEST/$APP" ]; then
  echo "==> 既存の $APP を置き換えます"
  # 起動中だと差し替えに失敗するので先に落とす
  osascript -e 'quit app "KAIDO"' 2>/dev/null || true
  # コアは app の子ではなく独立プロセスで、app は port 47831 が空いている
  # ときだけコアを起こす。ここで落とさないと、差し替えた後も古いコアが
  # 生き残り、新しい app が古い挙動のまま動く。
  pkill -f "$DEST/$APP/Contents/Resources/core/server.py" 2>/dev/null || true
  for _ in $(seq 25); do
    nc -z 127.0.0.1 47831 2>/dev/null || break
    sleep 0.2
  done
fi
echo "==> $DEST へ配置"
ditto "$TMP/x/$APP" "$DEST/$APP"
# curl 経由なら付かないが、経路が変わっても警告が出ないように落としておく
xattr -dr com.apple.quarantine "$DEST/$APP" 2>/dev/null || true

cat <<'EOS'

==> 完了

  open -a KAIDO

盤面に魔物（セッション）が並ぶには herdr / cmux / tmux 上で Claude Code / Codex が
動いている必要があります。カレンダー・GitHub・Slack の連携は README の「連携」を参照:

  https://github.com/KoshiOsaki/kaido-install#連携

EOS
