# Frame

各種カメラからの画像を受け取り、ORB特徴量を抽出して管理する。また外部からIMUの情報を受け取りこれも管理する。

# Tracking

カメラの入力とIMUの入力を受け取る。

# KeyFrame

Frameの中で地図の構築に用いられるもの。基本的にはFrameと同じだが自身の所属している地図などの情報を持つ。

# ORBextractor

与えられた画像からORB特徴量を抽出する機能を提供している。

# memo

- GetPoseとかが`Sophus::SE3`を返しているのは、これ自体が回転ベクトルと推進方向のベクトルの2つ組で、ロボットの位置は回転行列と推進方向のベクトルの2つで表せ、回転ベクトルは回転行列に変換可能だから。つまり、Pose -> ロボットの位置
- `Tba`みたいな変数は座標系`b`から座標系`a`への変換を表している。`T`が`R`とかだったら変換が回転など大文字が持つ意味になる。
  - これは、座標系の変換がいい感じにコード上で表現されるためにやっている気がする。
  - 例えば、`Tcb`と`Tba`があったときに、`Tcb * Tba`と書いたとき`b`が消えるのがわかりやすい。
- 座標系を表す小文字はおそらく以下の様になる。
  - `b` IMU座標系
  - `c` カメラ座標系
  - `w` グローバル座標系

# Atlas

- AtlasをFRP化する必要性がありそう
- FRP化した場合にバイナリとしてクラスを吐き出すのが困難そう
  - バイナリに吐き出すのは一時停止したときに復帰するのに必要そう

## 対処法

1. FRPAtlasをバイナリ可能な形式に変換/復元する方法を新しく作る
2. そもそも書き出さない（復帰を諦める）

追記 by eraser: これはFRP化されたAtlasやその他の中身には関係がないため、頭の片隅においておけばOK。Systemの実装時に考える必要あり。

# Trackingの副作用

- 1389行目の`SetLastMapChange`
- `TrackReferenceKeyFrame`内
  - 2186~2204行目のループ内での`MapPoint`に対する変更
- `TrackWithMotionModel`内
  - 2337~2354行目のループ内での`MapPoint`に対する変更
- `TrackLocalMap`内
  - Optimizerの関数に渡しているFrameが保持するMapPoints
- 1506行目の`CreateMapInAtlas`
- `mpSystem->ResetActiveMap`によってAtlasに変更がかかる？

# InitializeIMUにおけるInertialBA1とInertialBA2の意味

以下の記述がある。[1]

> Our previous work [3] shows that this results in large unpredictable errors,
> that can be corrected by adding two rounds of VisualInertial Bundle Adjustment (VI-BA),
> together with two tests to detect and discard bad initializations.

どうやらある程度大きいエラーを修正するにはBAを2回行うといいらしい。

# IMU initializationとは

以下のようなパラメータを推定すること

- スケール
- 重力の向き
- 初期速度
- 加速度計とジャイロスコープのバイアス

そのための手法は主にjointなものとdisjointなものに分けられる。

- joint
  - IMUの情報とカメラの情報を推定する方程式を立てている。
- disjoint
  - 単眼カメラから得られた軌跡はスケールを除いて正確であると仮定し、その情報を下にIMUの情報を最適化する。

ORB-SLAM3ではdisjointな方法を用いている。さらに、既存の手法と異なりその推定を一回で行っている。

ORB-SLAM3の初期化は以下の3つのステップに分けられる。

- Visual-only MAP estimation
  - 単眼カメラのSLAMを動かして(約2秒ほど)軌跡をBAを用いて推定する。これはスケールを除いて正確であると考えられる。
  - キーフレーム間とそれらの共分散間のIMU preintegrationを計算する。[8]
- Inertial-only MAP estimation
  - IMUとORB-SLAMの軌跡を推定する。
  - この段階でスケールとキーフレームの速度、重力の向き、そしてIMUのバイアスを見つける。
- Visual-inertial MAP estimation
  - 上で得られた情報を組み合わせてfull VI-BAを行う。

# Rwgの意味

重力を $g$ として、 $g = R_{wg}g_1$ となるもの。ただし $g_1 = (0, 0, G)$ で $G$は重力加速度。
[1]の式(1)から。

# Trackingのパラメータ読み込み

パラメータを読み込む際には

1. `Settings*`から持ってくる
2. 設定ファイルのパスから読み込み

と2つの選択肢があるが、2つも必要？`Settings*`からだけで良くない？

ちょっとソースコード読んでみたらやってることは同じな気がする（ファイルのパラメータから必要なパラメータを計算している手順とか）。

じつはそこら辺はいい感じに綺麗にできる気がする

# TODO

up-to-scaleをスケールを除いてと訳したが本当の意味は？

# 参考文献

- [1](https://arxiv.org/pdf/2003.05766)
