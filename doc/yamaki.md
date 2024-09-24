# ORBSLAM概要

## Tracking

フレームごとに動作する。

### 現在把握できているTrackingの役割

- ORB特徴点の抽出
- 特徴点のマッチング
- カメラ姿勢の最適化
- IMUデータの統合
- キーフレームの作成（キーフレーム条件を満たすとき）

## LocalMapping

Trackingで作成されたキーフレームごとに動作する。

### 現在把握できているLocalMappingの役割

- 地図の作成
- 未マッチングの特徴点に対して対応付け
- 重複するキーフレームを削除

## LoopClosing

キーフレームごとに動作する。

### 現在把握できているLoopClosingの役割

- ループの探索および統合
- EssentialGraphの最適化