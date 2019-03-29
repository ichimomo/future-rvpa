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

#g2 <- plot_yield(MSY.base,refs.all,AR=FALSE) # こちらでもまだ動きます
g2 <- plot_yield(MSY.base$trace,refs.all,AR=FALSE) 
g2 + ggtitle("図2. 漁獲量曲線とさまざまな管理基準値")

# xlimやylimを変更する場合
g2.2 <- plot_yield(MSY.base$trace,refs.all,AR=FALSE,xlim.scale=0.5,ylim.scale=1.3) 
g2.2 + ggtitle("図2. 漁獲量曲線とさまざまな管理基準値")

# yield curveの元データが欲しい場合
yield.table <- get.trace(MSY.base$trace) 
yield.table <- yield.table %>% mutate(age=as.character(age)) %>% spread(key=age,value=value) %>% arrange(ssb.mean)

# 将来予測と過去の漁獲量を追記する場合
g2.3 <- plot_yield(MSY.base$trace,refs.base,
                   future=list(future.Fcurrent,future.default),
                   past=res.pma,AR=FALSE,xlim.scale=0.4,ylim.scale=1.3)
g2.3 + ggtitle("図2. 漁獲量曲線とさまざまな管理基準値 (with 将来予測)") 

# 神戸チャート

# Btarget0として選ばれた管理基準値をベースにした神戸チャート4区分
# roll_meanで各年の値を何年分移動平均するか指定します
g3 <- plot_kobe_gg(res.pma,refs.base,roll_mean=3,category=4,
                   Blow="Btarget0",# <- Blowが重要な管理基準値になるのか不明。とりあえずBtargeと同じ値を入れておいてください
                   Btarget="Btarget0") # <- どの管理基準値を軸に使うのか指定。指定しなければ"0"マークがついた管理基準値が使われます
(g3 <- g3 + ggtitle("図3. 神戸チャート（4区分）"))

# Btarget0, Blow0, Blimit0として選ばれた管理基準値をベースにした神戸チャート6区分
# Blowを使うかどうかは不明。とりあえず6区分の一番上の境界(Blowのオプション)は"Btarget0"と、targetで使う管理基準値の名前を入れて下さい
g4 <- plot_kobe_gg(res.pma,refs.base,roll_mean=3,category=6,Blow="Btarget0")
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
                   Bban=derive_RP_value(refs.base,"Bban0")$SSB,
                   biomass.unit=10000,  # バイオマスの単位(100, 1000, or 10000トン)
                   font.size=18) # フォントサイズ
(g5 <- g5+ggtitle("図5. 現行のFとデフォルトのHCRを用いた時の将来予測\n(実線：平均値、範囲：80パーセント信頼区間)")+ylab("トン"))

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
library(formattable)
Fsakugen.table %>%  select(-stat_name) %>%
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

catch.aav.table %>% select(-stat_name) %>%
    formattable::formattable(list(area(col=-1)~color_tile("white","olivedrab"),
                                  beta=color_tile("white","blue"),
                                  HCR_name=formatter("span", 
                                                     style = ~ style(color = ifelse(HCR_name == "Btarget0-Blimit0-Bban0" & beta==0.8, "red", "black")))))


