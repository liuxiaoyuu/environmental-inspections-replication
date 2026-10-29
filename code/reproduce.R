source('code/model.R')
dir.create('results',showWarnings=FALSE)
start<-proc.time()[['elapsed']]
published<-read.csv('data/published_targets.csv')
comparison<-audits<-checks<-list()
for(case in names(analysis_cases())) {
  p<-prepare_panel(case);fit<-fit_both(p$data,case);audits[[case]]<-p$audit
  for(model in names(fit$models)) {
    m<-fit$models[[model]];cv<-cluster_vcov(fit,model,'city_name')
    a<-inference_rows(m$beta,cv$V,cv$G,model,'city','CV1',case)
    target<-published[published$model==model,]
    a$paper_beta<-target$beta[match(a$term,target$term)]
    a$paper_se<-target$se[match(a$term,target$term)]
    a$beta_rounding_match<-round(a$estimate,3)==a$paper_beta
    a$se_rounding_match<-round(a$se,3)==a$paper_se
    a$N<-nrow(fit$data);a$paper_N<-target$N[1]
    a$r_squared<-m$r_squared;a$paper_r_squared<-target$r2[1]
    comparison[[model]]<-a
    ck<-qr_check(fit,model)
    stopifnot(all(unlist(ck)<1e-8))
    checks[[model]]<-c(ck,cv[c('G','N','K','q','time_rank')])
  }
}
out<-do.call(rbind,comparison);rownames(out)<-NULL
write.csv(out,'results/table3_comparison.csv',row.names=FALSE)
jsonlite::write_json(audits,'results/sample_audit.json',pretty=TRUE,auto_unbox=TRUE,digits=16)
validation<-list(independent_qr=checks,published_beta_match=all(out$beta_rounding_match),
  published_se_match=all(out$se_rounding_match),published_N_match=all(out$N==out$paper_N),
  published_R2_match=all(round(out$r_squared,3)==out$paper_r_squared),
  all_published_targets_match=all(out$beta_rounding_match & out$se_rounding_match & out$N==out$paper_N & round(out$r_squared,3)==out$paper_r_squared),
  elapsed_seconds=proc.time()[['elapsed']]-start)
jsonlite::write_json(validation,'results/reproduction_validation.json',pretty=TRUE,auto_unbox=TRUE,digits=16)
writeLines(capture.output(sessionInfo()),'results/sessionInfo.txt')
print(out[,c('model','term','estimate','paper_beta','se','paper_se','beta_rounding_match','se_rounding_match')])
stopifnot(validation$published_beta_match,validation$published_se_match,validation$published_N_match)
if(!validation$published_R2_match)warning('Published R-squared does not match; see results/r_squared_audit.csv.')
