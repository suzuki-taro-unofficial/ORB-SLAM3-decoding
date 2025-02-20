#import "style.typ": style

#let title = [ORB-SLAM3 FRP化 共有会資料]
#let author = [加藤 豪, 藤原 遼, 八巻 輝星]

#show: style.with(title: title, author: author, date: "2025/02/20")

= 前回から調べたこと

== フレームの処理数について

- トラッキングで処理するフレームの数とデータセットにある画像の数は一致していた
  - 一部のフレームが読み取られなくなるようなことはない。

== MH04の動作について

- prfで実装したSLAMの挙動がおかしかった
  - 並列で実行すると、自己位置とキーフレームが作成される場所が異なる。
  - sendのディレイをなくすと動作がカクつく代わりに上記の挙動は発生しなくなった
    - ディレイを1msにするとカクつきが低減されて上記の挙動は発生しなかった
    - タイミングの問題？

== 削除されたMapPoint数

- キーフレーム数と消されたマップポイントの相関は見られなかった。
