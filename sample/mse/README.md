small MSE
================
Momoko Ichinokawa
2019-04-03

``` r
## Global options
library(rmarkdown)
library(knitr)
options(max.print="75")
opts_chunk$set(#echo=FALSE,
               prompt=FALSE,
               tidy=TRUE,
               comment=NA,
               message=FALSE,
               warning=FALSE)
```

# future.rvpaで簡易MSE

## 事前準備

``` r
# 関数の読み込み →
# warningまたは「警告」が出るかもしれませんが，その後動いていれば問題ありません
source("../../rvpa1.9.2.r")
source("../../future2.1.r")
source("../../utilities.r", encoding = "UTF-8")  # ggplotを使ったグラフ作成用の関数
source("future-diff.r")
library(tidyverse)  # うまくインストールできない場合、最新のRを使ってください
caa <- read.csv("../make_report1/caa_pma.csv", row.names = 1)
waa <- read.csv("../make_report1/waa_pma.csv", row.names = 1)
maa <- read.csv("../make_report1/maa_pma.csv", row.names = 1)
dat <- data.handler(caa = caa, waa = waa, maa = maa, M = 0.5)
names(dat)
```

    [1] "caa"        "maa"        "waa"        "index"      "M"         
    [6] "maa.tune"   "waa.catch"  "catch.prop"

``` r
# VPAによる資源量推定
res.pma <- vpa(dat, fc.year = 2015:2017, tf.year = 2008:2010, term.F = "max", 
    stat.tf = "mean", Pope = TRUE, tune = FALSE, p.init = 1)
# VPA結果を使って再生産データを作る
SRdata <- get.SRdata(res.pma, years = 1988:2016)
head(SRdata)
```

    $year
     [1] 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001
    [15] 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015
    [29] 2016
    
    $SSB
     [1] 12199.02 15266.68 15072.03 19114.22 23544.42 28769.36 34764.44
     [8] 38219.49 48535.10 61891.08 63966.56 38839.78 53404.29 47322.39
    [15] 54485.00 54385.04 47917.14 46090.76 59847.97 53370.62 48781.20
    [22] 42719.39 40095.19 39311.04 38332.44 37547.09 27543.26 22881.37
    [29] 22184.28
    
    $R
     [1]  406.0086  498.9652  544.3007  469.6025 1106.8877 1043.4237  696.7049
     [8]  923.9567 1353.1790 1698.8457 1117.5454 2381.1352 1669.1381 1818.3638
    [15] 1858.0043 1458.9524 1334.9288 1116.9433 1100.4598 1693.9768 1090.7172
    [22] 1081.8343 1265.0456 1023.9650  753.1901  764.0987  876.6335  500.9416
    [29]  549.3746

再生産モデルのフィット

``` r
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
```

``` 
   SR.rel AR.type L.type     AICc delta.AIC
7      HS       0     L2 11.68088 0.0000000
9      RI       0     L2 12.30980 0.6289293
8      BH       0     L2 12.35364 0.6727687
2      BH       0     L1 13.79426 2.1133843
3      RI       0     L1 13.87867 2.1977984
5      BH       1     L1 14.09788 2.4170057
6      RI       1     L1 14.10137 2.4204994
10     HS       1     L2 14.32407 2.6431965
1      HS       0     L1 14.75174 3.0708666
12     RI       1     L2 14.99619 3.3153125
11     BH       1     L2 15.05006 3.3691864
4      HS       1     L1 15.68126 4.0003803
```

``` r
# HSのうちR0が低いケース（12番）とAIC最小ケースとの比較
plot(SR.list[[1]]$pred,type="l",ylim=c(0,2000))
points(SR.list[[12]]$pred,type="l",col=2)
```

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

