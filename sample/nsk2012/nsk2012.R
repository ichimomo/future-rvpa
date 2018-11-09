## 日本海スケトウダラ  NSK
#
# Popeの近似式
# チューニングVPA
#
# 特徴：チューニングVPAだが，最近年のFは過去の平均とし，最近年・最高齢のFだけを推定する（sel.update=TRUE）
#       SSBは年中央の値
#       将来予測で使う成熟率はVPAで使う成熟率と異なる（半年ずれている）ので、そのデータを別途読み込む必要がある。RPSは、中央値でなく平均で将来予測。2012年の漁獲量はgivenで与える。
#       浮き魚よりも単位が1000小さいことに注意。 
# > res.nsk$naa$"2010"
# [1]  48814.902  43182.402 165456.774  44375.864  11429.299   5576.392   2723.761   1407.556   1557.291
# > res.nsk$naa$"2011"
# [1]  47081.5986  35956.6109  32028.5931 108258.2682  25811.4896   5832.4201   2665.0639    929.5297    706.7752
# > res.nsk$faa$"2010"
# [1] 0.005722674 0.048804005 0.174190234 0.291875984 0.422748136 0.488313963 0.825090159 1.183868031 1.183868031
# > res.nsk$faa$"2011"
# [1] 0.001718416 0.030598852 0.116164702 0.174578845 0.240942554 0.321393396 0.451756336 0.595235875 0.595235875
#

source("../../rvpa1.9.2.r")
source("../../future2.1.r")

  caa <- read.csv("caa_nsk.csv",row.names=1)
  waa <- read.csv("waa_nsk.csv",row.names=1)
  maa <- read.csv("maa_nsk.csv",row.names=1)
  cpue <- read.csv("cpue_nsk.csv",row.names=1)
  dat <- data.handler(caa, waa, maa, cpue, M=c(0.3,rep(0.25,8)))
 
  sel.nsk <- vpa(dat,rec.new=NULL,rec=NULL,rec.year=NULL,term.F="max",stat.tf="mean",Pope=TRUE,sel.update=FALSE,p.init=1.0)

  sel.f <- sel.nsk$saa$"2011"  # terminal selectivity = 2011

  res.nsk <- vpa(dat=dat,
    sel.f=sel.f,
    tf.year = 2006:2010,
    fc.year = 2007:2011, # Fcurrentでどの範囲を参照するか
    rec = c(48814.9019068935, 47081.5985815089),
    rec.year=c(2010,2011),
    term.F="max",
    Pope=TRUE,
    abund = "SSBm",  # 資源量指数がSSBの年の中央値
    min.age = 0,
    max.age = 8,
    faa0 = NULL,
    naa0 = NULL,
    link = "id",
    base = NA,
    stat.tf="mean",
    add.p.est=NULL,
    af=0,   # 資源量指数が漁期前
    tune=TRUE,
    plot=TRUE,
    plot.year=1998:2011,
    sel.update=TRUE,   # selectivityを更新しながら，繰り返し計算で最高齢のFを推定
#    use.final.ave = "saa", # かつては動いていたオプション。とりあえず外す
    sel.def = "maxage",
    p.init=0.2
  )

#  sel.f <- c(0.00288445640007,0.05136187966715,0.19521595487401,0.29334880020900,0.40483099944915,0.53997190660773,0.75896446612149,1.0,1.0)
#
#  res.nsk.xls <- vpa(dat=dat,sel.f=sel.f,tf.year = 2006:2010,fc.year = 2007:2011,
#    rec = c(48814.9019068935, 47081.5985815089),rec.year=c(2010,2011),
#    term.F="max",
#    Pope=TRUE,
#    abund = "SSBm", 
#    min.age = 0,
#    max.age = 8,
#    faa0 = NULL,
#    naa0 = NULL,
#    link = "id",
#    base = NA,
#    stat.tf="mean",
#    add.p.est=NULL,
#    af=0,  
#    tune=TRUE,plot=TRUE,
#    no.est = TRUE,
#    p.init=0.59575023752 
#  )
#
# > res.nsk$minimum
# [1] 0.4241816
# > res.nsk.xls$minimum
# [1] 0.4241828
#
# > res.nsk$naa$"2009"
# [1]  58744.386 255198.794  65632.990  18625.912   9828.924   6017.680   3782.272   2738.493   2156.769
# > res.nsk.xls$naa$"2009"
# [1]  58683.504 255027.012  65596.224  18618.436   9825.873   6016.712   3781.922   2738.277   2156.598
#
# わずかな尤度の差が100尾レベルの差をうむ
#

  # 将来予測で使う成熟率はVPAで使う成熟率と異なる(今のvpa関数ではmaa.tuneで指定可能)
  maa2 <- read.csv("maa_nsk2.csv",row.names=1)
  res.nsk$input$dat$maa[] <- maa2 # 成熟率を書き換え
  res.nsk$ssb[] <- res.nsk$input$dat$waa * res.nsk$naa * res.nsk$input$dat$maa  # ssbを上書き

  # ABC計算などのための前段階の計算
  byear.nsk <- 2007:2011
  rec.new <- list(year=2014,rec=385496)
  rec.arg <- list(rps.year=1989:2007,rpsmean=TRUE,
                          Blim.rec=Inf,upper.ssb=Inf,bias.corrected=FALSE,
                          upper.recruit=1858206) # 単位は千尾
  Blim.nsk <- 139958.1456 *1000
  SSBcur.nsk <- sum(res.nsk$ssb[as.character(2006)])
  Frec.multi <- apply(res.nsk$ssb,2,sum)["2011"]/1000/Blim.nsk

  # Fcurrent <- 過去5年平均
  par(mfrow=c(1,1))
  rres.nsk <- ref.F(res.nsk,
              waa.year=byear.nsk, 
              maa.year=byear.nsk,
              M.year=byear.nsk,rps.year=1989:2007,
              max.age=28,pSPR=c(20,30,40),Fspr.init=0.1)

