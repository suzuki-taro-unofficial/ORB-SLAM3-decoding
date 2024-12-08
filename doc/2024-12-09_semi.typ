#set text(
  size: 10pt,
  lang: "ja",
  font: ("IPAMincho")
)

= 2024/12/09 共有会資料

====== 作成: 加藤 豪, 藤原 遼

== ORB-SLAM3について

- ORB-SLAM3がなにか（必要？
- 全体像
- 各モジュールの働き
- モジュール同士の連携

とか？

== 並列FRPについて

- 概要
  - クラスタの概念を追加してクラスタ間を並列化させたFRPであること

現在、大本先輩が並列処理が可能なFRP

=== クラスタ

- クラスタとはなにか
- クラスタとトランザクションの関係性

=== クラスタ間の接続

- クラスタを接続した際の動作

=== グローバルセルループ

- グローバルセルループがなにか
- グローバルセルループの制約について

== 方針

大前提となる方針について簡単に。

- 何をして何をしないのか
- FRPから逸脱する部分をどう許しているのか
  - Map,KeyFrame,MapPointをコピーできない理由、しなくてもいい理由、してはいけない理由
  - Atlasに対する副作用が大丈夫な理由、無いとだめな理由

== 全体像

// ![ネットワーク図:全体像]()

- 各モジュールの概要
  - 働き
  - 入力・出力
- 動作
- 元のORB-SLAM3との違い
- クラスタの分け方
- グローバルループ

== LocalMapping

// ![ネットワーク図:LocalMapping]()

- 入力
- 振る舞い・出力
- 詳細
- 元のLocalMappingとの差異

その他注意点・工夫点折り込みつつ

== LoopClosing

#figure(
  image("../images/LoopClosingFRP.png")
)
=== 動作
=== 入力
- s_tick
  - Systemから送られるtickストリーム、
- s_insertKF
  - LMから送られるKFのストリーム、キューに蓄えられる。
- s_resetActiveMap
  - 
- c_stopLC
- c_activeLC
- c_LMisStopped
- c_GBAAisRunning
=== 出力
- s_stopGBA
- s_runGBA
- c_stopLM
- c_LMisStopped
=== 詳細
=== 元のLocalMappingとの差異

その他注意点・工夫点折り込みつつ

== GBAManager

#figure(
  image("../images/GBAManager.png"),
  caption: [
    GBAManagerのネットワーク
  ]
)

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

=== 動作

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

== Tracking

- 変更点

== どっかに入れたほうが良いかも？

- かたみ先輩のほうでキューを使ってネットワークの接続を切り離していたこと、今回その必要がないこと
- 一部機能を消していること
- 図の記法について
  - セルの矢印が違ったりとか
