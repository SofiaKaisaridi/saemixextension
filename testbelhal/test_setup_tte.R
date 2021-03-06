###################################################################################
cat("Running example RTTE\n")

library(fitdistrplus)

tte.saemix<-read.table(file.path(datDir,"rttellis.csv"),header=T, sep=",")
tte.saemix <- tte.saemix[tte.saemix$ytype==2,]
saemix.data<-saemixData(name.data=tte.saemix, name.group=c("id"),
  name.predictors=c("time"), name.response="y")

tte.model<-function(psi,id,xidep) {
T<-xidep[,1]
N <- nrow(psi)
Nj <- length(T)
# censoringtime = 6
censoringtime = max(T)
lambda <- psi[id,1]
beta <- psi[id,2]
init <- which(T==0)
cens <- which(T==censoringtime)
ind <- setdiff(1:Nj, append(init,cens))
hazard <- (beta/lambda)*(T/lambda)^(beta-1)
H <- (T/lambda)^beta
logpdf <- rep(0,Nj)
logpdf[cens] <- -H[cens] + H[cens-1]
logpdf[ind] <- -H[ind] + H[ind-1] + log(hazard[ind])
return(logpdf)
}

saemix.model<-saemixModel(model=tte.model,description="time model",modeltype="likelihood",
  psi0=matrix(c(2,1),ncol=2,byrow=TRUE,dimnames=list(NULL,
  c("lambda","beta"))),
  transform.par=c(1,1),covariance.model=matrix(c(1,0,0,1),ncol=2,
  byrow=TRUE))
saemix.options<-list(seed=632545,save=FALSE,save.graphs=FALSE)
saemix.fit<-saemix(saemix.model,saemix.data,saemix.options)

tte.fit<-saemix.fit

###################################################################################
# New dataset
xtim<-seq(0,4,1)
nsuj<-8
test.newdata<-data.frame(id=rep(1:nsuj,each=length(xtim)),time=rep(xtim,nsuj))

saemixObject<-tte.fit
psiM<-data.frame(lambda=seq(1.6,2,length.out=length(unique(test.newdata$id))),beta = seq(1,3,4))

simul.tte<-function(psi,id,xidep) {
  T<-xidep
  N <- nrow(psi)
  Nj <- length(T)
  censoringtime = 4
  lambda <- psi[id,1]
  beta <- psi[id,2]
  obs <-rep(0,length(T))

  for (i in (1:N)){
    obs[id==i] <- rweibull(n=length(id[id==i]), shape=lambda[i], scale=beta[i])
  }  

  return(obs)
}

preds <- simul.tte(psiM, test.newdata$id, test.newdata[,c("time")])
test.newdata$y<-preds
tte.newdata <- test.newdata
tte.psiM<-psiM

###################################################################################
# test.newdata<-read.table(file.path(datDir,"rtte1.csv"),header=T, sep=",")
# test.newdata <- test.newdata[test.newdata$ytype==2,]
# test.newdata <- test.newdata[1:358,]
# test.newdata <- test.newdata[which(test.newdata$time < 7),]
# fpred<-saemixObject["model"]["model"](psiM, test.newdata$id, test.newdata[,c("time"),drop=FALSE])
# test.newdata$LogProbs<-fpred
# test.newdata$y<-ifelse(test.newdata$time>0,1,0)
# tte.psiM<-psiM