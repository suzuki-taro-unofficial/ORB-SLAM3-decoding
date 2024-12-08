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

= 全体像

FRP化されたORB_SLAM3（以降ORB_SLAM3_FRP）全体のネットワーク図は以下のようになる。

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

またTrackingはメインスレッドで動作するため、上の３つとTrackingも非同期で動作する。

== 各モジュールの概要

以下のモジュールが存在する

- Tracking
  - 元のORB-SLAM3のTrackingに、FRPとの橋渡しを行う変更を加えたモジュール。
  - FRPの外で動作する。
- LocalMapping
  - Trackingで作られたキーフレームに対する最適化を行う。
- LoopClosing
  - LocalMappingで最適化が施されたキーフレームを元にループとマージの検出を行う。
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

= 各モジュールの詳細

== LocalMapping

// ![ネットワーク図:LocalMapping]()

- 入力
- 振る舞い・出力
- 詳細
- 元のLocalMappingとの差異

その他注意点・工夫点折り込みつつ

== LoopClosing

#figure(
  image("images/LoopClosingFRP.png"),
  caption: [
    LoopClosingのネットワーク
  ]
)
=== 入力

- s_tick
  - Systemから送られるunitのストリーム。
  - 5秒おきに発火。
- s_insertKF
  - LMから送られるKFのストリーム。
  - キューに蓄えられる。
- s_resetActiveMap
  - Trackingから送られるストリーム。
  - Mapのポインタを持っている。
- c_stopLC
  - GBAManagerが持つセル。
  - boolの値を持ち、trueの時、LCの動作を停止する。
  - 並列FRPではグローバルストリームループができないため、セルで実装している。
- c_activeLC
  - Systemが持つセル。
  - boolの値を持ち、falseの時、LCは行なわれない。
- c_LMisStopped
  - LMが持つセル。
  - trueの時、LMが停止している。
- c_GBAisRunning
  - GBAが行なわれているかのセル。
  - 通常Merge語にはGBAを行なわないが、GBAの途中でMergeを検出しGBAが停止した場合、Mergeの終了後GBAを行う。

=== 出力

- s_stopGBA
  - GBAを停止させるunitのストリーム。
- s_runGBA
  - GBAを実行させるストリーム。
  - mapのポインタとKFのIDを持つ。
- c_stopLM
  - LMを停止させるかどうかのセル
  - boolの値を持ち、trueのとき、LMを停止させる。
- c_LCisStopped
  - LCが停止したかどうかのセル
  - boolの値を持ちtrueのとき、LCが停止している。

=== 内部セル

- c_mode
  - Detect、CorrectLoop、Mergeの３種の状態を持つ。
  - この状態によって、tickを受け取った後の動作が決まる。
- c_detectInfo
  - Detectorで得られた情報を、ループとじ込みやMergeに渡すためのセル

== 動作

=== Detect

1. QueueからKFをpopする。
2. DetectorでそのKFに対してループやMergeの検出を行う。
  - 主にBoW（Bag-of-Words)によってループやDetectの検出を行う。
  - 前回KFで部分的に検出があれば、Sim3変換による検出も行う。
  - ループとMergeは同じ方法で検出される。
    - 同じ地図で検出されたらループ、違う地図で検出されたらMerge
3. ループやMergeが検出されたら以下の動作を行う
  - c_stopLMをtrueにする
  - c_modeを検出された処理に変更する
  - GBAが動いているのであれば、s_stopGBAを発火し、GBAを止める。
  - 一部の情報を、c_detectorInfoに保存する。

=== CorrectLoop

- 内部ではCovisibility Graphの更新や、ループ辺の追加を行う。
- 処理が終了したら、
  - s_runGBA を発火
  - c_modeをDetectにする
  - c_stopLMをfalseにする。

=== Merge

- 地図の統合を行う。
- 処理が終了したら、
  - c_modeをDetectにする
  - c_stopLMをfalseにする。
  - Detect時にGBAを止めていたなら、s_runGBAを発火する。

