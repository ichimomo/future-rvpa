## ---- echo=FALSE---------------------------------------------------------

## Global options
library(rmarkdown)
library(knitr)
options(max.print="75")
opts_chunk$set(echo=FALSE,
               prompt=FALSE,
               tidy=TRUE,
               comment=NA,
               message=FALSE,
               warning=FALSE)


## ----data-read-----------------------------------------------------------
# 関数の読み込み →  warningまたは「警告」が出るかもしれませんが，その後動いていれば問題ありません
source("../../rvpa1.9.2.r")
source("../../future2.1.r")
source("../../utilities.r",encoding="UTF-8") # ggplotを使ったグラフ作成用の関数

# ライブラリの読み込み
library(tidyverse) # うまくインストールできない場合、最新のRを使ってください

# データの読み込み
caa <- read.csv("caa_pma.csv",row.names=1)
waa <- read.csv("waa_pma.csv",row.names=1)
maa <- read.csv("maa_pma.csv",row.names=1)
dat <- data.handler(caa=caa, waa=waa, maa=maa, M=0.5)
names(dat)

## ----vpa-----------------------------------------------------------------
# VPAによる資源量推定
res.pma <- vpa(dat,fc.year=2015:2017,
               tf.year = 2008:2010,
               term.F="max",stat.tf="mean",Pope=TRUE,
               tune=FALSE,p.init=1.0)

## ------------------------------------------------------------------------
res.pma$Fc.at.age # 将来予測やMSY計算で使うcurrent Fを確認してプロットする
plot(res.pma$Fc.at.age,type="b",xlab="Age",ylab="F",ylim=c(0,max(res.pma$Fc.at.age)))

# 独自のFc.at.ageを使いたい場合は以下のようにここで指定する
# res.pma$Fc.at.age[] <- c(1,1,2,2)

## ----SRdata--------------------------------------------------------------
# VPA結果を使って再生産データを作る
SRdata <- get.SRdata(res.pma, years=1988:2016) 
head(SRdata)

## モデルのフィット(網羅的に試しています)
# 網羅的なパラメータ設定
SRmodel.list <- expand.grid(SR.rel = c("HS","BH","RI"), AR.type = c(0, 1), L.type = c("L1", "L2"))
SR.list <- list()
for (i in 1:nrow(SRmodel.list)) {
    SR.list[[i]] <- fit.SR(SRdata, SR = SRmodel.list$SR.rel[i], method = SRmodel.list$L.type[i], 
        AR = SRmodel.list$AR.type[i], hessian = FALSE)
}

SRmodel.list$AICc <- sapply(SR.list, function(x) x$AICc)
SRmodel.list$delta.AIC <- SRmodel.list$AICc - min(SRmodel.list$AICc)
SR.list <- SR.list[order(SRmodel.list$AICc)]  # AICの小さい順に並べたもの
(SRmodel.list <- SRmodel.list[order(SRmodel.list$AICc), ]) # 結果

SRmodel.base <- SR.list[[1]] # AIC最小モデルを今後使っていく

## ----future.vpa, fig.cap="図：is.plot=TRUEで表示される図．Fcurrentでの将来予測。資源量(Biomass)，親魚資源量(SSB), 漁獲量(Catch)の時系列．決定論的将来予測（Deterministic），平均値（Mean），中央値(Median)，80％信頼区間を表示"----
future.Fcurrent <- future.vpa(res.pma,
                      multi=1,
                      nyear=50, # 将来予測の年数
                      start.year=2018, # 将来予測の開始年
                      N=100, # 確率的計算の繰り返し回数=>実際の計算では1000~5000回くらいやってください
                      ABC.year=2019, # ABCを計算する年
                      waa.year=2015:2017, # 生物パラメータの参照年
                      maa.year=2015:2017,
                      M.year=2015:2017,
                      is.plot=TRUE, # 結果をプロットするかどうか
                      seed=1,
                      silent=FALSE,
                      recfunc=HS.recAR, # 再生産関係の関数
                      # recfuncに対する引数
                      rec.arg=list(a=SRmodel.base$pars$a,b=SRmodel.base$pars$b,
                                   rho=SRmodel.base$pars$rho, # ここではrho=0なので指定しなくてもOK
                                   sd=SRmodel.base$pars$sd,resid=SRmodel.base$resid))

