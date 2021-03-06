% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/taxa.R
\name{getId}
\alias{getId}
\title{Find a given taxa by name}
\usage{
getId(taxa, taxaNames)
}
\arguments{
\item{taxa}{a vector of taxonomic names}

\item{taxaNames}{a names data.table from \code{\link{read.names}}}
}
\value{
a vector of character strings giving taxa IDs (potentially comma concatenated for any taxa with ambiguous names)
}
\description{
Find a taxa by string in the NCBI taxonomy. Note that NCBI species are stored as Genus species e.g. "Bos taurus". Ambiguous taxa names will return a comma concatenated string e.g. "123,234" and generate a warning.
}
\examples{
namesText<-c(
  "1\\t|\\tall\\t|\\t\\t|\\tsynonym\\t|",
  "1\\t|\\troot\\t|\\t\\t|\\tscientific name\\t|",
  "3\\t|\\tMulti\\t|\\tBacteria <prokaryotes>\\t|\\tscientific name\\t|",
  "4\\t|\\tMulti\\t|\\tBacteria <prokaryotes>\\t|\\tscientific name\\t|",
  "2\\t|\\tBacteria\\t|\\tBacteria <prokaryotes>\\t|\\tscientific name\\t|",
  "2\\t|\\tMonera\\t|\\tMonera <Bacteria>\\t|\\tin-part\\t|",
  "2\\t|\\tProcaryotae\\t|\\tProcaryotae <Bacteria>\\t|\\tin-part\\t|"
)
names<-read.names(textConnection(namesText))
getId('Bacteria',names)
getId('Not a real name',names)
getId('Multi',names)
}
\seealso{
\code{\link{read.names}}
}
