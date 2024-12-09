== LocalMapping

以下にLocalMappingのネットワーク図を示す。

// ![ネットワーク図:LocalMapping]()
#figure(
 image("../images/LocalMapping.svg"),
  caption: [LocalMappingのネットワーク]
)

LocalMappingは、Trackingから入力されたキーフレームをキューに溜め込む。
s_tickストリームが発火した際に３回に一回だけキューからキーフレームを取り出し、本処理を開始する。
s_tickの残りの２回についてはLocalMappingの停止・稼働状態の更新をするにとどめる。停止・稼働状態については StopManager で詳しく説明する

本処理は以下の順で実行される

+ ProcessNewKeyFrame
+ MapPointCulling
+ CreateNewMapPoints
+ 以降はキューに他のデータがない場合のみ実行
+ SearchInNeighbors
+ LocalBA 
  - マップに２つ以上のKFが存在するときだけ
+ InitializeIMU1
  - １回目のInitializeIMU
+ InitializeIMU2and3
  - ２回目と３回目のInitializeIMU
  - ２回目と３回目が同一トランザクションで起こることはない
  - １回目と同一トランザクションで起こる場合はある
- ScaleRefinement
  - マップに含まれるKFが200以下の時だけ

そして本処理が実行された場合には、どこまで実行されたとしても最後にs_insertKFtoLCが発火し、
LoopClosingにキーフレームが渡される。

本処理内のそれぞれの処理については元々のORB-SLAM3とほぼ同一となっている。

=== StopManager <local-mapping_stop-manager>
