# ORBSLAM概要メモ

## Tracking

フレームごとに動作する。

今年は触らない

### 現在把握できているTrackingの役割

- ORB特徴点の抽出
- 特徴点のマッチング
- カメラ姿勢の最適化
- IMUデータの統合
- キーフレームの作成（キーフレーム条件を満たすとき）

## LocalMapping

Trackingで作成されたキーフレームごとに動作する。

### 現在把握できているLocalMappingの役割

- 局所地図に対し、特徴点の追加
- 局所地図の最適化（バンドル調整）
- 未マッチングの特徴点に対して対応付け
- 重複するキーフレームを削除

## LoopClosing

キーフレームごとに動作する。

### 現在把握できているLoopClosingの役割

- ループの探索および統合
- EssentialGraphの最適化

## コード解読

### 接頭辞

- `m` メンバ変数
- `l` リスト
- `v` vector
- `s` set
- `b` bool
- `p` ポインタ

### LocalMapping

#### 変数

- `mpSystem`
- `mbMonocular` 単眼カメラかどうかのbool値、MONOCULARカメラの時true
- `mbInertial` 慣性データがあるかどうかのbool値,使われているセンサーがIMU_MONOCULARもしくはIMU_STREOのときtrue
- `mbResetRequested`
- `mbResetRequestedActiveMap`
- `mbFinisjhRequested`
- `mpAtlas`
- `bInitializing`
- `mbAbortBA`
- `mbStopped`
- `mbStopRequested`
- `mbNotStop`
- `mbAcceptKeyFrames`
- `mIdxInit`
- `mbNotBA1`
- `mbNotBA2`
- `mIdxIteration`
- `infoInertial`

## TODO

- コード解読
- BRIEF、キーフレーム等のデータ構造の理解
