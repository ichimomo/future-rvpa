convert_df <- function(df,name){
    df %>%
        as_tibble %>%  
        mutate(age = rownames(.)) %>% 
        gather(key=year, value=value, -age, convert=TRUE) %>%
        group_by(year) %>%
        summarise(value=sum(value)) %>%
        mutate(type="vpa",sim="s0",stat=name)    
}

convert_future_table <- function(fout,label="tmp"){
    
    ssb <- fout$vssb %>%
        as_tibble %>%
        mutate(year=rownames(fout$vssb)) %>%
        gather(key=sim, value=value, -year, convert=TRUE) %>%
        mutate(year=as.numeric(year),stat="ssb",label=label)

    catch <- fout$vwcaa %>%
        as_tibble %>%
        mutate(year=rownames(fout$vssb)) %>%
        gather(key=sim, value=value, -year, convert=TRUE) %>%
        mutate(year=as.numeric(year),stat="catch",label=label)

    bind_rows(ssb,catch)
}
        
    
convert_vector <- function(vector,name){
    vector %>%
        as_tibble %>%  
        mutate(year = as.integer(names(vector))) %>% 
        mutate(type="vpa",sim="s0",stat=name,age=NA) 
} 

convert_vpa_tibble <- function(vpares){
    total.catch <- colSums(vpares$input$dat$caa*vpares$input$dat$waa)
    U <- total.catch/colSums(vpares$baa)
    
    bind_rows(convert_vector(colSums(vpares$ssb),"SSB"),
              convert_vector(colSums(vpares$baa),"total_biomass"),
              convert_vector(U,"U"),
              convert_vector(total.catch,"total_catch"),
              convert_df(vpares$naa,"fish_number"),
              convert_df(vpares$faa,"fishing_mortality"),              
              convert_df(vpares$input$dat$waa,"weight"),
              convert_df(vpares$input$dat$maa,"maturity"),
              convert_df(vpares$input$dat$caa,"catch_number"))
}

SRplot_gg <- function(SR_result,refs=NULL){
    SRdata <- as_tibble(SR_result$input$SRdata) %>%
        mutate(type="obs")
    SRdata.pred <- as_tibble(SR_result$pred) %>%
        mutate(type="pred",year=NA)    
    alldata <- bind_rows(SRdata,SRdata.pred)
    ymax <- max(alldata$R)
    g1 <- ggplot() +
        geom_point(data=dplyr::filter(alldata,type=="obs"),
                   aes(y=R,x=SSB,color=year)) +
        geom_label_repel(data=dplyr::filter(alldata,type=="obs"),
                 aes(y=R,x=SSB,label=year),size=3,box.padding=0.5,segment.color="gray") +        
        geom_line(data=dplyr::filter(alldata,type=="pred"),
                  aes(y=R,x=SSB)) +
        theme_bw()+
        theme(panel.grid = element_blank()) +
        xlab("親魚資源量")+
        ylab("加入尾数")+        
        coord_cartesian(ylim=c(0,ymax*1.05),expand=0) +
        labs(caption=str_c("関数形: ",SR_result$input$SR,", 自己相関: ",SR_result$input$AR,
                           ", 最適化法",SR_result$input$method,", AICc: ",round(SR_result$AICc,2)))

    if(!is.null(refs)){
        g1 <- g1+geom_vline(xintercept=c(refs$Bmsy,refs$Blim,refs$Bban),linetype=2)
    }
    g1
}



    
plot_yield <- function(MSY_base,refs_base,AR_select=FALSE){
    trace <- MSY_base$trace  %>% as_tibble() %>%
        select(starts_with("TC-mean"),ssb.mean,fmulti,catch.CV) %>%
        mutate(label=as.character(1:nrow(.)))

    trace <- trace %>% gather(value=value,key=age,-label,-fmulti,-ssb.mean,-catch.CV) %>%
        mutate(age=str_extract(age, "[0-9]")) %>%
        mutate(age=factor(age)) %>%
        mutate(age=fct_reorder(age,length(age):1))

    refs_base <- refs_base %>%
        mutate(RP_definition=ifelse(is.na(RP_definition),"",RP_definition)) %>%
        filter(AR==AR_select)
        

trace %>%   ggplot() +
    geom_area(aes(x=ssb.mean,y=value,fill=age)) +
#    geom_line(aes(x=ssb.mean,y=catch.CV,fill=age)) +
#    scale_y_continuous(sec.axis = sec_axis(~.*5, name = "CV catch"))+
    scale_fill_brewer() + theme_bw() +
    geom_point(data=refs_base,aes(y=Catch,x=SSB))+
    geom_label_repel(data=refs_base,
                     aes(y=Catch,x=SSB,
                         label=str_c(RP_name,":",RP_definition)),
                     size=3,box.padding=0.5,segment.color="gray")+
    xlab("平均親魚量") + ylab("平均漁獲量")
}