## ----msy, fig.cap="**図：est.MSYのis.plot=TRUEで計算完了時に表示される図．Fの強さに対する平衡状態の親魚資源量（左）と漁獲量（右）．推定された管理基準値も表示．**", fig.height=5, eval=TRUE----

# MSY管理基準値の計算
MSY.base <- est.MSY(res.pma, # VPAの計算結果
                 future.Fcurrent$input, # 将来予測で使用した引数
                 resid.year=0, # ARありの場合、最近何年分の残差を平均するかをここで指定する。ARありの設定を反映させたい場合必ずここを１以上とすること（とりあえず１としておいてください）。
                 N=100, # 確率的計算の繰り返し回数=>実際の計算では1000~5000回くらいやってください
                 calc.yieldcurve=TRUE,
                 PGY=c(0.95,0.9,0.6,0.1), # 計算したいPGYレベル。上限と下限の両方が計算される
                 onlylower.pgy=FALSE, # TRUEにするとPGYレベルの上限は計算しない（計算時間の節約になる）
                 B0percent=c(0.2,0.3,0.4),
                 Bempirical=c(round(tail(colSums(res.pma$ssb),n=1)),
                              round(max(colSums(res.pma$ssb))),
                              24000, # 現行Blimit
                              SRmodel.base$pars$b) # HSの折れ点
                 ) # 計算したいB0%レベル

## ----summary-------------------------------------------------------------
# 結果の表示(tibbleという形式で表示され、最初の10行以外は省略されます)
(refs.all <- MSY.base$summary_tb)

# 全データをじっくり見たい場合
# View(refs.all)


## ------------------------------------------------------------------------

# どの管理基準値をどのように定義するか、ここで指定します
refs.all$RP.definition <- NA 
refs.all$RP.definition[refs.all$RP_name=="MSY" & refs.all$AR==FALSE] <- "Btarget0"  # RP_nameがMSYでARがなしのものをBtargetとする
refs.all$RP.definition[refs.all$RP_name=="B0-20%" & refs.all$AR==FALSE] <- "Btarget1"  # たとえばBtargetの代替値をいちおう示す場合
refs.all$RP.definition[refs.all$RP_name=="PGY_0.95_lower" & refs.all$AR==FALSE] <- "Btarget2" 
refs.all$RP.definition[refs.all$RP_name=="PGY_0.9_lower" & refs.all$AR==FALSE] <- "Blow0"
refs.all$RP.definition[refs.all$RP_name=="PGY_0.6_lower" & refs.all$AR==FALSE] <- "Blimit0"
refs.all$RP.definition[refs.all$RP_name=="PGY_0.1_lower" & refs.all$AR==FALSE] <- "Bban0"
refs.all$RP.definition[refs.all$RP_name=="Ben-19431" & refs.all$AR==FALSE] <- "Bcurrent"
refs.all$RP.definition[refs.all$RP_name=="Ben-63967" & refs.all$AR==FALSE] <- "Bmax"
refs.all$RP.definition[refs.all$RP_name=="Ben-24000" & refs.all$AR==FALSE] <- "Blimit1"
refs.all$RP.definition[refs.all$RP_name=="Ben-51882" & refs.all$AR==FALSE] <- "B_HS"

# 定義した結果を見る
refs.all %>% select(RP_name,RP.definition)

# refs.allの中からRP.definitionで指定された行だけを抜き出す
(refs.base <- refs.all %>%
    dplyr::filter(!is.na(RP.definition)) %>% # RP.definitionがNAでないものを抽出
    arrange(desc(SSB)) %>% # SSBを大きい順に並び替え
    select(RP.definition,RP_name,SSB,Catch,U,Fref2Fcurrent)) #　列を並び替え


