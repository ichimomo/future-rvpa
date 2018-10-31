## ---- echo=FALSE---------------------------------------------------------
library(rmdformats)
## Global options
options(max.print="75")
opts_chunk$set(echo=TRUE,
#                     cache=TRUE,
               prompt=FALSE,
               tidy=TRUE,
               comment=NA,
               message=FALSE,
               warning=FALSE)
#opts_knit$set(width=75)


par(mar=c(4,4,3,1))

## ----data-read-----------------------------------------------------------
# 関数の読み込み →  warningまたは「警告」が出るかもしれませんが，その後動いていれば問題ありません
source("../../rvpa1.9.2.r")
source("../../future2.1.r")

# データの読み込み
caa <- read.csv("caa_pma.csv",row.names=1)
waa <- read.csv("waa_pma.csv",row.names=1)
maa <- read.csv("maa_pma.csv",row.names=1)
dat <- data.handler(caa=caa, waa=waa, maa=maa, M=0.5)
names(dat)


## ----vpa-----------------------------------------------------------------
# VPAによる資源量推定
res.pma <- vpa(dat,fc.year=2009:2011,rec=585,rec.year=2011,tf.year = 2008:2010,
               term.F="max",stat.tf="mean",Pope=TRUE,tune=FALSE,p.init=1.0)

## ------------------------------------------------------------------------
res.pma$Fc.at.age # 将来予測やMSY計算で使うcurrent F (fc.yearのオプションでいつのFの平均かが指定される)
plot(res.pma$Fc.at.age,type="b",xlab="Age",ylab="F",ylim=c(0,max(res.pma$Fc.at.age)))

## ------------------------------------------------------------------------
 res.pma2 <- read.vpa("out.csv")

## ----ref.F, fig.cap="**図：plot=TRUEで表示されるYPR, SPR曲線**"----------
byear <- 2009:2011 # 生物パラメータを平均する期間を2009年から2011年とする
rres.pma <- ref.F(res.pma, # VPAの計算結果
                  waa.year=byear, maa.year=byear, M.year=byear, # weight at age, maturity at age, Mは2009から2011年までの平均とする
                  rps.year=2000:2011, # Fmedを計算するときに用いるRPSの範囲
                  max.age=Inf, # SPR計算で仮定する年齢の最大値 
                  pSPR=c(10,20,30,35,40), # F_%SPRを計算するときに，何パーセントのSPRを計算するか
                  Fspr.init=1)

## ----ref.F2--------------------------------------------------------------
rres.pma$summary

## ----SRdata--------------------------------------------------------------
# VPA結果を使って再生産データを作る
SRdata <- get.SRdata(res.pma)
head(SRdata)

## ------------------------------------------------------------------------
# SSBとRのデータだけを持っている場合
SRdata0 <- get.SRdata(R.dat=exp(rnorm(10)),SSB.dat=exp(rnorm(10)))
# 特定の期間のデータだけを使う場合
SRdata0 <- get.SRdata(res.pma,years=1990:2000) 

## ----SRfit---------------------------------------------------------------
HS.par0 <- fit.SR(SRdata,SR="HS",method="L2",AR=0,hessian=FALSE)
HS.par1 <- fit.SR(SRdata,SR="HS",method="L2",AR=1,hessian=FALSE)
BH.par0 <- fit.SR(SRdata,SR="BH",method="L2",AR=0,hessian=FALSE)
BH.par1 <- fit.SR(SRdata,SR="BH",method="L2",AR=1,hessian=FALSE)
RI.par0 <- fit.SR(SRdata,SR="RI",method="L2",AR=0,hessian=FALSE)
RI.par1 <- fit.SR(SRdata,SR="RI",method="L2",AR=1,hessian=FALSE)
c(HS.par0$AICc,HS.par1$AICc,BH.par0$AICc,BH.par1$AICc,RI.par0$AICc,RI.par1$AICc)

## ---- fig.cap="図：**観測値（○）に対する再生産関係式．plot=赤がHS，緑と青がBH, RIだが両者はほとんど重なっていて見えない**"----
plot.SRdata(SRdata)
points(HS.par0$pred$SSB,HS.par0$pred$R,col=2,type="l",lwd=3)
points(BH.par0$pred$SSB,BH.par0$pred$R,col=3,type="l",lwd=3)    
points(RI.par0$pred$SSB,RI.par0$pred$R,col=4,type="l",lwd=3)

