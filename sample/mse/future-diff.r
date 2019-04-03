##----------------------- 将来予測関数 ----------------------------
## multiのオプションは管理後のFのmultiplier（管理前後でselectivityが同じ）
future.vpa <-
    function(res0,
             currentF=NULL, # 管理前のF
             multi=1, # 管理後（ABC.yearから）のF (current F x multi)
             nyear=10,Pope=res0$input$Pope,
             outtype="FULL",
             multi.year=1,#ある特定の年だけFを変えたい場合。デフォルトは1。変える場合は、指定した年またはタイムステップの要素数のベクトルで指定。
             # 年数の指定
             start.year=NULL, # 将来予測の開始年，NULLの場合はVPA計算の最終年の次の年
             ABC.year=NULL, # ABC yearを計算する年。NULLの場合はVPA計算の最終年の次の次の年
             waa.year=NULL, # VPA結果から生物パラメータをもってきて平均する期間
             # NULLの場合，VPAの最終年のパラメータを持ってくる
             maa.year=NULL, # VPA結果から生物パラメータをもってきて平均する期間
             M.year=NULL, # VPA結果から生物パラメータをもってきて平均する期間
             seed=NULL,
             strategy="F", # F: 漁獲係数一定, E: 漁獲割合一定、C: 漁獲量一定（pre.catchで漁獲量を指定）
             HCR=NULL,# HCRを使う場合、list(Blim=154500, Bban=49400,beta=1,year.lag=0)のように指定するか、以下の引数をセットする,year.lag=0で将来予測年の予測SSBを使う。-2の場合は２年遅れのSSBを使う
             use.MSE=FALSE,MSE.options=NULL,
             beta=NULL,delta=NULL,Blim=0,Bban=0,
             plus.group=res0$input$plus.group,
             N=1000,# 確率的なシミュレーションをする場合の繰り返し回数。
             # N+1の結果が返され、1列目に決定論的な結果が                       
             # 0を与えると決定論的な結果のみを出力
             silent=FALSE, is.plot=TRUE, # 計算条件を出力、プロットするか
             random.select=NULL, # 選択率をランダムリサンプリングする場合、ランダムリサンプリングする年を入れる
             # strategy="C"または"E"のときのみ有効
             pre.catch=NULL, # list(year=2012,wcatch=13000), 漁獲重量をgivenで与える場合
             # list(year=2012:2017,E=rep(0.5,6)), 漁獲割合をgivenで与える場合                       
             ##-------- 加入に関する設定 -----------------
             rec.new=NULL, # 指定した年の加入量
             # 年を指定しないで与える場合は、自動的にスタート年の加入になる。
             # list(year=, rec=)で与える場合は、対応する年の加入を置き換える。
             ##--- 加入関数
             recfunc=HS.recAR, # 再生産関係の関数
             rec.arg=list(a=1,b=1,rho=0,sd=0,c=1,bias.correction=TRUE,
                          resample=FALSE,resid=0,resid.year=NULL), # 加入の各種設定
             ##--- Frecオプション；Frec計算のための設定リストを与えると、指定された設定でのFrecに対応するFで将来予測を行う
             Frec=NULL,
             # list(stochastic=TRUE, # TRUEの場合、stochastic simulationで50%の確率でBlimitを越す(PMS, TMI)
             # FALSEの場合、RPS固定のprojectionがBilmitと一致する(NSK)
             #      future.year=2018, # 何年の資源量を見るか？
             #      Blimit=450*1000,  # Blimit (xトン)
             #      scenario="catch.mean" or "blimit" (デフォルトはblimit; "catch.mean"とするとstochastic simulationにおける平均漁獲量がBlimitで指定した値と一致するようになる)
             #      Frange=c(0.01,2*mult)) # Fの探索範囲
             waa=NULL,waa.catch=NULL,maa=NULL,M=NULL, # 季節毎の生物パラメータ、または、生物パラメータを外から与える場合
             replace.rec.year=2012, # 加入量を暦年の将来予測での加入量に置き換えるか？
             F.sigma=0,
             waa.fun=FALSE, #waaをnaaのfunctionとするか
             naa0=NULL,eaa0=NULL,ssb0=NULL,faa0=NULL,
             add.year=0, # 岡村オプションに対応。=1で1年分余計に計算する
             det.run=TRUE # 1回めのランは決定論的将来予測をする（完璧には対応していない）
             ){

        
        argname <- ls()
        arglist <- lapply(argname,function(x) eval(parse(text=x)))
        names(arglist) <- argname
        
        if(is.null(res0$input$unit.waa)) res0$input$unit.waa <- 1
        if(is.null(res0$input$unit.caa)) res0$input$unit.caa <- 1
        if(is.null(res0$input$unit.biom)) res0$input$unit.biom <- 1  
        if(is.null(plus.group)) plus.group <- TRUE
        if(is.null(Pope)) Pope <- FALSE
        
        ##--------------------------------------------------
        if(isTRUE(det.run)) N <- N + 1
        years <- as.numeric(dimnames(res0$naa)[[2]])
        
        ##------------- set default options
        if(is.null(currentF)) currentF <- res0$Fc.at.age
        if(is.null(waa.year)) waa.year <- rev(years)[1]
        if(is.null(maa.year)) maa.year <- rev(years)[1]
        if(is.null(M.year)) M.year <- rev(years)[1]
        if(is.null(start.year)) start.year <- rev(years)[1]+1
        if(is.null(ABC.year)) ABC.year <- rev(years)[1]+1
        arglist$ABC.year <- ABC.year

        ##------------- set SR options
        rec.arg <- set_SR_options(rec.arg,N=N,silent=silent,eaa0=eaa0)

        ##------------- set HCR options
        
        if(!is.null(HCR) && is.null(HCR$year.lag)) HCR$year.lag <- 0
        if(!is.null(beta)){
            HCR$beta <- beta
            HCR$Blim <- Blim
            HCR$Bban <- Bban
        }

        ##------------- set options for MSE
        if(isTRUE(use.MSE)){
            if(is.null(MSE.options)){
                MSE.options$recfunc <- recfunc
                MSE.options$rec.arg <- rec.arg
            }
            else{
                MSE.options$rec.arg <- set_SR_options(MSE.options$rec.arg,
                                                      N=N,silent=silent,eaa0=eaa0)
            }
        }
        ##-------------        
        
        #  fyears <- seq(from=start.year,to=start.year+nyear-1,by=1/ts)
        fyears <- seq(from=start.year,to=start.year+nyear+add.year,by=1)
        
        fyear.year <- floor(fyears)
        ntime <- length(fyears)
        ages <- as.numeric(dimnames(res0$naa)[[1]]) # ages:VPAで考慮される最大年齢数
        min.age <- min(as.numeric(ages))

        year.overlap <- years %in% start.year   
                 {if(sum(year.overlap)==0){
                      nage <- sum(!is.na(res0$naa[,ncol(res0$naa)])) # nage:将来予測で考慮すべき年の数
                  }
                  else{
                      nage <- sum(!is.na(res0$naa[,year.overlap])) 
                  }}
        
        if(!silent){
            arglist.tmp <-  arglist
            arglist.tmp$res0 <- NULL
            arglist.tmp$Bban <- arglist.tmp$Bblim <- arglist.tmp$beta <- arglist.tmp$ssb0 <- arglist.tmp$strategy <- NULL
            print(arglist.tmp)
        }
        
        # シードの設定
        if(is.null(seed)) arglist$seed <- as.numeric(Sys.time())
        
        #------------Frecオプションの場合 -------------
        if(!is.null(Frec)){
            multi.org <- multi
            if(is.null(Frec$stochastic)) Frec$stochastice <- TRUE
            if(is.null(Frec$target.probs)) Frec$target.probs <- 50
            if(is.null(Frec$scenario)) Frec$scenario <- "blimit" # 2017/12/25追記 
            if(is.null(Frec$Frange)) Frec$Frange <- c(0.01,multi.org*2)   # 2017/12/25追記(探索するFの範囲の指定)
            if(is.null(Frec$future.year)) Frec$future.year <- fyears[length(fyears)]-1
            #      arglist$Frec <- Frec
            
            getFrec <- function(x,arglist){
                set.seed(arglist$seed)
                arglist.tmp <- arglist
                arglist.tmp$multi <- x
                arglist.tmp$silent <- TRUE      
                arglist.tmp$Frec <- NULL
                arglist.tmp$is.plot <- FALSE
                if(Frec$stochastic==FALSE){
                    arglist.tmp$N <- 0
                }      
                fres.tmp <- do.call(future.vpa,arglist.tmp)
                tmp <- rownames(fres.tmp$vssb)==Frec$future.year
                if(all(tmp==FALSE)) stop("nyear should be longer than Frec$future.year.")
                if(Frec$stochastic==TRUE){
                    if(Frec$scenario=="blimit"){          
                        is.lower.ssb <- fres.tmp$vssb<Frec$Blimit
                        probs <- (sum(is.lower.ssb[tmp,-1],na.rm=T)-1)/
                            (length(is.lower.ssb[tmp,-1])-1)*100
                        return.obj <- probs-Frec$target.probs
                    }
                    # stochastic projectionにおける平均漁獲量を目的の値に一致させる 
                    if(Frec$scenario=="catch.mean"){
                        return.obj <- (log(Frec$Blimit)-log(mean(fres.tmp$vwcaa[tmp,-1])))^2
                    }
                    # stochastic projectionにおける平均親魚資源量を目的の値に一致させる 
                    if(Frec$scenario=="ssb.mean"){
                        return.obj <- (log(Frec$Blimit)-log(mean(fres.tmp$vssb[tmp,-1])))^2
                    }                
                }
                else{
                    return.obj <- Frec$Blimit-fres.tmp$vssb[tmp,1]
                }
                #        return(ifelse(Frec$method=="nibun",return.obj,return.obj^2))
                return(return.obj^2)                
            }
            
            res <- optimize(getFrec,interval=Frec$Frange,arglist=arglist)        
            multi <- res$minimum
            cat("F multiplier=",multi,"\n")
        }
        
        #-------------- main function ---------------------
        waa.org <- waa
        waa.catch.org <- waa.catch
        maa.org <- maa
        M.org <- M
        
        if(strategy=="C"|strategy=="E") multi.catch <- multi else multi.catch <- 1
        
        faa <- naa <- waa <- waa.catch <- maa <- M <- caa <- 
            array(NA,dim=c(length(ages),ntime,N),dimnames=list(age=ages,year=fyears,nsim=1:N))
        
        allyears <- sort(unique(c(fyears,years)))

        # 全部のデータを記録したフレーム  
        naa_all <- waa_all <- waa_catch_all <- maa_all <- faa_all <- 
            array(NA,dim=c(length(ages),length(allyears),N),dimnames=list(age=ages,year=allyears,nsim=1:N))
        naa_all[,1:length(years),] <- unlist(res0$naa)
        faa_all[,1:length(years),] <- unlist(res0$faa)        
        waa_all[,1:length(years),] <- unlist(res0$input$dat$waa)
        if(is.null(res0$input$dat$waa.catch)){
            waa_catch_all[,1:length(years),] <- unlist(res0$input$dat$waa)
        }else{
            waa_catch_all[,1:length(years),] <- unlist(res0$input$dat$waa.catch)
        }
        maa_all[,1:length(years),] <- unlist(res0$input$dat$maa)      
        i_all <- which(allyears%in%start.year)
        
        alpha <- thisyear.ssb <- array(1,dim=c(ntime,N),dimnames=list(year=fyears,nsim=1:N))
        
        # future biological patameter
        if(is.null(  M.org))   M.org <- apply(as.matrix(res0$input$dat$M[,years %in% M.year]),1,mean)
        if(is.null(waa.org)) waa.org <- apply(as.matrix(res0$input$dat$waa[,years %in% waa.year]),1,mean)
        if(is.null(maa.org)) maa.org <- apply(as.matrix(res0$input$dat$maa[,years %in% maa.year]),1,mean)
        if(is.null(waa.catch.org)){
            if(!is.null(res0$input$dat$waa.catch)) waa.catch.org <- apply(as.matrix(res0$input$dat$waa.catch[,years %in% waa.year]),1,mean)
            else waa.catch.org <- waa.org
        }
        
        M[] <- M.org
        waa[] <- waa.org
        waa_all[,(length(years)+1):dim(waa_all)[[2]],] <- waa.org
        maa[] <- maa.org
        maa_all[,(length(years)+1):dim(maa_all)[[2]],] <- maa.org
        waa.catch[] <- waa.catch.org
        waa_catch_all[,(length(years)+1):dim(maa_all)[[2]],] <- waa.catch.org        
        
        # future F matrix
        faa[] <- currentF*multi # *exp(rnorm(length(faa),0,F.sigma))
        faa_all[is.na(faa_all)] <- currentF*multi
        # ABCyear以前はcurrent Fを使う。
        faa[,fyears<min(ABC.year),] <- currentF*exp(rnorm(length(faa[,fyears<min(ABC.year),]),0,F.sigma))
        faa_all[,allyears%in%fyears[fyears<min(ABC.year)],] <- currentF*exp(rnorm(length(faa[,fyears<min(ABC.year),]),0,F.sigma))        
        
        ## VPA期間と将来予測期間が被っている場合、VPA期間のFはVPAの結果を使う
        overlapped.years <- list(future=which(fyear.year %in% years),vpa=which(years %in% fyear.year))
        if(length(overlapped.years$future)>0){  
            #          for(jj in 1:length(vpayears.overlapped)){
            for(j in 1:length(overlapped.years$future)){
                if(any(res0$faa[,overlapped.years$vpa[j]]>0) && !is.null(res0$input$dat$waa[,overlapped.years$vpa[j]])){ # もしfaaがゼロでないなら（PMIの場合、2012までデータが入っているが、faaはゼロになっているので
                    faa[,overlapped.years$future[j],] <- res0$faa[,overlapped.years$vpa[j]]
                    waa[,overlapped.years$future[j],] <- res0$input$dat$waa[,overlapped.years$vpa[j]]
                    if(!is.null(res0$input$dat$waa.catch)){
                        waa.catch[,overlapped.years$future[j],] <- res0$input$dat$waa.catch[,overlapped.years$vpa[j]]
                    }
                    else{
                        waa.catch[,overlapped.years$future[j],] <- res0$input$dat$waa[,overlapped.years$vpa[j]]
                    }
                }
            }}
        #}
        
        tmp <- aperm(faa,c(2,1,3))
        tmp <- tmp*multi.year
        faa <- aperm(tmp,c(2,1,3))
        
        #  vpa.multi <- ifelse(is.null(vpa.mode),1,vpa.mode$multi)
        # rps assumption
        rps.mat <- array(NA,dim=c(ntime,N),dimnames=list(fyears,1:N))
        eaa <- matrix(0,ntime,N)
        rec.tmp <- list(rec.resample=NULL,tmparg=NULL)
        
        if (waa.fun){ #年齢別体重の予測関数
            WAA <- res0$input$dat$waa
            NAA <- res0$naa
            #      nage <- nrow(WAA)
            WAA.res <- lapply(1:nage, function(i) {
                log.w <- as.numeric(log(WAA[i,]))
                log.n <- as.numeric(log(NAA[i,]))
                lm(log.w~log.n)
            })
            WAA.cv <- sapply(1:nage, function(i) sqrt(mean(WAA.res[[i]]$residuals^2)))
            WAA.b0 <- sapply(1:nage, function(i) as.numeric(WAA.res[[i]]$coef[1]))
            WAA.b1 <- sapply(1:nage, function(i) as.numeric(WAA.res[[i]]$coef[2]))
            ##      waa.rand <- array(0,dim=c(al,nyear+1-min.age,N))
            set.seed(0)      
            cv.vec <- rep(WAA.cv,N*ntime)
            waa.rand <- array(rnorm(length(cv.vec),-0.5*cv.vec^2,cv.vec),dim=c(nage,ntime,N))
            waa.rand[,,1] <- 0
        }
        
        set.seed(arglist$seed)        

        # 将来予測の最初の年の設定；バリエーションがありややこしいのでここで設定される
        if(!start.year%in%years){
            # VPA結果が2011年までで、将来予測の開始年が2012年の場合      
            if(start.year==(max(years)+1)){
            {if(is.null(res0$input$dat$M)){
                 M.lastyear <- M.org
             }
             else{
                 M.lastyear <- res0$input$dat$M[,length(years)]
             }}
            # 1年分forwardさせた年齢構成を初期値とする
            tmp <- forward.calc.simple(res0$faa[1:nage,length(years)],
                                       res0$naa[1:nage,length(years)],
                                       M.lastyear[1:nage],
                                       plus.group=plus.group)
            naa[1:nage,1,] <- naa_all[1:nage,i_all,] <- tmp

            
            if(fyears[1]-min.age < start.year){
                thisyear.ssb[1,] <- sum(res0$ssb[,as.character(fyears[1]-min.age)],na.rm=T)
                #                thisyear.ssb <- rep(thisyear.ssb,N)
            }
            else{
                if(waa.fun){
                    waa[2:nage,1,] <- waa_all[2:nage,i_all,] <-
                        t(sapply(2:nage, function(ii) as.numeric(exp(WAA.b0[ii]+WAA.b1[ii]*log(naa[ii,1,])+waa.rand[ii,1,]))))
                }
                thisyear.ssb[1,] <- colSums(naa[,1,]*waa[,1,]*maa[,1,],na.rm=T)*res0$input$unit.waa/res0$input$unit.biom                           }
            
            thisyear.ssb[1,] <- thisyear.ssb[1,]+(1e-10)
            
            if(!is.null(ssb0)) thisyear.ssb[1,] <- colSums(ssb0)
            
            rec.tmp <- recfunc(thisyear.ssb[1,],res0,
                               rec.resample=rec.tmp$rec.resample,
                               rec.arg=rec.arg)
            eaa[1,] <- rec.tmp$rec.resample[1:N]
            rec.arg$resid <- rec.tmp$rec.resample # ARオプションに対応
            
            if(!is.null(rec.tmp$rec.arg)) rec.arg <- rec.tmp$rec.arg
            naa[1,1,] <- naa_all[1,i_all,] <- rec.tmp$rec
            if (waa.fun) {
                waa[1,1,] <- waa_all[1,i_all,] <-
                    as.numeric(exp(WAA.b0[1]+WAA.b1[1]*log(naa[1,1,])+waa.rand[1,1,])) 
            }
            rps.mat[1,] <- naa[1,1,]/thisyear.ssb[1,]          
            }
            else{
                stop("ERROR Set appropriate year to start projection\n")
            }
        }
        else{
            # VPA期間と将来予測期間が被っている場合にはVPAの結果を初期値として入れる
            naa[,1,] <- naa_all[,i_all,] <- res0$naa[,start.year==years]
        }

        # もし引数naa0が与えられている場合にはそれを用いる
        if(!is.null(naa0)){
            naa[,1,] <- naa_all[,i_all,] <- naa0
            if(is.null(faa0)) faa0 <- res0$Fc.at.age
            faa[] <- faa0*multi
        }      
        
        if(!is.null(rec.new)){
            if(!is.list(rec.new)){
                naa[1,1,] <- naa_all[1,i_all,] <- rec.new
            }
            else{ # rec.newがlistの場合
                naa[1,fyears%in%rec.new$year,] <- naa_all[,allyears%in%rec.new$year,] <- rec.new$rec
            }}

        # 2年目以降の将来予測
        for(i in 1:(ntime-1)){
            
            #漁獲量がgivenの場合
            if(!is.null(pre.catch) && fyears[i]%in%pre.catch$year){
                if(!is.null(pre.catch$wcatch)){
                    if(fyears[i]<ABC.year){
                        tmpcatch <- as.numeric(pre.catch$wcatch[pre.catch$year==fyears[i]]) 
                    }
                    else{
                        tmpcatch <- as.numeric(pre.catch$wcatch[pre.catch$year==fyears[i]]) * multi.catch                  
                    }
                }
                if(!is.null(pre.catch$E)){
                    biom <- sum(naa[,i,]*waa[,i,]*res0$input$unit.waa/res0$input$unit.biom)
                    if(fyears[i]<ABC.year){
                        tmpcatch <- as.numeric(pre.catch$E[pre.catch$year==fyears[i]])  * biom
                    }
                    else{
                        tmpcatch <- as.numeric(pre.catch$E[pre.catch$year==fyears[i]]) * biom * multi.catch                  
                    }
                }
                
                # 選択率をランダムサンプリングする場合
                #          if(!is.null(random.select)) saa.tmp <- as.numeric(res0$saa[,colnames(res0$saa)==sample(random.select,1)])
                saa.tmp <- sweep(faa[,i,],2,apply(faa[,i,],2,max),FUN="/")
                tmp <- lapply(1:dim(naa)[[3]],
                              function(x) caa.est.mat(naa[,i,x],saa.tmp[,x],
                                                      waa.catch[,i,x],M[,i,x],tmpcatch,Pope=Pope))
                faa.new <- sweep(saa.tmp,2,sapply(tmp,function(x) x$x),FUN="*")
                caa[,i,] <- sapply(tmp,function(x) x$caa)
                faa[,i,] <- faa.new
            }
            else{
                faa.new <- NULL
            }
            
            ## HCRを使う場合(当年の資源量から当年のFを変更する)
            if(!is.null(HCR) && fyears[i]>=ABC.year
               && is.null(faa.new)) # <- pre.catchで漁獲量をセットしていない
            {

                if(!isTRUE(use.MSE)){
                    tmp <- i+HCR$year.lag
                    if(tmp>0){
                        ssb.tmp <- colSums(naa[,tmp,]*waa[,tmp,]*maa[,tmp,],na.rm=T)*
                            res0$input$unit.waa/res0$input$unit.biom
                    }
                    else{
                        vpayear <- fyears[i]+HCR$year.lag
                        ssb.tmp <- sum(res0$ssb[as.character(vpayear)])
                    }
                    alpha[i,] <- ifelse(ssb.tmp<HCR$Blim,HCR$beta*(ssb.tmp-HCR$Bban)/(HCR$Blim-HCR$Bban),HCR$beta)
                    faa[,i,] <- sweep(faa[,i,],2,alpha[i,],FUN="*")
                    faa[,i,] <- faa_all[,i,] <- ifelse(faa[,i,]<0,0,faa[,i,])

                }
                else{
                    ABC.tmp <- get_ABC_inMSE(naa_all,waa_all,maa_all,faa_all,M[,(i-2):(i),],res0,
                                             start_year=i_all-2,nyear=2,
                                             recfunc=MSE.options$recfunc,
                                             rec.arg=MSE.options$rec.arg,
                                             Pope=Pope,HCR=HCR,plus.group=plus.group,lag=min.age)
#                    if(fyears[i]==2020) browser()
                    ####
                    saa.tmp <- sweep(faa[,i,],2,apply(faa[,i,],2,max),FUN="/")
                    est.result <- lapply(1:dim(naa)[[3]],
                                  function(x) caa.est.mat(naa[,i,x],saa.tmp[,x],
                                                          waa.catch[,i,x],M[,i,x],ABC.tmp[x],Pope=Pope))
                    fmulti_to_saa <- sapply(est.result,function(x) x$x)
                    faa.new2 <- sweep(saa.tmp,2,fmulti_to_saa,FUN="*")
                    caa[,i,] <- sapply(est.result,function(x) x$caa)
                    faa[,i,] <- faa_all[,i_all,] <- faa.new2                    
                    ####                    
                    }
            }
            
            ## 漁獲して１年分前進（加入はまだいれていない）
            tmp <- forward.calc.mat2(faa[,i,],naa[,i,],M[,i,],plus.group=plus.group)
            # 既に値が入っているところ（１年目の加入量）は除いて翌年のNAAを入れる
            naa.tmp <- naa[,i+1,]
            naa.tmp[is.na(naa.tmp)] <- tmp[is.na(naa.tmp)]          
            naa[,i+1, ] <- naa_all[,i_all+1,] <- naa.tmp
            
            ## 当年の加入の計算
            if(fyears[i+1]-min.age < start.year){
                # 参照する親魚資源量がVPA期間である場合、VPA期間のSSBをとってくる
                thisyear.ssb[i+1,] <- sum(res0$ssb[,as.character(fyears[i+1]-min.age)],na.rm=T)*res0$input$unit.waa/res0$input$unit.biom
                #              thisyear.ssb <- rep(thisyear.ssb,N)              
                if(!is.null(ssb0)) thisyear.ssb[i+1,] <- colSums(ssb0)
            }
            else{
                # そうでない場合
                if(waa.fun){
                    # 動的なwaaは対応する年のwaaを書き換えた上で使う？
                    waa[2:nage,i+1-min.age,] <- waa[2:nage,i_all+1-min.age,] <- t(sapply(2:nage, function(ii) as.numeric(exp(WAA.b0[ii]+WAA.b1[ii]*log(naa[ii,i+1-min.age,])+waa.rand[ii,i+1-min.age,]))))

                }
                thisyear.ssb[i+1,] <- colSums(naa[,i+1-min.age,]*waa[,i+1-min.age,]*maa[,i+1-min.age,],na.rm=T)*res0$input$unit.waa/res0$input$unit.biom            
            }

            thisyear.ssb[i+1,] <- thisyear.ssb[i+1,]+(1e-10)
            rec.tmp <- recfunc(thisyear.ssb[i+1,],res0,
                               rec.resample=rec.tmp$rec.resample,
                               rec.arg=rec.arg)
            if(is.na(naa[1,i+1,1]))  naa[1,i+1,] <- naa_all[1,i_all+1,] <- rec.tmp$rec          
            #          if(!is.null(rec.tmp$rec.arg)) rec.arg <- rec.tmp$rec.arg      
            rps.mat[i+1,] <- naa[1,i+1,]/thisyear.ssb[i+1,]
            eaa[i+1,] <- rec.tmp$rec.resample[1:N]
            rec.arg$resid <- rec.tmp$rec.resample # ARオプションに対応
            
            i_all <- i_all+1
        }
        
        if (!is.null(rec.arg$rho)) rec.tmp$rec.resample <- NULL

        if(Pope){
            caa[] <- naa*(1-exp(-faa))*exp(-M/2)
        }
        else{
            caa[] <- naa*(1-exp(-faa-M))*faa/(faa+M)
        }

        
        
        caa <- caa[,-ntime,,drop=F]
        waa.catch <- waa.catch[,-ntime,,drop=F]
        thisyear.ssb <- thisyear.ssb[-ntime,,drop=F]      
        waa <- waa[,-ntime,,drop=F]
        maa <- maa[,-ntime,,drop=F]                
        naa <- naa[,-ntime,,drop=F]
        faa <- faa[,-ntime,,drop=F]
        alpha <- alpha[-ntime,,drop=F]      
        M <- M[,-ntime,,drop=F]
        fyears <- fyears[-ntime]
        
        biom <- naa*waa*res0$input$unit.waa/res0$input$unit.biom
        ssb <- naa*waa*maa*res0$input$unit.waa/res0$input$unit.biom
        
        wcaa <- caa*waa.catch*res0$input$unit.waa/res0$input$unit.biom
        vwcaa <- apply(wcaa,c(2,3),sum,na.rm=T)
        
        ABC <- apply(as.matrix(vwcaa[fyears%in%ABC.year,,drop=F]),2,sum)

        if(!is.null(rec.arg$resample)) if(rec.arg$resample==TRUE) eaa[] <- NA # resamplingする場合にはeaaにはなにも入れない
        
        fres <- list(faa=faa,naa=naa,biom=biom,baa=biom,ssb=ssb,wcaa=wcaa,caa=caa,M=M,rps=rps.mat,
                     maa=maa,vbiom=apply(biom,c(2,3),sum,na.rm=T),
                     eaa=eaa,alpha=alpha,thisyear.ssb=thisyear.ssb,
                     waa=waa,waa.catch=waa.catch,currentF=currentF,
                     vssb=apply(ssb,c(2,3),sum,na.rm=T),vwcaa=vwcaa,naa_all=naa_all,
                     years=fyears,fyear.year=fyear.year,ABC=ABC,recfunc=recfunc,rec.arg=rec.arg,
                     waa.year=waa.year,maa.year=maa.year,multi=multi,multi.year=multi.year,
                     Frec=Frec,rec.new=rec.new,pre.catch=pre.catch,input=arglist)

        if(is.plot){
            par(mfrow=c(2,2))
            plot.future(fres)
        }
        if(waa.fun) fres$waa.reg <- WAA.res

        
        if(outtype=="Det"){
            fres <- list(faa=faa[,,1],M=M[,,1],recruit=naa[1,,],eaa=eaa,baa=biom,
                         maa=maa[,,1],vbiom=apply(biom,c(2,3),sum,na.rm=T),
                         waa=waa[,,1],waa.catch=waa.catch[,,1],currentF=currentF,
                         vssb=apply(ssb,c(2,3),sum,na.rm=T),vwcaa=vwcaa,alpha=alpha,
                         years=fyears,fyear.year=fyear.year,ABC=ABC,recfunc=recfunc,
                         waa.year=waa.year,maa.year=maa.year,multi=multi,multi.year=multi.year,
                         Frec=Frec,rec.new=rec.new,pre.catch=pre.catch,input=arglist)
        }

        if(outtype=="short"){
            fres <- list(recruit=naa[1,,],eaa=eaa,baa=biom,
                         vbiom=apply(biom,c(2,3),sum,na.rm=T),
                         currentF=currentF,
                         vssb=apply(ssb,c(2,3),sum,na.rm=T),vwcaa=vwcaa,
                         years=fyears,fyear.year=fyear.year,ABC=ABC,
                         waa.year=waa.year,maa.year=maa.year,multi=multi,multi.year=multi.year,
                         Frec=Frec,rec.new=rec.new,pre.catch=pre.catch,input=arglist)
        }      

        ## if(non.det==TRUE){
        ##     fres <- list(faa=faa[,,-1,drop=F],naa=naa[,,-1,drop=F],biom=biom[,,-1,drop=F],
        ##                  ssb=ssb[,,-1,drop=F],wcaa=wcaa[,,-1,drop=F],caa=caa[,,-1,drop=F],
        ##                  M=M[,,-1,drop=F],rps=rps.mat[,-1,drop=F],
        ##                  maa=maa[,,-1,drop=F],vbiom=apply(biom[,,-1,drop=F],c(2,3),sum,na.rm=T),
        ##                  eaa=eaa[,-1,drop=F],
        ##                  waa=waa[,,-1,drop=F],waa.catch=waa.catch[,,-1,drop=F],currentF=currentF,
        ##                  vssb=apply(ssb[,,-1,drop=F],c(2,3),sum,na.rm=T),vwcaa=vwcaa[,-1,drop=F],
        ##                  years=fyears,fyear.year=fyear.year,ABC=ABC,recfunc=recfunc,rec.arg=rec.arg,
        ##                  waa.year=waa.year,maa.year=maa.year,multi=multi,multi.year=multi.year,
        ##                  Frec=Frec,rec.new=rec.new,pre.catch=pre.catch,input=arglist)
        ## }
        
        class(fres) <- "future"

        invisible(fres)
    }


