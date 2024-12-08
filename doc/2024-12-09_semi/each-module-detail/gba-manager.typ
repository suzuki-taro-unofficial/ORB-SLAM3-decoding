== GBAManager

#figure(
  image("../images/GBAManager.png"),
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


