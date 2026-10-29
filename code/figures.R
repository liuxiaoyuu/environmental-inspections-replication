library(ggplot2)
inf <- read.csv('results/inference_sensitivity.csv')
del <- read.csv('results/all_deletion_estimates.csv')
labels <- c(announcement='Announcement',onsite='Onsite',post='Post-inspection')
case_labels <- c(unweighted='Unweighted (Table 3, column 1)',weighted='Author weights (Table 3, column 2)')
selected <- subset(inf,model %in% c('col1','col2') & method %in% c('CV1','CV3J'))
selected$period <- factor(labels[selected$term],levels=unname(labels))
selected$case_label <- factor(case_labels[selected$case],levels=unname(case_labels))
selected$specification <- factor(paste(ifelse(selected$cluster=='city','City','Province'),selected$method),
  levels=rev(c('City CV1','City CV3J','Province CV1','Province CV3J')))
theme_set(theme_minimal(base_size=12) + theme(panel.grid.minor=element_blank(),
  plot.title=element_text(face='bold'),strip.text=element_text(face='bold'),
  plot.caption=element_text(hjust=0,size=10)))
p <- ggplot(selected,aes(x=estimate,y=specification,color=cluster))+
  geom_vline(xintercept=0,linetype=2,color='grey60')+
  geom_errorbar(aes(xmin=lower,xmax=upper),orientation='y',width=.15,linewidth=.7)+
  geom_point(size=2.5)+facet_grid(case_label~period)+
  scale_color_manual(values=c(city='#156B8A',province='#242424'),guide='none')+
  labs(title='Geographic dependence changes uncertainty in both specifications',
       subtitle='Full-sample coefficients with alternative cluster covariance estimates',
       x='Coefficient (log points); approximate 95% interval',y=NULL,
       caption='CV1: cluster sandwich. CV3J: centered delete-one-cluster jackknife. Intervals use t(G - 1).\n116 cities unweighted / 110 weighted; eight provinces in both. Eight-cluster inference is fragile; supplied weights held fixed.')
ggsave('results/inference_comparison.png',p,device=ragg::agg_png,width=12,height=7,dpi=170,bg='white')
province_names <- c('广东省'='Guangdong','黑龙江省'='Heilongjiang','河南省'='Henan','湖北省'='Hubei',
  '湖南省'='Hunan','山东省'='Shandong','山西省'='Shanxi','浙江省'='Zhejiang')
dp <- subset(del,cluster=='province' & model %in% c('col1','col2'))
dp$province <- factor(province_names[dp$omitted],levels=rev(sort(unname(province_names))))
stopifnot(!anyNA(dp$province))
dp$period <- factor(labels[dp$term],levels=unname(labels))
dp$case_label <- factor(case_labels[dp$case],levels=unname(case_labels))
baselines <- unique(dp[c('case_label','period','full_estimate')])
p2 <- ggplot(dp,aes(x=estimate,y=province))+
  geom_vline(xintercept=0,color='grey65',linetype=2)+
  geom_vline(data=baselines,aes(xintercept=full_estimate),color='#156B8A',linewidth=.7)+
  geom_segment(aes(x=full_estimate,xend=estimate,yend=province),color='grey75')+
  geom_point(size=2.5,color='#242424')+facet_grid(case_label~period)+
  labs(title='The pooled estimates depend more on provinces than individual cities',
    subtitle='Every deletion refits plant and year-week fixed effects; supplied weights are held fixed',
    x='Coefficient (log points)',y='Province omitted',
    caption='Blue lines: full sample. Dots: deletion estimates, not province-specific treatment effects.\nDeletion ranges are sensitivity diagnostics, not confidence intervals. Partial reproduction; other paper specifications are outside scope.')
ggsave('results/province_deletions.png',p2,device=ragg::agg_png,width=12,height=8.1,dpi=170,bg='white')
