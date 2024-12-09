= TODO: 追記

- ORB-SLAM3についての記述を増やす
  - スレッドの切り分け
    - Trackingがメインスレッドで動くこと
    - LocalMapping, LoopClosingが別スレッドで動くこと
    - GBAが都度スレッドを起動して行われること
  - 処理の停止再開について
    - LoopClosingのマップマージング・ループとじ込み中、GBAのマップ統合処理中はLocalMappingが停止されること
      - ただしTrackingが停止しないよう要求できること
    - LoopClosingもGBA中に止まる？こと
- Atlasに関する説明
  - どちらかというとFRPの方ではなくORB-SLAM3の説明の方？
  - FRP側ではそれをどう扱うかだけ述べれば良さげ？
- 副作用周りの話を強化

