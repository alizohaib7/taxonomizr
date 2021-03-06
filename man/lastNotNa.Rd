% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/taxa.R
\name{lastNotNa}
\alias{lastNotNa}
\title{Return last not NA value}
\usage{
lastNotNa(x, default = "Unknown")
}
\arguments{
\item{x}{a vector to look for the last value in}

\item{default}{a default value to use when all values are NA in a vector}
}
\value{
a single element from the last non NA value in x (or the default)
}
\description{
A convenience function to return the last value which is not NA in a vector
}
\examples{
lastNotNa(c(1:4,NA,NA))
lastNotNa(c(letters[1:4],NA,'z',NA))
lastNotNa(c(NA,NA))
}
