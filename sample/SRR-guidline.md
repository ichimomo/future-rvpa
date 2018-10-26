---
title: "<8d>Đ<b6><8e>Y<8a>֌W<83>`<83>F<83>b<83>N<83><8a><83>X<83>g"
author: ""
date: ""
output: html_document 
---


<8d>Đ<b6><8e>Y<8a>֌W<82>̑I<91><f0><81>E<90>f<92>f<82><f0><8d>s<82><a4><82><bd><82>߂̃`<83>F<83>b<83>N<83><8a><83>X<83>g<82>ł<b7><81>B<82><b1><82><b1><82>ŁA<8f><ab><97><88><97>\<91><aa><81>E<8a>Ǘ<9d><8a><92>l<8c>v<8e>Z<83>`<83><85><81>[<83>g<83><8a><83>A<83><8b> (../docs/future-doc-abc.html) <82>̗<e1><82><f0><8e>g<82><c1><82>Đ<e0><96><be><82><b5><82>܂<b7><81>B
  
<!-- ## 0. <8e>g<97>p<83>f<81>[<83>^<81>E<89><f0><90>̓R<81>[<83>h<93><99> -->

<!-- <89><c1><93><fc><97>ʁE<90>e<8b><9b><97>ʃf<81>[<83>^<81>F<95><bd><90><ac>29<94>N<93>x<94>N<93>x<83>}<83>T<83>o<91><be><95><bd><97>m<8c>n<8c>Q<8e><91><8c><b9><95>]<89><bf><95>[<82>ɂ<a8><82><af><82><e9><89><c1><93><fc><97>ʁE<90>e<8b><9b><97>ʃf<81>[<83>^   -->
<!-- <8a><fa><8a>ԁF1970~2016<94>N    -->
<!-- <8e>g<97>p<83>v<83><8d><83>O<83><89><83><80>:future.vpa1.11   -->
<!-- <8a><ab><97>v<88><f6><83>f<81>[<83>^<81>F<82>Ȃ<b5>   -->
  
## 1. <8d>Đ<b6><8e>Y<8a>֌W<8c>^<82>̔<e4><8a>r

Hockey-Stick<8c>^/Beverton-Holt<8c>^/Ricker<8c>^<82>̍Đ<b6><8e>Y<8a>֌W<82><f0><94><e4><8a>r<82><b5><82>܂<b7><81>B


```r
SRdata <- get.SRdata(res.pma) #res.pma: vpa������̌������������������

resHS <- fit.SR(SRdata,SR="HS",method="L2",AR=0)
resBH <- fit.SR(SRdata,SR="BH",method="L2",AR=0)
resRI <- fit.SR(SRdata,SR="RI",method="L2",AR=0)

plot(SRdata$R ~ SRdata$SSB, cex=2, type = "b",xlab="SSB",ylab="R",
     main="HS vs. BH vs. RI",ylim=c(0,max(SRdata$R)*1.3),xlim=c(0,max(SRdata$SSB)*1.1))
points(rev(SRdata$SSB)[1],rev(SRdata$R)[1],col=1,type="p",lwd=3,pch=16,cex=2)
points(resHS$pred$SSB,resHS$pred$R,col=2,type="l",lwd=3)
points(resBH$pred$SSB,resBH$pred$R,col=3,type="l",lwd=3,lty=2)    
points(resRI$pred$SSB,resRI$pred$R,col=4,type="l",lwd=3,lty=3)
legend("topleft",
       legend=c(sprintf("HS %5.2f",resHS$AICc),sprintf("BH %5.2f",resBH$AICc),sprintf("RI %5.2f",resRI$AICc)),
       lty=1:3,col=2:4,lwd=2,title="AICc",ncol=3)
```

![plot of chunk unnamed-chunk-1](figure/unnamed-chunk-1-1.png)

```r
resSR <- resHS #HS<82><f0><91>I<91><f0>
```
    
**<91>I<91><f0><82><b5><82><bd><8d>Đ<b6><8e>Y<8a>֌W<81>FHockey-Stick**
  
<97><9d><97>R<81>i<93><c1><82><c9>BH<82><e2>RI<82>̏ꍇ<82>͏ڂ<b5><82><ad><81>j<81>F
BH<82><c6>RI<82>ł͍Đ<b6><8e>Y<8a>֌W<82><aa><82>قڒ<bc><90><fc><82>ɂȂ邽<82>߁AHS<82><f0><91>I<91><f0><82><b5><82><bd><81>BAICc<82><e0>HS<82><aa><82><e2><82>⏬<82><b3><82><a2><81>B   


## 2. <8d>ŏ<ac><90><e2><91>Βl<96>@<82><e2><8e>c<8d><b7><82>̎<a9><8c>ȑ<8a><8a>ւ̌<9f><93><a2>

<83>T<83><93><83>v<83><8b><90><94><82><aa><8f><ad><82>Ȃ<a2><8f>ꍇ<82><e2><8e>c<8d><b7><82><aa><90><b3><8b>K<95><aa><95>z<82>ɏ]<82><c1><82>Ă<a2><82>Ȃ<a2><8f>ꍇ<81>i3<90>ߎQ<8f>Ɓj<81>A<8a>O<82><ea><92>l<82>ɑ΂<b5><82>Ċ挒<82>Ȑ<84><92><e8><95><fb><96>@<82>ł<a0><82><e9><8d>ŏ<ac><90><e2><91>Βl<96>@<81>i<92><86><89><9b><92>l<90><84><92><e8><81>j<82><aa><97>L<8c><f8><82>ȃI<83>v<83>V<83><87><83><93><82>Ƃ<b5><82>čl<82><a6><82><e7><82><ea><82>܂<b7><81>B
<82>܂<bd><81>A<89><c1><93><fc><82>̎c<8d><b7><82><aa><8a><ab><89>e<8b><bf><82>Ȃǂɂ<e6><82>莞<8a>ԓI<82>ȃg<83><8c><83><93><83>h<82><f0><82><e0><82>ꍇ<82>ɂ́i4<90>ߎQ<8f>Ɓj<81>A<8e>c<8d><b7><82>̎<a9><8c>ȑ<8a><8a>ւ<f0><8d>l<97><b6><82><b7><82><e9><95><fb><96>@<82><aa><8d>l<82><a6><82><e7><82><ea><82>܂<b7><81>B
<82><b1><82><b1><82>ł́A<82><b1><82><ea><82><e7><82>̎<e8><96>@<82>ɂ<e6><82><e8><8d>Đ<b6><8e>Y<8a>֌W<82><aa><82>ǂ̒<f6><93>x<95>ς<ed><82><e9><82>̂<a9><82><f0><83>`<83>F<83>b<83>N<82><b5><82>܂<b7><81>B


```r
resAR1 <- fit.SR(SRdata,SR="HS",method="L2",AR=1)
resL1 <- fit.SR(SRdata,SR="HS",method="L1",AR=0)

plot(SRdata$R ~ SRdata$SSB, cex=2, type = "b",xlab="SSB",ylab="R",
     main="Effects of autocorrelation and L1",ylim=c(0,max(SRdata$R)*1.3),xlim=c(0,max(SRdata$SSB)*1.1))
points(rev(SRdata$SSB)[1],rev(SRdata$R)[1],col=1,type="p",lwd=3,pch=16,cex=2)
points(resSR$pred$SSB,resSR$pred$R,col=2,type="l",lwd=3)
points(resAR1$pred$SSB,resAR1$pred$R,col=3,type="l",lwd=3,lty=2)    
points(resL1$pred$SSB,resL1$pred$R,col=4,type="l",lwd=3,lty=3)
legend("topleft",
       legend=c(sprintf("L2&AR0 %5.2f",resSR$AICc),sprintf("L2&AR1 %5.2f",resAR1$AICc),sprintf("L1&AR0 %5.2f",resL1$AICc)),
       lty=1:3,col=2:4,lwd=2,title="AICc",ncol=3)
```

![plot of chunk unnamed-chunk-2](figure/unnamed-chunk-2-1.png)

```r
resSR <- resL1 #L1 norm������������������̗p
```

**<91>I<91><f0><82><b5><82><bd><8d>Đ<b6><8e>Y<8a>֌W<81>FL1&AR0**  
  
<97><9d><97>R<81>F
<8e><a9><8c>ȑ<8a><8a>ւ𐄒肵<82><bd><8f>ꍇ<81>A<8e><a9><8c>ȑ<8a><8a>֌W<90><94><82>͒Ⴍ(rho=0.05)<81>AAICc<82>͍<82><82><ad><82>Ȃ<c1><82><bd><81>B<8e>c<8d><b7><82><aa><90><b3><8b>K<95><aa><95>z<82>ɏ]<82><c1><82>Ă<a2><82>Ȃ<a9><82><c1><82><bd><82><bd><82>߁i<89><ba><8b>L<8e>Q<8f>Ɓj<81>A<8d>Đ<b6><8e>Y<8a>֌W<82>͑傫<82><ad><95>ς<ed><82><e7><82>Ȃ<a2><82><e0><82>̂́A<8d>ŏ<ac><90><e2><91>Βl<96>@<82>ɂ<e6><82>钆<89><9b><92>l<90><84><92><e8><82><f0><8d>̗p<82><b5><82><bd><81>B   
  
  
## 3. <90><b3><8b>K<90><ab><82>̃`<83>F<83>b<83>N

<8d>Đ<b6><8e>Y<8a>֌W<82><a9><82><e7><97>\<91><aa><82><b3><82><ea><82><e9><89><c1><93><fc><97>ʂƊϑ<aa><92>l<81>i<8e><91><8c><b9><95>]<89><bf><92>l<81>j<82>̎c<8d><b7><82><aa><90><b3><8b>K<95><aa><95>z<82>ɏ]<82><c1><82>Ă<a2><82>邩<82><f0><83>`<83>F<83>b<83>N<82><b5><82>܂<b7><81>B
Shapiro-Wilk<8c><9f><92><e8><82><c6>Kolmogorov-Smirnov <8c><9f><92><e8><82><f0><8d>s<82><a2><81>A<81>u<8e>c<8d><b7><82><aa><90><b3><8b>K<95><aa><95>z<82>ɏ]<82><c1><82>Ă<a2><82><e9><81>v<82>Ƃ<a2><82><a4><8b>A<96><b3><89><bc><90><e0><82><f0><8c><9f><92>肵<82>܂<b7><81>B
<82>܂<bd><81>AQQ plot<82><f0><95>`<82><ab><81>A<97><9d><98>_<97>\<91><aa><92>l (y=x) <82><a9><82><e7><91>傫<82><ad><88><ed><92>E<82><b5><82>Ă<a2><82>Ȃ<a2><82><a9><82><f0><83>`<83>F<83>b<83>N<82><b5><82>܂<b7><81>B
<82><b1><82><ea><82><e7><82>̌<8b><89>ʁA<90><b3><8b>K<90><ab><82><aa><8b>^<82><ed><82><ea><82><e9><8f>ꍇ<82>ɂ͍ŏ<ac><90><e2><91>Βl<96>@<82><f0><8c><9f><93><a2><82><b7><82>邱<82>Ƃ<aa><96>]<82>܂<b5><82><a2><82>ł<b7><81>B
  

```r
check1 <- shapiro.test(resSR$resid)
check2 <- ks.test(resSR$resid,y="pnorm")

