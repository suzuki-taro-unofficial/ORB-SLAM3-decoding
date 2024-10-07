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

# 参考文献

- [1](https://arxiv.org/pdf/2003.05766)
