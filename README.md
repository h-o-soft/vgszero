# Video Game System - Zero [![suzukiplan](https://circleci.com/gh/suzukiplan/vgszero.svg?style=svg)](https://app.circleci.com/pipelines/github/suzukiplan/vgszero)

![logo](logo.png)

Video Game System - Zero (VGS-Zero) は RaspberryPi Zero 2W のベアメタル環境で動作するゲーム機です。

本リポジトリは、VGS-Zero の本体コード、配布イメージ、SDK、パソコン（Linux または macOS）で動作するエミュレータを提供します。

## VGS-Zero Feature

- CPU: Z80 16MHz (16,777,216Hz)
  - Z80 アセンブリ言語でプログラミング可能（[Programming Guide](#programming-guide)を参照）
  - C言語 (SDCC) でもプログラミング可能（[Programming Guide](#programming-guide)を参照）
  - ゲーム実行形式ファイル（[game.pkg](#gamepkg)）は最大 128 メガビット（100メガショック!）
  - [最大 2MB (8kb × 256banks)](#cpu-memory-map) のプログラムとデータ (※音声データを除く)
  - [RAM サイズ 16KB](#cpu-memory-map) (PV16相当!)
  - [セーブ機能](#save-data)に対応
- VDP; VGS-Video (映像処理)
  - [VRAM](#vram-memory-map) サイズ 16KB (TMS9918A 相当!)
  - 解像度: 240x192 ピクセル (TMS9918A より少しだけ狭い!)
  - [16 個の 16 色パレット](#palette)に対応（32,768 色中 256 色を同時発色可能）
  - 8x8 ピクセルの[キャラクタパターン](#character-pattern-table)を最大 256 枚 (8KB) 定義可能
  - [BG](#bg), [FG](#fg) の[ネームテーブル](#name-table)サイズ: 32x32 (256x256 ピクセル)
  - [ハードウェアスクロール](#hardware-scroll)対応（[BG](#bg), [FG](#fg) 各）
  - 最大 256 枚の[スプライト](#sprite)を表示可能（水平上限なし）
  - [BG](#bg), [FG](#fg), [スプライト](#sprite) にそれぞれ異なる[キャラクタパターン](#character-pattern-table)を設定できる [Direct Pattern Mapping](#direct-pattern-mapping) 機能に対応（最大 768 枚のキャラクターパターンを同時に表示可能）
  - [BG](#bg), [FG](#fg) は最大 [1024 パターンを表示できるモード](#1024-patterns-mode) に対応
  - [スプライト](#sprite)に複数の[キャラクタパターン](#character-pattern-table)を並べて表示できるハードウェア機能（[OAM Pattern Size](#oam-pattern-size)）を提供
  - [スプライト](#sprite)の [OAM](#oam) 毎に異なるバンクを指定できるハードウェア機能（[OAM Bank](#oam-bank)）を提供
- DMA (Direct Memory Access)
  - [特定の ROM バンクの内容をキャラクタパターンテーブルに高速転送が可能](#rom-to-character-dma)
  - [C言語の `memset` に相当する高速 DMA 転送機能を実装](#memset-dma)
  - [C言語の `memcpy` に相当する高速 DMA 転送機能を実装](#memcpy-dma)
- HAGe (High-speed Accumulator for Game)
  - [ハードウェア当たり判定機能を実装](#collision-detection)
  - [ハードウェア乗算・除算・剰余算](#hardware-calculation)
  - [ハードウェア sin テーブル](#hardware-sin-table)
  - [ハードウェア cos テーブル](#hardware-cos-table)
  - [ハードウェア atan2 テーブル](#hardware-atan2-table)
  - [ハードウェア乱数](#hardware-random)
  - [ハードウェア・パーリンノイズ](#hardware-perlin-noise)
- [BGM](#bgmdat)
  - VGS の MML で記述された BGM を再生可能
  - ゲームプログラム (Z80) 側でのサウンドドライバ実装が不要!
  - ゲームプログラム (Z80) 側の RAM (16KB) を専有不要!
  - 本体 ROM ([`game.rom`](#gamerom)) とは別アセット（[`bgm.dat`](#bgmdat)）
  - 最大 256 曲
- [SE](#sedat) (効果音)
  - 44100Hz 16bit 1ch (モノラル) 形式の PCM データ (.wav ファイル) を効果音として再生可能
  - ゲームプログラム (Z80) 側でのサウンドドライバ実装が不要!
  - ゲームプログラム (Z80) 側の RAM (16KB) を専有不要
  - 本体 ROM ([`game.rom`](#gamerom)) とは別アセット（[`se.dat`](#sedat)）
  - 最大 256 個
- 入力機器: [USB ジョイパッド](#joypad)
  - 8ボタン形式（カーソルキー、A/B、START/SELECT）のジョイパッドをサポート
  - [config.sys](#configsys) でボタン割当をカスタマイズ可能

## How to Execute

### on RaspberryPi Zero 2W

#### (Required Hardware)

以下のハードウェアが必要です。

- RaspberryPi Zero 2W
  - [https://www.switch-science.com/products/7600](https://www.switch-science.com/products/7600)
  - [https://www.amazon.co.jp/dp/B0B55MFH1D/](https://www.amazon.co.jp/dp/B0B55MFH1D/)
- HDMI ケーブル (mini HDMI Type C → HDMI Type A)
  - [https://www.amazon.co.jp/dp/B08R7BVL7T/](https://www.amazon.co.jp/dp/B08R7BVL7T/)
- USB ジョイパッド（D-Pad+A/B+Start/Select）+ 変換アダプタ
  - [https://www.amazon.co.jp/dp/B07M7SYX11/](https://www.amazon.co.jp/dp/B07M7SYX11/)
  - [https://www.amazon.co.jp/dp/B08BNFKCYM/](https://www.amazon.co.jp/dp/B08BNFKCYM/)
- USB 電源
  - [https://www.amazon.co.jp/dp/B09T3C758Q/](https://www.amazon.co.jp/dp/B09T3C758Q/)
- micro SD カード
  - [https://www.amazon.co.jp/gp/aw/d/B08PTP6KKS/](https://www.amazon.co.jp/gp/aw/d/B08PTP6KKS/)
  - 最大 20MB 程度の空き容量が必要です（ゲーム本体: 最大16MB、ファームウェア: 約4MB）
- テレビなど（以下の条件のもの）
  - HDMI入力対応
  - リフレッシュレート60Hz
  - 解像度 480x384 ピクセル以上
  - オーディオ出力対応

#### (Supported USB Joypad)

VGS-Zero での USB ジョイパッドのサポートリストを示します。

|製品名|サポート|補足事項|
|:-|:-:|:-|
|[HXBE37823 (XINYUANSHUNTONG)](https://ja.aliexpress.com/item/1005001905753033.html)|`OK`|完全に動作します|
|[suily USBコントローラー NESゲーム用（有線）](https://www.amazon.co.jp/dp/B07M7SYX11/)|`OK`|完全に動作します|
|[Elecom JC-U3312シリーズ](https://www.amazon.co.jp/dp/B003UIRHLE/)|`OK`|完全に動作します|
|[HORI リアルアーケードPro V3SA (PS3用)](https://www.amazon.co.jp/dp/B002YT9PSI)|`OK`|完全に動作します|
|[HORI グリップコントローラーアタッチメントセット for Nintendo Switch](https://www.amazon.co.jp/dp/B09JP9MFFY/)|`△`|十字キーが使用不可|
|[ロジクール (ロジテック) F310](https://www.amazon.co.jp/dp/B00CDG799E/)|`NG`|接続不可|
|[Kiwitata gamepad](https://github.com/rsta2/circle/wiki/Device-compatibility-list)|`NG`|Circleが非サポート|
|[Xbox 360 wired gamepad clone](https://github.com/rsta2/circle/wiki/Device-compatibility-list)|`NG`|Circleが非サポート|

> 標準 HID 準拠のジョイパッド（ゲームコントローラー）であれば動作できる可能性が高いです。
> パソコンでの利用に際して専用のデバイスドライバを必要とするものや、XInput対応のゲームコントローラー（比較的新しいゲームコントローラー）は、全く認識できなかったり、認識できても一部のキー入力が効かないものが多い傾向があるので非推奨です。
> SUZUKIPLAN が主に使用している製品は Elecom JC-U3312 と HXBE37823 です。Elecom JC-U3312 は EOL (製造終了) の商品のため入手が難しいかもしれません。HXBE37823 は [Aliexpress](https://ja.aliexpress.com/item/1005001905753033.html) に 300 円前後の安価なものが沢山あり、[Amazon](https://www.amazon.co.jp/dp/B07M7SYX11/) でも購入可能です。（ただし、HXBE37823 は上下左右の移動をする時に斜め入力が入ってしまうものがあり、感度の品質面に難があるかもしれませんが、[Battle Marine](https://github.com/suzukiplan/bmarine-zero/) のように左右に移動方向を絞ったゲームであれば快適にプレイできます）

#### (GPIO Joypad)

RaspberryPi Zero 2W の GPIO に次のピンアサインで直接ボタンを接続することもできます。

| Button | GPIO |
|:------:|:----:|
| Up     | 22   |
| Down   | 5    |
| Left   | 26   |
| Right  | 6    |
| A      | 24   |
| B      | 25   |
| Start  | 4    |
| Select | 23   |

RaspberryPi Zero 2W Pin Map

![joypad_pin.jpeg](joypad_pin.jpeg)

_※ GND の接続も必要です_

> GPIO 接続に関する詳細は [こちらの記事](https://note.com/suzukiplan/n/ncccafb305eae) をご参照ください。
>
> VGS-Zero 対応のジョイスティック・ジョイパッドは、企業（商業ハード）or 個人（同人ハード）に関係なく SUZUKIPLAN からのライセンス不要で自由に開発・販売していただくことが可能です。_（ライセンスは不要ですがサポートもしないスタイルなので、販売に伴う消費者へのサポート対応等は販売元の責任で行ってください）_

#### (Launch Sequence)

起動手順は次の通りです。

1. FAT32 フォーマットされた SD カードを準備
2. SD カードのルートディレクトリに [./image](./image) 以下のファイルをコピー
3. [game.pkg](#gamepkg) を起動対象のゲームに置き換える
4. SD カードを RaspberryPi Zero 2W に挿入
5. RaspberryPi Zero 2W に USB ジョイパッドを接続
6. RaspberryPi Zero 2W とテレビを HDMI ケーブルで接続
7. RaspberryPi Zero 2W に電源を接続して ON

### on PC for Debug (Linux or macOS)

SDL2 版エミュレータ（[./src/sdl2](./src/sdl2)）をビルドして、コマンドラインオプションに起動対象の [game.pkg](#gamepkg) を指定して実行してください。

### on Steam for Sale (Windows)

[VGS-Zero SDK for Steam](https://github.com/suzukiplan/vgszero-steam) を用いることで、最小限の労力で [Steam で販売](#steam) できる [game.pkg](#gamepkg) のバイナリ（Windows, Linux, macOS）を作成することができます。

## Examples

| Directory | Language | Description |
| :-------- | :------- | :---------- |
| [example/01_hello-asm](./example/01_hello-asm/) | Z80 | `HELLO,WORLD!` を表示 |
| [example/01_hello](./example/01_hello/) | C言語 | `HELLO,WORLD!` を表示 |
| [example/02_global](./example/02_global/) | C言語 | グローバル変数の使用例 |
| [example/03_sound](./example/03_sound/) | C言語 | BGM と効果音の使用例 |
| [example/04_heavy](./example/04_heavy/) | C言語 | エミュレータ側の負荷を最大化する検査用プログラム |
| [example/05_sprite256](./example/05_sprite256/) | C言語 | スプライトを256表示して動かす例 |
| [example/06_save](./example/06_save/) | C言語 | [セーブ機能](#save-data)の例 |
| [example/07_palette](./example/07_palette/) | C言語 | 16個の[パレット](#palette)を全て使った例 |
| [example/08_map-scroll](./example/08_map-scroll/) | C言語 | Tiled Map Editor で作ったマップデータのスクロール |
| [example/09_joypad](./example/09_joypad/) | C言語 | ジョイパッドの入力結果をプレビュー |
| [example/10_chr720](./example/10_chr720/) | C言語 | [Direct Pattern Mapping](#direct-pattern-mapping) で 1 枚絵を表示する例 |
| [example/11_bigsprite](./example/11_bigsprite/) | C言語 | [OAM](#oam) の `widthMinus1`, `heightMinus1`, `bank` の指定により巨大なスプライトを表示する例 |
| [example/12_angle](./example/12_angle) | C言語 | [ハードウェア atan2 テーブル](#hardware-atan2-table) を用いて完全な自機狙いを実装する例 |
| [example/13_perlin](./example/13_perlin) | C言語 | [ハードウェア・パーリンノイズ](#hardware-perlin-noise) の利用例 |
| [example/14_1024ptn](./example/14_1024ptn) | C言語 | [1024 パターンモード](#1024-patterns-mode) の利用例 |

## Joypad

VGS-Zero は、カーソル（D-PAD）、Aボタン、Bボタン、SELECTボタン、STARTボタンの8ボタン式 USB ジョイパッドによる入力のみサポートしています。

![joypad.png](joypad.png)

RaspberryPi Zero 2W に接続する USB ジョイパッドのボタン割当（key config）は、[config.sys](#configsys) ファイルにより利用者が自由にカスタマイズできます。

PC（[SDL2](./src/sdl2/) 版）のキー割当は次の通りです:

- D-Pad: カーソルキー
- A ボタン: `X` キー
- B ボタン: `Z` キー
- START ボタン: `SPACE` キー
- SELECT ボタン: `ESC` キー

## config.sys

RaspberryPi Zero 2W に挿入する SD カードのルートディレクトリに `config.sys` ファイルを配置することで色々なカスタマイズができます。

### Joypad Button Assign

```
#--------------------
# JoyPad settings
#--------------------
A BUTTON_1
B BUTTON_0
SELECT BUTTON_8
START BUTTON_9
UP AXIS_1 < 64
DOWN AXIS_1 > 192
LEFT AXIS_0 < 64
RIGHT AXIS_0 > 192
```

（凡例）

```
# ボタン設定
key_name △ BUTTON_{0-31}

# AXIS設定
key_name △ AXIS_{0-1} △ {<|>} △ {0-255}
```

`key_name`:

- `A` Aボタン
- `B` Bボタン
- `START` STARTボタン
- `SELECT` Aボタン
- `UP` 上カーソル
- `DOWN` 下カーソル
- `LEFT` 左カーソル
- `RIGHT` 右カーソル

カーソルに `BUTTON_` を割り当てたり、ボタンに `AXIS_` を割り当てることもできます。

[tools/joypad](./tools/joypad/) を用いれば、お手持ちの USB ジョイパッドのボタン内容をチェックできます。

## game.pkg

game.pkg は VGS-Zero のゲーム実行形式ファイルで、ツールチェインの [makepkg コマンド](./tools/makepkg/) で生成することができます。

```
makepkg  -o /path/to/output.pkg
         -r /path/to/game.rom
        [-b /path/to/bgm.dat]
        [-s /path/to/se.dat]
```

- [game.rom](#gamerom): プログラムや画像データ
- [bgm.dat](#bgmdat): BGM データ
- [se.dat](#sedat): 効果音データ

なお、game.pkg の最大サイズは **16MB (128Mbits)** です。

### game.rom

game.rom は [ROMバンク](#cpu-memory-map)に読み込まれる 8KB 単位の ROM データセットで、ツールチェインの [makerom コマンド](./tools/makepkg/) で生成することができます。

```
usage: makerom output input1 input2 ... input256
```

なお、入力ファイルが 8KB で割り切れない場合、パディングデータが自動的に挿入されます。

### bgm.dat

bgm.dat は、本リポジトリのツールチェインで提供している [vgsmml コマンド](./tools/vgsmml) でコンパイルされた1つ以上の楽曲データを纏めたデータセットで、ツールチェインの [makebgm コマンド](./tools/makebgm/) で生成することができます。

#### (Compile MML)

```
usage: vgsmml /path/to/file.mml /path/to/file.bgm
```

- MMLの仕様: [https://github.com/suzukiplan/vgs-mml-compiler/blob/master/MML-ja.md](https://github.com/suzukiplan/vgs-mml-compiler/blob/master/MML-ja.md)
- [東方BGM on VGS の MML](https://github.com/suzukiplan/tohovgs-cli/tree/master/mml) が全楽曲公開されているので、実用的な使い方はそちらが参考になるかもしれません
- MML ファイルは、ツールチェインの [vgsplay コマンド](./tools/vgsplay) を用いれば PC 上でプレビューできます

#### (Make bgm.dat)

```
makebgm bgm.dat song1.bgm [song2.bgm [song3.bgm...]]
```

BGM ファイルは最大 256 個指定することができます。

### se.dat

se.dat は、効果音のデータセットで、ツールチェインの [makese コマンド](./tools/makese/) で生成することができます。

```
makese se.dat se1.wav [se2.wav [se3.wav...]]
```

makese コマンドに指定できる .wav ファイルは、次の形式でなければなりません:

- 無圧縮 RIFF 形式
- サンプリングレート: 44100Hz
- ビットレート: 16bits
- チャネル数: 1 (モノラル)

.wav ファイルは最大 256 個指定することができます。

## Programming Guide

ゲームを開発する時の初期プロジェクトについては次のリポジトリを参考にしてください。

[https://github.com/suzukiplan/vgszero-empty-project](https://github.com/suzukiplan/vgszero-empty-project)

### Programming Language

- VGS-Zero のゲームは Z80 アセンブリ言語 または C言語 で記述することができます
  - Z80 アセンブリ言語: [./example/01_hello-asm](./example/01_hello-asm)
  - C言語: [./example/01_hello](./example/01_hello)
- C言語で記述する場合:
  - クロスコンパイラに [SDCC (Small Device C Compiler)](https://sdcc.sourceforge.net/) が使用できます
  - VGS-Zero が対応している SDCC は **バージョン 4.1.0 のみ** です
    - `brew`, `apt` 等でのデフォルトインストールバージョンとは異なります
    - [公式ダウンロードサイト](https://sourceforge.net/projects/sdcc/files/) からお使いの PC の機種の sdcc-4.1.0 をダウンロード＆展開して環境変数 `PATH` を切ってご使用ください
    - macOS(x64): [https://sourceforge.net/projects/sdcc/files/sdcc-macos-amd64/4.1.0/](https://sourceforge.net/projects/sdcc/files/sdcc-macos-amd64/4.1.0/)
    - Linux(x64): [https://sourceforge.net/projects/sdcc/files/sdcc-linux-amd64/4.1.0/](https://sourceforge.net/projects/sdcc/files/sdcc-linux-amd64/4.1.0/)
    - バージョン 4.2 〜 4.4 では [致命的な不具合](https://github.com/suzukiplan/vgszero/issues/8) が発生するので利用しないでください
  - 標準ライブラリは使用できません
  - [vgs0.lib](./lib/sdcc/) を使用することができます

### API Manual for Programming Language C

[vgs0lib.h](./lib/sdcc/vgs0lib.h) の実装を参照してください。

実装を見た方が手っ取り早いと思われるので非推奨ですが、以下のコマンドを実行すれば HTML 形式のマニュアルを閲覧できます。

```
sudo apt install doxygen build-essential
git clone https://github.com/suzukiplan/vgszero
cd vgszero/lib/sdcc
make doc
open doc/html/index.html
```

### Create Sound Data

- VGS 形式の Music Macro Language (MML) で [音楽データ](#bgmdat) を作成できます
- 44100Hz 16bits 1ch (モノラル) の wav ファイルで [効果音データ](#sedat) を作成できます

### Joypad Recommended Usage

VGS-Zero 向けに開発されるゲームは、ゲームの利用者が **可能な限りドキュメントなどを読まず** にゲームをプレイできるようにすることを目的として、敢えて [ジョイパッドのボタンをシンプルな 8 ボタン式（D-PAD, A/B, Select/Start）に固定](#joypad)しています。

- D-PAD usage
  - キャラクタやカーソルの移動などの目的で使用してください
- B button usage
  - 利用者が **頻繁に叩く（連打する）** ことが想定される操作に適したボタンです
  - 利用例: シューティングのショット、配管工によるファイアボールの発射、押したままカーソル入力でダッシュなど
  - RPG 等のコマンド操作のキャンセルは B ボタンを利用することが望ましいです
- A button usage
  - 利用者が **慎重に叩く** ことが想定される操作に適したボタンです
  - 利用例: シューティングのボンバー、ジャンプ、スナイピングショットなど
  - RPG 等のコマンド操作の決定は A ボタンを利用することが望ましいです
- START button usage
  - システム操作で押すことが想定されるボタンです
  - 利用例: ゲーム開始、ポーズ、コマンドを開くなど
- SELECT button usage
  - あまり利用することが想定されないボタンなので、積極的な利用は避けた方が良いと考えられます
  - 利用例: アーケード風ゲームのコイン投下など

### How to Debug

デバッグには、パソコン（Linux または macOS）上で動作するエミュレータ（[./src/sdl2](./src/sdl2)）を用いると便利です。

### CPU Memory Map

メインプログラム（Z80）から見えるメモリマップは次の通りです。

| CPU address | Map |
| :---------: | :-- |
| 0x0000 ~ 0x1FFF | ROM Bank 0 |
| 0x2000 ~ 0x3FFF | ROM Bank 1 |
| 0x4000 ~ 0x5FFF | ROM Bank 2 |
| 0x6000 ~ 0x7FFF | ROM Bank 3 |
| 0x8000 ~ 0xBFFF | VRAM |
| 0xC000 ~ 0xFFFF | RAM (16KB) |

- プログラムの ROM データは 8KB 区切りになっていて最大 256 個のバンクを持つことができます
- 電源投入またはリセットすると ROM Bank には 0〜3 がセットされ、ポート B0〜B3 の I/O で [バンク切り替え](#bank-switch) ができます
- スタック領域は 0xFFFE から 0xC000 の方向に向かって使われます
- グローバル変数を使用する場合 0xC000 から順番に使い、スタックによる破壊がされないように気をつけてプログラミングしてください

### VRAM Memory Map

|   CPU address   |  VRAM address   | Map |
| :-------------: | :-------------: | :-- |
| 0x8000 ~ 0x83FF | 0x0000 ~ 0x03FF | [BG](#bg) [Name Table](#name-table) (32 x 32) |
| 0x8400 ~ 0x87FF | 0x0400 ~ 0x07FF | [BG](#bg) [Attribute](#attribute) Table (32 x 32) |
| 0x8800 ~ 0x8BFF | 0x0800 ~ 0x0BFF | [FG](#fg) [Name Table](#name-table) (32 x 32) |
| 0x8C00 ~ 0x8FFF | 0x0C00 ~ 0x0FFF | [FG](#fg) [Attribute](#attribute) Table (32 x 32) |
| 0x9000 ~ 0x97FF | 0x1000 ~ 0x17FF | [OAM](#oam); Object Attribute Memory (8 x 256) |
| 0x9800 ~ 0x99FF | 0x1800 ~ 0x19FF | [Palette](#palette) Table (2 x 16 x 16) |
| 0x9F00          | 0x1F00	        | Register #0: Vertical [Scanline Counter](#scanline-counter) (read only) |
| 0x9F01          | 0x1F01          | Register #1: Horizontal [Scanline Counter](#scanline-counter) (read only) |
| 0x9F02          | 0x1F02          | Register #2: [BG](#bg) [Scroll](#hardware-scroll) X |
| 0x9F03          | 0x1F03          | Register #3: [BG](#bg) [Scroll](#hardware-scroll) Y |
| 0x9F04          | 0x1F04          | Register #4: [FG](#fg) [Scroll](#hardware-scroll) X |
| 0x9F05          | 0x1F05          | Register #5: [FG](#fg) [Scroll](#hardware-scroll) Y |
| 0x9F06          | 0x1F06          | Register #6: IRQ scanline position (NOTE: 0 is disable) |
| 0x9F07          | 0x1F07          | Register #7: [Status](#vdp-status) (read only) |
| 0x9F08          | 0x1F08          | Register #8: [BG](#bg) の [Direct Pattern Maaping](#direct-pattern-mapping) |
| 0x9F09          | 0x1F09          | Register #9: [FG](#fg) の [Direct Pattern Maaping](#direct-pattern-mapping) |
| 0x9F0A          | 0x1F0A          | Register #10: [スプライト](#sprite) の [Direct Pattern Maaping](#direct-pattern-mapping) |
| 0x9F0B          | 0x1F0B          | Register #11: [BG/FG の 1024 パターンモード設定](#1024-patterns-mode) |
| 0xA000 ~ $BFFF  | 0x2000 ~ 0x3FFF | [Character Pattern Table](#character-pattern-table) (32 x 256) |

VRAM へのアクセスは一般的な VDP とは異なり CPU アドレスへのロード・ストア（LD命令等）で簡単に実行できます。

#### (BG)

- BG (Background Graphics) は、基本となる背景映像です
- [スプライト](#sprite) と [FG](#fg) の背面に表示されます
- ゲームの背景映像として利用することを想定しています
- [ネームテーブル](#name-table) に[キャラクタ番号](#character-pattern-table)と[属性](#attribute)を指定することで表示できます
- 透明色が存在しません
- [属性](#attribute)の指定で描画を非表示（hidden）にすることができません
- [FG](#fg) とは独立した [ハードウェアスクロール](#hardware-scroll) に対応しています

#### (FG)

- FG (Foreground Graphics) は、最前面に表示される映像です
- [BG](#bg) と [スプライト](#sprite) の前面に表示されます
- ゲームのスコアやメッセージウインドウなどの表示に利用することを想定しています
- [ネームテーブル](#name-table) に[キャラクタ番号](#character-pattern-table)と[属性](#attribute)を指定することで表示できます
- [パレット](#palette) の色番号 0 が透明色になります
- [属性](#attribute)の指定で描画を非表示（hidden）にすることができ、デフォルトは非表示になっています
- [BG](#bg) とは独立した [ハードウェアスクロール](#hardware-scroll) に対応しています

#### (Sprite)

- 妖精（Sprite）は、画面上を動き回るキャラクタ映像です
- [BG](#bg) の前面 & [FG](#fg) の背面 に表示されます
- ゲームのキャラクタ表示に利用することを想定しています
- 最大 256 枚を同時に表示できます
- [OAM](#oam) に表示座標、[キャラクタ番号](#character-pattern-table)、[属性](#attribute)、サイズを指定することで表示できます
- [属性](#attribute)の指定で描画を非表示（hidden）にすることができ、デフォルトは非表示になっています
- サイズはデフォルトは 1x1 パターン（8x8ピクセル）ですが最大で 16x16 パターン（128x128ピクセル）のものを1枚のスプライトとして表示できます（詳細は [OAM](#oam) の `widthMinus1` と `heightMinus1` の解説を参照）

#### (Name Table)

- VGS-Zero では 8x8 ピクセルの矩形単位の[キャラクタパターン](#character-pattern-table)番号をネームテーブルに書き込むことでグラフィックスを表示します
- ネームテーブルは 32 行 32 列の二次元配列です（BG/FG 共通）

#### (Attribute)

アトリビュートは、BG, FG, スプライト共通のキャラクタパターン表示属性です。

| Bit-7 | Bit-6 | Bit-5 | Bit-4 | Bit-3 | Bit-2 | Bit-1 | Bit-0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `VI`  | `UD`  | `LR`  |   -   | `P3`  | `P2`  | `P1`  | `P0`  |

- `VI`: `0` = 非表示, `1` = 表示 _（※ BG に限り 0 でも表示されます）_
- `UD`: `1` にすると上下反転で表示
- `LR`: `1` にすると左右反転で表示
- `P0~P3`: [パレット](#palette)番号 (0 ~ 15)

#### (Palette)

- VGS-Zero では最大 16 個のパレットを使用できます
- 各パレットには 16 色を RGB555 形式で指定できます
- FG と スプライトの場合、色番号 0 は透明色になります

#### (OAM)

OAM は次の要素を持つ構造体です。

1. スプライトの表示座標
2. [キャラクタパターン](#character-pattern-table)番号
3. [属性](#attribute)
4. [サイズ](#oam-pattern-size)
5. [OAM別バンク番号](#oam-bank)

```c
struct OAM {
    unsigned char y;
    unsigned char x;
    unsigned char pattern;
    unsigned char attribute;
    unsigned char heightMinus1;
    unsigned char widthMinus1;
    unsigned char bank;
    unsigned char reserved;
} oam[256];
```

VGS-Zero では最大 256 枚のスプライトを同時に表示でき、水平方向の表示数に上限がありません。

#### (OAM Pattern Size)

[OAM](#oam) の `widthMinus1` と `heightMinus1` に 0 〜 15 の範囲で指定でき、1 以上の値を設定することで複数の[キャラクタパターン](#character-pattern-table)を並べて表示し、この時の[キャラクタパターン](#character-pattern-table)番号は、水平方向が +1、垂直方向は +16 (+0x10) づつ加算されます。

例えば `widthMinus1` が 2 で `heightMinus` が 3 の場合、下表の[キャラクタパターン](#character-pattern-table)グループを 1 枚のスプライトとして表示します。

|`\`|0|1|2|
|:-:|:-:|:-:|:-:|
|0|pattern+0x00|pattern+0x01|pattern+0x02|
|1|pattern+0x10|pattern+0x11|pattern+0x12|
|2|pattern+0x20|pattern+0x21|pattern+0x22|
|3|pattern+0x30|pattern+0x31|pattern+0x32|

#### (OAM Bank)

[OAM](#oam) の `bank` が 0 の場合、スプライトのキャラクタパターンには VRAM 上の[キャラクタパターン](#character-pattern-table)か、[Direct Pattern Mapping](#direct-pattern-mapping) で指定されたバンクのものが用いられますが、1 以上の値が指定されている場合、その指定値のバンク番号がその OAM のキャラクタパターンになります。

設定の優先度:

1. OAM Bank **(最優先)**
2. [Direct Pattern Mapping](#direct-pattern-mapping)
3. VRAM 上の[キャラクタパターン](#character-pattern-table) **(デフォルト)**

OAM Bank を用いることで、OAM 毎に異なるキャラクタパターンを使用できます。

#### (Scanline Counter)

- スキャンラインカウンタは、VDP のピクセルレンダリング位置を特定することができる読み取り専用の VDP レジスタです
- `0x9F00` が垂直方向で `0x9F01` が水平方向です
- 垂直方向の値を待機することでラスター[スクロール](#hardware-scroll)等の処理を **割り込み無し** で実装することができます
- 水平方向は高速に切り替わるため使い所は無いかもしれません

#### (Hardware Scroll)

- [BG](#bg) は `0x9F02` に X 座標, `0x9F03` に Y 座標の描画起点座標を指定することができます
- [FG](#fg) は `0x9F04` に X 座標, `0x9F05` に Y 座標の描画起点座標を指定することができます
- `0x9F02` ~ `0x9F05` を読み取ることで現在のスクロール位置を取得することもできます

#### (VDP Status)

| Bit-7 | Bit-6 | Bit-5 | Bit-4 | Bit-3 | Bit-2 | Bit-1 | Bit-0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|  BL   |   -   |   -   |   -   |   -   |   -   |   -   |   -   |

- BL: 1 = start vblank

NOTE: Status register always reset after read.

#### (Direct Pattern Mapping)

通常、[BG](#bg)、[FG](#fg)、[スプライト](#sprite)は共通の[キャラクターパターンテーブル](#character-pattern-table)を参照しますが、0x9F08、0x9F09、0x9F0A に **0以外** の値を書き込むことで、その値に対応する ROM バンクをそれぞれの[キャラクターパターンテーブル](#character-pattern-table)とすることができる DPM; Direct Pattern Mapping 機能を利用することができます。

- 0x9F08: [BG](#bg) の DPM
- 0x9F09: [FG](#fg) の DPM
- 0x9F0A: [スプライト](#sprite) の DPM

```z80
LD HL, 0x9F08
LD (HL), 0x10   # BG = Bank 16
INC HL
LD (HL), 0x11   # FG = Bank 17
INC HL
LD (HL), 0x12   # Sprite = Bank 18
```

> バンク切り替えアニメーションをしたい場合、[キャラクタパターンテーブル](#character-pattern-table) を [DMA](#rom-to-character-dma) で切り替えるよりも DPM を用いた方が CPU リソースを節約できます。


#### (1024 Patterns Mode)

0x9F0B の設定により BG/FG で利用できるパターン数を 1024 に拡張することができます。

> なお、本機能の利用には BG/FG の [DPM](#direct-pattern-mapping) の設定が必要です。

| Bit-7 | Bit-6 | Bit-5 | Bit-4 | Bit-3 | Bit-2 | Bit-1 | Bit-0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|   -   |   -   |   -   |   -   |   -   |   -   | `F1k` | `B1k` |

- `F1k` FG パターン数（0: 256, 1: 1024）
- `B1k` BG パターン数（0: 256, 1: 1024）

`B1k`, `F1k` をセットした場合、[ネームテーブル](#name-table) の `行÷8 + DPM` が適用されるパターンバンク番号になります。

- 0〜7行目: Pattern Bank = DPM + 0
- 8〜15行目: Pattern Bank = DPM + 1
- 16〜23行目: Pattern Bank = DPM + 2
- 24〜31行目: Pattern Bank = DPM + 3

[bmp2chr](./tools/bmp2chr/) に 256x256 ピクセルの `.bmp` ファイルを入力すれば、本モード用の 4 バンクセットの chr データを簡単に生成することができます。

> 詳細は [./example/14_1024ptn](./example/14_1024ptn/) を参照

#### (Character Pattern Table)

- キャラクタパターンテーブルには 8x8 ピクセルのキャラクタパターンを最大 256 個定義できます
- 1 キャラクタのサイズは 32 bytes です
- テーブル全体のサイズは 32 x 256 = 8192 bytes で丁度バンクのサイズと一致します
- 特定のバンクの内容をキャラクタパターンテーブルに転送できる高速 DMA 機能が搭載されています

キャラクタパターンテーブルのビットレイアウトは次の通りです。

| px0 | px1 | px2 | px3 | px4 | px5 | px6 | px7 | Line number |
| :-: | :-: | :-: | :-: | :-: | :-: | :-: | :-: | :---------- |
| H00 | L00 | H01 | L01 | H02 | L02 | H03 | L03 | Line 0      |
| H04 | L04 | H05 | L05 | H06 | L06 | H07 | L07 | Line 1      |
| H08 | L08 | H09 | L09 | H10 | L10 | H11 | L11 | Line 2      |
| H12 | L12 | H13 | L13 | H14 | L14 | H15 | L15 | Line 3      |
| H16 | L16 | H17 | L17 | H18 | L18 | H19 | L19 | Line 4      |
| H20 | L20 | H21 | L21 | H22 | L22 | H23 | L23 | Line 5      |
| H24 | L24 | H25 | L25 | H26 | L26 | H27 | L27 | Line 6      |
| H28 | L28 | H29 | L29 | H30 | L30 | H31 | L31 | Line 7      |

- `Hxx` : 上位 4bit (0 ~ 15 = 色番号) ※xxはバイト位置
- `Lxx` : 下位 4bit (0 ~ 15 = 色番号) ※xxはバイト位置
- FGとスプライトの場合、色番号0は常に透明色です
- 使用するパレット番号は[属性](#attribute)に指定します

Character Pattern Table のメモリ領域（0xA000〜0xBFFF）は、[BG](#bg)、[FG](#fg)、[スプライト](#sprite) の全てを [Direct Pattern Mapping](#direct-pattern-mapping) にすることで 8KB の RAM 相当の領域とすることができます。更に、この領域は DMA による高速なバンクロードにも対応しているため、シューティングゲームや RPG などの広大なマップデータ（1 チップ 1 バイトなら最大で 128x128 チップ!!）の展開先領域として最適かもしれません。

### I/O Map

|   Port    |  I  |  O  | Description  |
| :-------: | :-: | :-: | :----------- |
|   0xA0    |  o  |  -  | [ジョイパッド](#joypad) |
|   0xB0    |  o  |  o  | [ROM Bank](#bank-switch) 0 (default: 0x00) |
|   0xB1    |  o  |  o  | [ROM Bank](#bank-switch) 1 (default: 0x01) |
|   0xB2    |  o  |  o  | [ROM Bank](#bank-switch) 2 (default: 0x02) |
|   0xB3    |  o  |  o  | [ROM Bank](#bank-switch) 3 (default: 0x03) |
|   0xC0    |  -  |  o  | [ROM to Character DMA](#rom-to-character-dma) |
|   0xC2    |  -  |  o  | [memset 相当の DMA](#memset-dma) |
|   0xC3    |  -  |  o  | [memcpy 相当の DMA](#memcpy-dma) |
|   0xC4    |  o  |  -  | [当たり判定](#collision-detection) |
|   0xC5    |  -  |  o  | [乗算・除算・剰余算](hardware-calculation) |
|   0xC6    |  -  |  o  | [ハードウェア sin テーブル](#hardware-sin-table) |
|   0xC7    |  -  |  o  | [ハードウェア cos テーブル](#hardware-cos-table) |
|   0xC8    |  o  |  -  | [ハードウェア atan2 テーブル](#hardware-atan2-table) |
|   0xC9    |  o  |  o  | [ハードウェア乱数 (8-bits)](#hardware-random) |
|   0xCA    |  o  |  o  | [ハードウェア乱数 (16-bits)](#hardware-random) |
|   0xCB    |  -  |  o  | [パーリンノイズのシード設定](#hardware-perlin-noise) |
|   0xCC    |  -  |  o  | [パーリンノイズのX座標縮尺を設定](#hardware-perlin-noise) |
|   0xCD    |  -  |  o  | [パーリンノイズのY座標縮尺を設定](#hardware-perlin-noise) |
|   0xCE    |  o  |  -  | [パーリンノイズを取得](#hardware-perlin-noise) |
|   0xCF    |  o  |  -  | [パーリンノイズを取得（オクターブあり）](#hardware-perlin-noise) |
|   0xDA    |  o  |  o  | [データのセーブ・ロード](#save-data) |
|   0xE0    |  -  |  o  | BGM を[再生](#play-bgm) |
|   0xE1    |  -  |  o  | BGM を[中断](#pause-bgm)、[再開](#resume-bgm)、[フェードアウト](#fadeout-bgm) |
|   0xF0    |  -  |  o  | 効果音を再生 |
|   0xF1    |  -  |  o  | 効果音を停止 |
|   0xF2    |  -  |  o  | 効果音が再生中かチェック |

#### (JoyPad)

```z80
IN A, (0xA0)
```

| Bit-7 | Bit-6 | Bit-5 | Bit-4 | Bit-3 | Bit-2 | Bit-1 | Bit-0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `Up`  | `Down` | `Left` | `Right` | `Start` | `Select` | `A` | `B` |

#### (Bank Switch)

```z80
# Read current bank of ROM Bank 0
IN A, (0xB0)

# Switch ROM Bank 1 to No.17
LD A, 0x11
OUT (0xB1), A
```

#### (ROM to Character DMA)

```z80
 # バンク番号 = 0x22 をキャラクタパターンへ転送
LD A, 0x22
OUT (0xC0), A
```

#### (memset DMA)

```z80
LD BC, 0xC000   # 転送先アドレス
LD HL, 0x2000   # 転送バイト数
LD A,  0xFF     # 転送する値
OUT (0xC2), A   # memset
```

#### (memcpy DMA)

```z80
LD BC, 0xC000   # 転送先アドレス (RAM)
LD DE, 0x6000   # 転送元アドレス (ROM Bank 3)
LD HL, 0x2000   # 転送バイト数 (8KB)
OUT (0xC3), A   # memcpy (※書き込んだ値は無視されるので何でもOK)
```

#### (Collision Detection)

以下の 8 bytes の構造体が格納されたアドレスを HL に指定して 0xC4 を IN することで当たり判定ができます。

```c
struct rect {
    uint8_t x;      // X座標
    uint8_t y;      // Y座標
    uint8_t width;  // 幅
    uint8_t height; // 高さ
} chr[2];           // それらを 2 キャラクタ分（8bytes）
```

```z80
LD HL, 0xC000   # 構造体の先頭アドレス
IN A, (0xC4)    # チェック実行
JNZ DETECT_HIT  # 衝突を検出
JZ NOT_HIT      # 非衝突
```

#### (Hardware Calculation)

0xC5 の OUT により Z80 が苦手とする乗算、除算、剰余算を高速に実行できます。

```
# 8bit 演算命令
OUT (0xC5), 0x00 ... HL = H * L
OUT (0xC5), 0x01 ... HL = H / L
OUT (0xC5), 0x02 ... HL = H % L

# 8bit 演算命令 (符号付き)
OUT (0xC5), 0x40 ... HL = H * L
OUT (0xC5), 0x41 ... HL = H / L

# 16bit 演算命令
OUT (0xC5), 0x80 ... HL = HL * C (※HL: 演算結果 mod 65536)
OUT (0xC5), 0x81 ... HL = HL / C
OUT (0xC5), 0x82 ... HL = HL % C

# 16bit 演算命令 (符号付き)
OUT (0xC5), 0xC0 ... HL = HL * C (※HL: 演算結果 mod 65536)
OUT (0xC5), 0xC1 ... HL = HL / C

※ゼロ除算が実行された場合の HL は 0xFFFF
```

#### (Hardware SIN table)

```z80
LD A, 123      # A に求めるテーブル要素番号を指定
OUT (0xC6), A  # A = sin(A × π ÷ 128.0)
```

#### (Hardware COS table)

```z80
LD A, 123      # A に求めるテーブル要素番号を指定
OUT (0xC7), A  # A = cos(A × π ÷ 128.0)
```

#### (Hardware ATAN2 table)

```z80
LD H, <<<y1 - y2>>>   # H に Y 座標の差を設定
LD L, <<<x1 - x2>>>   # L に X 座標の差を設定
IN A, (0xC8)          # A に (x1, y1) と (x2, y2) の角度を求める
```

#### (Hardware Random)

収束保証型の乱数を取得することができます。

> 収束保証とは 8 ビットなら 256 回呼び出すと 0 から 255、16 ビットなら 65536 回呼び出すと 0 から 65535 の数が必ず 1 回づつ出現することを意味します。

```z80
# 8 bits 乱数の種を設定
LD L, 123
LD A, L
OUT (0xC9), A

# 8 bits 乱数を取得 (乱数は L レジスタにも格納される点を注意)
IN A, (0xC9)

# 16 bits 乱数の種を設定（OUT への指定値は無視されるので何でも OK）
LD HL, 12345
OUT (0xCA), A

# 16 bits 乱数を取得 (乱数は HL レジスタにも格納される点を注意)
IN A, (0xCA)
```

#### (Hardware Perlin Noise)

パーリンノイズを取得することができます。

> 詳細は [./example/13_perlin](./example/13_perlin/) を参照

```z80
# 乱数シードを設定
LD HL, 12345
OUT (0xCB), A

# X方向の縮尺を設定（小さいほど縮尺が大きい）
LD HL, 123
OUT (0xCC), A

# Y方向の縮尺を設定（小さいほど縮尺が大きい）
LD HL, 456
OUT (0xCD), A

# パーリンノイズを取得
LD HL, 789 # X座標
LD DE, 123 # Y座標
IN A, (0xCE)

# パーリンノイズをオクターブ指定して取得
LD HL, 789 # X座標
LD DE, 123 # Y座標
LD A, 10   # オクターブ
IN A, (0xCF)
```

#### (Save Data)

- ポート 0xDA の I/O でセーブ（OUT）、ロード（IN）ができます
- セーブデータのファイル名は SD カードルートディレクトリ（SDL2の場合はカレントディレクトリ）の `save.dat` 固定です
- RPG のセーブ機能や STG のハイスコア保存機能などで利用することを想定しています

セーブの実装例:

```z80
LD BC, 0xC000   # セーブするデータのアドレスを指定 (RAM 領域のみ指定可能)
LD HL, 0x2000   # セーブするデータのサイズを指定 (最大 16 KB = 0x4000)
OUT (0xDA), A   # セーブ (※書き込んだ値は無視されるので何でもOK)
AND 0xFF        # セーブ結果はレジスタAに格納される
JZ SAVE_SUCCESS # 成功時は 0
JNZ SAVE_FAILED # 失敗時は not 0
```

ロードの実装例:

```z80
LD BC, 0xC000   # ロード先のアドレスを指定 (RAM 領域のみ指定可能)
LD HL, 0x2000   # ロードするデータサイズを指定 (最大 16 KB = 0x4000)
IN A, (0xDA)    # セーブ (※書き込んだ値は無視されるので何でもOK)
JZ LOAD_SUCCESS # ロード成功時は 0
JNZ LOAD_FAILED # ロード失敗時は not 0 (※ロード先は 0x00 で埋められる)
```

RaspberryPi 固有の注意事項:

- SDカードへのセーブは非同期に行われるため、SDカードが挿入されていないなどの不正な状態でもセーブは成功を返します（この時、SDカードの書き込みに失敗した旨のシステムメッセージが画面上に表示されます）
- SDカードの劣化を防ぐ目的でセーブデータの内容に変更が加えられた時にのみ save.dat の書き込みを行います
- セーブ中は LED ランプが点灯し、書き込み失敗時は 3 回ブリンクします
- セーブ中に電源断を行うと SD カードが破損する恐れがあります
- カーネルは、セーブとロードが実行された時に SD カードのマウントを行い、処理が完了すると自動的にアンマウントします

共通の注意事項:

- save.dat がロード時に指定したサイズ（HL）よりも小さくてもロードは成功し、この時、データが存在しない領域は 0x00 で埋められます
- スタック領域へのロードを行うとプログラムが暴走する可能性があります
- ユーザが異なるゲームのセーブデータを用いて動かす可能性を考慮するのが望ましいです

#### (Play BGM)

```z80
LD A, 0x01      # 演奏対象のBGM番号を指定
OUT (0xE0), A   # BGMの演奏を開始
```

#### (Pause BGM)

```z80
LD A, 0x00      # オペレーションID: Pause
OUT (0xE1), A   # BGMの演奏を中断
```

#### (Resume BGM)

```z80
LD A, 0x01      # オペレーションID: Resume
OUT (0xE1), A   # BGMの演奏を再開
```

#### (Fadeout BGM)

```z80
LD A, 0x02      # オペレーションID: Fadeout
OUT (0xE1), A   # BGMの演奏をフェードアウト
```

#### (Play Sound Effect)

```z80
LD A, 0x01      # 再生する効果音の番号を指定
OUT (0xF0), A   # 効果音を再生
```

#### (Stop Sound Effect)

```z80
LD A, 0x02      # 停止する効果音の番号を指定
OUT (0xF1), A   # 効果音を停止
```

#### (Check Sound Effect)

```z80
LD A, 0x03      # チェックする効果音の番号を指定
OUT (0xF1), A   # 効果音をチェック (A=0: Stopped, A=1: Playing)
AND 0x01
JNZ EFF03_IS_PILAYING
JZ  EFF03_IS_NOT_PLAYING
```

## How to Sell Your Game

### RaspberryPi Zero 2W

コミックマーケットや通販で VGS-Zero 用のゲームを販売する時は、

1. FAT32 でフォーマットした micro SD カードを準備
2. [./image](./image/) 以下のファイルを micro SD カードのルートディレクトリへコピー
3. [game.pkg](#gamepkg) を差し替え
4. [README](./image/README) を削除
5. README.txt（ゲームの遊び方を記載したテキスト）を格納
6. micro-SD カードを[ケース](https://www.amazon.co.jp/dp/B08TWR47LV/)などに格納
7. ケースにゲームのラベルを塗布

といった形で媒体を準備して販売するのが良いかと思われます。（ダウンロード販売の場合は SD カードに格納するものと同等のものを ZIP で固めて販売）

README.txtの記載凡例:

```
================================================================================
<<<ゲームタイトル>>>
<<<コピーライト>>>
================================================================================

この度は「<<<ゲームタイトル>>>」をお買い上げいただき誠にありがとうございます。
本書は本ゲームの遊び方などを記載していますので、プレイ前にご一読ください。


【必要なハードウェア】
・RaspberryPi Zero 2W
  - https://www.switch-science.com/products/7600
  - https://www.amazon.co.jp/dp/B0B55MFH1D/
・HDMI ケーブル (mini HDMI Type C → HDMI Type A)
  - https://www.amazon.co.jp/dp/B08R7BVL7T/
・USB ジョイパッド（D-Pad+A/B+Start/Select）+ 変換アダプタ
  - https://www.amazon.co.jp/dp/B07M7SYX11/
  - https://www.amazon.co.jp/dp/B08BNFKCYM/
・USB 電源
  - https://www.amazon.co.jp/dp/B09T3C758Q/
・テレビなど（以下の条件のもの）
  - HDMI入力対応
  - リフレッシュレート60Hz
  - 解像度 480x384 ピクセル以上
  - オーディオ出力対応


【起動方法】
・RaspberryPi Zero 2W に本製品（micro SDカード）を挿入
・RaspberryPi Zero 2W の電源を ON


【ボタン割り当ての変更方法】
ジョイパッドのボタン割当は config.sys でカスタマイズできます。
config.sys に設定すべき内容については、以下のツールでチェックできます。
https://github.com/suzukiplan/vgszero/tree/master/tools/joypad


【遊び方】
<<<ゲームの遊び方を記載>>>


【連絡先】
<<<Twitter（通称X）のアカウントなどを記載>>>
```

通販で販売する場合、ロット数が多い場合は同人ショップでの委託販売が良いかもしれませんが、小ロット（100本以下程度）であればメルカリあたりが手軽で良いかもしれません。

販売により得られた収益の SUZUKIPLAN へのペイバック（ライセンス料）等は一切不要です。

### Steam

- [VGS-Zero SDK for Steam](https://github.com/suzukiplan/vgszero-steam) を使えば Steam (Windows & SteamDeck) 版を簡単に作成できます
- VGS-Zero SDK for Steam の利用には Steamworks への加入と App クレジットの購入が必要です
- 販売により得られた収益の SUZUKIPLAN へのペイバック（ライセンス料）等は一切不要です

### Nintendo Switch

将来的に対応したいと思っています（[参考](https://qiita.com/suzukiplan/items/8a740b593816ef9ef565#%E4%BB%BB%E5%A4%A9%E5%A0%82switch%E5%AF%BE%E5%BF%9C%E4%BA%88%E5%AE%9A)）

## License

- VGS-Zero 本体は GPLv3 の OSS です: [LICENSE-VGS0.txt](./LICENSE_VGS0.txt)
- VGS-Zero 本体配布イメージには RaspberryPi ブートローダーが含まれます: [LICENCE.broadcom](./LICENCE.broadcom)
- VGS-Zero 本体には Circle（GPLv3）が含まれます: [LICENSE-CIRCLE.txt](./LICENSE-CIRCLE.txt)
- VGS-Zero 本体には SUZUKI PLAN - Z80 Emulator (MIT) が含まれます: [LICENSE-Z80.txt](./LICENSE-Z80.txt)
- VGS-Zero Library for Z80 は MIT ライセンスの OSS です:[LICENSE-VGS0LIB.txt](./LICENSE_VGS0LIB.txt)

> あなたが開発した[game.pkg](#gamepkg)の著作権はあなたに帰属し、商業利用を含む自由な利用が可能です。
>
> VGS-Zero Library for Z80 のみ[game.pkg](#gamepkg)内に組み込まれる場合がありますが、その他の OSS はすべてカーネル（VGS-Zero本体）側で利用しているものなので、開発したゲームのライセンスに影響しません。
>
> ただし、再配布時に同梱する場合は [./image/README](./image/README) に記載されている事項を遵守する必要がありますので、内容を注意深くご確認ください。