## ---- eval=FALSE---------------------------------------------------------
## # install.packages("TMB")　#TMBがインストールされてなければ
## library(TMB)
## compile("autoregressiveSR2.cpp")
## dyn.load(dynlib("autoregressiveSR2"))
## HS.par11 <- fit.SR(SRdata,SR="HS",method="L2",AR=1,TMB=TRUE) #marginal likelihood

## ----future.vpa, fig.cap="**図：is.plot=TRUEで表示される図．資源量(Biomass)，親魚資源量(SSB), 漁獲量(Catch)の時系列．決定論的将来予測（Deterministic），平均値（Mean），中央値(Median)，80％信頼区間を表示**"----
fres.HS <- future.vpa(res.pma,
                      multi=1,
                      nyear=50, # 将来予測の年数
                      start.year=2012, # 将来予測の開始年
                      N=100, # 確率的計算の繰り返し回数
                      ABC.year=2013, # ABCを計算する年
                      waa.year=2009:2011, # 生物パラメータの参照年
                      maa.year=2009:2011,
                      M.year=2009:2011,
                      is.plot=TRUE, # 結果をプロットするかどうか
                      seed=1,
                      silent=TRUE,
                      recfunc=HS.recAR, # 再生産関係の関数
                      # recfuncに対する引数
                      rec.arg=list(a=HS.par0$pars$a,b=HS.par0$pars$b,
                                   rho=HS.par0$pars$rho, # ここではrho=0なので指定しなくてもOK
                                   sd=HS.par0$pars$sd,resid=HS.par0$resid))

## ----future.vpa2, fig.cap="**図：is.plot=TRUEで表示される図．資源量(Biomass)，親魚資源量(SSB), 漁獲量(Catch)の時系列．決定論的将来予測（Deterministic），平均値（Mean），中央値(Median)，80％信頼区間を表示**"----
fres.BH <- future.vpa(res.pma,
                      multi=1,
                      nyear=50, # 将来予測の年数
                      start.year=2012, # 将来予測の開始年
                      N=100, # 確率的計算の繰り返し回数
                      ABC.year=2013, # ABCを計算する年
                      waa.year=2009:2011, # 生物パラメータの参照年
                      maa.year=2009:2011,
                      M.year=2009:2011,
                      is.plot=TRUE, # 結果をプロットするかどうか
                      seed=1,
                      silent=TRUE,
                      recfunc=BH.recAR, # 再生産関係の関数
                      # recfuncに対する引数
                      rec.arg=list(a=BH.par0$pars$a,b=BH.par0$pars$b,
                                   sd=BH.par0$pars$sd,resid=BH.par0$resid))

## ------------------------------------------------------------------------
fres.HS2 <- do.call(future.vpa,fres.HS$input)

## ------------------------------------------------------------------------
# 引数をinput.tmpに代入．
input.tmp <- fres.HS2$input
# 引数の一部を変える
input.tmp$multi <- 0.5 # current Fの1/2で漁獲
fres.HS3 <- do.call(future.vpa,input.tmp)

## ---- fig.cap="図：plot.futures関数の結果"-------------------------------
par(mfrow=c(2,2))
plot.futures(list(fres.HS,fres.HS3),legend.text=c("F=Fcurrent","F=0.5Fcurrent"),target="SSB")
plot.futures(list(fres.HS,fres.HS3),legend.text=c("F=Fcurrent","F=0.5Fcurrent"),target="Catch")
plot.futures(list(fres.HS,fres.HS3),legend.text=c("F=Fcurrent","F=0.5Fcurrent"),target="Biomass") 