``` r
SRmodel.base <- SR.list[[1]] # AIC最小モデルを今後使っていく
SRmodel.R1 <- SR.list[[12]] # 別の加入シナリオ

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
```

    $ABC.year
    [1] 2019
    
    $Blim
    [1] 0
    
    $F.sigma
    [1] 0
    
    $Frec
    NULL
    
    $HCR
    NULL
    
    $M
    NULL
    
    $M.year
    [1] 2015 2016 2017
    
    $MSE.options
    NULL
    
    $N
    [1] 100
    
    $Pope
    [1] TRUE
    
    $add.year
    [1] 0
    
    $currentF
    NULL
    
    $delta
    NULL
    
    $det.run
    [1] TRUE
    
    $eaa0
    NULL
    
    $faa0
    NULL
    
    $is.plot
    [1] TRUE
    
    $maa
    NULL
    
    $maa.year
    [1] 2015 2016 2017
    
    $multi
    [1] 1
    
    $multi.year
    [1] 1
    
    $naa0
    NULL
    
    $nyear
    [1] 50
    
    $outtype
    [1] "FULL"
    
    $plus.group
    [1] TRUE
    
    $pre.catch
    NULL
    
    $random.select
    NULL
    
    $rec.arg
    $rec.arg$a
    [1] 0.02864499
    
    $rec.arg$b
    [1] 51882.06
    
    $rec.arg$rho
    [1] 0
    
    $rec.arg$sd
    [1] 0.2624895
    
    $rec.arg$resid
     [1]  0.15003999  0.13188525  0.23168312 -0.15352429  0.49544035
     [6]  0.23597319 -0.35721137 -0.16965875 -0.02705374  0.13375295
    [11] -0.28506140  0.76090931  0.11611132  0.29373043  0.22330688
    [16] -0.01847747 -0.02781840 -0.16723995 -0.30046800  0.13088282
    [21] -0.24773256 -0.12321799  0.09662881 -0.09504603 -0.37695727
    [26] -0.34187713  0.10535290 -0.26881174 -0.14558152
    
    
    $rec.new
    NULL
    
    $recfunc
    function (ssb, vpares, rec.resample = NULL, rec.arg = list(a = 1000, 
        b = 1000, sd = 0.1, rho = 0, resid = 0)) 
    {
        rec0 <- ifelse(ssb > rec.arg$b, rec.arg$a * rec.arg$b, rec.arg$a * 
            ssb)
        rec <- rec0 * exp(rec.arg$rho * rec.arg$resid)
        rec <- rec * exp(rnorm(length(ssb), -0.5 * rec.arg$sd2^2, 
            rec.arg$sd))
        new.resid <- log(rec/rec0) + 0.5 * rec.arg$sd2^2
        return(list(rec = rec, rec.resample = new.resid))
    }
    
    $replace.rec.year
    [1] 2012
    
    $seed
    [1] 1
    
    $silent
    [1] FALSE
    
    $start.year
    [1] 2018
    
    $use.MSE
    [1] FALSE
    
    $waa
    NULL
    
    $waa.catch
    NULL
    
    $waa.fun
    [1] FALSE
    
    $waa.year
    [1] 2015 2016 2017

![](README_files/figure-gfm/unnamed-chunk-3-2.png)<!-- -->

