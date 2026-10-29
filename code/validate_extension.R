# Independent QR and fixest cross-checks, not a choice of preferred results.
source('code/model.R')
out <- read.csv('results/all_deletion_estimates.csv')
summaries <- read.csv('results/deletion_summary.csv')
checks <- list(); r2 <- list()
for(case in names(analysis_cases())) {
  full <- fit_both(prepare_panel(case)$data,case)
  keys <- unique(out[out$case==case,c('cluster','omitted')])
  stopifnot(nrow(subset(keys,cluster=='city'))==length(unique(full$data$city_name)),
            nrow(subset(keys,cluster=='province'))==8,
            sum(out$case==case)==nrow(keys)*7,!anyNA(out$estimate))
  influential <- unique(summaries$most_influential[summaries$case==case & summaries$cluster=='city'])
  selected <- keys[keys$cluster=='province' | keys$omitted %in% influential,,drop=FALSE]
  selected <- rbind(data.frame(cluster='full',omitted='none'),selected)
  for(i in seq_len(nrow(selected))) {
    cl <- selected$cluster[i]; omitted <- selected$omitted[i]
    fit <- if(cl=='full') full else fit_both(full$data[full$data[[paste0(cl,'_name')]]!=omitted,],case)
    d <- fit$data
    for(model in names(fit$models)) {
      m <- fit$models[[model]]; terms <- names(m$beta)
      qr_result <- qr_check(fit,model)
      stopifnot(all(unlist(qr_result)<1e-8))
      fml <- as.formula(paste('log_concentration_SO2 ~',paste(terms,collapse='+'),'| plant_name1 + yweek'))
      independent <- fixest::feols(fml,data=d,weights=~.weight,vcov=~city_name,
        ssc=fixest::ssc(K.fixef='nonnested',K.exact=FALSE),fixef.tol=1e-10,notes=FALSE)
      beta_difference <- max(abs(stats::coef(independent)-m$beta))
      cv <- cluster_vcov(fit,model,'city_name')
      se_difference <- max(abs(fixest::se(independent)-sqrt(diag(cv$V))))
      independent_r2 <- as.numeric(fixest::fitstat(independent,'r2')[[1]])
      r2_difference <- abs(independent_r2-m$r_squared)
      stopifnot(beta_difference<1e-7,se_difference<1e-7,r2_difference<1e-8)
      if(cl!='full') {
        expected <- out[out$case==case & out$cluster==cl & out$omitted==omitted & out$model==model,]
        stopifnot(nrow(expected)==length(terms),max(abs(m$beta-expected$estimate[match(terms,expected$term)]))<1e-8)
      } else {
        N <- nrow(d); full_rank <- length(unique(fit$f))+time_rank(fit)+length(terms)
        overall_adjusted <- 1-(m$rss/(N-full_rank))/(m$tss/(N-1))
        within <- 1-m$rss/m$within_tss
        within_adjusted_reghdfe <- 1-(m$rss/(N-full_rank))/(m$within_tss/(N-full_rank+length(terms)))
        stats <- fixest::fitstat(independent,c('r2','ar2','wr2','war2'))
        stopifnot(abs(overall_adjusted-stats$ar2)<1e-8,abs(within-stats$wr2)<1e-8)
        paper <- read.csv('data/published_targets.csv')
        r2[[model]] <- data.frame(case=case,model=model,N=N,full_design_rank=full_rank,
          paper=paper$r2[match(model,paper$model)],overall=m$r_squared,
          adjusted_overall=overall_adjusted,within=within,
          adjusted_within_reghdfe=within_adjusted_reghdfe,
          fixest_overall=stats$r2,fixest_adjusted_overall=stats$ar2,
          fixest_within=stats$wr2,fixest_adjusted_within=stats$war2)
      }
      checks[[length(checks)+1L]] <- data.frame(case=case,cluster=cl,omitted=omitted,model=model,
        qr_max_beta_difference=qr_result$max_beta_difference,qr_max_se_difference=qr_result$max_se_difference,
        fixest_max_beta_difference=beta_difference,fixest_max_se_difference=se_difference,
        fixest_r2_difference=r2_difference)
    }
  }
}
write.csv(do.call(rbind,checks),'results/extension_validation.csv',row.names=FALSE)
write.csv(do.call(rbind,r2),'results/r_squared_audit.csv',row.names=FALSE)
cat('All deletion rows present;',length(checks),'model fits cross-checked by QR and fixest.\n')