par(mfrow=c(1,2),mar=c(4,4,2,2))
hist(resSR$resid,xlab="Residuals",main="Normality test",freq=FALSE)
X <- seq(min(resSR$resid)*1.3,max(resSR$resid)*1.3,length=200)
points(X,dnorm(X,0,resSR$pars$sigma),col=2,lwd=3,type="l")
```

```
## Error in dnorm(X, 0, resSR$pars$sigma):  数学関数に非数値引数が渡されました
```

```r
mtext(text=" P value",adj=1,line=-1,lwd=2,font=2)
mtext(text=sprintf(" SW: %1.3f",check1$p.value),adj=1,line=-2)
mtext(text=sprintf(" KS: %1.3f",check2$p.value),adj=1,line=-3)

qqnorm(resSR$resid2,cex=2)
qqline(resSR$resid2,lwd=3)
```

![plot of chunk unnamed-chunk-3](figure/unnamed-chunk-3-1.png)
  
<90>f<92>f<8c><8b><89>ʁFKolmogorov-Smirnov <8c><9f><92><e8><82>ł͗L<88>ӂƂȂ<e8><81>A<90><b3><8b>K<95><aa><95>z<82>ɏ]<82><c1><82>ĂȂ<a2><82><b1><82>Ƃ<aa><8e><a6><8d><b4><82><b3><82>ꂽ<81>BQQ plot<82><e0><82><e2><82>Ⓖ<90><fc><82>Ƃ͂<b8><82><ea><82>Ă<a2><82><bd><81>B  
  
  
## 4. <8e>c<8d><b7><82>̃g<83><8c><83><93><83>h<82>Ǝ<a9><8c>ȑ<8a><8a>֌W<90><94>

<8e>c<8d><b7><82>̎<9e><8a>ԓI<82>ȃg<83><8c><83><93><83>h<82><f0><83>`<83>F<83>b<83>N<82><b5><82>܂<b7><81>B
<83>g<83><8c><83><93><83>h<82><aa><8c><a9><82><e7><82>ꂽ<82><e8><81>A<8e><a9><8c>ȑ<8a><8a>֌W<90><94><82><aa><97>L<88>ӂł<a0><82><e9><8f>ꍇ<82>ɂ́A<8e>c<8d><b7><82>̎<a9><8c>ȑ<8a><8a>ւ<f0><8d>l<97><b6><82><b5><82><bd><8d>Đ<b6><8e>Y<8a>֌W<82><f0><8c><9f><93><a2><82><b7><82>邱<82>Ƃ<aa><96>]<82>܂<b5><82><a2><82>ł<b7><81>B


