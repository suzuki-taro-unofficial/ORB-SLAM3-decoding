## ORB-SLAM3の概要

- 画像からの特徴点抽出にはORBを使用
- MappingとTrackingが並列に行われる
- BA(バンドル調整)がリアルタイムに行われる
  - リアルタイムの意図は不明
-

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
