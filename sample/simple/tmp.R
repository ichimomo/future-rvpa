input.current <- MSY.HS$input[[2]]
input.current$multi <- 1
input.current$start.year <- 2012
fout.current <- do.call(future.vpa,input.current)

input.msy <- MSY.HS$input[[2]]
input.msy$start.year <- 2012
MSY.HS <- do.call(future.vpa,input.msy)

x <- cbind(apply(MSY.HS$vwcaa,1,mean),
           apply(fout.current$vwcaa,1,mean))

x.low10 <- cbind(apply(MSY.HS$vwcaa,1,quantile,probs=0.1),
                 apply(fout.current$vwcaa,1,quantile,probs=0.1))
x.low90 <- cbind(apply(MSY.HS$vwcaa,1,quantile,probs=0.9),
           apply(fout.current$vwcaa,1,quantile,probs=0.9))

#x <- cbind(apply(MSY.HS$vssb,1,mean),
#           apply(fout.current$vssb,1,mean))

xx <- sweep(x,2,x[1,],FUN="-")

b <- barplot(t(xx[c(2:6,20),]),beside=TRUE,col=2:3)
lines(b[1,],x.low10[c(2:6,20),1])
legend("topleft",fill=2:3,legen=c("MSY","Status quo"))

#------------------------
plot.kobe.tidy <- function(vpares,Bmsy,Umsy,Blim=NULL,Bban=NULL,plot.history=FALSE,is.plot=FALSE,pickU="",pickB="",ylab.tmp="U/Umsy",xlab.tmp="SSB/SSBmsy",title.tmp="",HCR=NULL,...){ # HCR=list(beta=0.8)
    
    if (is.null(vpares$wcaa)) vpares$wcaa <- vpares$input$dat$caa * vpares$input$dat$waa
    vpares$TC.MT <- as.numeric(colSums(vpares$wcaa))
    UBdata <- data.frame(years=as.numeric(colnames(vpares$baa)),
                         U=as.numeric(vpares$TC.MT)/as.numeric(colSums(vpares$baa,na.rm=T))/Umsy,
                         B=as.numeric(colSums(vpares$ssb))/Bmsy)

    x <- UBdata$B
    y <- UBdata$U
    tmp <- x>0 & y>0
    x <- x[tmp]
    y <- y[tmp]
    UBdata <- UBdata[tmp,]

    if(!is.null(Blim)){
        Blim.percent <- Blim/Bmsy
    }
    else{
        Blim.percent <- 0.5
    }
    
    plot(x,
         y,type="n",xlim=c(0,ifelse(max(x)<2,2,max(x,na.rm=T))),
         ylim=c(0,ifelse(max(y,na.rm=T)<3,3,max(y,na.rm=T))),
         cex=c(1,rep(1,length(y)-2),3),ylab="",xlab="",axes=F)
    polygon(c(-1,1,1,-1),c(-1,-1,1,1),col="khaki1",border=NA)
    polygon(c(1,6,6,1),c(-1,-1,1,1),col="olivedrab2",border=NA)
    polygon(c(1,6,6,1),c(1,1,6,6),col="khaki1",border=NA)
    polygon(c(-1,Blim.percent,Blim.percent,-1),c(1,1,6,6),col="indianred1",border=NA)
    polygon(c(Blim.percent,1,1,Blim.percent),c(1,1,6,6),col="tan1",border=NA)
    polygon(c(-1,Blim.percent,Blim.percent,-1),c(-1,-1,1,1),col="khaki2",border=NA)
    polygon(c(Blim.percent,1,1,Blim.percent),c(-1,-1,1,1),col="khaki1",border=NA)            

    if(!is.null(HCR)){
        lines(c(Bban/Bmsy,Blim/Bmsy,6),c(0,0.8,0.8),lty=2)
    }


#      points(x,y,type="o",pch=c(3,rep(1,length(y)-2),20),col=c(1,rep(1,length(y)-2),1),cex=c(1,r
      points(x,y,type="l",pch=20,col=gray(0.3),lwd=4)
#      points(x,y,type="p",pch=20,col=gray(c(seq(from=0.7,to=0,length=length(x)))),cex=1.2)
      points(rev(x)[1],rev(y)[1],type="p",pch=20,cex=2.5)
    title(title.tmp,adj=0.8,line=-2)
    
    if(isTRUE(plot.history)){
      plot(UBdata$years,y,type="b",ylab="U/Umsy",xlab="Year",ylim=c(0,max(y)))
      abline(h=1)
      plot(UBdata$years,x,type="b",ylab="SSB/SSBmsy",xlab="Year",ylim=c(0,max(y)))
      abline(h=1); abline(h=Blim.percent,lty=2)
    }


    invisible(UBdata)    
}