## ---- fig.cap="Frecオプションを使った場合は、結果の図に目的とする年・資源量のところに赤線が入ります。これが将来予測の結果と一致しているか確かめてください。もし一致していない場合、multi（初期値）かFrecのオプションのFrangeを指定してやり直してください"----
# たとえば現状の資源量に維持するシナリオ
fres.currentSSB <- future.vpa(res.pma,
                      multi=0.8,
                      nyear=50, # 将来予測の年数
                      start.year=2012, # 将来予測の開始年
                      N=100, # 確率的計算の繰り返し回数
                      ABC.year=2013, # ABCを計算する年
                      waa.year=2009:2011, # 生物パラメータの参照年
                      maa.year=2009:2011,
                      M.year=2009:2011,seed=1,
                      is.plot=TRUE, # 結果をプロットするかどうか
                      Frec=list(stochastic=TRUE,future.year=2023,Blimit=rev(colSums(res.pma$ssb))[1],scenario="blimit",target.probs=50),
                      recfunc=HS.recAR, # 再生産関係の関数
                      # recfuncに対する引数
                      rec.arg=list(a=HS.par0$pars$a,b=HS.par0$pars$b,
                                   rho=HS.par0$pars$rho,                                    
                                   sd=HS.par0$pars$sd,bias.corrected=TRUE))

## ------------------------------------------------------------------------
# 残差リサンプリングによる将来予測
fres.HS4 <- future.vpa(res.pma,
                          multi=1,
                          nyear=50, # 将来予測の年数
                          start.year=2012, # 将来予測の開始年
                          N=100, # 確率的計算の繰り返し回数
                          ABC.year=2013, # ABCを計算する年
                          waa.year=2009:2011, # 生物パラメータの参照年
                          maa.year=2009:2011,
                          M.year=2009:2011,
                          is.plot=TRUE, # 結果をプロットするかどうか
                          seed=1,
                          recfunc=HS.rec, # 再生産関係の関数（HS.rec=Hockey-stick)                                
                          rec.arg=list(a=HS.par0$pars$a,b=HS.par0$pars$b,
                                       rho=HS.par0$pars$rho,
                                       sd=HS.par0$pars$sd,bias.correction=TRUE,
                                       resample=TRUE,resid=HS.par0$resid))

## ----eval=FALSE----------------------------------------------------------
## par(mfrow=c(2,2))
## plot(fres.HS$vssb[,-1],fres.HS$naa[1,,-1],xlab="SSB",ylab="Recruits")
## plot(fres.HS4$vssb[,-1],fres.HS4$naa[1,,-1],xlab="SSB",ylab="Recruits")
## plot.futures(list(fres.HS,fres.HS4)) # 両者の比較

## ------------------------------------------------------------------------
lm.res <- plot.waa(res.pma) # weight at ageが資源尾数の関数になっているかどうか，確認してみる．この例の場合は特に有意な関係はない
# lm.resの中に回帰した結果が年齢分だけ入っています
fres.HS6 <- fres.HS
fres.HS6$input$waa.fun <- TRUE
fres.HS6$input$N <- 1000
fres.HS6 <- do.call(future.vpa, fres.HS6$input)

## ----msy, fig.cap="**図：est.MSYのis.plot=TRUEで計算完了時に表示される図．Fの強さに対する平衡状態の親魚資源量（左）と漁獲量（右）．推定された管理基準値も表示．**", fig.height=5----

# MSY管理基準値の計算
MSY.HS <- est.MSY(res.pma, # VPAの計算結果
                 fres.HS$input, # 将来予測で使用した引数
#                 nyear=NULL, # 何年計算するかは、指定しなければ関数内部で世代時間の20倍の年数を計算し、それを平衡状態とする
                 N=100, # 将来予測の年数，繰り返し回数
                 PGY=c(0.9,0.6,0.1), # 計算したいPGYレベル。上限と下限の両方が計算される
                 onlylower.pgy=FALSE, # TRUEにするとPGYレベルの上限は計算しない（計算時間の節約になる）
                 B0percent=c(0.3,0.4)) # 計算したいB0%レベル

## ----summary-------------------------------------------------------------
# 結果の表示（平衡状態）
MSY.HS$summary
# 結果の表示（直近の自己相関を考慮）
MSY.HS$summaryAR

# のちの使用のために、Bmsy, Blimit, Bban, Fmsyを定義しておく
refs <- list(BmsyAR=as.numeric(MSY.HS$summaryAR$SSB[1]),
             BlimAR=as.numeric(MSY.HS$summaryAR$SSB[6]),
             BbanAR=as.numeric(MSY.HS$summaryAR$SSB[8]),
             Bmsy=as.numeric(MSY.HS$summary$SSB[1]),
             Blim=as.numeric(MSY.HS$summary$SSB[6]),
             Bban=as.numeric(MSY.HS$summary$SSB[8]),
             Fmsy=as.numeric(MSY.HS$summary$"Fref/Fcur"[1]))

