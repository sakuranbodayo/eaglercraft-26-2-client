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


## Natural Light テクスチャパック

オリジナルの軽量 32×32 高詳細テクスチャパックを追加しました。水・植物・葉は 32 フレーム・最短間隔の高速で滑らかなアニメーション、地面は控えめな濡れた光沢、空・雲・光は明るいピクセルアートで表現しています。

- [eaglercraft-light-natural-pack.zip](./eaglercraft-light-natural-pack.zip)
- クライアントの「ファイルを開く」で ZIP を読み込んでください。
- 実時間の影やジオメトリの植物揺れを追加するシェーダー／MODではありません。


### 最新更新

水・植物・葉のアニメーションを 32 フレーム、フレーム時間 1 に変更し、太陽・月・雲・松明・グロウストーンの光彩を強化しました。


### 水と建造物の改良

水面を青緑色の深度表現、波紋、コースティクス風の明暗、反射ハイライトで改良しました。石、丸石、オーク材、レンガ、ガラスには同じ光の方向を意識したオリジナルの 32×32 テクスチャを追加し、建造物が見やすくなるようにしています。


### 追加した主要ブロック

- 鉱石：石炭、鉄、金、ダイヤモンド、エメラルド、レッドストーン、ラピスラズリ、ネザー水晶
- 木材：オーク、トウヒ、シラカバ、ジャングル、アカシア、ダークオークの板材と原木
- 建築・地形：砂岩、赤砂岩、黒曜石、ネザーラック、エンドストーン、粘土、雪
- 鉱物ブロック：鉄、金、ダイヤモンド、エメラルド、レッドストーン、ラピスラズリ

すべてオリジナルの 32×32 テクスチャで、石・レンガ・ガラスと同じ明暗方向になるよう統一しています。


### Eaglercraft 互換性について

添付画像の警告は、このクライアントが Java 版 Minecraft 26.2 の Resource Pack version 88.0 を実装していないために表示されています。この Eaglercraft クライアントで認識される旧形式に合わせ、`pack_format: 1` と `textures/blocks/` を使用しています。警告が出た場合は、内容を確認して **Yes** を選んでください。


### シェーダー・PBRについて

このクライアントには Java 版の OptiFine／Iris／Oculus 用シェーダー設定はなく、通常のリソースパックから影マップ、Specular、PBR、リアルタイム反射を調整することはできません。このパックでは水・光源・建材のテクスチャとアニメーションだけを改善しています。


### 本家に近い標準見た目

本家 Minecraft のテクスチャを再配布せず、Eaglercraft に内蔵された標準テクスチャをそのまま使用するための空パックを追加しました。

- [eaglercraft-vanilla-base-pack.zip](./eaglercraft-vanilla-base-pack.zip)
- 「ファイルを開く」から読み込めます。
- テクスチャを上書きしないため、標準見た目を維持します。


### Eaglercraft 26.x Realistic Shader

ユーザー提供のコアシェーダー上書きパックを追加しました。草・シダ・サトウキビの風揺れ、水面の波・空反射、日向と日陰の色分け、時間帯による太陽色、大気散乱、トーンカーブを含みます。

- [シェーダー ZIP をダウンロード](./eagler-realistic-shader-repo.zip)
- [展開したソースを見る](./eagler-realistic-shader-repo/)
- Eaglercraft の **Import Pack... / ファイルを開く**から ZIP を読み込んでください。
- リアルタイム影マップ、完全な PBR、地形の水面反射は README 記載のとおり非対応です。
