// コードブロックをいい感じにスタイリングしてくれる
#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(languages: codly-languages)
#codly(zebra-fill: none)

== 並列FRP

=== 用語

今回、FRPの基本的な説明は省略し、用語については以下のように定義する。

#table(
  columns: (auto, auto),
  inset: 6pt,
  align: horizon,
  table.header(
    [*用語*], [*意味*]
  ),
  ..(
    ..([セル], [時間に対して連続的な値を持つ値]),
    ..([ストリーム], [
        時間に対して離散的な値を持つ値\
        イベントプログラミングにおけるイベント
      ]),
    ..([時変値], [セルとストリームの総称]),
    ..([プリミティブ], [ライブラリから提供される、時変値から時変値を作り出すためのAPI一般]),
    ..([操作], [プリミティブをつかって時変値から時変値を作り出すこと]),
    ..([トランザクション], [ある時変値の変更・発火を起点とした更新処理])
  ),
)

=== 概要

現在、大本先輩が並列処理可能なFRPライブラリ(以降prf)を制作しており、
prfは基本的にSodiumと同じインタフェースと動作を提供する。
またprfはクラスタという新規の概念を追加し、そのクラスタ同士を並列に実行することができる。

=== クラスタ

prfでは時変値の依存グラフをクラスタと呼ばれるものに切り分けることができる。

以下に複数のクラスタに分割された依存グラフの例を示す。

#figure(
  image("../images/cluster-diaglam.svg"),
  caption: [
    クラスタ
  ]
)
あるトランザクションにおいて更新しなければならない時変値は、その依存グラフから求められる。
そしてprfではトランザクションによる更新処理がクラスタと各時変値の2段階になっている。

そしてprfでは以下の条件下においてクラスタ同士を並列に実行することができる。

- あるトランザクションにおいて更新するべきクラスタc1、c2があって、これらが依存関係にない場合にはc1とc2を並列に更新可能
- あるトランザクションt1とその次のトランザクションt2が在ったとき、t1による更新が終わったクラスタc1については、t1による別クラスタc2の更新が実行中でもt2によるc1の更新を開始できる。このときc2がc1に依存していても構わない。

ただしクラスターが並列に更新可能である場合であっても、prfの実装の都合上、必ずしも並列に実行されるわけではない。
これは、依存関係か否かの判定処理の計算量による問題である。

==== コードにおけるクラスタ

prfのユーザはClusterクラスを宣言することによってクラスタの切り分けを行う。

#codly(
  annotations: (
    (start: 0, end: 1, content: block(width: 16em, [暗黙的なクラスタ0])),
    (start: 3, end: 7, content: block(width: 16em, [明示的なクラスタ1])),
    (start: 9, end: 9, content: block(width: 16em, [暗黙的なクラスタ2])),
  )
)

```java
Stream<int> s1;
Stream<double> s2;

Cluster cluster1;
Stream<int> s3 = s1.map((v) => v * v);
Stream<double> s4 = s2.filter((v) => v > 10.0);
Stream<double> s5 = s1.merge(s2, (v1, v2) => v1 + v2);
cluster1.close();

Stream<String> s6 = s5.map((v) => v.toString());
```

=== グローバルセルループ

クラスタを跨いだセルループについてはグローバルセルループ（仮名）という特別なものとなる。
以下にグローバルセルループを含む依存グラフの例を示す。赤いノードがグローバルセルループで、赤い矢印はグローバルセルループの依存である。

#figure(
  image("../images/global-cell-loop.svg"),
  caption: [
    グローバルセルループ
  ]
)

グローバルセルループで接続されたクラスタ、時変値に関してはprfの動作時には依存として扱われない。
すなわち先程の図において、あるトランザクションによってクラスタ２の更新が発生した場合以下のような動作をする。

- トランザクションによってクラスタ２の更新が開始する
- c2が更新される
- クラスタ2の更新が終了する
- クラスタ0はクラスタ2に依存しないこととなっているので、クラスタ0の更新は開始しない

これによって依存関係のトランザクションの更新処理が必ず終了することを保証する。

また、これではs3の更新が行われる際にc1の新しい値使うことができないため、グローバルセルループのsnapshotプリミティブを用いることによって最新の値を取得することができる。このとき、グローバルセルループの新しい値を参照できるのは、今更新したトランザクションが終了後に新しく発生したトランザクションだけである。