## ----beta-tmp------------------------------------------------------------
beta <- calc.beta(MSY.HS$input$msy,Ftar=refs$Fmsy,Btar=refs$Bmsy,Blim=refs$Blim,Bban=refs$Bban,N=1000)

## ----abc-----------------------------------------------------------------
input.abc <- MSY.HS$input$msy # MSY計算で使った引数を使う
input.abc$N <- 1000 # 実際に計算するときは10000以上を使ってください
input.abc$HCR <- list(Blim=refs$Blim,
                      Bban=refs$Bban,
                      beta=beta)
input.abc$nyear <- 20 # ABC計算時には長期間計算する必要はない
input.abc$ABC.year <- 2013 # ここでABC.yearを設定しなおしてください
input.abc$is.plot <- TRUE
fres.abc1 <- do.call(future.vpa,input.abc)

par(mfrow=c(1,1))
hist(fres.abc1$ABC,main="distribution of ABC") # ABCの分布
ABC <- mean(fres.abc1$ABC) # 平均値をABCとする

## SSBの将来予測結果
par(mfrow=c(1,1))
plot.future(fres.abc1,what=c(FALSE,TRUE,FALSE),is.legend=TRUE,lwd=2,
            col="darkblue",N=5,label=rep(NA,3))
draw.refline(cbind(unlist(refs[c(1,1,2,3)+3]),unlist(refs[c(1,1,2,3)])),horiz=TRUE,lwd=1,scale=1)
## 漁獲量の将来予測結果
par(mfrow=c(1,1))
plot.future(fres.abc1,what=c(FALSE,FALSE,TRUE),is.legend=TRUE,lwd=2,
            col="darkblue",N=5,label=rep(NA,3))
points(fres.abc1$input$ABC.year,ABC,pch=20,col=2,cex=3)
text(fres.abc1$input$ABC.year+1,ABC,"ABC",col=2)

## 実際に、どんなFが将来予測で使われているか
boxplot(t(fres.abc1$faa[1,,]/fres.abc1$faa[1,1,]),ylab="multiplier to current F")

## ----HCR-----------------------------------------------------------------
# どんなHCRなのか書いてみる
ssb.abc <- mean(fres.abc1$vssb[rownames(fres.abc1$vssb)%in%fres.abc1$input$ABC.year,]) # ABC計算年のssbをとる
plot.HCR(beta=beta,bban=refs$Bban,blimit=refs$Blim,btarget=refs$Bmsy,lwd=2,
         xlim=c(0,refs$Bmsy*2),ssb.cur=ssb.abc,Fmsy=refs$Fmsy,yscale=0.7,scale=1000)

## ----probability---------------------------------------------------------
plot(apply(fres.abc1$vssb>refs$Bmsy,1,mean)*100,type="b",ylab="Probability",ylim=c(0,100))
points(apply(fres.abc1$vssb>refs$BmsyAR,1,mean)*100,pch=2,type="b")
points(apply(fres.abc1$vssb>refs$Blim,1,mean)*100,pch=1,col=2,type="b")
points(apply(fres.abc1$vssb>refs$BlimAR,1,mean)*100,pch=2,col=2,type="b")
abline(h=c(50,90),col=c(1,2))
legend("bottomright",col=c(1,1,2,2),title="Probs",pch=c(1,2,1,2),legend=c(">Btarget_Eq",">Btarget_AR",">Blimit_Eq",">Blimit_AR"))


## ----ref.label='data-read', eval=FALSE-----------------------------------
## NA

## ----ref.label='vpa',  eval=FALSE----------------------------------------
## NA

## ----ref.label='SRdata', eval=FALSE--------------------------------------
## NA

## ----ref.label='SRfit', eval=FALSE---------------------------------------
## NA

## ----ref.label='future.vpa', eval=FALSE----------------------------------
## NA

## ----ref.label='msy', eval=FALSE-----------------------------------------
## NA

## ----ref.label='beta.tmp', eval=FALSE------------------------------------
## NA

## ----ref.label='abc', eval=FALSE-----------------------------------------
## NA

## ----ref.label='HCR', eval=FALSE-----------------------------------------
## NA

## ----ref.label='probability', eval=FALSE---------------------------------
## NA

