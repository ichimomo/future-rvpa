convert_df <- function(df,name){
    df %>%
        as_tibble %>%  
        mutate(age = as.numeric(rownames(df))) %>% 
        gather(key=year, value=value, -age, convert=TRUE) %>%
        group_by(year) %>%
#        summarise(value=sum(value)) %>%
        mutate(type="VPA",sim="s0",stat=name)    
}

convert_future_table <- function(fout,label="tmp"){
    ssb <- fout$vssb %>%
        as_tibble %>%
        mutate(year=rownames(fout$vssb)) %>%
        gather(key=sim, value=value, -year, convert=TRUE) %>%
        mutate(year=as.numeric(year),stat="SSB",label=label)

    catch <- fout$vwcaa %>%
        as_tibble %>%
        mutate(year=rownames(fout$vssb)) %>%
        gather(key=sim, value=value, -year, convert=TRUE) %>%
        mutate(year=as.numeric(year),stat="catch",label=label)

    biomass <- fout$vbiom %>%
        as_tibble %>%
        mutate(year=rownames(fout$vbiom)) %>%
        gather(key=sim, value=value, -year, convert=TRUE) %>%
        mutate(year=as.numeric(year),stat="biomass",label=label)

    alpha_value <- fout$alpha %>%
        as_tibble %>%
        mutate(year=rownames(fout$alpha)) %>%
        gather(key=sim, value=value, -year, convert=TRUE) %>%
        mutate(year=as.numeric(year),stat="alpha",label=label)

    if(is.null(fout$Fsakugen)) fout$Fsakugen <- -(1-fout$faa[1,,]/fout$input$res0$Fc.at.age[1])
    Fsakugen <- fout$Fsakugen %>%
        as_tibble %>%
        mutate(year=rownames(fout$Fsakugen)) %>%
        gather(key=sim, value=value, -year, convert=TRUE) %>%
        mutate(year=as.numeric(year),stat="Fsakugen",label=label)

    if(is.null(fout$recruit)) fout$recruit <- fout$naa[1,,]
    Recruitment <- fout$recruit %>%                                    #追加
        as_tibble %>%                                                   #追加
        mutate(year=rownames(fout$recruit)) %>%                             #追加
        gather(key=sim, value=value, -year, convert=TRUE) %>%           #追加
        mutate(year=as.numeric(year),stat="Recruitment",label=label)   
    
    bind_rows(ssb,catch,biomass,alpha_value,Fsakugen,Recruitment)
}
        
    
convert_vector <- function(vector,name){
    vector %>%
        as_tibble %>%  
        mutate(year = as.integer(names(vector))) %>% 
        mutate(type="VPA",sim="s0",stat=name,age=NA) 
} 

convert_vpa_tibble <- function(vpares){

    total.catch <- colSums(vpares$input$dat$caa*vpares$input$dat$waa,na.rm=T)
    U <- total.catch/colSums(vpares$baa)

    SSB <- convert_vector(colSums(vpares$ssb,na.rm=T),"SSB") %>%
        dplyr::filter(value>0&!is.na(value))
    Biomass <- convert_vector(colSums(vpares$baa,na.rm=T),"biomass") %>%
        dplyr::filter(value>0&!is.na(value))
    FAA <- convert_df(vpares$faa,"fishing_mortality") %>%
        dplyr::filter(value>0&!is.na(value))
    Recruitment <- convert_vector(colSums(vpares$naa[1,,drop=F]),"Recruitment") %>%
        dplyr::filter(value>0&!is.na(value))    
    
    all_table <- bind_rows(SSB,
                           Biomass,
                           convert_vector(U[U>0],"U"),
                           convert_vector(total.catch[total.catch>0],"catch"),
                           convert_df(vpares$naa,"fish_number"),
                           FAA, 
                           convert_df(vpares$input$dat$waa,"weight"),
                           convert_df(vpares$input$dat$maa,"maturity"),
                           convert_df(vpares$input$dat$caa,"catch_number"),
                           Recruitment)
}

