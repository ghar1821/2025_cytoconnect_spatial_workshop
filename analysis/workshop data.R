data <- read.csv("~/Library/CloudStorage/OneDrive-TheUniversityofSydney(Staff)/DROPBOX/Submissions/Presentation (moved to Harddrive)/2025/202511_CytoCon/Workshop IMC/measurements (1).csv")
theme_set(theme_classic())
cnames <- colnames(data)

cnames <- gsub("^ROI..1.00.px.per.pixel..", "", cnames)
cnames <- gsub(".tif..Mean" , "", cnames)
colnames(data) <- cnames
ggplot(data, aes(Centroid.X.px, Centroid.Y.px, size=Area.px.2, color = Ecadherin))+geom_point()

data[,12:21] %>% pivot_longer(cols = colnames(.),names_to = "Marker", values_to = "Exp") %>% ggplot(aes(log(Exp+1), color=Marker))+geom_density()

exp <- data[,12:48]
for(i in 1:ncol(exp)) {
  print(max(exp[,i]))
}

normed_exp <- log2(exp+1)
scaled_exp <- scale(normed_exp)


normed_exp %>% pivot_longer(cols = colnames(.),names_to = "Marker", values_to = "Exp") %>% ggplot(aes(Exp, color=Marker))+geom_density()
scaled_exp %>% as.data.frame()%>% pivot_longer(cols = colnames(.),names_to = "Marker", values_to = "Exp") %>% ggplot(aes(Exp, color=Marker))+geom_density()

cols_to_use <- c("aSMA", "CD14", "CD11c", "CD20", "CD3", "CD31", "CD45", "Ecadherin", "FXIIIa", "Ki67", "Podoplanin")
cols_to_use %in% colnames(exp)

pca <- prcomp(as.matrix(t(normed_exp[,colnames(exp) %in% cols_to_use])))

ggplot(pca$rotation, aes(PC1,PC2))+geom_point()

k <- kmeans(pca$rotation[,1:10], centers = 6)

pca_df <- pca$rotation %>%as.data.frame(); pca_df$clust = k$cluster
ggplot(pca_df, aes(PC1,PC2, color=as.factor(clust)))+geom_point()

um <- uwot::umap(pca$rotation[,1:10])
pca_df$umap1 <- um[,1]
pca_df$umap2 <- um[,2]
ggplot(pca_df, aes(umap1,umap2, color=as.factor(clust)))+geom_point()

m <- "Ecadherin"

cbind(pca_df, normed_exp) %>% ggplot(aes(Ecadherin, color=as.factor(clust)))+geom_density()

normed_exp[,cols_to_use] %>% 
  mutate(clust = pca_df$clust) %>% 
  pivot_longer(cols = cols_to_use) %>% 
  group_by(clust, name) %>% 
  summarise(value = mean(value)) %>% 
  ggplot(aes(clust, name, fill=value))+geom_tile() + scale_fill_viridis_c(option = "D")
  


ggplot(data%>% 
         mutate(clust = pca_df$clust), aes(Centroid.X.px, Centroid.Y.px, size=Area.px.2, color = as.factor(clust)))+geom_point()
  
ggplot(normed_exp%>% 
         mutate(clust = pca_df$clus, X = data$Centroid.X.px, Y = data$Centroid.Y.px, Area = data$Area.px.2 ), aes(X, Y, size=Area, color = HIV))+geom_point()




