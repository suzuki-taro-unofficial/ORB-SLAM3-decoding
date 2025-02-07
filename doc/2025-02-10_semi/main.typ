#import "style.typ": style

#let title = [ORB-SLAM3 FRP化 共有会資料]
#let author = [加藤 豪, 藤原 遼, 八巻 輝星]

#show: style.with(title: title, author: author, date: "2025/02/10")

#let overall_result_figure(file, cap_str, cap) = {
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

= 前回からの変更点

= 実行結果

#overall_result_figure("res/result-kfs.csv", "KeyFrames for each dataset", <res-kfs>)
#overall_result_figure("res/result-mps.csv", "MapPoints for each dataset", <res-mps>)
#overall_result_figure("res/result-sec.csv", "Execution time each dataset", <res-sec>)
