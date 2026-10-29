# Two-way fixed-effects implementation for Karplus & Wu (2023), DOI 10.1073/pnas.2214262120.
set.seed(20261028)
analysis_cases <- function() list(
  unweighted=list(file='campaign_all_10wk_nt.dta',md5='877c1e5df5090b7b25e1000b37478bd8',weight=NULL,models=c('col1','col4')),
  weighted=list(file='campaign_all_10wk_match_nt.dta',md5='c8b6813611c3d5dc49a88d1e0ad749e3',weight='_webal',models=c('col2','col5')))

prepare_panel <- function(case) {
  config <- analysis_cases()[[case]]
  path <- file.path('data/raw',config$file)
  stopifnot(unname(tools::md5sum(path))==config$md5)
  raw <- as.data.frame(haven::read_dta(path,encoding='UTF-8'))
  legacy <- as.data.frame(haven::read_dta(path,encoding='latin1'))
  num <- names(raw)[vapply(raw,is.numeric,logical(1))]
  for(v in num) {
    stopifnot(identical(as.numeric(raw[[v]]),as.numeric(legacy[[v]])))
    raw[[v]] <- as.numeric(raw[[v]])
  }
  for(v in c('plant_name','city_name','province_name'))
    stopifnot(identical(match(raw[[v]],unique(raw[[v]])),match(legacy[[v]],unique(legacy[[v]]))))
  raw$announcement <- as.numeric(raw$campaigntime>=-4 & raw$campaigntime<=-1 & raw$campaign_treated==1)
  raw$onsite <- as.numeric(raw$campaigntime>=0 & raw$campaigntime2<=0 & raw$campaign_treated==1)
  raw$post <- as.numeric(raw$campaigntime2>=1 & raw$campaign_treated==1)
  raw$post_1_5 <- as.numeric(raw$campaigntime2>=1 & raw$campaigntime2<=5 & raw$campaign_treated==1)
  raw$post_6_10 <- as.numeric(raw$campaigntime2>=6 & raw$campaigntime2<=10 & raw$campaign_treated==1)
  raw$.weight <- if(is.null(config$weight)) rep(1,nrow(raw)) else raw[[config$weight]]
  stopifnot(!anyNA(raw[c('announcement','onsite','post','post_1_5','post_6_10')]),
            all(raw$post==raw$post_1_5+raw$post_6_10))
  required <- c('log_concentration_SO2','announcement','onsite','post','post_1_5','post_6_10',
                'plant_name1','yweek','city_name','province_name','.weight')
  complete <- raw[complete.cases(raw[required]) & is.finite(raw$.weight) & raw$.weight>0,]
  effective <- remove_singletons(complete)
  np <- function(d)length(unique(d$plant_name1))
  audit <- list(case=case,raw_rows=nrow(raw),raw_plants=np(raw),complete_rows=nrow(complete),
    complete_plants=np(complete),regression_rows=nrow(effective),regression_plants=np(effective),
    missing_outcome_rows=sum(is.na(raw$log_concentration_SO2)),
    missing_weight_rows=sum(is.na(raw$.weight)),nonpositive_weight_rows=sum(raw$.weight<=0,na.rm=TRUE),
    singleton_rows=nrow(complete)-nrow(effective),
    plants_without_complete_rows=length(setdiff(unique(raw$plant_name1),unique(complete$plant_name1))),
    plants_lost_to_singletons=length(setdiff(unique(complete$plant_name1),unique(effective$plant_name1))),
    cities=length(unique(effective$city_name)),provinces=length(unique(effective$province_name)),
    utf8_numeric_values_and_label_partitions_match_latin1=TRUE,
    monitor_id_available=FALSE,weight_source=if(is.null(config$weight))'unit weights' else 'author _webal; not re-estimated')
  list(data=effective,audit=audit)
}
remove_singletons <- function(d) {
  repeat {
    f<-match(d$plant_name1,unique(d$plant_name1));t<-match(d$yweek,unique(d$yweek))
    keep<-tabulate(f)[f]>1 & tabulate(t)[t]>1
    if(all(keep))return(d)
    d<-d[keep,,drop=FALSE]
    if(nrow(d)==0)stop('Empty sample after singleton removal')
  }
}
demean <- function(A,f,w=rep(1,nrow(A))) {
  means<-rowsum(A*w,f,reorder=TRUE)/drop(rowsum(w,f,reorder=TRUE))
  A-means[f,,drop=FALSE]
}
residualize <- function(A,f,t,w=rep(1,nrow(A)),tolerance=1e-11) {
  for(i in seq_len(4000)) {
    old<-A;A<-demean(demean(A,f,w),t,w);delta<-max(abs(A-old))
    if(delta<tolerance)return(list(A=A,iterations=i,delta=delta))
  }
  stop('Fixed effects failed to converge')
}
fit_both <- function(d,case='unweighted') {
  d<-remove_singletons(d);w<-d$.weight/mean(d$.weight)
  f<-match(d$plant_name1,unique(d$plant_name1));t<-match(d$yweek,unique(d$yweek))
  vars<-c('log_concentration_SO2','announcement','onsite','post','post_1_5','post_6_10')
  projected<-residualize(as.matrix(d[vars]),f,t,w)
  A<-projected$A
  specs<-list(c('announcement','onsite','post'),c('announcement','onsite','post_1_5','post_6_10'))
  names(specs)<-analysis_cases()[[case]]$models
  models<-lapply(specs,function(terms){
    X<-A[,terms,drop=FALSE];y<-A[,1];Xw<-X*sqrt(w)
    if(qr(Xw)$rank!=ncol(X))stop('Singular slope design')
    bread<-solve(crossprod(Xw));b<-drop(bread%*%crossprod(X,w*y));names(b)<-terms
    u<-drop(y-X%*%b);rss<-sum(w*u^2)
    tss<-sum(w*(d$log_concentration_SO2-weighted.mean(d$log_concentration_SO2,w))^2)
    list(beta=b,X=X,u=u,bread=bread,rss=rss,tss=tss,within_tss=sum(w*y^2),r_squared=1-rss/tss)
  })
  list(models=models,data=d,f=f,t=t,w=w,iterations=projected$iterations,delta=projected$delta)
}
time_rank <- function(fit) {
  T<-diag(max(fit$t))[fit$t,,drop=FALSE]
  qr(demean(T,fit$f,fit$w)*sqrt(fit$w),tol=1e-8)$rank
}
cluster_vcov <- function(fit,model,cluster) {
  d<-fit$data;m<-fit$models[[model]];g<-match(d[[cluster]],unique(d[[cluster]]));G<-max(g);N<-nrow(d)
  stopifnot(G>1,all(vapply(split(g,fit$f),function(x)length(unique(x))==1,logical(1))))
  # Documented reghdfe nesting convention: plant FE nested in geographic
  # clusters do not receive an additional DoF penalty. Include time rank + intercept.
  tr<-time_rank(fit);K<-length(m$beta)+tr+1L
  stopifnot(N>K)
  q<-G/(G-1)*(N-1)/(N-K)
  scores<-rowsum(m$X*(fit$w*m$u),g,reorder=TRUE)
  V<-q*m$bread%*%crossprod(scores)%*%m$bread
  list(V=V,G=G,N=N,K=K,q=q,time_rank=tr)
}
inference_rows <- function(beta,V,G,model,cluster,method,case) {
  se<-sqrt(diag(V));critical<-qt(.975,G-1)
  data.frame(case=case,model=model,cluster=cluster,method=method,term=names(beta),
    estimate=unname(beta),se=unname(se),df=G-1,p_value=unname(2*pt(-abs(beta/se),G-1)),
    lower=unname(beta-critical*se),upper=unname(beta+critical*se))
}
qr_check <- function(fit,model,cluster='city_name') {
  m<-fit$models[[model]];d<-fit$data;w<-fit$w
  B<-demean(as.matrix(d[c('log_concentration_SO2',names(m$beta))]),fit$f,w)*sqrt(w)
  T<-demean(diag(max(fit$t))[fit$t,,drop=FALSE],fit$f,w)*sqrt(w)
  res<-qr.resid(qr(T,tol=1e-8),B)
  qfit<-lm.fit(res[,-1,drop=FALSE],res[,1]);X<-res[,-1,drop=FALSE]
  bread<-solve(crossprod(X));scores<-rowsum(X*qfit$residuals,d[[cluster]],reorder=TRUE)
  cv<-cluster_vcov(fit,model,cluster)
  V<-cv$q*bread%*%crossprod(scores)%*%bread
  list(max_beta_difference=max(abs(qfit$coefficients-m$beta)),
    max_se_difference=max(abs(sqrt(diag(V))-sqrt(diag(cv$V)))),
    max_weighted_residual_difference=max(abs(qfit$residuals-m$u*sqrt(w))))
}
