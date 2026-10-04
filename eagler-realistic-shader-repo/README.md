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

## 調整
`assets/minecraft/shaders/core/terrain.fsh` 冒頭の `SUN_SHADOW` `WATER_REFLECTION` `SATURATION` `EXPOSURE`、
`terrain.vsh` の `WIND_STRENGTH` `WAVE_HEIGHT`。草が根元から揺れる場合は `TIP_A/TIP_B` を `1/2` に。

## ライセンス
独自部分は MIT License。
シェーダーの入出力定義（`#moj_import` やサンプリング部分など）は Minecraft 標準の `terrain` シェーダーに由来し、
その著作権は Mojang Studios にあります。Minecraft および Mojang は Mojang AB / Microsoft の商標です。
本パックは Mojang / Microsoft と無関係の非公式プロジェクトです。
