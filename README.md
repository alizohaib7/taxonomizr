# Convert accession numbers to taxonomy

[![Build Status](https://travis-ci.org/sherrillmix/taxonomizr.svg?branch=master)](https://travis-ci.org/sherrillmix/taxonomizr)
[![codecov.io](https://codecov.io/github/sherrillmix/dnaplotr/taxonomizr.svg?branch=master)](https://codecov.io/github/sherrillmix/taxonomizr?branch=master)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/taxonomizr)](https://cran.r-project.org/package=taxonomizr)

## Introduction

`taxonomizr` provides some simple functions to parse NCBI taxonomy files and accession dumps and efficiently use them to assign [taxonomy](https://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/) to accession numbers or taxonomic IDs. This is useful for example to assign taxonomy to BLAST results. This is all done locally after downloading the appropriate files from NCBI using included functions (see [below](#preparation)). 

## Installation
The package is on CRAN, so it should install with a simple:

```r
install.packages("taxonomizr")
```

If you want the development version directly from github, use the [<code>devtools</code>](https://github.com/hadley/devtools) library and run:

```r
devtools::install_github("sherrillmix/taxonomizr")
```

To use the library, load it in R:

```r
library(taxonomizr)
```



## Preparation<a name="preparation"></a>
In order to avoid constant internet access and slow APIs, the first step in using the package is to downloads all necessary files from NCBI. This uses a bit of disk space but makes future access reliable and fast.

**Note:** It is not necessary to manually check for the presence of these files since the functions automatically check to see if their output is present and if so skip downloading/processing. Delete the local files if you would like to redownload or reprocess them.

### Download names and nodes
First, download the necessary names and nodes files from [NCBI](ftp://ftp.ncbi.nih.gov/pub/taxonomy/):

```r
getNamesAndNodes()
```

```
## [1] "./names.dmp" "./nodes.dmp"
```

### Download accession to taxa files

Then download accession to taxa id conversion files from [NCBI](ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/). **Note:** this is a pretty _big_ download (several gigabytes):

```r
#this is a big download
getAccession2taxid()
```

```
## [1] "./nucl_gb.accession2taxid.gz"  "./nucl_est.accession2taxid.gz"
## [3] "./nucl_gss.accession2taxid.gz" "./nucl_wgs.accession2taxid.gz"
```

If you would also like to identify protein accession numbers, also download the prot file from NCBI (again this is a _big_ download):

```r
#this is a big download
getAccession2taxid(types='prot')
```

```
## [1] "./prot.accession2taxid.gz"
```

### Convert accessions to database

Then process the downloaded accession files into a more easily accessed form (this could take a while):


```r
read.accession2taxid(list.files('.','accession2taxid.gz$'),'accessionTaxa.sql')
```

```
## Reading nucl_est.accession2taxid.gz.
```

```
## Reading nucl_gb.accession2taxid.gz.
```

```
## Reading nucl_gss.accession2taxid.gz.
```

```
## Reading nucl_wgs.accession2taxid.gz.
```

```
## Reading in values. This may take a while.
```

```
## Adding index. This may also take a while.
```

```
## [1] TRUE
```

Now everything should be ready for processing. All files are cached locally and so the preparation is only required once (or whenever you would like to update the data). It is not necessary to manually check for the presence of these files since the functions automatically check to see if their output is present and if so skip downloading/processing. Delete the local files if you would like to redownload or reprocess them.

## Assigning taxonomy

### Finding taxonomy for NCBI accession numbers

First, load the nodes and names files into memory:


```r
taxaNodes<-read.nodes('nodes.dmp')
taxaNames<-read.names('names.dmp')
```


Then we are ready to convert NCBI accession numbers to taxonomic IDs. For example, to find the taxonomic IDs associated with NCBI accession numbers "LN847353.1" and "AL079352.3":

```r
taxaId<-accessionToTaxa(c("LN847353.1","AL079352.3"),"accessionTaxa.sql")
print(taxaId)
```

```
## [1] 1313 9606
```

And to get the taxonomy for those IDs:


```r
getTaxonomy(taxaId,taxaNodes,taxaNames)
```

```
##      superkingdom phylum       class      order            
## 1313 "Bacteria"   "Firmicutes" "Bacilli"  "Lactobacillales"
## 9606 "Eukaryota"  "Chordata"   "Mammalia" "Primates"       
##      family             genus           species                   
## 1313 "Streptococcaceae" "Streptococcus" "Streptococcus pneumoniae"
## 9606 "Hominidae"        "Homo"          "Homo sapiens"
```

### Finding taxonomy for taxonomic names

If you'd like to find IDs for taxonomic names then you can do something like:

```r
taxaId<-getId(c('Homo sapiens','Bos taurus','Homo'),taxaNames)
print(taxaId)
```

``` 
## [1] "9606" "9913" "9605"
```

And again to get the taxonomy for those IDs use `getTaxonomy`:


```r
getTaxonomy(taxaId,taxaNodes,taxaNames)
```

```
##      superkingdom phylum     class      order      family      genus 
## 9606 "Eukaryota"  "Chordata" "Mammalia" "Primates" "Hominidae" "Homo"
## 9913 "Eukaryota"  "Chordata" "Mammalia" NA         "Bovidae"   "Bos" 
## 9605 "Eukaryota"  "Chordata" "Mammalia" "Primates" "Hominidae" "Homo"
##      species       
## 9606 "Homo sapiens"
## 9913 "Bos taurus"  
## 9605 NA
```
