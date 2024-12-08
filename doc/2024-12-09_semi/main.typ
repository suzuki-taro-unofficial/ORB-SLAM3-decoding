// コードブロックをいい感じにスタイリングしてくれる
#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(languages: codly-languages)
#codly(zebra-fill: none)

#let title = [ORB-SLAM3 FRP化 共有会資料]
#let author = [加藤 豪, 藤原 遼, 八巻 輝星]

#set heading(numbering: "1.1.1.")
#show heading: it => {
  block(width: 100%)[
    #if (it.level == 1) {
      text(it, size: 16pt)
    } else if (it.level == 2) {
      text(it, size: 12pt)
    } else if (it.level == 3) {
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
]

= ORB-SLAM3について

- ORB-SLAM3がなにか（必要？
- 全体像
- 各モジュールの働き
- モジュール同士の連携

とか？

= 並列FRPについて

- 概要
  - クラスタの概念を追加してクラスタ間を並列化させたFRPであること

現在、大本先輩が並列処理可能なFRPライブラリ(以降prf)を制作している。

prfは基本的にSodiumと同じインタフェースと動作を提供する。

そこにクラスタという新規の概念を追加し、そのクラスタ同士を並列に実行することができる。

== クラスタ

クラスタとはプリミティブ操作の集合である。
また各ストリーム、セルはプリミティブと同一の

prfのユーザはクラスタを明示的に宣言することによって、プリミティブ操作の集合を定義できる。

```java
// 暗黙的なクラスタ０
Stream<int> s1;
Stream<double> s2;

// 明示的なクラスタ１
Cluster cluster1;
Stream<int> s3 = s1.map((v) => v * v);
Stream<double> s4 = s2.filter((v) => v > 10.0);
Stream<double> s5 = s1.merge(s2, (v1, v2) => v1 + v2);
cluster1.close();
// クラスタ１の終了

// 暗黙的なクラスタ２
```

- クラスタとはなにか
- クラスタとトランザクションの関係性

== クラスタ間の接続

- クラスタを接続した際の動作

== グローバルセルループ

- グローバルセルループがなにか
- グローバルセルループの制約について

= 方針

大前提となる方針について簡単に。

- 何をして何をしないのか
- FRPから逸脱する部分をどう許しているのか
  - Map,KeyFrame,MapPointをコピーできない理由、しなくてもいい理由、してはいけない理由
  - Atlasに対する副作用が大丈夫な理由、無いとだめな理由

= 全体像

#figure(
  image("images/Overall.png"),
  caption: [
    全体のネットワーク
  ]
)

== 各モジュール

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

== 動作

全体としては、Trackingのメソッドが外部から呼び出されることから始まる。
Trackingが入力を処理してキーフレームにしたものをLMInputBridgeを介して
LocalMappingに渡す。
その後、LocalMappingがキーフレームに最適化を施した後にそのキーフレームを
LoopClosingにわたす。
最後に、LoopClosingがループやマージの検出と統合の処理を行い、状況に応じて
マップ全体の最適化をGBAManagerを用いて行う。

ここで、各モジュールは独立したティックの発火で動作しており、各モジュール間の
データの受け渡しはストリームで行われる。

= LocalMapping

// ![ネットワーク図:LocalMapping]()

- 入力
- 振る舞い・出力
- 詳細
- 元のLocalMappingとの差異

その他注意点・工夫点折り込みつつ

= LoopClosing

#figure(
  image("images/LoopClosingFRP.png"),
  caption: [
    LoopClosingのネットワーク
  ]
)

== 動作

== 入力
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

== 出力

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

== 内部セル
- c_mode
  - Detect、CorrectLoop、Mergeの３種の状態を持つ。
  - この状態によって、tickを受け取った後の動作が決まる。
- c_detectInfo
  - Detectorで得られた情報を、ループとじ込みやMergeに渡すためのセル

== 詳細な動作

=== Detect

== 元のLoopClosingとの差異

- GBAをループクロージング内で実行していたが、GBAManagerを新たに作成しそこに委託するようにした。

= GBAManager

#figure(
  image("images/GBAManager.png"),
  caption: [
    GBAManagerのネットワーク
  ]
)

== 状態

- c_thread
  - GBAが起動しているなら、そのスレッドを保持する
- c_updateInfo
  - GBAが正常に終了し、各種情報を更新することができる際にそのための情報を保持する
- c_runInfo
  - GBAを起動させることができる際に起動のための情報を保持する

== 入力

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

== 出力

出力として以下のストリームが存在する

- c_stopLM
  - マップの更新処理を行う際にtrueになりLMを停止させるセル
- c_stopLC
  - マップの更新処理を行う際にtrueになりLCを停止させるセル
- c_running
  - GBAが動作している際にtrueとなるセル

== 動作

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

== 注意点

GBAをネットワークにすると、GBAを停止するという動作がFRPで表現できないため、
GBAをFRPの外で起動し、そのスレッドの管理をセルを通じて行うようにしている。

= Tracking

今回TrackingはFRPにしないが、FRPと連携して動く必要があるため、
後述するInputBridgeとOutputBridgeを用いて各モジュールの関数呼び出しを置換した。

== InputBridge

ネットワークへ渡すStreamSinkを持ち、
sendを行う関数群を用いてネットワークへの入力を行う。

```cpp
struct InputBridge {
  InputBridge();
  void doSomething(int value) { ssink_doSomething.send(value); }
  sodium::stream<int> ssink_doSomething;
};
```

== OutputBridge

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
- 一部機能を消していること
- 図の記法について
  - セルの矢印が違ったりとか
