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
    - タイミングの問題？

== 削除されたMapPoint数

- キーフレーム数と消されたマップポイントの相関は見られなかった。

== TODO

- 総キーフレーム数と消されたMapPointの数の相関を見る
  - 比率がオリジナルと同じような結果であればこれは総キーフレーム数に依存していることがわかる
  - 比率勝ちがければマップポイント削除に固有の問題がある可能性がある
- MapPointのマッチングがオリジナルに比べ取れていない可能性がある
  - (図3, 4を見たときにクロテンが増えていることから)
  - マッチング処理の場所の調査と実行の判定などにさいがないか確認
  - 一個前のマップ情報を見れているか
- 動画フレーム数と処理フレーム数を見てみる
- MH04のハズレ値について調査
  - MH04,05は実行回数を増やしてみたい
- 各データの標準偏差を見てみる
- With Inertialのときの処理に変なことが起きてないか見張る