```r
par(mfrow=c(1,2),mar=c(4,4,2,2))
plot(SRdata$year, resSR$resid2,pch=16,main="",xlab="Year",ylab="Residual")
abline(0,0,lty=2)
par(new=T)
scatter.smooth(SRdata$year, resSR$resid2, lpars=list(col="red", lwd=2),ann=F,axes=FALSE)
ac.res <- acf(resSR$resid2,plot=FALSE)
plot(ac.res,main="",lwd=3)
```

![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4-1.png)

<90>f<92>f<8c><8b><89>ʁF<8e>c<8d><b7><82>Ɏ<9e><8a>ԓI<82>ȃg<83><8c><83><93><83>h<82>͌<a9><82><e7><82><ea><82>邪<81>A<8e><a9><8c>ȑ<8a><8a>֌W<90><94><82>͗L<88>ӂłȂ<a9><82><c1><82><bd><81>B  
  
  
## 5. <8e>c<8d><b7><83>u<81>[<83>g<83>X<83>g<83><89><83>b<83>v

<83>p<83><89><83><81><81>[<83>^<90><84><92><e8><82>̐M<97><8a><90><ab><82><f0><83>`<83>F<83>b<83>N<82><b7><82>邽<82>߂ɁA<8e>c<8d><b7><83>u<81>[<83>g<83>X<83>g<83><89><83>b<83>v<82><f0><8d>s<82><a2><82>܂<b7><81>B<90>M<97><8a><8b><e6><8a>Ԃ<aa><8d>L<82><a2><8f>ꍇ<82><e2><81>A<83>u<81>[<83>g<83>X<83>g<83><89><83>b<83>v<82>̒<86><89><9b><92>l<82>Ɠ_<90><84><92><e8><92>l<82>̘<a8><97><a3><82><aa><91>傫<82><a2><8f>ꍇ<82>ɂ́A<83>p<83><89><83><81><81>[<83>^<90><84><92><e8><82>̐M<97><8a><90><ab><82><aa><92>Ⴂ<82><b1><82>ƂɂȂ<e8><82>܂<b7><81>B


```r
boot.res <- boot.SR(resSR)

par(mfrow=c(2,2),mar=c(4,4,2,2))
hist(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$a),xlab="",ylab="",main="a")
abline(v=resSR$pars$a,col=2,lwd=3)
abline(v=median(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$a)),col=3,lwd=3,lty=2)
arrows(quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$a),0.1),0,
       quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$a),0.9),0,
       col=4,lwd=3,code=3)
