#import "style.typ": style

#let title = [ORB-SLAM3 FRP化 共有会資料]
#let author = [加藤 豪, 藤原 遼, 八巻 輝星]

#show: style.with(title: title, author: author, date: "2025/02/10")

#let result_figure(file, cap_str, cap) = {
  [
    #figure(
      table(
        columns: 7,
        table.cell(rowspan: 2, align: horizon, [dataset]),
        [Original], [prf serial], [prf parallel], [Original], [prf serial], [prf parallel],
        table.cell(colspan: 3, [No Inertial]),
        table.cell(colspan: 3, [With Inertial]),
        ..csv(file).flatten()
      ),
      caption: [#cap_str],
    ) #cap
  ]
}

= 実行結果

#result_figure("res/result-kfs.csv", "KeyFrames for each dataset", <res-kfs>)
#result_figure("res/result-mps.csv", "MapPoints for each dataset", <res-mps>)
#result_figure("res/result-sec.csv", "Execution time each dataset", <res-sec>)

#result_figure("res/result-lm-executed-times.csv", "LocalMappingの実行回数", <res-lm-executed-times>)
#result_figure("res/result-kfremoved.csv", "Removed KeyFrames", <res-removed-kfs>)
#result_figure("res/result-mpremoved.csv", "Removed MapPointss", <res-removed-mps>)
#result_figure("res/result-lm-time-ave.csv", "LocalMappingの平均実行時間", <res-lm-time-ave>)
#result_figure("res/result-lm-time-sum.csv", "LocalMappingの総実行時間", <res-lm-time-sum>)

#result_figure("res/result-loops.csv", "Loopの検出回数", <res-lc-loops>)
#result_figure("res/result-merges.csv", "Mergeの検出回数", <res-lc-merges>)

#figure(
  image("res/V101-noInertial-original.png"),
  caption:[
    originalが生成した地図(IMU無し)
  ]
)

#figure(
  image("res/V101-noInertial-prf.jpg"),
  caption:[
    prfが生成した地図(IMU無し)
  ]
)


#figure(
  image("res/V101-inertial-original.jpg"),
  caption:[
    originalが生成した地図(IMUあり)
  ]
)

#figure(
  image("res/V101-inertial-prf.jpg"),
  caption:[
    prfが生成した地図(IMUあり)
  ]
)

= 実行結果から分かること

== 全体

- 並列実行はうまく行われていそう
  - 各モジュールを直列に動作させた場合と並列に動作させた場合を比べると、並列に動作させた場合のほうが平均して10から20秒ほど早い
  - 一部のデータセットで直列のほうが早い場合があったが、原因は不明
  - 挙動が安定しないので、悪い動作を引き続けた可能性がある
- 最終的なキーフレームの数が多くなるケースが多い
  - 基本的にオリジナルと同じかそれ以上のキーフレーム数になる
- 生成された地図を見比べると
  - MapPointがoriginalと同じように生成されている。
  - Graphの量がやや少ない。

== LocalMapping

LocalMappingの実行回数（キューからデータを取り出した回数）がオリジナルよりも少ないケースが多い。
取り出した回数はキューに入れられた回数に一致していたので、そもそもトラッキングで作成されているキーフレーム数が減っている。
原因は不明。

KeyFrameCullingによって削除されるKeyFrameの数がオリジナルよりも少ないケースが多い。
これはKeyFrameCullingにおいて探索範囲となるCovisivilityGraphが、オリジナルよりも接続が少ないことに起因している可能性がある。
また総キーフレーム数も少ないためその影響もあると思われる。

== LoopClosing

- LoopClosingのループ、マージの検出回数の検出回数は若干のブレが見られた。
  - キーフレームの量や質の差などにより、差が生まれたと考えている。
  - ループを検出すべきデータセット（Vから始まるデータセット）でループを検出できている。