get_ABC_inMSE <- function(naa_all,waa_all,maa_all,faa,M,res0,start_year,nyear,recfunc,rec.arg,Pope,HCR,
                          plus.group=plus.group,lag=0){
    ABC.all <- numeric()
    N <- dim(naa_all)[[3]]
    naa_dummy <- naa_all
    naa_dummy[] <- NA
    faa_dummy <- faa
    rec.tmp <- list(rec.resample=NULL,tmparg=NULL)
    
    for(s in 1:N){
        naa_dummy[,1:start_year,] <- naa_all[,1:start_year,s]
        faa_dummy[,1:start_year,] <- faa[,1:start_year,s]        
        for(j in 1:nyear){
            sj <- start_year+j
            naa_dummy[,sj,] <- forward.calc.mat2(faa_dummy[,sj-1,],naa_dummy[,sj-1,],M[,j,],
                                                          plus.group=plus.group)
            thisyear.ssb <- colSums(naa_dummy[,sj-lag,] * waa_all[,sj-lag,s] *
                                    maa_all[,sj-lag,s],na.rm=T)
            naa_dummy[1,sj,] <- recfunc(thisyear.ssb,res0,
                                        rec.resample=rec.tmp$rec.resample,
                                        rec.arg=rec.arg)$rec
        }

        lastyear <- start_year+nyear
        ssb.tmp <- colSums(naa_dummy[,lastyear,]*
                           waa_all[,lastyear,]*
                           maa_all[,lastyear,],na.rm=T)*
            res0$input$unit.waa/res0$input$unit.biom    
        alpha <- ifelse(ssb.tmp<HCR$Blim,HCR$beta*(ssb.tmp-HCR$Bban)/(HCR$Blim-HCR$Bban),HCR$beta)
        faa_dummy[,lastyear,] <- sweep(faa[,lastyear,],2,alpha,FUN="*")
    
        if(Pope){
            ABC <- naa_dummy[,lastyear,]*(1-exp(-faa_dummy[,lastyear,]))*exp(-M[,nyear,]/2)*waa_all[,lastyear,]
        }
        else{
            ABC <- naa_dummy[,lastyear,]*(1-exp(-faa_dummy[,lastyear,]-M[,nyear,]))*faa_dummy[,lastyear,]/(faa_dummy[,lastyear,]+M[,nyear,])*waa_all[,lastyear,] 
        }
        
        ABC.all[s] <- mean(colSums(ABC))

        if(0){
            boxplot(t(apply(naa_dummy*waa_all*maa_all,c(2,3),sum)),ylim=c(0,200000),col=2)
            locator(1)
#            if(Pope){
#                ABC <- naa_dummy*(1-exp(-faa_dummy))*exp(-M[,nyear,]/2)*waa_all
#            }
#            else{
#                ABC <- naa_dummy*(1-exp(-faa_dummy-M[,nyear,]))*faa_dummy/(faa_dummy+M[,nyear,])*waa_all 
#            }
#            boxplot(t(apply(ABC,c(2,3),sum)),col=2)            
        }
    }
    
    return(ABC.all)

}

