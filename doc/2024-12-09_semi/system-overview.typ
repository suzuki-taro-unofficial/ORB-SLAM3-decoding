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
  - FRPの外で動作する
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