legend("topright",
       legend=c("Estimate","Median","CI(0.8)"),lty=1:2,col=2:4,lwd=2,ncol=1,cex=1)

hist(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$b),xlab="",ylab="",main="b")
abline(v=resSR$pars$b,col=2,lwd=3)
abline(v=median(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$b)),col=3,lwd=3,lty=2)
arrows(quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$b),0.1),0,
       quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$b),0.9),0,
       col=4,lwd=3,code=3)

hist(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$sigma),xlab="",ylab="",main="sigma")
```

```
## Error in hist.default(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$sigma), : 'x' must be numeric
```

```r
abline(v=resSR$pars$sigma,col=2,lwd=3)
abline(v=median(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$sigma)),col=3,lwd=3,lty=2)
```

```
## Error in sort.int(x, na.last = na.last, decreasing = decreasing, ...): 'x' must be atomic
```

```r
arrows(quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$sigma),0.1),0,
       quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$sigma),0.9),0,
       col=4,lwd=3,code=3)
```

```
## Error in sort.int(x, na.last = na.last, decreasing = decreasing, ...): 'x' must be atomic
```

```r
if (resSR$input$AR==1) {
  hist(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$rho),xlab="",ylab="",main="rho")
  abline(v=resSR$pars$rho,col=2,lwd=3)
  abline(v=median(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$rho)),col=3,lwd=3,lty=2)
  arrows(quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$rho),0.1),0,
         quantile(sapply(1:length(boot.res), function(i) boot.res[[i]]$pars$rho),0.9),0,
         col=4,lwd=3,code=3)
}