library(tidyverse)
library(gridExtra)
#x <- t(matrix(1:6,2,3))
#colnames(x) <- c("テスト","資源量")

# 表で示す有効数字 => 最小の管理基準値で2桁表示されるresolution?
# ==> Rで出力するには複雑すぎる、、、表としてRの外で最初から整形したほうが
#current.year <- 2011
#refs$Bcurrent <- sum(res.pma$ssb[current.year==names(res.pma$ssb)])
#refs$Ucurrent <- sum(res.pma$wcaa[current.year==names(res.pma$ssb)])/sum(res.pma$baa[current.year==names(res.pma$ssb)])

#refs %>% as.data.frame() %>% as.tibble %>% format(digits=2)
#x <- cbind(RP.name=names(refs),value=as.numeric(refs)) %>%
#    mutate(value.format=format(value,digit=2,big.mark=",")) 

#grid.arrange(tableGrob(select(x,RP.name,value.format)))

get.summaryplot <- function(res.pma,refs,MSY.HS){
layout(t(as.matrix(c(1,2,3,4))),height=1,width=c(0.7,0.7,0.7,1))
par(mar=c(2,3,3,0.5),ps=18)
RP.summary <- data.frame(RP.name=names(refs),value=as.numeric(refs))[c(-1:-3,-7),]
RP.summary <- rbind(RP.summary,data.frame(RP.name="Bcurrent (2011)",value=rev(colSums(res.pma$ssb))[1]))
RP.summary <- rbind(RP.summary,data.frame(RP.name="Ucurrent (2011)",value=rev(colSums(res.pma$wcaa))[1]/rev(colSums(res.pma$baa))[1]))
plot.info(RP.summary)
title("管理基準値",adj=0)

col.level <- c("indianred1","khaki2","khaki1","olivedrab2","indianred1","tan1")
aa <- plot.kobe.tidy(res.pma,refs$Bmsy,refs$Umsy,refs$Blim,refs$Bban)
last_year_ratio <- aa[nrow(aa),]
lines(rep(last_year_ratio[3],2),c(0,last_year_ratio[2]),lty=2)
lines(c(0,last_year_ratio[3]),rep(last_year_ratio[2],2),lty=2)
text(last_year_ratio[3],0.1,round(last_year_ratio[3],2))
text(0.1,last_year_ratio[2],round(last_year_ratio[2],2))
title("資源の現状",adj=0)

par(mar=c(4,3,3,0.5),ps=18)
vssb11 <- table(cut(MSY.HS$vssb[11,],breaks=c(0,refs$Bban,refs$Blim,refs$Bmsy,Inf)))/ncol(MSY.HS$vssb)*100
vssb21 <- table(cut(MSY.HS$vssb[21,],breaks=c(0,refs$Bban,refs$Blim,refs$Bmsy,Inf)))/ncol(MSY.HS$vssb)*100
bb <- barplot(xx <- cbind(vssb11,vssb21),col=col.level[1:4],names=rownames(MSY.HS$vssb)[c(11,21)],border=NA,
              yaxt="n",legend.text=c("禁漁","要回復","目標以下","目標以上"),xlim=c(0,4))
xx.tmp <- apply(xx,2,cumsum)-xx/2
for(i in 1:2) text(rep(bb[i],4),xx.tmp[,i],paste(round(xx[,i]),"%",sep=""))
title("将来の親魚資源量",adj=0)

last.catch <- colSums(res.pma$input$dat$waa * res.pma$input$dat$caa)
last.catch <- last.catch[last.catch>0]
last.catch <- rev(last.catch)[1] *1.5
xx <- MSY.HS$vwcaa[1:5,]#-last.catch
xx.mean <- c(last.catch,rowMeans(xx))

par(mar=c(3,4,3,1))
aa <- barplot(xx.mean,yaxt="n",ylim=c(0,max(xx.mean)*1.3),
              col=c("white",rep("skyblue",5)))
abline(h=last.catch,lty=2)
#text(-diff(aa[1:2,1]/2),last.catch,paste("2017\n catch=\n",round(last.catch),sep=""))
ci50 <- apply(xx,1,quantile,probs=c(0.1,0.9))
for(i in 1:(nrow(aa)-1)) arrows(aa[i+1,1],ci50[1,i],aa[i+1,1],
                                ci50[2,i],angle=90,code=3,lwd=2,col=gray(0.4),length=0.1)
text(aa[,1],max(xx.mean)*0.1,round(xx.mean))
title("将来(2012〜)の漁獲量",adj=0)
}

pdf("summaryplot.pdf",family="Japan1GothicBBB",width=13,height=3)
get.summaryplot(res.pma,refs,MSY.HS)
dev.off()


