#					AGREE.COEFF3.DIST.R
#				 	 (July 29, 2019)
#Description: This script file contains a series of R functions for computing various agreement coefficients
#		  for multiple raters (2 or more) when the input data file is in the form of nxq matrix or data frame showing 
#             the count of raters by subject and by category. That is n = number of subjects, and q = number of categories.
#             A typical table entry (i,k) represents the number of raters who classified subject i into category k. 
#Author: Kilem L. Gwet, Ph.D.
#

#===========================================================================================
#gwet.ac1.dist: Gwet's AC1/Ac2 coefficient (Gwet(2008)) and its standard error for multiple raters when input 
#		   dataset is a nxq matrix representing the distribution of raters by subject and by category. 
#-------------
#The input data "ratings" is an nxq matrix showing the number of raters by subject and category. A typical entry associated
#with a subject and a category, represents the number of raters who classified the subject into the specified category. Exclude 
#all subjects that are not rated by any rater.
#Bibliography:
#Gwet, K. L. (2008). ``Computing inter-rater reliability and its variance in the presence of high
#		agreement." British Journal of Mathematical and Statistical Psychology, 61, 29-48.
#============================================================================================
#' Gwet's AC1/AC2 agreement coefficient among multiple raters (2, 3, +) when the input dataset is the distribution of raters by subject and category.
#' @param ratings An \emph{nxq} matrix / data frame containing the distribution of raters by subject and category. Each cell \emph{(i,k)} contains the number of raters who classsified subject \emph{i} into category \emph{k}.
#' @param weights is an optional parameter that is either a string variable or a matrix. The string describes one of the predefined 
#' weights and must take one of the values ("quadratic", "ordinal", "linear", "radical", "ratio", "circular", "bipolar"). 
#' If this parameter is a matrix then it must be a square matri qxq where q is the number of posssible categories where a subject 
#' can be classified. If some of the q possible categories are not used, then it is strobgly advised to specify the complete list of 
#' possible categories as a vector in parametr categ. Otherwise, only the categories reported will be used.
#' @param categ An optional parameter representing all categories available to raters during the experiment. This parameter may be useful if 
#' some categories were not used by any rater inspite of being available to the raters. 
#' @param conflev An optional parameter representing the confidence level associated with the confidence interval. Its default value is 0.95.
#' @param N An optional parameter representing the population size (if any). It may be use to perform the final population correction to the variance.  Its default value is infinity. 
#' @importFrom stats pt qt
#' @return A vector containing the following information: pa(the percent agreement),pe(the percent chance agreement),
#' coeff(Gwet's AC1 or AC2 dependending on whether weights are used or not),stderr(the standard error of Gwet's coefficient),
#' conf.int(the confidence interval of Gwet's coefficient), p.value(the p-value of Gwet's coefficient),coeff.name (AC1/AC2).
#' @examples 
#' #The dataset "distrib.6raters" comes with this package. It represents the distribution of 6 raters 
#' #by subject and by category. Note that each row of this dataset sums to the number of raters, which
#' #is 6. You may this dataset as follows:
#' distrib.6raters
#' gwet.ac1.dist(distrib.6raters) #AC1 coefficient, precision measures, weights & list of categories
#' ac1 <- gwet.ac1.dist(distrib.6raters)$coeff #Yields AC1 coefficient alone.
#' ac1
#' q <- ncol(distrib.6raters) #Number of categories
#' gwet.ac1.dist(distrib.6raters,weights = quadratic.weights(1:q)) #AC2 with quadratic weights
#' @source Gwet, K. L. (2008). ``Computing inter-rater reliability and its variance in the presence of high agreement," 
#' \emph{British Journal of Mathematical and Statistical Psychology}, 61, 29-48.
#' @export
gwet.ac1.dist <- function(ratings,weights="unweighted",categ=NULL,conflev=0.95,N=Inf){ 
  agree.mat <- as.matrix(ratings) 
  n <- nrow(agree.mat) # number of subjects
  q <- ncol(agree.mat) # number of categories
  f <- n/N # final population correction 

  # creating the weights matrix

  if (is.null(categ)) categ <- 1:q
    else{
      q2 <- length(categ)
      if (!is.numeric(categ)) categ <- 1:q2
      if (q2>q){
        colna1 <- colnames(agree.mat) 
        agree.mat <- cbind(agree.mat,matrix(0,n,(q2-q)))
        colna2 <- sapply(1:(q2-q),function(x) paste0("v",x))
        colnames(agree.mat) <- c(colna1,colna2)
        q <- q2
      } 
      
    }
  if (is.character(weights)){
    w.name <- weights
    if (weights=="quadratic") weights.mat<-quadratic.weights(categ)
    else if (weights=="ordinal") weights.mat<-ordinal.weights(categ)
    else if (weights=="linear") weights.mat<-linear.weights(categ)
    else if (weights=="radical") weights.mat<-radical.weights(categ)
    else if (weights=="ratio") weights.mat<-ratio.weights(categ)
    else if (weights=="circular") weights.mat<-circular.weights(categ)
    else if (weights=="bipolar") weights.mat<-bipolar.weights(categ)
    else weights.mat<-identity.weights(categ)
  }else{
    w.name <- "Custom Weights"
    weights.mat= as.matrix(weights)
  }
  agree.mat.w <- t(weights.mat%*%t(agree.mat))

  # calculating gwet's ac1 coefficient

  ri.vec <- agree.mat%*%rep(1,q)
  sum.q <- (agree.mat*(agree.mat.w-1))%*%rep(1,q)
  n2more <- sum(ri.vec>=2)
  pa <- sum(sum.q[ri.vec>=2]/((ri.vec*(ri.vec-1))[ri.vec>=2]))/n2more

  pi.vec <- t(t(rep(1/n,n))%*%(agree.mat/(ri.vec%*%t(rep(1,q)))))
  pe <- sum(weights.mat) * sum(pi.vec*(1-pi.vec)) / (q*(q-1))
  gwet.ac1 <- (pa-pe)/(1-pe)

  # calculating variance, stderr & p-value of gwet's ac1 coefficient
  
  den.ivec <- ri.vec*(ri.vec-1)
  den.ivec <- den.ivec - (den.ivec==0) # this operation replaces each 0 value with -1 to make the next ratio calculation always possible.
  pa.ivec <- sum.q/den.ivec

  pe.r2 <- pe*(ri.vec>=2)
  ac1.ivec <- (n/n2more)*(pa.ivec-pe.r2)/(1-pe)
  pe.ivec <- (sum(weights.mat)/(q*(q-1))) * (agree.mat%*%(1-pi.vec))/ri.vec
  ac1.ivec.x <- ac1.ivec - 2*(1-gwet.ac1) * (pe.ivec-pe)/(1-pe)
  
  var.ac1 <- ((1-f)/(n*(n-1))) * sum((ac1.ivec.x - gwet.ac1)^2)
  stderr <- sqrt(var.ac1)# ac1's standard error
  p.value <- 2*(1-pt(gwet.ac1/stderr,n-1))
  
  lcb <- gwet.ac1 - stderr*qt(1-(1-conflev)/2,n-1) # lower confidence bound
  ucb <- min(1,gwet.ac1 + stderr*qt(1-(1-conflev)/2,n-1)) # upper confidence bound
  conf.int <- paste0("(",round(lcb,3),",",round(ucb,3),")")
  coeff <- gwet.ac1
  if (sum(weights.mat)==q) coeff.name <-"Gwet's AC1"
  else coeff.name <-"Gwet's AC2"
  df.out <- data.frame(coeff.name,coeff,stderr,conf.int,p.value,pa,pe)  
  #invisible(df.out)
  return(df.out)
}
#=====================================================================================
#fleiss.kappa.dist: This function computes Fleiss' generalized kappa coefficient (see Fleiss(1971)) and 
#		   its standard error for 3 raters or more when input dataset is a nxq matrix representing 
#              the distribution of raters by subject and by category. 
#-------------
#The input data "ratings" is an nxq matrix showing the number of raters by subject and category. A typical entry associated
#with a subject and a category, represents the number of raters who classified the subject into the specified category. Exclude 
#all subjects that are not rated by any rater.
#Bibliography:
#Fleiss, J. L. (1981). Statistical Methods for Rates and Proportions. John Wiley & Sons.
#============================================================================================
#' Fleiss' agreement coefficient among multiple raters (2, 3, +) when the input dataset is the distribution of raters by subject and category.
#' @param ratings An \emph{nxq} matrix / data frame containing the distribution of raters by subject and category. Each cell \emph{(i,k)} contains the number of raters who classsified subject \emph{i} into category \emph{k}.
#' @param weights is an optional parameter that is either a string variable or a matrix. The string describes one of the predefined 
#' weights and must take one of the values ("quadratic", "ordinal", "linear", "radical", "ratio", "circular", "bipolar"). 
#' If this parameter is a matrix then it must be a square matri qxq where q is the number of posssible categories where a subject 
#' can be classified. If some of the q possible categories are not used, then it is strobgly advised to specify the complete list of 
#' possible categories as a vector in parametr categ. Otherwise, only the categories reported will be used.
#' @param categ An optional parameter representing all categories available to raters during the experiment. This parameter may be useful if 
#' some categories were not used by any rater inspite of being available to the raters. 
#' @param conflev An optional parameter representing the confidence level associated with the confidence interval. Its default value is 0.95.
#' @param N An optional parameter representing the population size (if any). It may be use to perform the final population correction to the variance.  Its default value is infinity. 
#' @return A vector containing the following information: 
#' pa(the percent agreement),pe(the percent chance agreement),coeff(Fleiss' agreement coefficient),
#' stderr(the standard error of Fleiss' coefficient),conf.int(the confidence interval of Fleiss Kappa coefficient),
#' p.value(the p-value of Fleiss' coefficient),coeff.name ("Fleiss").
#' @examples 
#' #The dataset "distrib.6raters" comes with this package. It represents the distribution of 6 raters 
#' #by subject and by category. Note that each row of this dataset sums to the number of raters, which
#' #is 6. You may this dataset as follows:
#' distrib.6raters
#' fleiss.kappa.dist(distrib.6raters) #Fleiss' kappa, precision measures, weights & list of categories
#' fleiss <- fleiss.kappa.dist(distrib.6raters)$coeff #Yields Fleiss' kappa alone.
#' fleiss
#' q <- ncol(distrib.6raters) #Number of categories
#' fleiss.kappa.dist(distrib.6raters,weights = quadratic.weights(1:q)) #Weighted fleiss/quadratic wts
#' @source Fleiss, J. L. (1981). \emph{Statistical Methods for Rates and Proportions}. John Wiley & Sons.
#' @export
fleiss.kappa.dist <- function(ratings,weights="unweighted",categ=NULL,conflev=0.95,N=Inf){ 
  agree.mat <- as.matrix(ratings) 
  n <- nrow(agree.mat) # number of subjects
  q <- ncol(agree.mat) # number of categories
  f <- n/N # final population correction 

  # creating the weights matrix
  
  if (is.null(categ)) categ <- 1:q
  else{
    q2 <- length(categ)
    if (!is.numeric(categ)) categ <- 1:q2
    if (q2>q){
      colna1 <- colnames(agree.mat) 
      agree.mat <- cbind(agree.mat,matrix(0,n,(q2-q)))
      colna2 <- sapply(1:(q2-q),function(x) paste0("v",x))
      colnames(agree.mat) <- c(colna1,colna2)
      q <- q2
    } 
  }
  if (is.character(weights)){
    w.name <- weights
    if (weights=="quadratic") weights.mat<-quadratic.weights(categ)
    else if (weights=="ordinal") weights.mat<-ordinal.weights(categ)
    else if (weights=="linear") weights.mat<-linear.weights(categ)
    else if (weights=="radical") weights.mat<-radical.weights(categ)
    else if (weights=="ratio") weights.mat<-ratio.weights(categ)
    else if (weights=="circular") weights.mat<-circular.weights(categ)
    else if (weights=="bipolar") weights.mat<-bipolar.weights(categ)
    else weights.mat<-identity.weights(categ)
  }else{
    w.name <- "Custom Weights"
    weights.mat= as.matrix(weights)
  }
  
  agree.mat.w <- t(weights.mat%*%t(agree.mat))

  # calculating fleiss's generalized kappa coefficient

  ri.vec <- agree.mat%*%rep(1,q)
  sum.q <- (agree.mat*(agree.mat.w-1))%*%rep(1,q)
  n2more <- sum(ri.vec>=2)
  pa <- sum(sum.q[ri.vec>=2]/((ri.vec*(ri.vec-1))[ri.vec>=2]))/n2more

  pi.vec <- t(t(rep(1/n,n))%*%(agree.mat/(ri.vec%*%t(rep(1,q)))))
  pe <- sum(weights.mat * (pi.vec%*%t(pi.vec)))
  fleiss.kappa <- (pa-pe)/(1-pe)

  # calculating variance, stderr & p-value of gwet's ac1 coefficient
  
  den.ivec <- ri.vec*(ri.vec-1)
  den.ivec <- den.ivec - (den.ivec==0) # this operation replaces each 0 value with -1 to make the next ratio calculation always possible.
  pa.ivec <- sum.q/den.ivec

  pe.r2 <- pe*(ri.vec>=2)
  kappa.ivec <- (n/n2more)*(pa.ivec-pe.r2)/(1-pe)
  pi.vec.wk. <- weights.mat%*%pi.vec
  pi.vec.w.k <- t(weights.mat)%*%pi.vec
  pi.vec.w <- (pi.vec.wk. + pi.vec.w.k)/2

  pe.ivec <- (agree.mat%*%pi.vec.w)/ri.vec
  kappa.ivec.x <- kappa.ivec - 2*(1-fleiss.kappa) * (pe.ivec-pe)/(1-pe)
  
  var.fleiss <- ((1-f)/(n*(n-1))) * sum((kappa.ivec.x - fleiss.kappa)^2)
  stderr <- sqrt(var.fleiss)# kappa's standard error
  p.value <- 2*(1-pt(fleiss.kappa/stderr,n-1))
  
  lcb <- fleiss.kappa - stderr*qt(1-(1-conflev)/2,n-1) # lower confidence bound
  ucb <- min(1,fleiss.kappa + stderr*qt(1-(1-conflev)/2,n-1)) # upper confidence bound
  conf.int <- paste0("(",round(lcb,3),",",round(ucb,3),")")
  coeff <- fleiss.kappa
  coeff.name <- "Fleiss' Kappa"
  df.out <- data.frame(coeff.name,coeff,stderr,conf.int,p.value,pa,pe)
  #colnames(df.out) <- c("pa","pe","f.kappa","stderr","Conf.Int","p.value")
  #invisible(df.out)
  return(df.out)
}
#=====================================================================================
#krippen.alpha.dist: This function computes Krippendorff's alpha coefficient (see Krippendorff(1970, 1980)) and 
#		   its standard error for 3 raters or more when input dataset is a nxq matrix representing 
#              the distribution of raters by subject and by category. 
#The input data "ratings" is an nxq matrix showing the number of raters by subject and category. A typical entry associated
#with a subject and a category, represents the number of raters who classified the subject into the specified category. Exclude 
#all subjects that are not rated by any rater.
#-------------
#The algorithm used to compute krippendorff's alpha is very different from anything that was published on this topic. Instead,
#it follows the equations presented by K. Gwet (2010)
#Bibliography:
#Gwet, K. (2012). Handbook of Inter-Rater Reliability: The Definitive Guide to Measuring the Extent of Agreement Among 
#	Multiple Raters, 3rd Edition.  Advanced Analytics, LLC; 3rd edition (March 2, 2012)
#Krippendorff (1970). "Bivariate agreement coefficients for reliability of data." Sociological Methodology,2,139-150
#Krippendorff (1980). Content analysis: An introduction to its methodology (2nd ed.), New-bury Park, CA: Sage.
#============================================================================================
#' Krippendorff's agreement coefficient among multiple raters (2, 3, +) when the input dataset is the distribution of raters by subject and category.
#' @param ratings An \emph{nxq} matrix / data frame containing the distribution of raters by subject and category. Each cell \emph{(i,k)} contains the number of raters who classsified subject \emph{i} into category \emph{k}.
#' @param weights is an optional parameter that is either a string variable or a matrix. The string describes one of the predefined 
#' weights and must take one of the values ("quadratic", "ordinal", "linear", "radical", "ratio", "circular", "bipolar"). 
#' If this parameter is a matrix then it must be a square matri qxq where q is the number of posssible categories where a subject 
#' can be classified. If some of the q possible categories are not used, then it is strobgly advised to specify the complete list of 
#' possible categories as a vector in parametr categ. Otherwise, only the categories reported will be used.
#' @param categ An optional parameter representing all categories available to raters during the experiment. This parameter may be useful if 
#' some categories were not used by any rater inspite of being available to the raters. 
#' @param conflev An optional parameter representing the confidence level associated with the confidence interval. Its default value is 0.95.
#' @param N An optional parameter representing the population size (if any). It may be use to perform the final population correction to the variance.  Its default value is infinity. 
#' @return A vector containing the following information: 
#' pa(the percent agreement),pe(the percent chance agreement),coeff(Krippendorff's alpha),
#' stderr(the standard error of Krippendorff's coefficient),conf.int(the confidence interval of Krippendorff's alpha coefficient),
#' p.value(the p-value of Krippendorff's alpha), coeff.name ("krippen alpha").
#' @examples 
#' #The dataset "distrib.6raters" comes with this package. It represents the distribution of 6 raters 
#' #by subject and by category. Note that each row of this dataset sums to the number of raters, which
#' #is 6. You may this dataset as follows:
#' distrib.6raters
#' krippen.alpha.dist(distrib.6raters) #Krippendorff's alpha, precision measures, weights & categories
#' alpha <- krippen.alpha.dist(distrib.6raters)$coeff #Yields Krippendorff's alpha coefficient alone.
#' alpha
#' q <- ncol(distrib.6raters) #Number of categories
#' krippen.alpha.dist(distrib.6raters,weights = quadratic.weights(1:q)) #Weighted alpha
#' @source Gwet, K. (2014). \emph{Handbook of Inter-Rater Reliability: The Definitive Guide to Measuring the Extent of Agreement Among 
#' Multiple Raters}, 4th Edition.  Advanced Analytics, LLC
#' Krippendorff (1970). ``Bivariate agreement coefficients for reliability of data," \emph{Sociological Methodology},2,139-150
#' Krippendorff (1980). \emph{Content analysis: An introduction to its methodology (2nd ed.)}, New-bury Park, CA: Sage.
#' @export
krippen.alpha.dist <- function(ratings,weights="unweighted",categ=NULL,conflev=0.95,N=Inf){ 
  agree.mat <- as.matrix(ratings) 
  n <- nrow(agree.mat) # number of subjects
  q <- ncol(agree.mat) # number of categories
  f <- n/N # final population correction 

  # creating the weights matrix
  
  if (is.null(categ)) categ <- 1:q
  else{
    q2 <- length(categ)
    if (!is.numeric(categ)) categ <- 1:q2
    if (q2>q){
      colna1 <- colnames(agree.mat) 
      agree.mat <- cbind(agree.mat,matrix(0,n,(q2-q)))
      colna2 <- sapply(1:(q2-q),function(x) paste0("v",x))
      colnames(agree.mat) <- c(colna1,colna2)
      q <- q2
    } 
  }
  if (is.character(weights)){
    w.name <- weights
    if (weights=="quadratic") weights.mat<-quadratic.weights(categ)
    else if (weights=="ordinal") weights.mat<-ordinal.weights(categ)
    else if (weights=="linear") weights.mat<-linear.weights(categ)
    else if (weights=="radical") weights.mat<-radical.weights(categ)
    else if (weights=="ratio") weights.mat<-ratio.weights(categ)
    else if (weights=="circular") weights.mat<-circular.weights(categ)
    else if (weights=="bipolar") weights.mat<-bipolar.weights(categ)
    else weights.mat<-identity.weights(categ)
  }else{
    w.name <- "Custom Weights"
    weights.mat= as.matrix(weights)
  }
  
  agree.mat.w <- t(weights.mat%*%t(agree.mat))

  # calculating krippendorff's alpha coefficient

  ri.vec <- agree.mat%*%rep(1,q)
  agree.mat<-agree.mat[(ri.vec>=2),]
  agree.mat.w <- agree.mat.w[(ri.vec>=2),]
  ri.vec <- ri.vec[(ri.vec>=2)]
  ri.mean <- mean(ri.vec)
  n <- nrow(agree.mat)
  epsi <- 1/sum(ri.vec)
  sum.q <- (agree.mat*(agree.mat.w-1))%*%rep(1,q)
  pa <- (1-epsi)* sum(sum.q/(ri.mean*(ri.vec-1)))/n + epsi

  pi.vec <- t(t(rep(1/n,n))%*%(agree.mat/ri.mean))
  pe <- sum(weights.mat * (pi.vec%*%t(pi.vec)))
  krippen.alpha <- (pa-pe)/(1-pe)

  # calculating variance, stderr & p-value of gwet's ac1 coefficient
  
  den.ivec <- ri.mean*(ri.vec-1)
  pa.ivec <- sum.q/den.ivec
  pa.v <- mean(pa.ivec)
  pa.ivec <- (1-epsi)*(pa.ivec-pa.v*(ri.vec-ri.mean)/ri.mean) + epsi

  krippen.ivec <- (pa.ivec-pe)/(1-pe)
  pi.vec.wk. <- weights.mat%*%pi.vec
  pi.vec.w.k <- t(weights.mat)%*%pi.vec

  pi.vec.w <- (pi.vec.wk. + pi.vec.w.k)/2

  pe.ivec <- (agree.mat%*%pi.vec.w)/ri.mean - sum(pi.vec) * (ri.vec-ri.mean)/ri.mean
  krippen.ivec.x <- krippen.ivec - (1-krippen.alpha) * (pe.ivec-pe)/(1-pe)
  
  var.krippen <- ((1-f)/(n*(n-1))) * sum((krippen.ivec.x - krippen.alpha)^2)
  stderr <- sqrt(var.krippen)# alpha's standard error
  p.value <- 2*(1-pt(krippen.alpha/stderr,n-1))
  
  lcb <- krippen.alpha - stderr*qt(1-(1-conflev)/2,n-1) # lower confidence bound
  ucb <- min(1,krippen.alpha + stderr*qt(1-(1-conflev)/2,n-1)) # upper confidence bound
  conf.int <- paste0("(",round(lcb,3),",",round(ucb,3),")")
  coeff <- krippen.alpha
  coeff.name <-"Krippendorff's Alpha"
  df.out <- data.frame(coeff.name,coeff,stderr,conf.int,p.value,pa,pe)
  #colnames(df.out) <- c("pa","pe","alpha","stderr","Conf.Int","p.value")
  #invisible(df.out)
  return(df.out)
}
#===========================================================================================
#bp.coeff.dist: Brennan-Prediger coefficient (see Brennan & Prediger(1981)) and its standard error for multiple raters when input 
#		   dataset is a nxq matrix representing the distribution of raters by subject and by category. 
#The input data "ratings" is an nxq matrix showing the number of raters by subject and category. A typical entry associated
#with a subject and a category, represents the number of raters who classified the subject into the specified category. Exclude 
#all subjects that are not rated by any rater.
#--------------------------------------------
#Bibliography:
#Brennan, R.L., and Prediger, D. J. (1981). ``Coefficient Kappa: some uses, misuses, and alternatives."
#           Educational and Psychological Measurement, 41, 687-699.
#======================================================================================
#' Brennan-Prediger's agreement coefficient among multiple raters (2, 3, +) when the input dataset is the distribution of raters by subject and category.
#' @param ratings An \emph{nxq} matrix / data frame containing the distribution of raters by subject and category. Each cell \emph{(i,k)} contains the number of raters who classsified subject \emph{i} into category \emph{k}.
#' @param weights is an optional parameter that is either a string variable or a matrix. The string describes one of the predefined 
#' weights and must take one of the values ("quadratic", "ordinal", "linear", "radical", "ratio", "circular", "bipolar"). 
#' If this parameter is a matrix then it must be a square matri qxq where q is the number of posssible categories where a subject 
#' can be classified. If some of the q possible categories are not used, then it is strobgly advised to specify the complete list of 
#' possible categories as a vector in parametr categ. Otherwise, only the categories reported will be used.
#' @param categ An optional parameter representing all categories available to raters during the experiment. This parameter may be useful if 
#' some categories were not used by any rater inspite of being available to the raters. 
#' @param conflev An optional parameter representing the confidence level associated with the confidence interval. Its default value is 0.95.
#' @param N An optional parameter representing the population size (if any). It may be use to perform the final population correction to the variance.  Its default value is infinity. 
#' @return A vector containing the following information: 
#' pa(the percent agreement),pe(the percent chance agreement),coeff(Brennan-Prediger coefficient),
#' stderr(the standard error of Brennan-Prediger coefficient),conf.int(the p-value of Brennan-Prediger coefficient), 
#' p.value(the p-value of Brennan-Prediger coefficient),coeff.name ("Brennan-Prediger").
#' @examples 
#' #The dataset "distrib.6raters" comes with this package. It represents the distribution of 6 raters 
#' #by subject and by category. Note that each row of this dataset sums to the number of raters, which
#' #is 6. You may this dataset as follows:
#' distrib.6raters
#' bp.coeff.dist(distrib.6raters) #BP coefficient, precision measures, weights & list of categories
#' bp <- bp.coeff.dist(distrib.6raters)$coeff #Yields Brennan-Prediger coefficient alone.
#' bp
#' q <- ncol(distrib.6raters) #Number of categories
#' bp.coeff.dist(distrib.6raters,weights = quadratic.weights(1:q)) #Weighted BP with quadratic weights
#' @source Brennan, R.L., and Prediger, D. J. (1981). ``Coefficient Kappa: some uses, misuses, and alternatives," 
#' \emph{Educational and Psychological Measurement}, 41, 687-699.
#' @export
bp.coeff.dist <- function(ratings,weights="unweighted",categ=NULL,conflev=0.95,N=Inf){ 
  agree.mat <- as.matrix(ratings) 
  n <- nrow(agree.mat) # number of subjects
  q <- ncol(agree.mat) # number of categories
  f <- n/N # final population correction 

  # creating the weights matrix
  
  if (is.null(categ)) categ <- 1:q
  else{
    q2 <- length(categ)
    if (!is.numeric(categ)) categ <- 1:q2
    if (q2>q){
      colna1 <- colnames(agree.mat) 
      agree.mat <- cbind(agree.mat,matrix(0,n,(q2-q)))
      colna2 <- sapply(1:(q2-q),function(x) paste0("v",x))
      colnames(agree.mat) <- c(colna1,colna2)
      q <- q2
    } 
  }
  if (is.character(weights)){
    w.name <- weights
    if (weights=="quadratic") weights.mat<-quadratic.weights(categ)
    else if (weights=="ordinal") weights.mat<-ordinal.weights(categ)
    else if (weights=="linear") weights.mat<-linear.weights(categ)
    else if (weights=="radical") weights.mat<-radical.weights(categ)
    else if (weights=="ratio") weights.mat<-ratio.weights(categ)
    else if (weights=="circular") weights.mat<-circular.weights(categ)
    else if (weights=="bipolar") weights.mat<-bipolar.weights(categ)
    else weights.mat<-identity.weights(categ)
  }else{
    w.name <- "Custom Weights"
    weights.mat= as.matrix(weights)
  }
  
  agree.mat.w <- t(weights.mat%*%t(agree.mat))

  # calculating gwet's ac1 coefficient

  ri.vec <- agree.mat%*%rep(1,q)
  sum.q <- (agree.mat*(agree.mat.w-1))%*%rep(1,q)
  n2more <- sum(ri.vec>=2)
  pa <- sum(sum.q[ri.vec>=2]/((ri.vec*(ri.vec-1))[ri.vec>=2]))/n2more

  pi.vec <- t(t(rep(1/n,n))%*%(agree.mat/(ri.vec%*%t(rep(1,q)))))
  pe <- sum(weights.mat) / (q^2)
  bp.coeff <- (pa-pe)/(1-pe)

  # calculating variance, stderr & p-value of gwet's ac1 coefficient
  
  den.ivec <- ri.vec*(ri.vec-1)
  den.ivec <- den.ivec - (den.ivec==0) # this operation replaces each 0 value with -1 to make the next ratio calculation always possible.
  pa.ivec <- sum.q/den.ivec

  pe.r2 <- pe*(ri.vec>=2)
  bp.ivec <- (n/n2more)*(pa.ivec-pe.r2)/(1-pe)
  var.bp <- ((1-f)/(n*(n-1))) * sum((bp.ivec - bp.coeff)^2)
  stderr <- sqrt(var.bp)# BP's standard error
  p.value <- 2*(1-pt(bp.coeff/stderr,n-1))
  
  lcb <- bp.coeff - stderr*qt(1-(1-conflev)/2,n-1) # lower confidence bound
  ucb <- min(1,bp.coeff + stderr*qt(1-(1-conflev)/2,n-1)) # upper confidence bound
  conf.int <- paste0("(",round(lcb,3),",",round(ucb,3),")")
  coeff <- bp.coeff
  coeff.name <- "Brennan-Prediger"
  df.out <- data.frame(coeff.name,coeff,stderr,conf.int,p.value,pa,pe)
  #colnames(df.out) <- c("pa","pe","B.P","stderr","Conf.Int","p.value")
  #invisible(df.out)
  return(df.out)
}
#======================================================================================
#' Percent agreement coefficient among multiple raters (2, 3, +) when the input dataset is the distribution of raters by subject and category.
#' @param ratings An \emph{nxq} matrix / data frame containing the distribution of raters by subject and category. Each cell \emph{(i,k)} contains the number of raters who classsified subject \emph{i} into category \emph{k}.
#' @param weights is an optional parameter that is either a string variable or a matrix. The string describes one of the predefined 
#' weights and must take one of the values ("quadratic", "ordinal", "linear", "radical", "ratio", "circular", "bipolar"). 
#' If this parameter is a matrix then it must be a square matri qxq where q is the number of posssible categories where a subject 
#' can be classified. If some of the q possible categories are not used, then it is strobgly advised to specify the complete list of 
#' possible categories as a vector in parametr categ. Otherwise, only the categories reported will be used.
#' @param categ An optional parameter representing all categories available to raters during the experiment. This parameter may be useful if 
#' some categories were not used by any rater inspite of being available to the raters. 
#' @param conflev An optional parameter representing the confidence level associated with the confidence interval. Its default value is 0.95.
#' @param N An optional parameter representing the population size (if any). It may be use to perform the final population correction to the variance.  Its default value is infinity. 
#' @return A vector containing the following information: 
#' pa(the percent agreement),pe(the percent chance agreement),coeff(Brennan-Prediger coefficient),
#' stderr(the standard error of Brennan-Prediger coefficient),conf.int(the p-value of Brennan-Prediger coefficient), 
#' p.value(the p-value of Brennan-Prediger coefficient),coeff.name ("Brennan-Prediger").
#' @examples 
#' #The dataset "distrib.6raters" comes with this package. It represents the distribution of 6 raters 
#' #by subject and by category. Note that each row of this dataset sums to the number of raters, which
#' #is 6. You may this dataset as follows:
#' distrib.6raters
#' pa.coeff.dist(distrib.6raters) #percent agreement, precision measures, weights& list of categories
#' pa <- pa.coeff.dist(distrib.6raters)$coeff #Yields the percent agreement coefficient alone.
#' pa
#' q <- ncol(distrib.6raters) #Number of categories
#' pa.coeff.dist(distrib.6raters,weights = quadratic.weights(1:q)) #Weighted percent agreement
#' @source Brennan, R.L., and Prediger, D. J. (1981). ``Coefficient Kappa: some uses, misuses, and alternatives," 
#' \emph{Educational and Psychological Measurement}, 41, 687-699.
#' @export
pa.coeff.dist <- function(ratings,weights="unweighted",categ=NULL,conflev=0.95,N=Inf){ 
  agree.mat <- as.matrix(ratings) 
  n <- nrow(agree.mat) # number of subjects
  q <- ncol(agree.mat) # number of categories
  f <- n/N # final population correction 
  
  # creating the weights matrix
  
  if (is.null(categ)) categ <- 1:q
  else{
    q2 <- length(categ)
    if (!is.numeric(categ)) categ <- 1:q2
    if (q2>q){
      colna1 <- colnames(agree.mat) 
      agree.mat <- cbind(agree.mat,matrix(0,n,(q2-q)))
      colna2 <- sapply(1:(q2-q),function(x) paste0("v",x))
      colnames(agree.mat) <- c(colna1,colna2)
      q <- q2
    } 
  }
  if (is.character(weights)){
    w.name <- weights
    if (weights=="quadratic") weights.mat<-quadratic.weights(categ)
    else if (weights=="ordinal") weights.mat<-ordinal.weights(categ)
    else if (weights=="linear") weights.mat<-linear.weights(categ)
    else if (weights=="radical") weights.mat<-radical.weights(categ)
    else if (weights=="ratio") weights.mat<-ratio.weights(categ)
    else if (weights=="circular") weights.mat<-circular.weights(categ)
    else if (weights=="bipolar") weights.mat<-bipolar.weights(categ)
    else weights.mat<-identity.weights(categ)
  }else{
    w.name <- "Custom Weights"
    weights.mat= as.matrix(weights)
  }
  agree.mat.w <- t(weights.mat%*%t(agree.mat))
  # calculating percent agreement
  ri.vec <- agree.mat%*%rep(1,q)
  sum.q <- (agree.mat*(agree.mat.w-1))%*%rep(1,q)
  n2more <- sum(ri.vec>=2)
  pa <- sum(sum.q[ri.vec>=2]/((ri.vec*(ri.vec-1))[ri.vec>=2]))/n2more
  # calculating variance, stderr & p-value of the percent agreement
  den.ivec <- ri.vec*(ri.vec-1)
  den.ivec <- den.ivec - (den.ivec==0) # this operation replaces each 0 value with -1 to make the next ratio calculation always possible.
  pa.ivec <- sum.q/den.ivec
  
  pi.vec <- t(t(rep(1/n,n))%*%(agree.mat/(ri.vec%*%t(rep(1,q)))))
  pa.ivec <- (n/n2more)*pa.ivec
  var.pa <- ((1-f)/(n*(n-1))) * sum((pa.ivec - pa)^2)
  stderr <- sqrt(var.pa)# kappa's standard error
  p.value <- 2*(1-pt(pa/stderr,n-1))
  
  lcb <- pa - stderr*qt(1-(1-conflev)/2,n-1) # lower confidence bound
  ucb <- min(1,pa + stderr*qt(1-(1-conflev)/2,n-1)) # upper confidence bound
  conf.int <- paste0("(",round(lcb,3),",",round(ucb,3),")")
  pe <-0
  coeff <- pa
  coeff.name <- "Percent agreement"
  df.out <- data.frame(coeff.name,coeff,stderr,conf.int,p.value,pa,pe)
  return(df.out)
}