``` r
future.Fcurrent_R1 <- future.vpa(res.pma,
                      multi=1,
                      nyear=50, # 将来予測の年数
                      start.year=2018, # 将来予測の開始年
                      N=1000, # 確率的計算の繰り返し回数=>実際の計算では1000~5000回くらいやってください
                      ABC.year=2019, # ABCを計算する年
                      waa.year=2015:2017, # 生物パラメータの参照年
                      maa.year=2015:2017,
                      M.year=2015:2017,
                      is.plot=TRUE, # 結果をプロットするかどうか
                      seed=1,
                      silent=FALSE,
                      recfunc=HS.recAR, # 再生産関係の関数
                      # recfuncに対する引数
                      rec.arg=list(a=SRmodel.R1$pars$a,b=SRmodel.R1$pars$b,
                                   rho=SRmodel.R1$pars$rho, # ここではrho=0なので指定しなくてもOK
                                   sd=SRmodel.R1$pars$sd,resid=SRmodel.R1$resid))
```

    $ABC.year
    [1] 2019
    
    $Blim
    [1] 0
    
    $F.sigma
    [1] 0
    
    $Frec
    NULL
    
    $HCR
    NULL
    
    $M
    NULL
    
    $M.year
    [1] 2015 2016 2017
    
    $MSE.options
    NULL
    
    $N
    [1] 1000
    
    $Pope
    [1] TRUE
    
    $add.year
    [1] 0
    
    $currentF
    NULL
    
    $delta
    NULL
    
    $det.run
    [1] TRUE
    
    $eaa0
    NULL
    
    $faa0
    NULL
    
    $is.plot
    [1] TRUE
    
    $maa
    NULL
    
    $maa.year
    [1] 2015 2016 2017
    
    $multi
    [1] 1
    
    $multi.year
    [1] 1
    
    $naa0
    NULL
    
    $nyear
    [1] 50
    
    $outtype
    [1] "FULL"
    
    $plus.group
    [1] TRUE
    
    $pre.catch
    NULL
    
    $random.select
    NULL
    
    $rec.arg
    $rec.arg$a
    [1] 0.02785911
    
    $rec.arg$b
    [1] 49274.13
    
    $rec.arg$rho
    [1] 0.08763593
    
    $rec.arg$sd
    [1] 0.2719476
    
    $rec.arg$resid
     [1]  1.778584e-01  1.597037e-01  2.595015e-01 -1.257059e-01  5.232588e-01
     [6]  2.637916e-01 -3.293930e-01 -1.418403e-01  7.646767e-04  2.131451e-01
    [11] -2.056692e-01  7.887277e-01  1.955035e-01  3.215488e-01  3.026991e-01
    [16]  6.091473e-02  1.770836e-08 -1.394215e-01 -2.210758e-01  2.102750e-01
    [21] -2.199142e-01 -9.539957e-02  1.244472e-01 -6.722762e-02 -3.491389e-01
    [26] -3.140587e-01  1.331713e-01 -2.409933e-01 -1.177631e-01
    
    
    $rec.new
    NULL
    
    $recfunc
    function (ssb, vpares, rec.resample = NULL, rec.arg = list(a = 1000, 
        b = 1000, sd = 0.1, rho = 0, resid = 0)) 
    {
        rec0 <- ifelse(ssb > rec.arg$b, rec.arg$a * rec.arg$b, rec.arg$a * 
            ssb)
        rec <- rec0 * exp(rec.arg$rho * rec.arg$resid)
        rec <- rec * exp(rnorm(length(ssb), -0.5 * rec.arg$sd2^2, 
            rec.arg$sd))
        new.resid <- log(rec/rec0) + 0.5 * rec.arg$sd2^2
        return(list(rec = rec, rec.resample = new.resid))
    }
    <bytecode: 0x8c61578>
    
    $replace.rec.year
    [1] 2012
    
    $seed
    [1] 1
    
    $silent
    [1] FALSE
    
    $start.year
    [1] 2018
    
    $use.MSE
    [1] FALSE
    
    $waa
    NULL
    
    $waa.catch
    NULL
    
    $waa.fun
    [1] FALSE
    
    $waa.year
    [1] 2015 2016 2017

![](README_files/figure-gfm/unnamed-chunk-3-3.png)<!-- -->

``` r
plot.futures(list(future.Fcurrent,future.Fcurrent_R1))
```

![](README_files/figure-gfm/unnamed-chunk-3-4.png)<!-- -->

MSY管理基準値の計算;

``` r
# MSYはbase caseのシナリオをもとにする
MSY.base <- est.MSY(res.pma, # VPAの計算結果
                 future.Fcurrent$input, # 将来予測で使用した引数
                 resid.year=0, # ARありの場合、最近何年分の残差を平均するかをここで指定する。ARありの設定を反映させたい場合必ずここを１以上とすること（とりあえず１としておいてください）。
                 N=100, # 確率的計算の繰り返し回数=>実際の計算では1000~5000回くらいやってください
                 calc.yieldcurve=TRUE,
                 PGY=c(0.6,0.1), # 計算したいPGYレベル。上限と下限の両方が計算される
                 onlylower.pgy=TRUE, # TRUEにするとPGYレベルの上限は計算しない（計算時間の節約になる）
                 B0percent=NULL,
                 Bempirical=NULL
                 ) 
```

    Estimating MSY
    F multiplier= 0.4903466 
    Estimating PGY  60 %
    F multiplier= 1.009095 
    Estimating PGY  10 %
    F multiplier= 1.076097 

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

