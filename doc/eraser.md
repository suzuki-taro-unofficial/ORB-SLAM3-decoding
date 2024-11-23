## ORB-SLAM3の概要

- 画像からの特徴点抽出にはORBを使用
- MappingとTrackingが並列に行われる
- BA(バンドル調整)がリアルタイムに行われる
  - リアルタイムの意図は不明
- DBoW2というLoop Closingを採用
  - eraser: DBoW2で得た特徴量をキーとしたKFのDBみたいなのがあって、KFが入力されるたびにそのDBoW2の特徴量でDBに検索をかけ、近いものがあればループ検出成功、みたいになるのかな？

ORB独自のものとして

1. キーフレームは適者生存戦略をとる．キーフレームを多めにとることで局所的に精度の良い自己位置推定を行い，あとから余計なキーフレームを削除する．
2. 初期化を自動で行う

[参考](https://noshumi.blogspot.com/2017/07/orb-slam.html#:~:text=ORB-SLAM%E3%81%A8%E3%81%AF%E7%89%B9%E5%BE%B4,%E3%81%8C%E7%89%B9%E5%BE%B4%E3%83%99%E3%83%BC%E3%82%B9%E3%81%AESLAM%EF%BC%8E)

## 出現用語について

- ORB: Oriented FAST and Rotated BRIEF
  - FASTによる特徴点検出とBRIEFによる特徴量記述子を組合わせたもの
  - FASTによってエッジ点などの特徴点を検出しBRIEFやその他の加工によって、回転などに強い画像(特徴店同士)のマッチングに使えるっぽい
  - [参考1](https://labs.eecs.tottori-u.ac.jp/sd/Member/oyamada/OpenCV/html/py_tutorials/py_feature2d/py_orb/py_orb.html)
  - [参考2](https://qiita.com/hitomatagi/items/62989573a30ec1d8180b)
    - ORBは、特徴点、特徴量を抽出するアルゴリズムで、移動、回転、ズームのどれにもロバストネスがあるアルゴリズムです。
- フレーム: 入力(カメラやIMUの情報が入ってるっぽい)
- キーフレーム: フレームの中でも重要なのを選んだもの
  - 他にも情報上乗せされてたりするかもだけど基本はこうらしい
  - 前回のキーフレームからの差異が大きくなると採用されるっぽい
    - 新しい特徴点が増えた
    - 特徴点の結び付けがほとんどできない
    - ロボットの位置・姿勢が大きく変わった
    - など
- マップポイント: マップ上の点？
- キーポイント: キーフレームと同様重要なものを選んだもの
  - [ORBについて調べたところ](https://www.argocorp.com/OpenCV/imageprocessing/opencv_orb_feature_matching.html)画像上の特徴的な点のことっぽい？
- DBoW2:
  - BoW(Bag of Wards)という、テキストに出現する単語をカウントして用いて特徴を得る手法？を画像に発展させたものがDBoWっぽい
  - 見ていた感じ画像上の特徴点をクラスタリングして、そのクラスタを単語のように扱うことでカウントしているっぽい
  - DBoW2ライブラリに任せているっぽいので大雑把な理解
- Covisibility Graph
  - KeyFrameをノード、フレーム間で共通して見えるORB特徴が閾値以上のものをエッジとしてグラフ化したもの
- Spanning Tree
  - Covisibility Graphから作成した全域木
- Essential Graph
  - Spanning Treeに強いエッジを追加したもの

## 周辺知識

- SO(3): 3次元空間における回転を表すリー群です。つまり、3次元空間の原点を中心に回転させる行列の集合です。これらの行列は、直交行列であり、行列式が1であるという特性があります。
- SE(3): 3次元空間における剛体変換を表すリー群です。これは回転と平行移動の両方を含む変換の集合であり、一般的には4x4の同次変換行列として表されます。

## 2024/10/25追記

- CreateNewMapPointsについて
  - 冒頭あたりで、GetBestCovisibilityKeyFramesを使ってCovisibilityGraph上でつながったKFを探している。
  - その後、currentKFのprevKFを探索していって、GetBestCovisibilityKeyFramesの結果に含まれていたら、GetBestCovisibilityKeyFramesの結果にKF（prevKF）を加えている。
  - つまり、同一のKFをvector上に入れている。
  - ちょっとよくわからない。

## Dockerの環境での問題点

Docker環境を用意し、ビルドまではうまくようになった。
ただ、実行すると以下のようなエラーが出る。

```txt
root@2f60aff5afbf:/ORB_SLAM3# make run1
./Examples/Stereo/stereo_euroc ./Vocabulary/ORBvoc.txt ./Examples/Stereo/EuRoC.yaml ~/dataset/MH04 ./Examples/Stereo/EuRoC_TimeStamps/MH04.txt dataset-MH04_stereo
./Examples/Stereo/stereo_euroc: error while loading shared libraries: libORB_SLAM3.so: cannot open shared object file: No such file or directory
make: *** [Makefile:2: run1] Error 127
root@2f60aff5afbf:/ORB_SLAM3# ldd build/Examples/Stereo
Stereo/          Stereo-Inertial/
root@2f60aff5afbf:/ORB_SLAM3# ldd build/Examples/Stereo/stereo_euroc | grep ORB_SLAM3
        libORB_SLAM3.so => /ORB_SLAM3/build/src/libORB_SLAM3.so (0x00007fa562600000)
        libDBoW2.so => /ORB_SLAM3/Thirdparty/DBoW2/lib/libDBoW2.so (0x00007fa561b26000)
        libg2o.so => /ORB_SLAM3/Thirdparty/g2o/lib/libg2o.so (0x00007fa561a8b000)
```

shared libraryが見つからないとのことだが、lddでみてみるとちゃんと存在しているように見える。

## メモ 2024/10/31

- System::SaveDebugDataでのみ読み込まれるメンバ変数が割とある。
  - それさえなければ
    - unusedなもの: mcovInertial, etc.
    - 書き込みだけ行われるもの: mInitTime, etc.
    - ローカル変数にできるものなど: mScale, etc.
  - FRP化するからにはこういう読み取り方法もできなくなるので、SaveDebugData自体消してしまっても良いかも？
    - 必要になった時に作るとか
    - SaveDebugDataが何を出しているのかとか見てから考える

## メモ 2024/11/9

- LoopClosingがTrackingのGetLastKeyframeを呼び出すのが妥当なのかわからない
  - GetLastKeyframeが返すのは、Trackingが生成した最新のKF
  - CurrentKeyframeに付いてループ検出マージ検出をしたのに、それより新しい可能性のあるLastKeyFrameをマージ処理に使っている
- MergeLocalの際にGBAが絶対に実行されない
  - MergeLocalの処理内でGlobalBAを実行するための条件式に、bRelaunchBAがある
  - bRelaunchBAは常にfalse
  - したがって実行されない
  - コメントを残してGlobalBAの処理をMergeLocalから削除した
- よくわからないフローの処理があった
  - TrackingでSystem::ResetActiveMapを呼び出す
  - System::ResetActiveMapはSystem.mbResetActiveMapをtrueに設定する
  - System::TrackStereoなどの各種トラック関数がSystem.mbResetActiveMapを読み取り、trueだった場合にTracking::ResetActiveMapを呼び出す
  - Tracking::ResetActiveMapはマップのリセット処理を行う

## メモ 2024/11/11

- Streo + IMUなど特定パターンのみ対応しそれ以外のパターンをすべて消してしまいたい
  - 我々の研究の目標はORB_SLAM3を完全に移植することではなく、 並列FRPを用いたVisual SLAMのプロトタイプを実装すること
  - プロトタイプの時点で全てのカメラタイプを網羅することは考えなくて良いはず。
  - 複数のカメラタイプを想定することにおよってコードの煩雑化、スパゲティ化がひどいので、
    Stereo + IMUなど特定パターンについてのみ考えることでシステムやネットワークをシンプルにしたい

## メモ 2024/11/12

- LocalMapping.mbBadImuについて
  - mbBadImuはLocalBAの中でいくつかの条件を突破するとtrueになる
  - mbBadImuがtrueになっていると、LocalMappingの主要な処理全体が行われないようになる
  - mbBadImuはResetIfRequestedでリセットリクエストが飛んでいた場合にfalseに戻る
  - Tracking::Track内で、mbBadImuがtrueの場合にLocalMapping::RequestResetActiveMapを実行している
  - LocalMappingは3000ms毎、Trackingは画像が入る毎なので速度に差はあるが、
    LocalMapping側で結局ループしてリセットリクエストを見てという形でLocalMappingのタイミングに同期されているので、
    LocalMapping内に閉じることができそう

## メモ 2024/11/15

- IMUを使っているかの情報について
  - Atlas::SetImuInitialized()
    - mpCurrentMap->SetImuInitialized()
  - Atlas::IsImuInitialized()
    - mpCurrentMap->IsImuInitialized()
  - Atlas::IsInertial()
    - mpCurrentMap->IsInertial()
      - return map.mbInertial
  - Atlas::SetInertialSensor()
    - mpCurrentMap->SetInertialSensor()
      - map.mbInertial = true
  - Map::IsInertial()
    - 呼び出し元
      - Atlas, LoopClosing
  - Map::SetInertailSensor()
    - 呼び出し元
      - Atlas

## メモ 2024/11/23

- FRPで表現不可能な処理をどうするか
  - LocalMapping::InteraptBA()
    - LocalBAなど一部の処理をキャンセルするためのフラグを立てる
    - 共有メモリへの書き込みと読み取りでトランザクションを強制終了するなどするしか無い
  - LocalMapping::IsInitializing()
    - IMUの初期化処理の最中かどうかが返り、これによってTrackingの処理が変わる
    - これも共有メモリを書き込むなどするしか無い
