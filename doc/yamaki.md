# ORBSLAM概要メモ

## ORBSLAMのシステム概要

### Tracking

フレームごとに動作する。

今年は触らない

#### 現在把握できているTrackingの役割

- ORB特徴点の抽出
- 特徴点のマッチング
- カメラ姿勢の最適化
- IMUデータの統合
- キーフレームの作成（キーフレーム条件を満たすとき）

### LocalMapping

Trackingで作成されたキーフレームごとに動作する。

#### 現在把握できているLocalMappingの役割

- 局所地図に対し、特徴点の追加
- 局所地図の最適化（バンドル調整）
- 未マッチングの特徴点に対して対応付け
- 重複するキーフレームを削除

### LoopClosing

キーフレームごとに動作する。

#### 現在把握できているLoopClosingの役割

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

#### コンストラクタで初期化される変数

- `mpSystem` ORBSLAM3システムへのポインタ
- `mbMonocular` 単眼カメラかどうかのbool値、MONOCULARカメラの時true
- `mbInertial` 慣性データがあるかどうかのbool値,使われているセンサーがIMU_MONOCULARもしくはIMU_STREOのときtrue
- `mbResetRequested`
- `mbResetRequestedActiveMap`
- `mbFinisjhRequested`
- `mpAtlas` 現在のマップ情報へのポインタ
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

#### setLoopCloser

メンバ変数`mpLoopCloser`にLoopCloserのポインタをセットしているだけ

#### setTracker

メンバ変数`mpTracker`にTrackerのポインタをセットしているだけ

#### Run()

以下の動作を行う

1. キーフレームの挿入をロックし、今現在新しいキーフレームがあるか確認する。ないなら2～　は省略
2. `ProcessNewKeyFrame`を実行し、キーフレームの処理を行う。
3. `MapPointCulling`を実行し、不適切なMapPointを削除する。
4. `CreateNewMapPoints`を実行し、新しいマップポイントを生成する。
5. まだほかに新しいキーフレームがあるなら重複を調べる？
6.
7.
8.

#### 注)以下GPTによるヘッダファイルの解析内容を含む

#### InsertKeyFrame

新しいキーフレームをローカルマッピングのキューに追加
キューの最後尾にキーフレームを追加している。
フラグとして`mbAbortBA`をtrueにしている?

#### CheckNewKeyFrames

新しいキーフレームがあればtrue、なければfalseを返す。

#### ProcessNewKeyFrame

挿入されたキーフレームを処理し、新しいマップポイントの作成や周囲のキーフレームとの関係を更新する

- キーフレームの取得(取得の際、使われるキーフレームはキューからpopされる)
- Bowの計算
- キーフレームにMapPointを関連付ける
- Covicibility Graphの更新
- キーフレームをマップに挿入

などの動作を行っている

#### EmptyQueue

キーフレームのキューが空になるまで、`ProcessNewKeyFrame`を実行する

#### CreateNewMapPoints

キーフレームと対応するフレームの特徴点から新しいマップポイントを生成する。

#### MapPointCulling

不適切なマップポイントを削除する。観測数が少ないマップポイントや品質の低いものが削除対象。

#### SearchInNeighbors

新しいキーフレームの周辺にあるキーフレームと一致するマップポイントを探索し、関連性を高める

#### KeyFrameCulling

一定条件に基づいて、不要なキーフレームを削除する。キーフレーム数を適切に管理しメモリ使用量を抑える

#### RequestStop / Stop / Rerease

ローカルマッピングのスレッドを制御する。ローカルマッピングの停止や再開がリクエストされた場合の動作を定義している。

#### RequestReset

リセットをリクエストし、ローカルマッピングの状態を初期化する。

#### RequestFinish / isFinished

ローカルマッピングの終了をリクエストし、終了したかどうかを確認するためのメソッド。

#### InitializeIMU

IMUを用いてシステムの初期化を行う。IMUデータを用いてローカルマッピングの精度を向上させる。

以下概要

1. `minTime`と`nMinKF`を設定する（モノクロカメラかどうかで決める）
2. 時間順位すべてのキーフレームを取得し、`lpKF`に保存し、これをvectorの`vpKF`に変換
3. 新しいキーフレームがあるなら、すべての新しいキーフレームを処理し、`lpKF`と`vpKF`に挿入する。
4. IMUの初期化を行う
5. IMUの最適化を行う
6. 現在の地図に対してスケールや回転を適用する。
7. キーフレームとマップポイントを更新し、補正を適用
8. 終了処理

`dirG`は重力加速度の向きっぽい

#### ScaleRefinement

マップのスケールを微調整するためのメソッド。IMUを用いてスケールの調整を行う。

#### IsInitializing

`bInitializing`をそのまま返す。

#### GetCurrKF

現在のキーフレーム返す。

### ImuTypes

IMUデータの処理をおこなう関数群の定義

### Atlas

### KeyFrame

### LoopClosing

#### NewDetectCommonRegion

GPT曰く慣性情報を使用している場合、高精度な移動推定がすでにできているため、システムの負荷軽減のために処理がスキップされているらしい。

`mnLoopNumCoincidences`は、最初はBoWでループが見つかると増加する。

## TODO

- コード解読
- BRIEF、キーフレーム等のデータ構造の理解

## memo

- LocalMappingはBAのみさわる。
- 中間ポスター、図とかあるといいね
- 次回までに中間発表の切り分けきめる
