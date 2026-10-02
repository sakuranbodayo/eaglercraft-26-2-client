# Eaglercraft 26.2 v0.6

This repository publishes the supplied standalone HTML file through GitHub Pages.

- Entry point: [`index.html`](./index.html)
- Original supplied download page: <https://www.mediafire.com/file/9lykhf9fsh3jxjk/eaglercraft-26.2-0.6.html/file>
- File SHA-256: `07c8eefe17b88a0887493b844720c696c5bbc33038accea249d04b7ae3b70be0`

The deployed GitHub Pages URL will be available at the repository's Pages address after publishing is enabled.


## 内蔵 PBR シェーダーを有効にする

このクライアントには Eaglercraft 専用の PBR（物理ベースレンダリング）シェーダーが内蔵されています。通常の Minecraft 用 OptiFine／Iris シェーダーパックではなく、クライアント内蔵の機能を使用してください。

1. [公開 URL](https://sakuranbodayo.github.io/eaglercraft-26-2-client/) を開き、クライアントを起動します。
2. メインメニューまたは一時停止メニューから **Options...** を開きます。
3. **Shaders...** を選択します。
4. 内蔵 PBR シェーダーを選択して有効化します。
5. 必要に応じて PBR マテリアル、反射、影、描画品質などを調整します。
6. FPS が低下する場合は、影・反射・PBR マテリアルの品質を下げるか、同じ画面でシェーダーをオフにしてください。

> 注意：Eaglercraft のシェーダーはブラウザの WebGL 上で動作する Eaglercraft 専用形式です。Java 版 Minecraft の OptiFine／Iris／Oculus 用シェーダーや影 MOD（`.jar`）をそのまま追加することはできません。