## ------------------------------------------------------------------------
# デフォルトのHCRはBtarget0,Blimit0,Bban0のセットになるので、それを使って将来予測する

input.abc <- future.Fcurrent$input # Fcurrentにおける将来予測の引数をベースに将来予測します
input.abc$multi <- derive_RP_value(refs.base,"Btarget0")$Fref2Fcurrent # currentFへの乗数を"Btarget0"で指定した値に
input.abc$HCR <- list(Blim=derive_RP_value(refs.base,"Blimit0")$SSB,
                      Bban=derive_RP_value(refs.base,"Bban0")$SSB,
                      beta=0.8,year.lag=0) # BlimitはBlimit0, BbanはBban0の値
future.default <- do.call(future.vpa,input.abc) # デフォルトルールの結果→図示などに使う

## 網羅的将来予測の実施
# default
kobeII.table <- calc_kobeII_matrix(future.Fcurrent,
                         refs.base,
                         Btarget=c("Btarget0","Btarget1"), # HCRの候補として選択したい管理基準値を入れる
                         Blimit=c("Blimit0","Blimit1"),
                         beta=seq(from=0.5,to=1,by=0.1)) # betaの区分

# 例えば2017~2023,28,38年の漁獲量の表を作成する
(catch.table <- kobeII.table %>%
    dplyr::filter(year%in%c(2017:2023,2028,2038),stat=="catch") %>% # 取り出す年とラベル("catch")を選ぶ
    group_by(HCR_name,beta,year) %>%
    summarise(catch.mean=round(mean(value),  # 値の計算方法を指定（漁獲量の平均ならmean(value)）
                               -floor(log10(min(kobeII.table$value))))) %>%
    spread(key=year,value=round(catch.mean)) %>% ungroup() %>%
    arrange(HCR_name,desc(beta)) %>% # HCR_nameとbetaの順に並び替え
    mutate(stat_name="catch.mean"))

# SSB>SSBtargetとなる確率
ssbtarget.table <- kobeII.table %>%
    dplyr::filter(year%in%c(2017:2023,2028,2038),stat=="SSB") %>%
    group_by(HCR_name,beta,year) %>%
    summarise(ssb.over.target=round(100*mean(value>Btarget))) %>%
    spread(key=year,value=ssb.over.target) %>%
    ungroup() %>%
    arrange(HCR_name,desc(beta))%>%
    mutate(stat_name="Pr(SSB>SSBtarget)")

# SSB>SSBlow(=高位水準)となる確率
ssblow.table <- kobeII.table %>%
    dplyr::filter(year%in%c(2017:2023,2028,2038),stat=="SSB") %>%
    group_by(HCR_name,beta,year) %>%
    summarise(ssb.over.target=round(100*mean(value>Blow))) %>%
    spread(key=year,value=ssb.over.target)%>%
    ungroup() %>%
    arrange(HCR_name,desc(beta))%>%
    mutate(stat_name="Pr(SSB>SSBlow)")

# SSB>SSBlimとなる確率
ssblimit.table <- kobeII.table %>%
    dplyr::filter(year%in%c(2017:2023,2028,2038),stat=="SSB") %>%
    group_by(HCR_name,beta,year) %>%
    summarise(ssb.over.target=round(100*mean(value>Blimit))) %>%
    spread(key=year,value=ssb.over.target)%>%
    ungroup() %>%
    arrange(HCR_name,desc(beta))%>%
    mutate(stat_name="Pr(SSB>SSBlim)")

# SSB>SSBmin(過去最低親魚量を上回る確率)
ssb.min <- min(unlist(colSums(res.pma$ssb)))
ssbmin.table <- kobeII.table %>%
    dplyr::filter(year%in%c(2017:2023,2028,2038),stat=="SSB") %>%
    group_by(HCR_name,beta,year) %>%
    summarise(ssb.over.target=round(100*mean(value>ssb.min))) %>%
    spread(key=year,value=ssb.over.target)%>%
    ungroup() %>%
    arrange(HCR_name,desc(beta))%>%
    mutate(stat_name="Pr(SSB>SSBlim)")

