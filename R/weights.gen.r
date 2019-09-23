#' Function for computing the Identity Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of identity weights to be used for calculating the unweighted coefficients.
#' @export
identity.weights<-function(categ){
	weights<-diag(length(categ))
	return (weights)
}

#' Function for computing the Quadratic Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of quadratic weights to be used for calculating the weighted coefficients.
#' @export
quadratic.weights<-function(categ){
	q<-length(categ)
	weights <- diag(q)
	if (is.numeric(categ)) { 
	   categ.vec <- sort(categ)
	}
	else {
	   categ.vec<-1:length(categ)
	}
	xmin<-min(categ.vec)
	xmax<-max(categ.vec)
	for(k in 1:q){
	    for(l in 1:q){
		  weights[k,l] <- 1-(categ.vec[k]-categ.vec[l])^2/(xmax-xmin)^2 
	    }
      }
	return (weights)
}
#' Function for computing the Linear Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of quadratic weights to be used for calculating the weighted coefficients.
#' @export
linear.weights<-function(categ){
	q<-length(categ)
	weights <- diag(q)
	if (is.numeric(categ)) { 
	   categ.vec <- sort(categ)
	}
	else {
	   categ.vec<-1:length(categ)
	}
	xmin<-min(categ.vec)
	xmax<-max(categ.vec)
	for(k in 1:q){
	    for(l in 1:q){
		    weights[k,l] <- 1-abs(categ.vec[k]-categ.vec[l])/abs(xmax-xmin)
	    }
  }
	return (weights)
}
#--------------------------------
#' Function for computing the Radical Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of quadratic weights to be used for calculating the weighted coefficients.
#' @export
radical.weights<-function(categ){
	q<-length(categ)
	weights <- diag(q)
	if (is.numeric(categ)) { 
	   categ.vec <- sort(categ)
	}
	else {
	   categ.vec<-1:length(categ)
	}
	xmin<-min(categ.vec)
	xmax<-max(categ.vec)
	for(k in 1:q){
	    for(l in 1:q){
		    weights[k,l] <- 1-sqrt(abs(categ.vec[k]-categ.vec[l]))/sqrt(abs(xmax-xmin))
	    }
  }
	return (weights)
}

#--------------------------------
#' Function for computing the Ratio Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of quadratic weights to be used for calculating the weighted coefficients.
#' @export
ratio.weights<-function(categ){
	q<-length(categ)
	weights <- diag(q)
	if (is.numeric(categ)) { 
	   categ.vec <- sort(categ)
	}
	else {
	   categ.vec<-1:length(categ)
	}
	xmin<-min(categ.vec)
	xmax<-max(categ.vec)
	for(k in 1:q){
	    for(l in 1:q){
		    weights[k,l] <- 1-((categ.vec[k]-categ.vec[l])/(categ.vec[k]+categ.vec[l]))^2 / ((xmax-xmin)/(xmax+xmin))^2
	    }
  }
	return (weights)
}

#--------------------------------
#' Function for computing the Circular Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of quadratic weights to be used for calculating the weighted coefficients.
#' @export
circular.weights<-function(categ){
	q<-length(categ)
	weights <- diag(q)
	if (is.numeric(categ)) { 
	   categ.vec <- sort(categ)
	}
	else {
	   categ.vec<-1:length(categ)
	}
	xmin<-min(categ.vec)
	xmax<-max(categ.vec)
	U = xmax-xmin+1
	for(k in 1:q){
	    for(l in 1:q){
		  weights[k,l] <- (sin(pi*(categ.vec[k]-categ.vec[l])/U))^2
	    }
      }
	weights <- 1-weights/max(weights)
	return (weights)
}

#--------------------------------
#' Function for computing the Bipolar Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of quadratic weights to be used for calculating the weighted coefficients.
#' @export
bipolar.weights<-function(categ){
	q<-length(categ)
	weights <- diag(q)
	if (is.numeric(categ)) { 
	   categ.vec <- sort(categ)
	}
	else {
	   categ.vec<-1:length(categ)
	}
	xmin<-min(categ.vec)
	xmax<-max(categ.vec)
	for(k in 1:q){
	    for(l in 1:q){
		  if (k!=l)
		  	weights[k,l] <- (categ.vec[k]-categ.vec[l])^2 / (((categ.vec[k]+categ.vec[l])-2*xmin)*(2*xmax-(categ.vec[k]+categ.vec[l])))
		  else weights[k,l] <- 0
	    }
      }
	weights <- 1-weights/max(weights)
	return (weights)
}


#--------------------------------
#' Function for computing the Ordinal Weights
#' @param  categ A mandatory parameter representing the vector of all possible ratings.
#' @return A square matrix of quadratic weights to be used for calculating the weighted coefficients.
#' @export
ordinal.weights<-function(categ){
	q<-length(categ)
	weights <- diag(q)
      categ.vec<-1:length(categ)
	for(k in 1:q){
	    for(l in 1:q){
		  nkl <- max(k,l)-min(k,l)+1
		  weights[k,l] <- nkl * (nkl-1)/2
	    }
      }
	weights <- 1-weights/max(weights)
	return (weights)
}