SRplot_gg <- function(SR_result,refs=NULL){
    require(tidyverse,quietly=TRUE)    
    require(ggrepel)
    
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

get.trace <- function(trace){
    trace <- trace  %>% as_tibble() %>%
        select(starts_with("TC-mean"),ssb.mean,fmulti,catch.CV) %>%
        mutate(label=as.character(1:nrow(.)))

    trace <- trace %>% gather(value=value,key=age,-label,-fmulti,-ssb.mean,-catch.CV) %>%
        mutate(age=str_extract(age, "[0-9]")) %>%
        mutate(age=factor(age)) %>%
        mutate(age=fct_reorder(age,length(age):1))
    return(trace)
}
    
plot_yield <- function(MSY_obj,refs_base,AR_select=FALSE,xlim.scale=1.1,ylim.scale=1.2,future=NULL,past=NULL,future.name=NULL){
    
    if("trace" %in% names(MSY_obj)) trace.msy <- MSY_obj$trace
    else trace.msy <- MSY_obj
        
    require(tidyverse,quietly=TRUE)
    require(ggrepel)    

    trace <- get.trace(trace.msy)

    refs_base <- refs_base %>%
        mutate(RP.definition=ifelse(is.na(RP.definition),"",RP.definition))
    if("AR"%in%names(refs_base)) refs_base <- refs_base %>% dplyr::filter(AR==AR_select)

    ymax <- trace %>%
        group_by(ssb.mean) %>%
        summarise(catch.mean=sum(value))
    ymax <- max(ymax$catch.mean)

    g1 <- trace %>%   ggplot()

    if(is.null(future.name)) future.name <- 1:length(future)
    
    if(!is.null(future)){
        tmpdata <- NULL
        for(j in 1:length(future)){
            tmpdata <- bind_rows(tmpdata,
                tibble(
                year        =as.numeric(rownames(future[[j]]$vssb)),
                ssb.future  =apply(future[[j]]$vssb[,-1],1,mean),
                catch.future=apply(future[[j]]$vwcaa[,-1],1,mean),
                scenario=future.name[j]))
            }
        tmpdata <- tmpdata %>% group_by(scenario)
        g1 <- g1 +
            geom_point(data=tmpdata,
                       mapping=aes(x=ssb.future,y=catch.future,color=year,
                                   shape=factor(scenario))) +
            geom_path(data=tmpdata,
                      mapping=aes(x=ssb.future,y=catch.future,
                                  linetype=factor(scenario)))
    }

    if(!is.null(past)){
        tmpdata <- tibble(
            year      =as.numeric(colnames(past$ssb)),
            ssb.past  =unlist(colSums(past$ssb)),
            catch.past=unlist(colSums(past$input$dat$caa*past$input$dat$waa))
        )

        g1 <- g1 +
            geom_point(data=tmpdata,mapping=aes(x=ssb.past,y=catch.past,
                                                alpha=year),shape=2) +
            geom_path(data=tmpdata,mapping=aes(x=ssb.past,y=catch.past),color="gray")
    }
    
    g1 <- g1 + geom_area(aes(x=ssb.mean,y=value,fill=age),col="gray",alpha=0.5) +
#    geom_line(aes(x=ssb.mean,y=catch.CV,fill=age)) +
#    scale_y_continuous(sec.axis = sec_axis(~.*5, name = "CV catch"))+
    scale_fill_brewer() + theme_bw() +
    geom_point(data=refs_base,aes(y=Catch,x=SSB))+
    theme(panel.grid = element_blank()) +
    coord_cartesian(xlim=c(0,max(trace$ssb.mean,na.rm=T)*xlim.scale),
                    ylim=c(0,ymax*ylim.scale),expand=0) +    
    geom_label_repel(data=refs_base,
                     aes(y=Catch,x=SSB,
                         label=str_c(RP_name,":",RP.definition)),
                     size=3,box.padding=0.5,segment.color="gray")+
    xlab("平均親魚量") + ylab("平均漁獲量")

    return(g1)
        
}

make_RP_table <- function(refs_base){
    require(formattable)
    require(tidyverse,quietly=TRUE)
    table_output <- refs_base %>%
        select(-RP_name) %>% # どの列を表示させるか選択する
        # 各列の有効数字を指定
        mutate(SSB=round(SSB,-floor(log10(min(SSB)))),
               SSB2SSB0=round(SSB2SSB0,2),                              
               Catch=round(Catch,-floor(log10(min(Catch)))),
               Catch.CV=round(Catch.CV,2),
               U=round(U,2),
               Fref2Fcurrent=round(Fref2Fcurrent,2)) %>%
        rename("管理基準値"=RP.definition,"親魚資源量"=SSB,"B0に対する比"=SSB2SSB0,
               "漁獲量"=Catch,"漁獲量の変動係数"=Catch.CV,"漁獲率"=U,"努力量の乗数"=Fref2Fcurrent)
    
   table_output  %>%    
        # 表をhtmlで出力
        formattable::formattable(list(親魚資源量=color_bar("olivedrab"),
                                  漁獲量=color_bar("steelblue"),
                              漁獲率=color_bar("orange"),
                              努力量の乗数=color_bar("tomato")))

#    return(table_output)
    
}

derive_RP_value <- function(refs_base,RP_name){
#    refs_base %>% dplyr::filter(RP.definition%in%RP_name)
#    subset(refs_base,RP.definition%in%RP_name)
    refs_base[refs_base$RP.definition%in%RP_name,]    
}


calc_kobeII_matrix <- function(fres_base,
                              refs_base,
                              Btarget=c("Btarget0"),
                              Blimit=c("Blimit0"),
                              Blow=c("Blow0"),
                              Bban=c("Bban0"),
                              year.lag=0,
                              beta=seq(from=0.5,to=1,by=0.1)){
    require(tidyverse,quietly=TRUE)    
# HCRの候補を網羅的に設定
#    HCR_candidate1 <- expand.grid(
#        Btarget_name=refs_base$RP.definition[str_detect(refs_base$RP.definition,Btarget)],
#        Blow_name=refs_base$RP.definition[str_detect(refs_base$RP.definition,Blow)],    
#        Blimit_name=refs_base$RP.definition[str_detect(refs_base$RP.definition,Blimit)],
#        Bban_name=refs_base$RP.definition[str_detect(refs_base$RP.definition,Bban)],
    #        beta=beta)

    refs.unique <- unique(c(Btarget,Blimit,Blow,Bban))
    tmp <- !refs.unique%in%refs_base$RP.definition    
    if(sum(tmp)>0) stop(refs.unique[tmp]," does not appear in column of RP.definition\n")

    HCR_candidate1 <- expand.grid(
        Btarget_name=derive_RP_value(refs_base,Btarget)$RP.definition,
        Blow_name=derive_RP_value(refs_base,Blow)$RP.definition,    
        Blimit_name=derive_RP_value(refs_base,Blimit)$RP.definition,
        Bban_name=derive_RP_value(refs_base,Bban)$RP.definition,
        beta=beta)    

    HCR_candidate2 <- expand.grid(
        Btarget=derive_RP_value(refs_base,Btarget)$SSB,
        Blow=derive_RP_value(refs_base,Blow)$SSB,    
        Blimit=derive_RP_value(refs_base,Blimit)$SSB,    
        Bban=derive_RP_value(refs_base,Bban)$SSB,   
        beta=beta) %>% select(-beta)

    HCR_candidate <- bind_cols(HCR_candidate1,HCR_candidate2) %>% as_tibble()
    
    HCR_candidate <- refs_base %>% #dplyr::filter(str_detect(RP.definition,Btarget)) %>%
        dplyr::filter(RP.definition%in%Btarget) %>%
        mutate(Btarget_name=RP.definition,Fmsy=Fref2Fcurrent) %>%
        select(Btarget_name,Fmsy) %>%
        left_join(HCR_candidate) %>%
        arrange(Btarget_name,Blimit_name,Bban_name,desc(beta))
    
    HCR_candidate$HCR_name <- str_c(HCR_candidate$Btarget_name,
                                    HCR_candidate$Blimit_name,
                                    HCR_candidate$Bban_name,sep="-")
    
    kobeII_table <- HCR.simulation(fres_base$input,HCR_candidate,year.lag=year.lag)

    cat(length(unique(HCR_candidate$HCR_name)), "HCR is calculated: ",
        unique(HCR_candidate$HCR_name),"\n")

    kobeII_table <- left_join(kobeII_table,HCR_candidate)
    kobeII_table    
}


HCR.simulation <- function(finput,HCRtable,year.lag=year.lag){
    
    tb <- NULL
    
    for(i in 1:nrow(HCRtable)){
        HCR_base <- HCRtable[i,]
        finput$multi <- HCR_base$Fmsy
        finput$HCR <- list(Blim=HCR_base$Blimit,Bban=HCR_base$Bban,
                           beta=HCR_base$beta,year.lag=year.lag)
        finput$is.plot <- FALSE
        finput$silent <- TRUE
        fres_base <- do.call(future.vpa,finput) # デフォルトルールの結果→図示などに使う
        tmp <- convert_future_table(fres_base,label=HCRtable$HCR_name[i]) %>%
            rename(HCR_name=label) 
        tmp$beta <- HCR_base$beta
        tb <- bind_rows(tb,tmp)
    }
    tb <- tb %>% mutate(scenario=str_c(HCR_name,beta))
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




plot_kobe_gg <- function(vpares,refs_base,roll_mean=1,
                         category=4,# 4区分か、6区分か
                         Btarget=c("Btarget0"),
                         Blimit=c("Blimit0"),
                         Blow=c("Blow0"),
                         Bban=c("Bban0")){
    
    require(tidyverse,quietly=TRUE)
    require(ggrepel,quietly=TRUE)    

    target.RP <- derive_RP_value(refs_base,Btarget)
    limit.RP <- derive_RP_value(refs_base,Blimit)
    low.RP <- derive_RP_value(refs_base,Blow) 
    ban.RP <- derive_RP_value(refs_base,Bban)

    low.ratio <- low.RP$SSB/target.RP$SSB
    limit.ratio <- limit.RP$SSB/target.RP$SSB
    ban.ratio <- ban.RP$SSB/target.RP$SSB        
    
    require(RcppRoll)
    vpa_tb <- convert_vpa_tibble(vpares)
    UBdata <- vpa_tb %>% dplyr::filter(stat=="U" | stat=="SSB") %>%
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
        geom_label_repel(data=dplyr::filter(UBdata,year%%10==0|year==max(year)),
                         aes(x=Bratio,y=Uratio,label=year),
                         size=3,box.padding=2,segment.color="gray")

    g4 <- kobe.4area +
        geom_point(mapping=aes(x=Bratio,y=Uratio,color=year),size=2) +
        geom_path(mapping=aes(x=Bratio,y=Uratio)) +
        coord_cartesian(xlim=c(0,max.B*1.1),ylim=c(0,max.U*1.1),expand=0) +
        ylab("U/Umsy") + xlab("SSB/SSBmsy")  +
        geom_label_repel(data=dplyr::filter(UBdata,year%%10==0|year==max(year)),
                         aes(x=Bratio,y=Uratio,label=year),
                         size=3,box.padding=2,segment.color="gray")


    if(low.ratio<1){
        g6 <- g6 + geom_text(data=tibble(x=c(ban.ratio,limit.ratio,low.ratio,1),
                              y=rep(0.1,4),
                              label=c("Bban","Blimit","Blow","Btarget")),
                             aes(x=x,y=y,label=label))
        g4 <- g4 + geom_vline(xintercept=c(ban.ratio,limit.ratio,low.ratio,1),linetype=2)+
        geom_text(data=tibble(x=c(ban.ratio,limit.ratio,low.ratio,1),
                              y=rep(0.1,4),
                              label=c("Bban","Blimit","Blow","Btarget")),
                  aes(x=x,y=y,label=label))
    }else{
        g6 <- g6 + geom_text(data=tibble(x=c(ban.ratio,limit.ratio,1),
                              y=rep(0.1,3),
                              label=c("Bban","Blimit","Btarget")),
                             aes(x=x,y=y,label=label))
        g4 <- g4 + geom_vline(xintercept=c(ban.ratio,limit.ratio,1),linetype=2)+
            geom_text(data=tibble(x=c(ban.ratio,limit.ratio,1),
                                  y=rep(0.1,3),
                                  label=c("Bban","Blimit","Btarget")),
                      aes(x=x,y=y,label=label))        
    }    
    
    if(category==4) return(g4) else return(g6)
}

plot_futures <- function(vpares,
                         future.list=NULL,
                         future.name=names(future.list),
                         future_tibble=NULL,
                         CI_range=c(0.1,0.9),
                         maxyear=NULL,font.size=18,
                         biomass.unit=1,
                         Btarget=0,Blimit=0,Bban=0,Blow=0,
                         n_example=3, # number of examples
                         seed=1 # seed for selecting the above example
                         ){

    junit <- c("","十","百","千","万")[log10(biomass.unit)+1]
    require(tidyverse,quietly=TRUE)
    rename_list <- tibble(stat=c("Recruitment","SSB","biomass","catch","Fsakugen"),
                          jstat=c(str_c("加入尾数"),
                              str_c("親魚量 (",junit,"トン)"),
                              str_c("資源量 (",junit,"トン)"),
                              str_c("漁獲量 (",junit,"トン)"),
                              "努力量の削減率"))
    
    if(!is.null(future.list)){
        if(is.null(future.name)) future.name <- str_c("s",1:length(future.list))
        names(future.list) <- future.name
    }
    else{
        if(is.null(future.name)) future.name <- str_c("s",1:length(unique(future_tibble$HCR_name)))
    }

    if(is.null(future_tibble)) future_tibble <- purrr::map_dfr(future.list,convert_future_table,.id="scenario")

    future.table <-
        future_tibble %>%
        dplyr::filter(stat%in%rename_list$stat) %>%
        mutate(stat=factor(stat,levels=rename_list$stat))

    set.seed(seed)
    future.example <- future.table %>%
        dplyr::filter(sim%in%sample(1:max(future.table$sim),n_example)) %>%
        mutate(value=ifelse(stat=="Fsakugen",value,value/biomass.unit)) %>%
        left_join(rename_list) %>%
        group_by(sim,scenario)
        

    if(is.null(maxyear)) maxyear <- min(future.table$year)+32

    min.age <- as.numeric(rownames(vpares$naa)[1])
    vpa_tb <- convert_vpa_tibble(vpares) %>%
        dplyr::filter(stat=="SSB"|stat=="biomass"|stat=="catch"|stat=="Recruitment") %>%
        mutate(scenario=type,year=as.numeric(year),
               stat=factor(stat,levels=rename_list$stat),
               mean=value,sim=0)
    tmp <- vpa_tb %>% group_by(stat) %>%
        summarise(value=tail(value[!is.na(value)],n=1,na.rm=T),year=tail(year[!is.na(value)],n=1,na.rm=T),sim=0) 
    future.dummy <- purrr::map_dfr(future.name,function(x) mutate(tmp,scenario=x))

    org.warn <- options()$warn
    options(warn=-1)
    future.table <- bind_rows(future.table,vpa_tb,future.dummy) %>%
        mutate(stat=factor(stat,levels=rename_list$stat)) %>%
        mutate(value=ifelse(stat=="Fsakugen",value,value/biomass.unit))

    future.table.qt <- future.table %>% group_by(scenario,year,stat) %>%
        summarise(low=quantile(value,CI_range[1]),
                  high=quantile(value,CI_range[2]),
                  median=median(value),
                  mean=mean(value))

    # make dummy for y range
    dummy <- future.table %>% group_by(stat) %>% summarise(max=max(value)) %>%
        mutate(value=0,year=min(future.table$year)) %>%
        select(-max)

    dummy2 <- future.table %>% group_by(stat) %>%
        summarise(max=max(quantile(value,CI_range[2]))) %>%
        mutate(value=max*1.1,
               year=min(future.table$year)) %>%
        select(-max)


    future.table.qt <- left_join(future.table.qt,rename_list) %>%
        mutate(jstat=factor(jstat,levels=rename_list$jstat))

   
    dummy <- left_join(dummy,rename_list)
    dummy2 <- left_join(dummy2,rename_list)
    dummy3 <- tibble(jstat=rename_list$jstat[2],
                     value=c(Btarget,Blimit,Blow,Bban)/biomass.unit,
                     RP_name=c("Btarget","Blimit","Blow","Bban"))
    
    options(warn=org.warn)
    
    g1 <- future.table.qt %>% 
        ggplot() +
        geom_ribbon(aes(x=year,ymin=low,ymax=high,fill=scenario),alpha=0.5)+        
        geom_line(aes(x=year,y=mean,color=scenario),lwd=1)+
        geom_line(aes(x=year,y=mean,color=scenario),linetype=2,lwd=1)+
        geom_blank(data=dummy,mapping=aes(y=value,x=year))+
        geom_blank(data=dummy2,mapping=aes(y=value,x=year))+
        theme_bw(base_size=font.size) +
        coord_cartesian(expand=0)+
        theme(legend.position="bottom",panel.grid = element_blank())+
        facet_wrap(~factor(jstat,levels=rename_list$jstat),scales="free")+        
        xlab("年")+ylab("")+ labs(fill = "",linetype="",color="")+
        geom_hline(data=dummy3,aes(yintercept=value,linetype=RP_name)) 


    if(n_example>0){
        g1 <- g1 + geom_line(data=future.example,
                       mapping=aes(x=year,y=value,alpha=factor(sim),color=scenario)) + scale_alpha_discrete(guide=FALSE)
            
    }
    return(g1)
}

plot_Fcurrent <- function(vpares,
                          year.range=NULL){

    if(is.null(year.range)) year.range <- min(as.numeric(colnames(vpares$naa))):max(as.numeric(colnames(vpares$naa)))
    vpares_tb <- convert_vpa_tibble(vpares)

    fc_at_age <- vpares_tb %>%
        dplyr::filter(stat=="fishing_mortality", year%in%year.range) %>%
        mutate(F=value,year=as.character(year)) %>%
        select(-stat,-sim,-type,-value)
    fc_at_age_current <- tibble(F=vpares$Fc.at.age,age=as.numeric(rownames(vpares$naa)),
                                year="currentF")
    fc_at_age <- bind_rows(fc_at_age,fc_at_age_current) %>%
        mutate(color=c("gray","tomato")[as.numeric(year=="currentF")+1]) %>%
        group_by(year)
    
    g <- fc_at_age %>% ggplot() +
        geom_line(aes(x=age,y=as.numeric(F),alpha=year,
                      color=color),lwd=1.5) +
        scale_colour_identity()+
#        geom_line(data=fc_at_age_current,
#                  mapping=aes(x=age,y=F),
#                  alpha=0.5,lwd=2) +    
        theme_bw()+
        coord_cartesian(expand=0,ylim=c(0,max(fc_at_age$F)*1.1),xlim=range(fc_at_age$age)+c(-0.5,0.5))+
#        theme(#legend.position="bottom",
#            panel.grid = element_blank())+
    xlab("Ages")+ylab("Fishing mortality")#+
#    scale_colour_manual(
#        values = c(
#            col1  = "gray",
#            col2  = "tomato",
#            col3  = "blue3",
    #            col4  = "yellow3")    )
    return(g)
}