par(mfrow=c(1,1))
```

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5-1.png)

```r
plot(SRdata$R ~ SRdata$SSB, cex=2, type = "b",xlab="SSB",ylab="R",
     main="Residual bootstrap",ylim=c(0,max(SRdata$R)*1.3))
points(rev(SRdata$SSB)[1],rev(SRdata$R)[1],col=1,type="p",lwd=3,pch=16,cex=2)
for (i in 1:length(boot.res)) {
  points(boot.res[[i]]$pred$SSB,boot.res[[i]]$pred$R,type="l",lwd=2,col=rgb(0,0,1,alpha=0.1))
}
points(resSR$pred$SSB,resSR$pred$R,col=2,type="l",lwd=3)
```

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5-2.png)

<90>f<92>f<8c><8b><89>ʁF<83>p<83><89><83><81><81>[<83>^a<82><c6>b<82>́A<83>u<81>[<83>g<83>X<83>g<83><89><83>b<83>v<90><84><92><e8><92>l<82>̒<86><89><9b><92>l<82>Ɠ_<90><84><92><e8><92>l<82><aa><82>قڈ<ea><92>v<82><b5><82><bd><81>Bsigma<82>͂<e2><82>₸<82><ea><82>Ă<a2><82><bd><81>B
<8d>Đ<b6><8e>Y<8a>֌W<82>͔<e4><8a>r<93>I<83><8d><83>o<83>X<83>g<82>ł<a0><82><c1><82><bd><81>B
  
## 6. <83>W<83><83><83>b<83>N<83>i<83>C<83>t<90><84><92><e8>

<83>p<83><89><83><81><81>[<83>^<90><84><92><e8><82>̊挒<90><ab><82>𒲂ׂ邽<82>߂ɁA<88><ea><93>_<82><b8><82><9c><82><a2><82>ăf<81>[<83>^<82><f0><83>W<83><83><83>b<83>N<83>i<83>C<83>t<89><f0><90>͂<f0><8d>s<82><a2><82>܂<b7><81>B<82><b1><82><ea><82>ɂ<e6><82><e8><81>A<82>ǂ̔N<82>̃f<81>[<83>^<82>̉e<8b><bf><82><aa><91>傫<82><a2><82><a9><82><aa><96><be><82>炩<82>ɂȂ<e8><82>܂<b7><81>B  


```r
jack.res <- lapply(1:length(SRdata$year), function(i){
  jack <- resSR
  jack$input$w[i] <- 0
  do.call(fit.SR,jack$input)
})

par(mfrow=c(2,2),mar=c(4,4,2,2))
plot(SRdata$year,sapply(1:length(SRdata$year), function(i) jack.res[[i]]$pars$a),type="b",
     xlab="Removed year",ylab="",main="a",pch=19)
abline(resSR$pars$a,0,lwd=3,col=2)

plot(SRdata$year,sapply(1:length(SRdata$year), function(i) jack.res[[i]]$pars$b),type="b",
     xlab="Removed year",ylab="",main="b",pch=19)
abline(resSR$pars$b,0,lwd=3,col=2)

plot(SRdata$year,sapply(1:length(SRdata$year), function(i) jack.res[[i]]$pars$sigma),type="b",
     xlab="Removed year",ylab="",main="sigma",pch=19)
```

```
## Error in xy.coords(x, y, xlabel, ylabel, log):  (list) オブジェクトは 'double' に変換できません
```

```r
abline(resSR$pars$sigma,0,lwd=3,col=2)

if (resSR$input$AR==1){
  plot(SRdata$year,sapply(1:length(SRdata$year), function(i) jack.res[[i]]$pars$rho),type="b",
       xlab="Removed year",ylab="",main="rho",pch=19)
  abline(resSR$pars$rho,0,lwd=3,col=2)
}

par(mfrow=c(1,1))  
```

![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-1.png)

```r
plot(SRdata$R ~ SRdata$SSB, cex=2, type = "b",xlab="SSB",ylab="R",
     main="Jackknife estimate",ylim=c(0,max(SRdata$R)*1.3))