SRdata <- get.SRdata(res.nsk)
HS.par0 <- fit.SR(SRdata,SR="HS",method="L2",AR=0,hessian=FALSE)

#------ 将来予測 ---------------
pre.catch <- list(year=2012,wcatch=13000)
rec.new <- list(year=2012,rec=385496)
fres.nsk <- future.vpa(res.nsk,currentF=NULL,
                         # 詳細な将来予測結果は0.9*Fsusについて
                       multi=rres.nsk$summary$Fmean[3]*0.9, 
                       nyear=20,start.year=2012,N=1000,
                       waa.year=byear.nsk,maa.year=byear.nsk,
                       rec.new=rec.new,
                       ABC.year=2013, 
                       pre.catch=pre.catch,
                       recfunc=HS.recAR, # 再生産関係の関数                         
                       rec.arg=list(a=HS.par0$pars$a,b=HS.par0$pars$b,
                                    rho=HS.par0$pars$rho, # ここではrho=0なので指定しなくてもOK
                                    sd=HS.par0$pars$sd,resid=HS.par0$resid))

# res.newを与えない場合
pre.catch <- NULL
rec.new <- NULL
fres.nsk2 <- future.vpa(res.nsk,currentF=NULL,
                         # 詳細な将来予測結果は0.9*Fsusについて
                       multi=rres.nsk$summary$Fmean[3]*0.9, 
                       nyear=20,start.year=2012,N=1000,
                       waa.year=byear.nsk,maa.year=byear.nsk,
                       rec.new=rec.new,
                       ABC.year=2013, 
                       pre.catch=pre.catch,
                       recfunc=HS.recAR, # 再生産関係の関数                         
                       rec.arg=list(a=HS.par0$pars$a,b=HS.par0$pars$b,
                                    rho=HS.par0$pars$rho, # ここではrho=0なので指定しなくてもOK
                                    sd=HS.par0$pars$sd,resid=HS.par0$resid))

# start.yearをもっと遡る場合、VPA結果のfaaを使ってシミュレーションをする→設定の確認（2018/11/09バグ修正）
pre.catch <- NULL
rec.new <- NULL
fres.nsk3 <- future.vpa(res.nsk,currentF=NULL,
                       multi=rres.nsk$summary$Fmean[3]*0.9, 
                       nyear=20,start.year=2005,N=1000,
                       waa.year=byear.nsk,maa.year=byear.nsk,
                       rec.new=rec.new,
                       ABC.year=2013, 
                       pre.catch=pre.catch,
                       recfunc=HS.recAR, # 再生産関係の関数                         
                       rec.arg=list(a=HS.par0$pars$a,b=HS.par0$pars$b,
                                    rho=HS.par0$pars$rho, # ここではrho=0なので指定しなくてもOK
                                    sd=HS.par0$pars$sd,resid=HS.par0$resid))  

# faaにVPA結果が入っているか確認
matplot(dimnames(fres.nsk3$faa)[[2]],t(fres.nsk3$faa[,,1]),xlab="Years",ylab="F at age")
matpoints(colnames(res.nsk$faa),t(res.nsk$faa),col=1,type="l")

## ただし、faaの列にすべてゼロが入っている場合（太平洋マイワシなど）、その列のfaaには将来予測のcurrent Fの値が入る

res.nsk2 <- res.nsk
res.nsk2$faa[,32] <- 0
pre.catch <- NULL
rec.new <- NULL
fres.nsk4 <- future.vpa(res.nsk2,currentF=NULL,
                       multi=rres.nsk$summary$Fmean[3]*0.9, 
                       nyear=20,start.year=2005,N=1000,
                       waa.year=byear.nsk,maa.year=byear.nsk,
                       rec.new=rec.new,
                       ABC.year=2013, 
                       pre.catch=pre.catch,
                       recfunc=HS.recAR, # 再生産関係の関数                         
                       rec.arg=list(a=HS.par0$pars$a,b=HS.par0$pars$b,
                                    rho=HS.par0$pars$rho, # ここではrho=0なので指定しなくてもOK
                                    sd=HS.par0$pars$sd,resid=HS.par0$resid))                    
                  
# F=0を入れた2011年のFはcurrent Fの値が使われている
matplot(dimnames(fres.nsk4$faa)[[2]],t(fres.nsk4$faa[,,1]),xlab="Years",ylab="F at age")
matpoints(colnames(res.nsk2$faa),t(res.nsk2$faa),col=1,type="l")
