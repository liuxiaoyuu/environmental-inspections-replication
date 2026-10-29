# Data-free tests: the fixed-effects estimator and clustered SEs on a simulated panel.
source('code/model.R')
set.seed(412)
plants <- data.frame(plant_name1=sprintf('p%03d',1:120),city_name=sprintf('c%02d',rep(1:30,each=4)))
plants$province_name <- sprintf('v%d',(as.integer(factor(plants$city_name))-1)%/%5+1)
d <- merge(plants,data.frame(yweek=1:40))
d$announcement <- as.numeric(d$yweek %in% 10:12 & d$plant_name1<'p060')
d$onsite <- as.numeric(d$yweek %in% 13:16 & d$plant_name1<'p060')
d$post_1_5 <- as.numeric(d$yweek %in% 17:21 & d$plant_name1<'p060')
d$post_6_10 <- as.numeric(d$yweek %in% 22:26 & d$plant_name1<'p060')
d$post <- d$post_1_5+d$post_6_10
d$log_concentration_SO2 <- rnorm(120)[match(d$plant_name1,plants$plant_name1)]+sin(d$yweek/5)-
  .2*d$announcement-.5*d$onsite-.4*d$post_1_5-.15*d$post_6_10+rnorm(nrow(d),sd=.3)
d$.weight <- runif(nrow(d),.5,2)
d <- d[-sample(nrow(d),200),]
for (case in c('unweighted','weighted')) {
  dd <- d; if (case=='unweighted') dd$.weight <- 1
  fit <- fit_both(dd,case)
  for (model in names(fit$models)) {
    m <- fit$models[[model]]; terms <- names(m$beta)
    stopifnot(all(unlist(qr_check(fit,model))<1e-8))
    independent <- fixest::feols(as.formula(paste('log_concentration_SO2 ~',paste(terms,collapse='+'),'| plant_name1 + yweek')),
      data=fit$data,weights=~.weight,vcov=~city_name,ssc=fixest::ssc(K.fixef='nonnested',K.exact=FALSE),fixef.tol=1e-10,notes=FALSE)
    stopifnot(max(abs(stats::coef(independent)-m$beta))<1e-7,
              max(abs(fixest::se(independent)-sqrt(diag(cluster_vcov(fit,model,'city_name')$V))))<1e-7,
              abs(as.numeric(fixest::fitstat(independent,'r2')[[1]])-m$r_squared)<1e-8)
  }
}
# Plant c is observed once and is dropped; the remaining 2x2 panel is kept.
stopifnot(nrow(remove_singletons(data.frame(plant_name1=c('a','a','b','b','c'),yweek=c(1,2,1,2,1))))==4)
cat('Fixed-effects estimates, clustered SEs, R-squared and singleton removal match fixest.\n')
