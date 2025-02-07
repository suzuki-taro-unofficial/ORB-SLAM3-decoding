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
