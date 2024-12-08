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
  - 5ミリ秒おきに発火。
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

=== 動作

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
後述するInputBridgeとOutputBridgeを用いて各モジュールに対する処理を置換した。

置換した処理としては以下の通り

- TODO

=== InputBridge

ネットワークへ渡すStreamSinkを持ち、
sendを行う関数群を用いてネットワークへの入力を行う。

```cpp
struct InputBridge {
  InputBridge();
  void doSomething(int value) { ssink_doSomething.send(value); }
  sodium::stream<int> s_doSomething;
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

