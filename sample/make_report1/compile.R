library(knitr)
library(rmarkdown)

# rmdのコンパイル用のメモ
render("1do_MSYestimation.rmd",output_file="1do_MSYestimation.md")
knitr::purl("1do_MSYestimation.rmd")

#
opts_chunk$set(echo=FALSE)
render("2make_report.rmd",output_file="../../docs/make_report.html",
       output_format="html_document")

opts_chunk$set(echo=TRUE)
knitr::purl("2make_report.rmd")
# echo=TRUEにしてから
render("2make_report.rmd",
       output_format="md_document")
