== LoopClosing

#figure(
  image("../images/LoopClosingFRP.png"),
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
- 元の実装ではGBAがGBAの結果をmapに書き込んでいる間、ループとじ込みやMergeはmutexにより停止するが、検出を並列に行っていた。今回の実装ではGBAがマップに書き込んでいる間はすべての動作を停止するようにした。

