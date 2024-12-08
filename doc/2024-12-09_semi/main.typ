// コードブロックをいい感じにスタイリングしてくれる
#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(languages: codly-languages)
#codly(zebra-fill: none)
#let title = [ORB-SLAM3 FRP化 共有会資料]
#let author = [加藤 豪, 藤原 遼, 八巻 輝星]

#set heading(numbering: "1.1.1.1.")
#show heading: it => {
  block(width: 100%)[
    #if (it.level == 1) {
      text(it, size: 16pt)
    } else if (it.level == 2) {
      text(it, size: 12pt)
    } else {
      text(it, size: 10pt)
    }
    #v(-0.3cm)
    #line(length: 100%, stroke: gray)
    #v(0.3cm)
  ]
}

#set text(
  size: 10pt,
  lang: "ja",
  font: ("IPAMincho")
)

#set list(indent: 12pt, body-indent: 0.7em, spacing: 0.8em)
#set enum(indent: 12pt, body-indent: 0.7em, spacing: 0.8em)

#place(
  top + center,
  float: true,
  scope: "parent",
)[
  #align(center, text(20pt)[
    #title
  ])
  #v(-1em)
  #line(length: 100%)
  #grid(
    columns: (1fr, 1fr),
    align(left)[
      #text(12pt)[
        2024/12/09
      ]
    ],
    align(right)[
      #text(12pt)[
        #author
      ]
    ]
  )
  #v(1.5em)
  #outline(depth: 2, indent: 12pt)
  #v(1.5em)
]

#include "prerequisite-knowledge/main.typ"

= 今回の実装方針

今回のORB-SLAM3の並列FPRによる実装において大前提となる方針について簡単に述べる。

今回我々は、以下の方針で実装を進めている

+ LocalMapping、LoopClosingの動作フロー全般をFRPに置き換える
+ Trackingの動作フローは置き換えない
+ Optimizerなどの数値計算部分は置き換えない
+ 内部で扱われる、Atlas、KeyFrame、Map、MapPointなどのデータ構造について副作用を許す

我々としてはORB-SLAM3のFRP化を目指しているため、1でできる限りのネットワーク構築を目指している。
2に関しては、Trackingには3D点の復元など我々の知識では扱えない部分が多く存在すること、実装量の削減のためなどいくつかの理由で実装を行わない方針となった。
3に関しても実装量の削減のためや、副作用が多く存在しFRP化が難しいなどの理由で実装を行わない方針となった。
4に関しては元の並列処理において複数スレッド間で同時に参照・編集を行っていた部分であるため、ここの副作用を取り除いてしまうとORB-SLAM3として正常な動作が望めないと判断し副作用を残す方針となった。

= ネットワークの主な記法

#align(center)[
  #grid(
    columns: 3,
    [#figure(
      image("images/cell.png"),
      caption: [
        セル
      ]
    )<cell>],
    [#figure(
      image("images/stream.png"),
      caption: [
        ストリーム
      ]
    )<stream>],
    [#figure(
      image("images/ConnectFRPAndNonFRP.png"),
      caption: [
        FRPと外界の繋がり
      ]
    )<conn-frp-non-frp>]
  )
]

ネットワークを図として記述する際にセルやストリームを区別することは重要である。
この報告書ではセルを白抜きのひし形 (@cell)、
ストリームを黒塗りの矢印 (@stream) として記述する。

また、本実装ではFRPとそうでない部分をつなげる必要があり、それを図に明記するため
繋がりを点線の矢印 (@conn-frp-non-frp) で記述する。

= FRP化されたORB-SLAM3の全体像

FRP化されたORB-SLAM3（以降ORB_SLAM3_FRP）全体のネットワーク図は以下のようになる。

#figure(
  image("images/Overall.png"),
  caption: [
    全体のネットワーク
  ]
)

全体の動作は、TrackingのメソッドがORB_SLAM3_FRP外部(ユーザ)から呼び出されることから始まる。
この呼び出しの際にTrackingはIMUデータとフレーム（画像）データを基に3D点の復元などを行い、キーフレームを作成する。
作成されたキーフレームをLocalMappingInputBridgeを介してLocalMappingに渡す。
LocalMappingは専用の作動ストリームを受けてTrackingからもらったキーフレームを処理し、処理の終わったキーフレームをLoopClosingにわたす。
最後に、LoopClosingがループやマージの検出と統合の処理を行い、状況に応じて
マップ全体の最適化をGBAManagerを用いて行う。

ここで、LocalMapping,LoopClosing,GBAManagerは独立した作動開始ストリームの発火で動作しており、本動作はそれぞれ非同期に実行される。

クラスタの分割としては、以下のように切り分けられている。

- `LMInputBridge`, `LocalMapping`, `LMOutputBridge`で１つ
- `LCInputBridge`, `LoopClosing`で１つ
- `GBAManager`で１つ

またTrackingの本動作はメインスレッドで動作するため、上の３つとTrackingも非同期で動作する。

== 各モジュールの概要

以下のモジュールが存在する

- Tracking
  - 元のORB-SLAM3のTrackingに、FRPとの橋渡しを行う変更を加えたモジュール
  - FRPの外で動作する。k
- LocalMapping
  - Trackingで作られたキーフレームに対する前処理
  - 余計なキーフレーム・マップポイントの削除
  - 局所最適化
- LoopClosing
  - LocalMappingで最適化が施されたキーフレームを元にループとマージの検出を行う
  - 検出された場合にはそれぞれループとじ込み、マップマージングを行う
  - 後述するGBAManagerを場合によって起動させる。
- GBAManager
  - マップ全体の最適化を行うモジュール。
  - FRPの外で動作するGBAを行っているスレッドを管理する。

== ORB-SLAM3にのみ存在する機能

- Atlasのセーブ/ロード
  - 存在するが、使われていなく動作が不明瞭だった。
  - 機能を削除しても動作に支障が出ないため削除した。
- LocalMappingの実行の有効無効の切り替え
  - 実装にはネットワークを止める（もしくは類似する）動作が必要。
  - 実装に時間がかかりそうなので、必要になったら追加する。

#include "each-module-detail/main.typ"

= どっかに入れたほうが良いかも？

- かたみ先輩のほうでキューを使ってネットワークの接続を切り離していたこと、今回その必要がないこと