make_RP_table <- function(refs_base){
    refs_base %>%
        select(-RP_name) %>% # どの列を表示させるか選択する
        # 各列の有効数字を指定
        mutate(SSB=round(SSB,-floor(log10(min(SSB)))),
               Catch=round(Catch,-floor(log10(min(Catch)))),
               U=round(U,2),
               Fref2Fcurrent=round(Fref2Fcurrent,2)) %>%
        rename("管理基準値"=RP_definition,"親魚資源量"=SSB,
               "漁獲量"=Catch,"漁獲率"=U,"努力量の乗数"=Fref2Fcurrent) %>%    
        # 表をhtmlで出力
        formattable::formattable(list(親魚資源量=color_bar("olivedrab"),
                                  漁獲量=color_bar("steelblue"),
                              漁獲率=color_bar("orange"),
                              努力量の乗数=color_bar("tomato")))
}

derive_RP_value <- function(refs_base,RP_name){
    tmp1 <- str_detect(refs_base$RP_definition,RP_name)
    tmp2 <- str_detect(refs_base$RP_name,RP_name)    
    refs_base[tmp1|tmp2,]
}


calc_kobeII_matrix <- function(fres_base,
                              refs_base,
                              Btarget=c("Btarget0"),
                              Blimit=c("Blimit0"),
                              Blow=c("Blow"),
                              Bban=c("Bban"),
                              beta=seq(from=0.5,to=1,by=0.1)){
# HCRの候補を網羅的に設定
    HCR_candidate1 <- expand.grid(
        Btarget_name=refs_base$RP_definition[str_detect(refs_base$RP_definition,Btarget)],
        Blow_name=refs_base$RP_definition[str_detect(refs_base$RP_definition,Blow)],    
        Blimit_name=refs_base$RP_definition[str_detect(refs_base$RP_definition,Blimit)],
        Bban_name=refs_base$RP_definition[str_detect(refs_base$RP_definition,Bban)],
        beta=beta)

    HCR_candidate2 <- expand.grid(
        Btarget=refs_base$SSB[str_detect(refs_base$RP_definition,Btarget)],
        Blow=refs_base$SSB[str_detect(refs_base$RP_definition,Blow)],    
        Blimit=refs_base$SSB[str_detect(refs_base$RP_definition,Blimit)],
        Bban=refs_base$SSB[str_detect(refs_base$RP_definition,Bban)],
        beta=beta) %>% select(-beta)

    HCR_candidate <- bind_cols(HCR_candidate1,HCR_candidate2) %>% as_tibble()
    
    HCR_candidate <- refs_base %>% filter(str_detect(RP_definition,Btarget)) %>%
        mutate(Btarget_name=RP_definition,Fmsy=Fref2Fcurrent) %>%
        select(Btarget_name,Fmsy) %>%
        left_join(HCR_candidate) %>%
        arrange(Btarget_name,Blimit_name,Bban_name,desc(beta))
    
    HCR_candidate$HCR_name <- str_c(HCR_candidate$Btarget_name,
                                    HCR_candidate$Blimit_name,
                                    HCR_candidate$Bban_name,sep="-")
    
    kobeII_table <- HCR.simulation(fres_base$input,HCR_candidate)

    cat(length(unique(HCR_candidate$HCR_name)), "HCR is calculated: ",
        unique(HCR_candidate$HCR_name),"\n")

    kobeII_table <- left_join(kobeII_table,HCR_candidate)
    kobeII_table    
}


