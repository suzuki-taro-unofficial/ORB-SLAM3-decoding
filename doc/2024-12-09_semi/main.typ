#import "style.typ": style, title_page

#let title = [ORB-SLAM3 FRP化 共有会資料]
#let author = [加藤 豪, 藤原 遼, 八巻 輝星]

#show: style.with(title: title)
#title_page(title: title, author: author)

#include "prerequisite-knowledge/main.typ"

= 今回の実装方針

今回のORB-SLAM3の並列FPRによる実装において大前提となる方針について簡単に述べる。

今回我々は、以下の方針で実装を進めている

+ LocalMapping、LoopClosingの動作フロー全般をFRPに置き換える
+ Trackingの動作フローは置き換えない
+ Optimizerなどの数値計算部分は置き換えない
+ 内部で扱われる、Atlas、KeyFrame、Map、MapPointなどのデータ構造について副作用を許す

我々としてはORB-SLAM3のFRP化を目指しているため、1でできる限りのネットワーク構築を目指している。
2に関しては、Trackingには3D点の復元など我々の知識では扱えない部分が多く存在すること、実装量の削減のためなどいくつかの理由で実装を行わない方針となった。
3に関しても実装量の削減のためや、副作用が多く存在しFRP化が難しいなどの理由で実装を行わない方針となった。
4に関しては元の並列処理において複数スレッド間で同時に参照・編集を行っていた部分であるため、ここの副作用を取り除いてしまうとORB-SLAM3として正常な動作が望めないと判断し副作用を残す方針となった。

= ネットワークの主な記法

#align(center)[
  #grid(
    columns: 3,
    [#figure(
      image("images/cell.png"),
      caption: [
        セル
      ]
    )<cell>],
    [#figure(
      image("images/stream.png"),
      caption: [
        ストリーム
      ]
    )<stream>],
    [#figure(
      image("images/ConnectFRPAndNonFRP.png"),
      caption: [
        FRPと外界の繋がり
      ]
    )<conn-frp-non-frp>]
  )
]

ネットワークを図として記述する際にセルやストリームを区別することは重要である。
この報告書ではセルを白抜きのひし形 (@cell)、
ストリームを黒塗りの矢印 (@stream) として記述する。

また、本実装ではFRPとそうでない部分をつなげる必要があり、それを図に明記するため
繋がりを点線の矢印 (@conn-frp-non-frp) で記述する。

#include "system-overview.typ"

#include "each-module-detail/main.typ"
