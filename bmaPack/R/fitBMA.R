#' Fitting BMA
#'
#' Runs Bayesian Modeling Average given the regressions for every combination of the input covariates with no constant
#'
#' @param Y A matrix object; The number of columns is one; The number of rows depends on the data 
#' @param X A matrix object; The number of rows is the same as that of \code{Y}; The number of columns depends on the data
#'  
#' @return An object of class Regressions containing
#'  \item{output}{Output includes coefficients and the value of R.squared}
#' @author Taeyong Park
#' 
#' @examples
#' set.seed(0520)
#' myY <- matrix(sample(1:20, 50, replace=TRUE), 50, 1) 
#' myX <- matrix(c(runif(50), runif(50), rnorm(50), rnorm(50)), 50, 4)
#' fitBMA(Y=myY, X=myX)
#' @seealso \code{\link{summary}}
#' @rdname fitBMA
#' @aliases BMA,ANY-method  
#' @export
setGeneric(name="fitBMA",  # setGeneric sets a generic function
           def=function(Y, X, ...)
           {standardGeneric("fitBMA")}
)

#' @export
setMethod(f="fitBMA",  # setMethod specifies the function fitBMA()
          definition=function(Y, X, g=3){ # g=3 is default 
            Y <- (Y-mean(Y))/sd(Y) # Standardize dependent variable
            X <- (X-mean(X))/sd(X) # Standardize covariates
            Z <- list()  # Z will contain every combination of X
            coefficientsList <- list() # This will be transformed to coefficients which is a matrix
            coefficients<-matrix(NA, ncol(X), ncol(X)) # We want the output of coefficients as a matrix; Since we will run regressions without constant, the output has the same number of rows and columns
            R2 <- eBetaModel <- bayesF <- numeric() # Empty numerics for several statistics
            for (i in 2:ncol(X)){ # The first elements are not looped to make it easy to create every combination of the covariates
              Z[[1]] <- X[,1]  
              Z[[i]] <- cbind(X[,i],Z[[i-1]]) # This ensures that Z will contain every combination of the covariates
              coefficientsList[[1]] <- summary(lm(Y ~ Z[[1]]-1))$coef[,1] # The first element for coefficient is not looped 
              coefficientsList[[i]] <- summary(lm(Y ~ Z[[i]]-1))$coef[,1] # We should run regressions with no constant
              coefficients[1,] <- c(coefficientsList[[1]], rep(NA, ncol(X)-length(coefficientsList[[1]]))) # Now, we want to transform coef to the form of matrix
              coefficients[i,] <- c(coefficientsList[[i]], rep(NA, ncol(X)-length(coefficientsList[[i]]))) # An empty cell will be expressed as "NA"
              R2[1] <- summary(lm(Y ~ Z[[1]]-1))$r.squared # The first element for R2 is not looped
              R2[i] <- summary(lm(Y ~ Z[[i]]-1))$r.squared # We should run regressions with no constant
            }
            for (k in 1:ncol(X)){
              p=k  # p indicates the number of covariates of the model under consideration
              n=nrow(X)  # n indicates the number of rows of input data for explnatory variables
              bayesF[k] <- (1+g)^((n-p-1)/2)*(1+g*(1-R2[k]))^(-(n-1)/2) # This returns Bayes's factor for the models; This is the posterior model odds for each model
            }
            for (j in 1:ncol(X)){
              eBetaModel[j] <- mean((g/(g+1))*coefficients[j:ncol(X),1]) # This returns E(\beta_j|M_k) from Slide 3
            }
            postModel <- bayesF/sum(bayesF) # Posterior probability of the model; The total weight assigned to all models that include each variable; This gives us the posterior probability that the coefficient is non-zero
            postCoef <- postModel*eBetaModel # Posterior expected value of each coefficient
            output <- list(coefficients, R2, bayesF, postCoef, postModel)  
            names(output) <- c("coefficients", "R.squared", "postOdds", "postCoef", "probSig")  # postOdds from bayesF; probSig from postModel
            return((new("BMA", Y=Y, X=X, output=output)))
          }
)

