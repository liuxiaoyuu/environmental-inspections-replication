source('code/model.R')
start <- proc.time()[['elapsed']]
inferences <- list(); deletions <- list(); contrasts <- list(); summaries <- list()
for (case in names(analysis_cases())) {
 p <- prepare_panel(case); full <- fit_both(p$data,case)
 for (cluster in c('city_name','province_name')) {
  group_names <- sort(unique(full$data[[cluster]])); G <- length(group_names)
  label <- sub('_name','',cluster)
  B <- lapply(full$models,function(m)matrix(NA_real_,G,length(m$beta),dimnames=list(group_names,names(m$beta))))
  for (i in seq_along(group_names)) {
    group <- group_names[i]
    # Full re-estimation of fixed effects is necessary for valid deletion fits.
    subset <- full$data[full$data[[cluster]]!=group,,drop=FALSE]
    fit <- fit_both(subset,case)
    for (model in names(B)) {
      beta <- fit$models[[model]]$beta
      B[[model]][i,] <- beta
      deletions[[length(deletions)+1L]] <- data.frame(case=case,cluster=label,omitted=group,model=model,
        term=names(beta),estimate=unname(beta),full_estimate=unname(full$models[[model]]$beta),
        delta=unname(beta-full$models[[model]]$beta),N=nrow(fit$data),
        dropped_rows=nrow(full$data)-nrow(fit$data),iterations=fit$iterations)
    }
    if(i%%10==0 || i==G) {cat(case,label,':',i,'/',G,'deletion fits complete\n');flush.console()}
  }
  for (model in names(B)) {
    b <- full$models[[model]]$beta
    cv1 <- cluster_vcov(full,model,cluster)
    centered_full <- sweep(B[[model]],2,b)
    centered_mean <- sweep(B[[model]],2,colMeans(B[[model]]))
    matrices <- list(CV1=cv1$V,CV3=(G-1)/G*crossprod(centered_full),CV3J=(G-1)/G*crossprod(centered_mean))
    for (method in names(matrices)) {
      V <- matrices[[method]]
      inferences[[length(inferences)+1L]] <- inference_rows(b,V,G,model,label,method,case)
      if(model %in% c('col4','col5')) {
        contrast <- c(announcement=0,onsite=-1,post_1_5=0,post_6_10=1)
        estimate <- sum(contrast*b)
        variance <- drop(t(contrast)%*%V%*%contrast)
        contrasts[[length(contrasts)+1L]] <- inference_rows(c(late_post_minus_onsite=estimate),
          matrix(variance,1,1),G,model,label,method,case)
      }
    }
    for (term in names(b)) {
      vals <- B[[model]][,term]; influential <- which.max(abs(vals-b[term]))
      summaries[[length(summaries)+1L]] <- data.frame(case=case,cluster=label,G=G,model=model,term=term,
        full_estimate=b[term],deletion_min=min(vals),deletion_max=max(vals),
        sign_changes=sum(sign(vals)!=sign(b[term])),most_influential=group_names[influential],
        max_absolute_change=abs(vals[influential]-b[term]),
        deletion_estimate_at_max_change=vals[influential])
    }
  }
}
}
write.csv(do.call(rbind,deletions),'results/all_deletion_estimates.csv',row.names=FALSE)
write.csv(do.call(rbind,inferences),'results/inference_sensitivity.csv',row.names=FALSE)
write.csv(do.call(rbind,contrasts),'results/attenuation_contrast.csv',row.names=FALSE)
write.csv(do.call(rbind,summaries),'results/deletion_summary.csv',row.names=FALSE)
jsonlite::write_json(list(elapsed_seconds=proc.time()[['elapsed']]-start,
  deletion_fits=length(deletions)/2,coefficient_rows=nrow(do.call(rbind,deletions)),
  weights='Deposited weights held fixed on retained observations; no recalibration',
  singular_fits=0,method='Full deletion refits; CV1, CV3 and CV3J; approximate t(G-1) inference',
  note='Deletion ranges are not confidence intervals; eight-province inference is exploratory.'),
  'results/extension_run.json',pretty=TRUE,auto_unbox=TRUE)
print(do.call(rbind,summaries))