``` r
(refs.all <- MSY.base$summary_tb)
```

    # A tibble: 8 x 15
      RP_name   AR       SSB SSB2SSB0      B     U  Catch Catch.CV `Fref/Fcur`
      <chr>     <lgl>  <dbl>    <dbl>  <dbl> <dbl>  <dbl>    <dbl>       <dbl>
    1 MSY       FALSE 1.25e5   0.256  2.21e5 0.325 71794.    0.141       0.490
    2 B0        FALSE 4.88e5   1.00   5.93e5 0.        0.  NaN           0.   
    3 PGY_0.6_… FALSE 3.55e4   0.0727 9.37e4 0.460 43065.    0.463       1.01 
    4 PGY_0.1_… FALSE 5.56e3   0.0114 1.52e4 0.473  7175.    1.41        1.08 
    5 MSY       TRUE  1.26e5   0.256  2.21e5 0.326 72004.    0.147       0.490
    6 B0        TRUE  4.93e5   1.00   5.97e5 0.        0.  NaN           0.   
    7 PGY_0.6_… TRUE  3.62e4   0.0727 9.45e4 0.460 43509.    0.476       1.01 
    8 PGY_0.1_… TRUE  5.65e3   0.0114 1.56e4 0.470  7363.    1.71        1.08 
    # ... with 6 more variables: Fref2Fcurrent <dbl>, F0 <dbl>, F1 <dbl>,
    #   F2 <dbl>, F3 <dbl>, RP.definition <chr>

``` r
# refs.allの中からRP.definitionで指定された行だけを抜き出す
(refs.base <- refs.all %>%
    dplyr::filter(!is.na(RP.definition)) %>% # RP.definitionがNAでないものを抽出
    arrange(desc(SSB)) %>% # SSBを大きい順に並び替え
    select(RP.definition,RP_name,SSB,SSB2SSB0,Catch,Catch.CV,U,Fref2Fcurrent)) #　列を並び替え
```

    # A tibble: 3 x 8
      RP.definition RP_name           SSB SSB2SSB0  Catch Catch.CV     U
      <chr>         <chr>           <dbl>    <dbl>  <dbl>    <dbl> <dbl>
    1 Btarget0      MSY           124683.   0.256  71794.    0.141 0.325
    2 Blimit0       PGY_0.6_lower  35482.   0.0727 43065.    0.463 0.460
    3 Bban0         PGY_0.1_lower   5564.   0.0114  7175.    1.41  0.473
    # ... with 1 more variable: Fref2Fcurrent <dbl>

将来予測比較

``` r
# HCRによる将来予測
input.abc <- future.Fcurrent$input  # Fcurrentにおける将来予測の引数をベースに将来予測します
input.abc$multi <- derive_RP_value(refs.base, "Btarget0")$Fref2Fcurrent  # currentFへの乗数を'Btarget0'で指定した値に
input.abc$silent <- TRUE
input.abc$HCR <- list(Blim = derive_RP_value(refs.base, "Blimit0")$SSB, Bban = derive_RP_value(refs.base, 
    "Bban0")$SSB, beta = 0.8, year.lag = 0)  # BlimitはBlimit0, BbanはBban0の値
input.abc$N <- 1000
future.default <- do.call(future.vpa, input.abc)  # デフォルトルールの結果→図示などに使う
```

![](README_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

``` r
# MSEによる将来予測
source("future-diff.r")
input.mse <- input.abc
input.mse$N <- 10
input.mse$use.MSE <- TRUE  # MSE仕様での将来予測
input.mse$is.plot <- FALSE
future.mse <- do.call(future.vpa, input.mse)

# use.MSEオプションで、ARありバージョンには十分対応していない→今後の課題
input.mse_R1 <- input.mse
input.mse_R1$MSE.options$recfunc <- future.Fcurrent_R1$recfunc
input.mse_R1$MSE.options$rec.arg <- future.Fcurrent_R1$rec.arg
input.mse_R1$N <- 10
future.mse_R1 <- do.call(future.vpa, input.mse)


# 結果の比較
plot_futures(res.pma, list(future.default, future.mse, future.mse_R1), future.name = c("default", 
    "mse", "mse_R1"))
```

![](README_files/figure-gfm/unnamed-chunk-5-2.png)<!-- -->

``` r
# 直近の漁獲量の比較
all.table <- purrr::map_dfr(list(future.mse, future.default, future.mse_R1), 
    convert_future_table, .id = "scenario")
all.table %>% dplyr::filter(stat == "catch", year < 2025, year > 2018) %>% ggplot() + 
    geom_boxplot(aes(x = factor(year), y = value, fill = scenario))
```

![](README_files/figure-gfm/unnamed-chunk-5-3.png)<!-- -->