HCR.simulation <- function(finput,HCRtable){

    tb <- NULL
    for(i in 1:nrow(HCRtable)){
        HCR_base <- HCRtable[i,]
        finput$multi <- HCR_base$Fmsy
        finput$HCR <- list(Blim=HCR_base$Blimit,Bban=HCR_base$Bban,
                           beta=HCR_base$beta)
        finput$is.plot <- FALSE
        finput$silent <- TRUE
        fres_base <- do.call(future.vpa,finput) # デフォルトルールの結果→図示などに使う
        tmp <- convert_future_table(fres_base,label=HCRtable$HCR_name[i]) %>%
            rename(HCR_name=label)
        tmp$beta <- HCR_base$beta
        tb <- bind_rows(tb,tmp)
    }
    return(tb)
}


get.stat4 <- function(fout,Brefs,
                      refyear=c(2019:2023,2028,2038)){
    col.target <- ifelse(fout$input$N==0,1,-1)
    years <- as.numeric(rownames(fout$vwcaa))

    if(is.null(refyear)){
        refyear <- c(seq(from=min(years),to=min(years)+5),
                           c(min(years)+seq(from=10,to=20,by=5)))
    }

    catch.mean <- rowMeans(fout$vwcaa[years%in%refyear,col.target])
    names(catch.mean) <- str_c("Catch",names(catch.mean)) 
    catch.mean <- as_tibble(t(catch.mean))
    
    Btarget.prob <- rowMeans(fout$vssb[years%in%refyear,col.target]>Brefs$Btarget) %>%
        t() %>% as_tibble() 
    names(Btarget.prob) <- str_c("Btarget_prob",names(Btarget.prob))

    Blow.prob <- rowMeans(fout$vssb[years%in%refyear,col.target]>Brefs$Blow) %>%
        t() %>% as_tibble() 
    names(Blow.prob) <- str_c("Blow_prob",names(Blow.prob))

    Blimit.prob <- rowMeans(fout$vssb[years%in%refyear,col.target]<Brefs$Blimit) %>%
        t() %>% as_tibble() 
    names(Blimit.prob) <- str_c("Blimit_prob",names(Blimit.prob))

    Bban.prob <- rowMeans(fout$vssb[years%in%refyear,col.target]<Brefs$Bban) %>%
        t() %>% as_tibble() 
    names(Bban.prob) <- str_c("Bban_prob",names(Bban.prob))             

    return(bind_cols(catch.mean,Btarget.prob,Blow.prob,Blimit.prob,Bban.prob))
}