## csvファイルに一括して出力する場合
all.table <- bind_rows(catch.table,
                       ssbtarget.table,
                       ssblow.table,
                       ssblimit.table,
                       ssbmin.table)
write.csv(all.table,file="all.table.csv")

## ------------------------------------------------------------------------
# future.default/calc_kobeII_matrixの計算時に以下のように指定する

# 将来予測
input.abc.yearlag <- input.abc
input.abc.yearlag$HCR <- list(Blim=derive_RP_value(refs.base,"Blimit0")$SSB,
                      Bban=derive_RP_value(refs.base,"Bban0")$SSB,
                      beta=0.8,year.lag=-2) # year.lag=-2と設定してSSB参照年を調整する
future.default.yearlag <- do.call(future.vpa,input.abc.yearlag)

# alpha(=beta * (B-Bban)/(Blim-Bban))の値の比較
# lagありの場合は2019, 2020年のαは一意に決まるが、lagなしに比べてalphaの値は小さくなる（漁獲量制限によって資源が回復する、という将来予測になっているため）。
alpha_lag <- convert_future_table(future.default.yearlag) %>% dplyr::filter(stat=="alpha") %>% mutate(lag="lagあり")
alpha_nolag <- convert_future_table(future.default)       %>% dplyr::filter(stat=="alpha") %>% mutate(lag="lagなし")
alpha_result <- bind_rows(alpha_lag,alpha_nolag)
alpha_result %>% dplyr::filter(year<2025) %>% group_by(year) %>%
    ggplot() +
    geom_boxplot(aes(x=factor(year),y=value)) +
    facet_wrap(.~lag) + theme_bw() + ylab("alpha") + xlab("Year")

# kobeII計算; year.lagというオプションをつけてください
kobeII.table.yearlag <- calc_kobeII_matrix(future.Fcurrent,
                         refs.base,
                         Btarget=c("Btarget0","Btarget1"), 
                         Blimit=c("Blimit0","Blimit1"),year.lag=-2,
                         beta=seq(from=0.5,to=1,by=0.1)) # betaの区分

# パフォーマンスの比較
# 漁獲量
(catch.table.yearlag <- kobeII.table.yearlag %>%
    dplyr::filter(year%in%c(2017:2023,2028,2038),stat=="catch") %>% # 取り出す年とラベル("catch")を選ぶ
    group_by(HCR_name,beta,year) %>%
    summarise(catch.mean=round(mean(value),  # 値の計算方法を指定（漁獲量の平均ならmean(value)）
                               -floor(log10(min(kobeII.table$value))))) %>%
    spread(key=year,value=round(catch.mean)) %>% ungroup() %>%
    arrange(HCR_name,desc(beta)) %>% # HCR_nameとbetaの順に並び替え
    mutate(stat_name="catch.mean"))

# デフォルトオプションの場合の漁獲量の比較(lagあり/lagなし)
catch.table.yearlag[3,3:10]/catch.table[3,3:10]

# targetを超す確率
ssbtarget.table.yearlag <- kobeII.table.yearlag %>%
    dplyr::filter(year%in%c(2017:2023,2028,2038),stat=="SSB") %>%
    group_by(HCR_name,beta,year) %>%
    summarise(ssb.over.target=round(100*mean(value>Btarget))) %>%
    spread(key=year,value=ssb.over.target) %>%
    ungroup() %>%
    arrange(HCR_name,desc(beta))%>%
    mutate(stat_name="Pr(SSB>SSBtarget)")

# デフォルトオプションの場合の漁獲量の比較(lagあり/lagなし) => lagありのほうが回復が１年早い
rbind(ssbtarget.table.yearlag[3,3:10],ssbtarget.table[3,3:10])




