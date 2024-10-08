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

## 雑記

# やらなきゃいけないこと

解読
FRP化の設計と適用範囲、方法の考察
実装

この内、１が２に依存、３と２が相互依存している？
ここまで１のみについてやってきたが、２について考えながら１をやってくれと言われたので。
（FRP化しない部分は読まないなどそういう意味で）

# 段階的な実装の方法について考える

- メンバ変数を暗黙的な引数にしているのを明示的な引数へ変える
  - mapで包むだけでFRP可が可能な状態にする
- 関数を切りける
  - mapなどで扱いやすいサイズにする
  - 中身の変更までしない部分は触らない？
    - ほぼすべてのメンバ関数が副作用を持っているため、副作用を引数に移動する作業はほぼすべての関数に必要
    - その際に変更しやすいサイズにしておく？
  - 結局読み取り及び書き込みを行うメンバ変数の把握は必要だし、引数化する場合ネスト先の関数の引数までネスト元で受け取る必要がある
  - そもそもメンバ変数として保つ必要があるかどうかについて考えるべき？
    - グローバル変数と言い換えてもいい
    - 自身のメンバ関数を呼び出す際には引数を渡さない縛りが入っていて、そのためにメンバ変数にされているものが多そう
    - 実際外部からの入力以外では引数にとっていなさそう
    - 呼び出し元で計算したものを伝える手段としてメンバ変数を使っており、これらは状態ではない
    - 状態と計算結果のメモを分ける作業が必要
      - FRPの性質上必須（Cellとして扱うかの判断）
      - 状態とメモの分け方について考えておく必要あり
  - あとは前処理と中身が切り分けられているのが、知識の漏れ出しではないのかについても考えるべき
    - 少なくとも前処理を関数化したほうがいい部分は大いにある

頭ゴチャゴチャしたから一旦リセット。

もうちょっと大域的に分けて

- 現コードのリファクタリング
- FRP化

っていうのでいいかも。

現コードのリファクタリングは

- 状態以外のメンバ変数をローカル変数などに変更
- （必要なら）処理の切り分け
- （必要なら）モジュール（クラス）やファイルの切り分け

その他諸々。必須なのは１番上だけ。

他にも変数名とかをまともにしたいなという気持ちがないでもないが、元コードと対応付けが取れる状態の方が良い？
大改築が入って誤差みたいなことになりそうw

FRP化は

- SystemのFRP化（ルートロジック）
- Tracking、LocalMapping、LoopClosingのFRP化（モジュール）
- AtlasのFRP化（ストア）

が必要そうになっていて、全てのモジュールがストアの読み取り・書き込みをできるように工夫する必要があり、この実現が一番難しそう。
各モジュール内のFRP化は、上記の仕組みができている前提で設計・実装することは可能？
仕組みが各モジュールの実装に影響を与えるのであれば、ある程度形になるまでトップダウンに制作したい。
ルートとストアと、モジュールのインタフェース部分だけは完成しないと動作テストはできないから期にしなくていい？

というか、似たような構成と仕組みを持った簡単なアプリケーションを作ってみるのが良さそうか？
2つなり３つなり、複数のモジュールがそれぞれ別々のトランザクションで稼働していて、全てが同じストアを読み取り・書き込みできる、簡単なアプリケーション。

追加後に内容編集可能なToDoListを複数人がいじる。これを１画面上に全員分表示して、Aさんの方で編集するとBさんの方でも確認ができる。

っていうのが思いつく中で一番簡単な実装になるかな？

こう考えると何もむずくなさそうに聞こえるんだが、ORB SLAMでむずそうに見えてるのはもっと別の場所？
あぁ…KF、Map、MPが相互参照している状態で消したり追加したりしなきゃいけないからだ….。
もっというならKFとMPが多対多なのも拍車をかけそう…

# Reやらなきゃいけないこと

改めてやらなきゃいけないことは

- 解読
  - コードの解読
  - 論文のリサーチ（pogyomoが読んでみたいな、もうちょっと踏み込んだ部分それぞれに対しての論文があるみたいなのでそれをちょっと見てみるべきかなと
- FRP化の設計と適用範囲、方法の考察
  - テストアプリの制作（さっきのToDoListみたいなの）
- 実装
  - 現コードのリファクタリング
    - 状態以外のメンバ変数をローカル変数などに変更
    - （必要なら）処理の切り分け
    - （必要なら）モジュール（クラス）やファイルの切り分け
  - FRP化
    - SystemのFRP化（ルートロジック）
    - Tracking、LocalMapping、LoopClosingのFRP化（モジュール）
    - AtlasのFRP化（ストア）

今やらなきゃいけないことは １メインと２なんだが、気持ちが２メインと３寄りに揺れている。
理由は単純明快で、3.aがやりたすぎるのと１が嫌すぎること。

ただ流石に３は気が早いし、教授に進捗報告してもそう言われるのは明らか。

一旦２に振り切ってしまう？

- テストアプリの制作
  - やるなら１日とかでぱっと終わらせる
- それを踏まえて、ORB SLAMをどうしてくれようか考えながら解読
  - Atlas周りとか。肝になるのはストア周りになりそうだから。

１に重点を置くときは3.aも並列処理していくのはあり？
完全に並列処理するのはやめたほうがいいか？少なくとも大筋理解してからやらないとバカやりそう。まぁ、やろうとしてもそもそもできんか。

とりま3.aが怖いのは、リファクタリングのつもりがぶっ壊しましたーってやつ。それをやるのは明確に実装期にはいるまで取っておきたい気持ち。