points(rev(SRdata$SSB)[1],rev(SRdata$R)[1],col=1,type="p",lwd=3,pch=16,cex=2)
for (i in 1:length(jack.res)) {
  points(jack.res[[i]]$pred$SSB,jack.res[[i]]$pred$R,type="l",lwd=3,col=rgb(0,0,1,alpha=0.1))
}
points(resSR$pred$SSB,resSR$pred$R,col=2,type="l",lwd=3)
```

![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6-2.png)

<90>f<92>f<8c><8b><89>ʁF1992<94>N<81>E2000<94>N<82>̃f<81>[<83>^<82><f0><8f><9c><82><ad><82><c6>b<82>̐<84><92><e8><92>l<82><aa><91>傫<82><ad><82>Ȃ<e9><81>B
<82><bb><82>̂ق<a9><82>̃p<83><89><83><81><81>[<83>^<82>͊e<83>f<81>[<83>^<82>̏<9c><8b><8e><82>ɑ΂<b5><82>Ĕ<e4><8a>r<93>I<8a>挒<82>ł<a0><82><e9><81>B  

  

## 7. <83>v<83><8d><83>t<83>@<83>C<83><8b><96>ޓx

<83>p<83><89><83><81><81>[<83>^a, b<82>̒l<82><f0><95>ς<a6><82><bd><82>Ƃ<ab><82>ɖޓx<82><aa><82>ǂ̒<f6><93>x<95>ω<bb><82><b7><82>邩<82><f0><89><f0><90>͂<b5><82>܂<b7><81>B<82><b1><82><b1><82>ł́Asigma<82><e2>rho<82>͍Ŗސ<84><92><e8><92>l<82>ɌŒ肵<82>Ă<a2><82>܂<b7><81>B<82><b1><82>̌<8b><89>ʂƃu<81>[<83>g<83>X<83>g<83><89><83>b<83>v<90>M<97><8a><8b><e6><8a>Ԃ<a8><82><e6><82>уW<83><83><83>b<83>N<83>i<83>C<83>t<89><f0><90>͂̌<8b><89>ʂ<e0><93><af><8e><9e><82>ɐ}<8e><a6><82><b5><82>܂<b7><81>B



```r
ngrid <- 100
a.grid <- seq(resSR$pars$a*0.5,resSR$pars$a*1.5,length=ngrid)
b.grid <- seq(min(SRdata$SSB),max(SRdata$SSB),length=ngrid)
ba.grids <- expand.grid(b.grid,a.grid)
prof.lik.res <- sapply(1:nrow(ba.grids),function(i) prof.lik(resSR,a=as.numeric(ba.grids[i,2]),b=as.numeric(ba.grids[i,1])))

image(b.grid,a.grid,matrix(prof.lik.res,nrow=ngrid),ann=F,col=cm.colors(12),
      ylim=c(resSR$pars$a*0.5,resSR$pars$a*1.5),xlim=c(min(SRdata$SSB),max(SRdata$SSB)))
par(new=T, xaxs="i",yaxs="i")
contour(b.grid,a.grid,matrix(prof.lik.res,nrow=ngrid),
        ylim=c(resSR$pars$a*0.5,resSR$pars$a*1.5),xlim=c(min(SRdata$SSB),max(SRdata$SSB)),
        xlab="b",ylab="a",main="Profile likelihood")
for(i in 1:length(jack.res)) points(jack.res[[i]]$pars$b,jack.res[[i]]$pars$a,lwd=1,col=1)

lines(y=as.numeric(quantile(sapply(1:length(boot.res),function(i)boot.res[[i]]$pars$a),c(0.1,0.9))),
      x=rep(resSR$pars$b,2),col=4,lwd=2)
lines(x=as.numeric(quantile(sapply(1:length(boot.res),function(i)boot.res[[i]]$pars$b),c(0.1,0.9))),
      y=rep(resSR$pars$a,2),col=4,lwd=2)
legend("bottomleft",c("Bootstrap CI(0.8)","Jackknife"),lty=1:0,pch=c("","<81><9b>"),col=c(4,1),lwd=2:1)
```

```
## Error:  構文解析中に不正なマルチバイト文字列がありました (19 行)
```

<90>f<92>f<8c><8b><89>ʁF<83>p<83><89><83><81><81>[<83>^b<82>̒l<82><aa><91>傫<82><ad><82>Ȃ<c1><82>Ă<e0><96>ޓx<82>̕ω<bb><82>͔<e4><8a>r<93>I<8f><ac><82><b3><82><a2>
  


<!-- ## 7. <82>܂Ƃ<df> -->