set_SR_options <- function(rec.arg,N=100, silent=TRUE,eaa0=NULL){
        ##---- set S-R functin option -----
        ## 使う関数によっては必要ないオプションもあるが、使わないオプションを入れてもエラーは出ないので、
        # rec.arg$resampleがNULLかどうかで、パラメトリックな誤差分布かそうでないか（残差リサンプリング）を判別する
        if(is.null(rec.arg$rho)){
            rec.arg$rho <- 0
            if(!silent) cat("rec.arg$rho is assumed to be 0...\n")
        }
        if(is.null(rec.arg$sd2)) rec.arg$sd2 <- sqrt(rec.arg$sd^2/(1-rec.arg$rho^2)) #rho込み平均補正用SD # HS.recAR

        ## resampling optionを使わない場合
        if(is.null(rec.arg$resample)|!isTRUE(rec.arg$resample)){
            if(is.null(rec.arg$bias.correction)) rec.arg$bias.correction <- TRUE # HS.recAR, HS.rec0
            if(is.null(rec.arg$rho)){
                rec.arg$rho <- 0 # HS.recAR, HS.rec0
                rec.arg$resid <- 0
            }
            if(!is.null(rec.arg$rho)){
                if(rec.arg$rho>0){
                    if(is.null(eaa0)){
                        if(is.null(rec.arg$resid.year)) rec.arg$resid <- rep(rev(rec.arg$resid)[1],N)
                        else rec.arg$resid <- rep(mean(rev(rec.arg$resid)[1:rec.arg$resid.year]),N)
                    }
                    else{
                        rec.arg$resid <- eaa0
                    }
                }
                else{
                    rec.arg$resid <- rep(0,N)
                }
            }
        }
        else{
            if(rec.arg$rho>0) stop("You set rho is >0. You cannot use resample=TRUE option when rho>0") # resamplingの場合に自己相関は考慮できないのでrhoは強制的にゼロ
        }
        
    if(!is.null(rec.arg$sd)) rec.arg$sd <- c(0,rep(rec.arg$sd,N-1))
    if(!is.null(rec.arg$sd2)) rec.arg$sd2 <- c(0,rep(rec.arg$sd2,N-1))
    return(rec.arg)
}
