setwd("C:/Data/BujuBanton/msc/comp6115kdda/worksheets/Project1")
getwd()
rm(list = ls())
options(scipen = 99999)

dataset <- "https://goo.gl/At238b" %>%  #DataFlair
  read.csv %>% # read in the data
  select(survived, embarked, sex, 
         sibsp, parch, fare) %>%
  mutate(embarked = factor(embarked),
         sex = factor(sex))

### Step 2 - Split data into training and testing data 
set.seed(1)
DTDataset <-sample.split(Y=dataset$survived, SplitRatio = 0.7)
DTtrainData <- dataset[DTDataset,]
dim(DTtrainData)
plot(DTtrainData$survived)
DTtestData <- dataset[!DTDataset,]
dim(DTtestData)

### Step 3 - Fit a Decision Tree using training data
#DTmodel <- rpart(TenYearCHD ~ .,method="class", data=DTtrainData, parms = list (split ="information gain"), control = rpart.control(minsplit = 10, maxdepth = 5))
#DTmodel <- rpart(TenYearCHD ~ .,method="class", data=DTtrainData, parms = list (split ="gini"), control = rpart.control(minsplit = 15, maxdepth = 5))  
DTmodel <- rpart(survived ~ ., data=DTtrainData)  

# Fitting the model
#rpart.plot(DTmodel, type=3, extra = 101, fallen.leaves = F, cex = 0.8) ##try extra with 2,8,4, 101
rpart.plot(DTmodel)

summary(DTmodel) # detailed summary of splits
DTmodel #prints the rules

###Step 4 - Use the fitted model to do predictions for the test data

DTpredTest <- predict(DTmodel, DTtestData, type="class")
DTprobTest <- predict(DTmodel, DTtestData, type="prob")

DTactualTest <- DTtestData$survived

### Step 5 - Create Confusion Matrix and compute the misclassification error
DTt <- table(predictions= DTpredTest, actual = DTactualTest)
DTt # Confusion matrix
DTaccuracy <- sum(diag(DTt))/sum(DTt)
DTaccuracy 

## Visualization of probabilities
hist(DTprobTest[,2], breaks = 100)

### ROC and Area Under the Curve
DTROC <- roc(DTactualTest, DTprobTest[,2])
plot(DTROC, col="blue")
DTAUC <- auc(DTROC)
DTAUC

#A new dataframe with Predicted Prob, Actual Value and Predicted Value
DTpredicted_data <- data.frame(Probs = DTprobTest, Actual_Value= DTactualTest ,Predicted_Value = DTpredTest )  #Create data frame with prob and predictions
DTpredicted_data <- DTpredicted_data[order(DTpredicted_data$Probs.1, decreasing=TRUE),] # Sort on Probabilities
DTpredicted_data$Rank <- 1:nrow(DTpredicted_data) # Add a new variable rank

library(ggplot2)

ggplot(data=DTpredicted_data, aes(x=Rank, y=Probs.1)) + 
  geom_point(aes(color = DTpredicted_data$Actual_Value)) + xlab("Index") + ylab("Predicted Probability of getting Cardiovascular Diseases")

### Step 6 - Use model to make predictions on newdata. Note we can specify the newData as data.frame with one or many records
DTnewData <- data.frame(male = 0, age = 50, education = 0, currentSmoker = 0, cigsPerDay = 9, BPMeds = 0, prevalentStroke = 0, prevalentHyp = 0, diabetes = 0, totChol = 236, sysBP = 102.0, diaBP = 71, BMI = 100, heartRate = 100, glucose = 200 )

# terminal nodes
# age
# glucose
# diaBP
# BMI

DTpredProbability <-predict(DTmodel, DTnewData, type='prob')
DTpredProbability
#
## Performance measures - 
#
#set.seed(1), gini
# Simplicity =  leaves
# Accuracy = 
# AUC = 
#
#set.seed(1), information
# Simplicity =  leaves
# Accuracy = 
# AUC = 
#
#set.seed(1), blank
# Accuracy = 0.7582697 0r 0.76
# AUC = 0.7453 0r 0.75
#
### Step 7 - EXAMINING STABILITY - Creating Decile Plots for Class 1 or 0 Sort 
#
#-----Create empty df-------
DTdecile<- data.frame(matrix(ncol=4,nrow = 0))
colnames(DTdecile)<- c("Decile","per_correct_preds","No_correct_Preds","cum_preds")
#-----Initialize variables
DTnum_of_deciles = 10
DTObs_per_decile <- nrow(DTpredicted_data)/DTnum_of_deciles
DTdecile_count = 1
DTstart = 1
DTstop = (DTstart-1) + DTObs_per_decile
DTprev_cum_pred <- 0
DTx = 0

#-----Loop through DF and create deciles
while (DTx < nrow(DTpredicted_data)) {
  DTsubset <- DTpredicted_data[c(DTstart:DTstop),]
  DTcorrect_count <- ifelse(DTsubset$Actual_Value == DTsubset$Predicted_Value, 1, 0)
  DTno_correct_Preds <- sum(DTcorrect_count, na.rm = TRUE)
  DTper_correct_Preds <- (DTno_correct_Preds / DTObs_per_decile) * 100
  DTcum_preds <- DTno_correct_Preds+DTprev_cum_pred
  DTaddRow <- data.frame("Decile" = DTdecile_count, "per_correct_preds" = DTper_correct_Preds, "No_correct_Preds" = DTno_correct_Preds, "cum_preds" = DTcum_preds)
  DTdecile <- rbind(DTdecile,DTaddRow)
  DTprev_cum_pred <- DTprev_cum_pred+DTno_correct_Preds
  DTstart <- DTstop + 1
  DTstop = (DTstart - 1) + DTObs_per_decile
  DTx <- DTx+DTObs_per_decile
  DTdecile_count <- DTdecile_count + 1
}
#------Stability plot (correct preds per decile)
plot(DTdecile$Decile,DTdecile$per_correct_preds,type = "l",xlab = "Decile",ylab = "Percentage of correct predictions",main="Stability Plot for Class 1")

write.csv(dataset,file = "./output/DT2_BO_CHD.csv",row.names = FALSE)
dataset <- read.csv("./output/DT2_BO_CHD.csv",header = TRUE)
