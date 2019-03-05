## ---- echo=FALSE---------------------------------------------------------

## Global options
library(rmarkdown)
library(knitr)
options(max.print="75")
opts_chunk$set(prompt=FALSE,
               tidy=TRUE,
               comment=NA,
               message=FALSE,
               warning=FALSE)


## ------------------------------------------------------------------------
library(tidyverse)
# 再生産関係のプロット
g1 <- SRplot_gg(SRmodel.base)
g1 + ggtitle("図1. 再生産関係")

## ------------------------------------------------------------------------
# 管理基準値表
make_RP_table(refs.base)

# 漁獲量曲線
# 再生産関係をもとにしたyield curveと管理基準値のプロット。
# 計算した全管理基準値を示す場合にはrefs.allを、厳選したものだけを示す場合にはrefs.baseを引数に使ってください
# AR==TRUEにするとARありの結果もプロットされます
g2 <- plot_yield(MSY.base,refs.all,AR=FALSE) 
g2 + ggtitle("図2. 漁獲量曲線とさまざまな管理基準値")

# 神戸チャート

# Btarget0として選ばれた管理基準値をベースにした神戸チャート4区分
# roll_meanで各年の値を何年分移動平均するか指定します
g3 <- plot_kobe_gg(res.pma,refs.base,roll_mean=3,category=4,
                   Btarget=="Btarget0") # <- どの管理基準値を軸に使うのか指定。指定しなければ"0"マークがついた管理基準値が使われます
(g3 <- g3 + ggtitle("図3. 神戸チャート（4区分）"))

# Btarget0, Blow0, Blimit0として選ばれた管理基準値をベースにした神戸チャート4区分
g4 <- plot_kobe_gg(res.pma,refs.base,roll_mean=3,category=6)
(g4 <- g4 + ggtitle("図4. 神戸チャート（6区分）"))


## ------------------------------------------------------------------------
# 親魚資源量と漁獲量の時系列の図示
g5 <- plot_futures(res.pma, # vpaの結果
                   list(future.Fcurrent,future.default), # 将来予測結果
                   future.name=c("現行のF","HCRによるF"),
                   CI_range=c(0.1,0.9),
                   maxyear=2045,
                   Btarget=derive_RP_value(refs.base,"Btarget0")$SSB,
                   Blimit=derive_RP_value(refs.base,"Blimit0")$SSB,
                   Blow=derive_RP_value(refs.base,"Blow0")$SSB,
                   Bban=derive_RP_value(refs.base,"Bban0")$SSB)
(g5 <- g5+ggtitle("図5. 現行のFとデフォルトのHCRを用いた時の将来予測\n(実線：平均値、範囲：90パーセント信頼区間)")+ylab("トン"))

g6 <- plot_Fcurrent(res.pma,year.range=2000:2017)
(g6 <- g6+ggtitle("図6. MSY計算とHCRで仮定されたcurrent Fの定義（赤線)"))


## ------------------------------------------------------------------------
library(formattable)
catch.table %>%  select(-stat_name) %>%
    formattable::formattable(list(area(col=-1)~color_tile("white","steelblue"),
                                  beta=color_tile("white","blue"),
                                  HCR_name=formatter("span", 
    style = ~ style(color = ifelse(HCR_name == "Btarget0-Blimit0-Bban0" & beta==0.8, "red", "black")))))

## ------------------------------------------------------------------------
ssbtarget.table %>% select(-stat_name) %>%
    formattable::formattable(list(area(col=-1)~color_tile("white","olivedrab"),
                                  beta=color_tile("white","blue"),
                                  HCR_name=formatter("span", 
                                                     style = ~ style(color = ifelse(HCR_name == "Btarget0-Blimit0-Bban0" & beta==0.8, "red", "black")))))


## ------------------------------------------------------------------------

ssblow.table %>% select(-stat_name) %>%
    formattable::formattable(list(area(col=-1)~color_tile("white","olivedrab"),
                                  beta=color_tile("white","blue"),
                                  HCR_name=formatter("span", 
                                                     style = ~ style(color = ifelse(HCR_name == "Btarget0-Blimit0-Bban0" & beta==0.8, "red", "black")))))


## ------------------------------------------------------------------------

ssblimit.table %>% select(-stat_name) %>%
    formattable::formattable(list(area(col=-1)~color_tile("white","olivedrab"),
                                  beta=color_tile("white","blue"),
                                  HCR_name=formatter("span", 
                                                     style = ~ style(color = ifelse(HCR_name == "Btarget0-Blimit0-Bban0" & beta==0.8, "red", "black")))))


## ------------------------------------------------------------------------

ssblimit.table %>% select(-stat_name) %>%
    formattable::formattable(list(area(col=-1)~color_tile("white","olivedrab"),
                                  beta=color_tile("white","blue"),
                                  HCR_name=formatter("span", 
                                                     style = ~ style(color = ifelse(HCR_name == "Btarget0-Blimit0-Bban0" & beta==0.8, "red", "black")))))


## ------------------------------------------------------------------------

ssbmin.table %>% select(-stat_name) %>%
    formattable::formattable(list(area(col=-1)~color_tile("white","olivedrab"),
                                  beta=color_tile("white","blue"),
                                  HCR_name=formatter("span", 
                                                     style = ~ style(color = ifelse(HCR_name == "Btarget0-Blimit0-Bban0" & beta==0.8, "red", "black")))))




## ------------------------------------------------------------------------


