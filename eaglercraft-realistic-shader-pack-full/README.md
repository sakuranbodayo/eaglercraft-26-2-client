# Eagler Realistic Shader

Eaglercraft 26.x クライアント用の、コアシェーダー上書きパックです。

> ⚠️ 実機での動作確認は限定的です。起動しない場合は Issue にブラウザコンソールの `__eaglerShaderPack` の内容を貼ってください。

## 機能
- 草・シダ・サトウキビの風ゆれ（根元固定）
- 水面のサイン波と、空・雲・太陽の反射
- 空光ベースの日向 / 日陰の色分け（木の下・屋根の下が陰になる）
- 時間帯に応じた太陽色と、大気散乱風フォグ
- フィルミックなトーンカーブ

## できないこと
このクライアントは `core/` シェーダーの上書きのみ対応のため、リアルタイムの影マップ、ゴッドレイ、PBR、
地形が水面に映る反射はできません。

## 使い方
1. [Releases](../../releases) から zip をダウンロード
2. クライアントの **Import Pack...** で zip を読み込む
3. バージョン警告が出たら **Yes**

## 実験的: ポストエフェクト（Full 版）
`assets/minecraft/shaders/post/transparency.fsh` が、画面全体の深度を使う追加処理を行います。
**オプション > ビデオ > 「透明度の改善 (Improved Transparency)」を ON** にしたときだけ動きます。
- SSAO（隅・接触部の陰影）
- 水面のスクリーンスペース反射（木・地形・建物が水に映る）
- ブルーム、ビネット

制限: カメラ行列が渡されないため、FOV 70・描画距離などを仮定して位置を復元しています
（`FOV` を変えたら `TAN_HALF_FOV` を変更）。画面外のものは反射に映りません。
動かない / 画面が壊れる場合は、post 抜きの `eaglercraft-realistic-shader-pack.zip` を使ってください。

## 調整（シェーダー冒頭の定数）
| 定数 | ファイル | 内容 |
|---|---|---|
| `WIND_STRENGTH` | terrain.vsh | 草の風ゆれの強さ（既定 1.8） |
| `LEAF_STRENGTH` | terrain.vsh | 葉の揺れの強さ（0.0 で無効、大きいと境目に隙間） |
| `WAVE_HEIGHT` | terrain.vsh | 水面の波の高さ |
| `TIP_A` / `TIP_B` | terrain.vsh | 草が根元から揺れる場合は `1` / `2` に入れ替え |
| `SUN_SHADOW` | terrain.fsh | 日向・日陰のコントラスト（影マップではなく空光ベース） |
| `SUN_INTENSITY` | terrain.fsh | 日向の暖色・明るさ |
| `WATER_REFLECTION` | terrain.fsh | 水面の空の反射 |
| `FOG_SCATTER` | terrain.fsh | 太陽方向の大気散乱 |
| `SATURATION` / `EXPOSURE` | terrain.fsh | 彩度 / 明るさ |

## 読み込みテスト
うまく動かない場合は、先に `load-test` パック（地形が赤っぽくなるだけ）を読み込み、
シェーダーの上書き自体が効いているかを確認してください。

## トラブルシュート
| 症状 | 原因の例 |
|---|---|
| バージョン警告 | `pack.mcmeta` の `pack_format` がクライアントと不一致 |
| 何も変わらない | zip の階層違い（`pack.mcmeta` が直下にない） |
| コンパイル失敗 | ブラウザコンソールの `__eaglerShaderPack` を確認 |
| 草が浮く / 逆に揺れる | `TIP_A` / `TIP_B` を入れ替え |
| 水面が割れる | `WAVE_HEIGHT` を下げる |

## ライセンス
独自部分は MIT License。
シェーダーの入出力定義（`#moj_import` やサンプリング部分など）は Minecraft 標準の `terrain` シェーダーに由来し、
その著作権は Mojang Studios にあります。Minecraft および Mojang は Mojang AB / Microsoft の商標です。
本パックは Mojang / Microsoft と無関係の非公式プロジェクトです。