plot_kobe_gg <- function(vpares,refs_base,roll_mean=1){ 
    vpa_tb <- convert_vpa_tibble(vpares)
    UBdata <- vpa_tb %>% filter(stat=="U" | stat=="SSB") %>%
        spread(key=stat,value=value) %>%
        mutate(Uratio=roll_mean(U/target.RP$U,n=roll_mean,fill=NA,align="right"),
               Bratio=roll_mean(SSB/target.RP$SSB,n=roll_mean,fill=NA,align="right")) %>%
        arrange(year)

    max.B <- max(c(UBdata$Bratio,1.2),na.rm=T)
    max.U <- max(c(UBdata$Uratio,1.2),na.rm=T)

    kobe.6area <- ggplot(data=UBdata) +
        geom_polygon(data=tibble(x=c(-1,low.ratio,low.ratio,-1),
                                 y=c(-1,-1,1,1)),
                     aes(x=x,y=y),fill="khaki1")+
        geom_polygon(data=tibble(x=c(low.ratio,10,10,low.ratio),
                                 y=c(-1,-1,1,1)),
                     aes(x=x,y=y),fill="olivedrab2")+
        geom_polygon(data=tibble(x=c(low.ratio,10,10,low.ratio),
                                 y=c(1,1,10,10)),
                     aes(x=x,y=y),fill="khaki1")+
        geom_polygon(data=tibble(x=c(-1,limit.ratio,limit.ratio,-1),
                                 y=c(1,1,10,10)),
                     aes(x=x,y=y),fill="indianred1") +
        geom_polygon(data=tibble(x=c(limit.ratio,low.ratio,low.ratio,limit.ratio),
                                 y=c(1,1,10,10)),aes(x=x,y=y),fill="tan1") +
        geom_polygon(data=tibble(x=c(-1,limit.ratio,limit.ratio,-1),
                                 y=c(-1,-1,1,1)),aes(x=x,y=y),fill="khaki2") +
        geom_polygon(data=tibble(x=c(limit.ratio,low.ratio,low.ratio,limit.ratio),
                                 y=c(-1,-1,1,1)),aes(x=x,y=y),fill="khaki1")+
        geom_vline(xintercept=c(1,ban.ratio),linetype=2)

    kobe.4area <- ggplot(data=UBdata) +
        geom_polygon(data=tibble(x=c(-1,low.ratio,low.ratio,-1),
                                 y=c(-1,-1,1,1)),
                     aes(x=x,y=y),fill="khaki1")+
        geom_polygon(data=tibble(x=c(1,10,10,1),
                                 y=c(-1,-1,1,1)),
                     aes(x=x,y=y),fill="olivedrab2")+
        geom_polygon(data=tibble(x=c(1,10,10,1),
                                 y=c(1,1,10,10)),
                     aes(x=x,y=y),fill="khaki1")+
        geom_polygon(data=tibble(x=c(-1,1,1,-1),
                                 y=c(1,1,10,10)),
                     aes(x=x,y=y),fill="indianred1") +
        geom_polygon(data=tibble(x=c(-1,1,1,-1),
                                 y=c(-1,-1,1,1)),aes(x=x,y=y),fill="khaki1")


    g6 <- kobe.6area +
        geom_point(mapping=aes(x=Bratio,y=Uratio,color=year),size=2) +
        geom_path(mapping=aes(x=Bratio,y=Uratio)) +
        coord_cartesian(xlim=c(0,max.B*1.1),ylim=c(0,max.U*1.1),expand=0) +
        ylab("U/Umsy") + xlab("SSB/SSBmsy")  +
        geom_label_repel(data=filter(UBdata,year%%10==0|year==max(year)),
                         aes(x=Bratio,y=Uratio,label=year),
                         size=3,box.padding=2,segment.color="gray")+
        geom_text(data=tibble(x=c(ban.ratio,limit.ratio,low.ratio,1),
                              y=rep(0.1,4),
                              label=c("Bban","Blimit","Blow","Btarget")),
                  aes(x=x,y=y,label=label))

    g4 <- kobe.4area +
        geom_point(mapping=aes(x=Bratio,y=Uratio,color=year),size=2) +
        geom_path(mapping=aes(x=Bratio,y=Uratio)) +
        coord_cartesian(xlim=c(0,max.B*1.1),ylim=c(0,max.U*1.1),expand=0) +
        ylab("U/Umsy") + xlab("SSB/SSBmsy")  +
        geom_label_repel(data=filter(UBdata,year%%10==0|year==max(year)),
                         aes(x=Bratio,y=Uratio,label=year),
                         size=3,box.padding=2,segment.color="gray")+
        geom_vline(xintercept=c(ban.ratio,limit.ratio,low.ratio,1),linetype=2)+
        geom_text(data=tibble(x=c(ban.ratio,limit.ratio,low.ratio,1),
                              y=rep(0.1,4),
                              label=c("Bban","Blimit","Blow","Btarget")),
                  aes(x=x,y=y,label=label))
    list(g4,g6)
}
