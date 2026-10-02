# Eaglercraft 26.2 v0.6

This repository publishes the supplied standalone HTML file through GitHub Pages.

- Entry point: [`index.html`](./index.html)
- Original supplied download page: <https://www.mediafire.com/file/9lykhf9fsh3jxjk/eaglercraft-26.2-0.6.html/file>
- File SHA-256: `07c8eefe17b88a0887493b844720c696c5bbc33038accea249d04b7ae3b70be0`

The deployed GitHub Pages URL will be available at the repository's Pages address after publishing is enabled.



## シェーダー／影機能について

この v0.6 クライアントでは、ゲーム内に **Shaders...** ボタンは表示されず、利用者が操作できるのはファイルを開く（インポート）機能だけです。以前の案内にあった **Options... → Shaders...** の手順はこのビルドには当てはまりません。

- 「ファイルを開く」は、対応する Eaglercraft 用リソースパックを読み込むために使います。
- Java 版 Minecraft の OptiFine／Iris／Oculus 用シェーダーや影 MOD（`.jar`）は、そのまま開いても動作しません。
- `.zip` を読み込める場合でも、Eaglercraft 用に作られた互換リソースパックである必要があります。
- 対応パックがない状態で、本家 Minecraft の影 MOD を変換して使うことはできません。

したがって、このクライアントだけで内蔵シェーダーをボタンから有効化する手順はありません。シェーダーを追加する場合は、Eaglercraft 26.2 v0.6 が受け付ける形式の、利用許諾を確認済みのリソースパックを用意してから「ファイルを開く」でインポートしてください。