=== 元のLoopClosingとの差異

- 元の実装ではc_modeのような状態を持っていない。FRPではwhileとsleepで外部の変化を待つことができないため、外部の状態の変更を待つ必要のある処理をmodeで分けることで、外部の状態の変更をtickごとに待つことができるようにした。
- GBAをループクロージング内でスレッドを立てて実行していたが、GBAManagerに委託するようにした。

== GBAManager

#figure(
  image("images/GBAManager.png"),
  caption: [
    GBAManagerのネットワーク
  ]
)

動作は主にs_tickによって行われ、以下のようになっている。

- c_runInfoに情報がある
  - c_updateInfoに情報がない場合
    - 新たにスレッドを起動する
    - この際、別スレッドが走っているなら止めてから起動する
  - c_updateInfoに情報がある
    - c_isLMStoppedがfalse
      - LMに対して停止を要求するストリームを発火させる
    - c_isLMStoppedがtrue
      - 情報を用いてキーフレームやマップポイントの情報を更新する
      - 更新後、LMの再開を要求するストリームを発火させる
- c_runInfoに情報が無い
  - c_updateInfoに情報が無いなら何も行わない
  - そうでないなら、上と同じ動作を行う


=== 状態

- c_thread
  - GBAが起動しているなら、そのスレッドを保持する
- c_updateInfo
  - GBAが正常に終了し、各種情報を更新することができる際にそのための情報を保持する
- c_runInfo
  - GBAを起動させることができる際に起動のための情報を保持する

=== 入力

入力として以下のストリームとセルを受け取る

- s_tick
  - 発火した際に、c_runInfoにGBAをするマップが存在し、かつc_updateInfoに更新するべきマップが存在しない場合にGBAを起動させる
- s_stopGBA
  - 発火した際にc_threadで走っているスレッドを中断した後joinして終了まで待つ
  - c_threadをnoneで更新する
- s_runGBA
  - GBAを行うマップの情報を持って発火し、その際にc_runInfoをその情報で更新する
- c_isLMStopped
  - ローカルマッピングが停止しているかを保持するセル
- c_isLCStopped
  - ループクロージングが停止しているかを保持するセル

=== 出力

出力として以下のストリームが存在する

- c_stopLM
  - マップの更新処理を行う際にtrueになりLMを停止させるセル
- c_stopLC
  - マップの更新処理を行う際にtrueになりLCを停止させるセル
- c_running
  - GBAが動作している際にtrueとなるセル

=== 注意点

GBAをネットワークにすると、GBAを停止するという動作がFRPで表現できないため、
GBAをFRPの外で起動し、そのスレッドの管理をセルを通じて行うようにしている。

== Tracking

今回TrackingはFRPにしないが、FRPと連携して動く必要があるため、
後述するInputBridgeとOutputBridgeを用いて各モジュールの関数呼び出しを置換した。

=== InputBridge

ネットワークへ渡すStreamSinkを持ち、
sendを行う関数群を用いてネットワークへの入力を行う。

```cpp
struct InputBridge {
  InputBridge();
  void doSomething(int value) { ssink_doSomething.send(value); }
  sodium::stream<int> ssink_doSomething;
};
```

=== OutputBridge

ネットワークの出力ストリーム・セルをlistenし、
内部で変数を書き換えそれをゲッターを用いて取得する。

```cpp
struct OutputBridge {
  OutputBridge(sodium::stream<int> s, sodium::cell<int> c) {
    s.listen([](int x) { sv = x; });
    c.listen([](int x) { cv = x; });
  }
  int get_sv(void) { return sv; }
  int get_cv(void) { return cv; }
private:
  int sv, cv;
};
```

= どっかに入れたほうが良いかも？

- かたみ先輩のほうでキューを使ってネットワークの接続を切り離していたこと、今回その必要がないこと
- 図の記法について
  - セルの矢印が違ったりとか
