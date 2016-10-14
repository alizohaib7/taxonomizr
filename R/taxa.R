#' Read NCBI names file
#' 
#' Take an NCBI names file, keep only scientific names and convert it to a data.table
#'
#' @param nameFile string giving the path to an NCBI name file to read from (both gzipped or uncompressed files are ok)
#' @return a data.table with columns id and name with a key on id
#' @export
#' @examples
#' @references \url{ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid}
#' @seealso \code{\link{readNodes}}
#' names<-c(
#'   "1\t|\tall\t|\t\t|\tsynonym\t|",
#'   "1\t|\troot\t|\t\t|\tscientific name\t|",
#'   "2\t|\tBacteria\t|\tBacteria <prokaryotes>\t|\tscientific name\t|",
#'   "2\t|\tMonera\t|\tMonera <Bacteria>\t|\tin-part\t|",
#'   "2\t|\tProcaryotae\t|\tProcaryotae <Bacteria>\t|\tin-part\t|"
#' )
#' readNames(textConnection(names))
readNames<-function(nameFile){
  splitLines<-do.call(rbind,strsplit(readLines(nameFile),'\\s*\\|\\s*'))
  splitLines<-splitLines[splitLines[,4]=='scientific name',-(3:4)]
  colnames(splitLines)<-c('id','name')
  splitLines<-data.frame('id'=as.numeric(splitLines[,'id']),'name'=splitLines[,'name'],stringsAsFactors=FALSE)
  out<-data.table::data.table(splitLines,key='id')
  return(out)
}

#' Read NCBI nodes file
#' 
#' Take an NCBI nodes file and convert it to a data.table
#'
#' @param nodeFile string giving the path to an NCBI node file to read from (both gzipped or uncompressed files are ok)
#' @return a data.table with columns id, parent and rank with a key on id
#' @references \url{ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid}
#' @seealso \code{\link{readNames}}
#' @export
#' @examples
#' nodes<-c(
#'  "1\t|\t1\t|\tno rank\t|\t\t|\t8\t|\t0\t|\t1\t|\t0\t|\t0\t|\t0\t|\t0\t|\t0\t|\t\t|", 
#'  "2\t|\t131567\t|\tsuperkingdom\t|\t\t|\t0\t|\t0\t|\t11\t|\t0\t|\t0\t|\t0\t|\t0\t|\t0\t|\t\t|", 
#'  "6\t|\t335928\t|\tgenus\t|\t\t|\t0\t|\t1\t|\t11\t|\t1\t|\t0\t|\t1\t|\t0\t|\t0\t|\t\t|", 
#'  "7\t|\t6\t|\tspecies\t|\tAC\t|\t0\t|\t1\t|\t11\t|\t1\t|\t0\t|\t1\t|\t1\t|\t0\t|\t\t|", 
#'  "9\t|\t32199\t|\tspecies\t|\tBA\t|\t0\t|\t1\t|\t11\t|\t1\t|\t0\t|\t1\t|\t1\t|\t0\t|\t\t|"
#' )
#' readNodes(textConnection(nodes))
readNodes<-function(nodeFile){
  splitLines<-do.call(rbind,strsplit(readLines(nodeFile),'\\s*\\|\\s*'))
  splitLines<-splitLines[,1:3]
  colnames(splitLines)<-c('id','parent','rank')
  splitLines<-data.frame('id'=as.numeric(splitLines[,'id']),'rank'=splitLines[,'rank'],'parent'=as.numeric(splitLines[,'parent']),stringsAsFactors=FALSE)
  out<-data.table::data.table(splitLines,key='id')
  return(out)
}

#' Return last not NA value
#' 
#' A convenience function to return the last value which is not NA in a vector
#'
#' @param x a vector to look for the last value in 
#' @param default a default value to use when all values are NA in a vector
#' @return a single element from the last non NA value in x (or the default) 
#' @export
#' @examples
#' lastNotNa(c(1:4,NA,NA))
#' lastNotNa(c(letters[1:4],NA,'z',NA))
#' lastNotNa(c(NA,NA))
lastNotNa<-function(x,default='Unknown'){
  out<-tail(na.omit(x),1)
  if(length(out)==0)return(default)
  return(out)
}

#' Process a large file piecewise
#' 
#' A convenience function to read in a large file piece by piece, process it (hopefully reducing the size either by summarizing or removing extra rows or columns) and return the output
#'
#' @param bigFile a path to a file to be read in
#' @param n number of lines to read per chuck
#' @param FUN a function taking the unparsed lines from a chunk of the bigfile as a single argument and returning the desired output
#' @param vocal if TRUE cat a "." as each chunk is processed
#' @param ... any additional arguments to FUN
#' @return a list containing the results from applying func to the multiple chunks of the file
#' @export
#' @examples
#' temp<-tempfile()
#' writeLines(letters,temp)
#' streamingRead(temp,2,paste,collapse='',vocal=TRUE)
#' unlist(streamingRead(temp,2,sample,1))
streamingRead<-function(bigFile,n=1e6,FUN=function(x)sub(',.*','',x),...,vocal=FALSE){
  FUN<-match.fun(FUN)
  handle<-file(bigFile,'r')
  out<-list()
  while(length(piece<-readLines(handle,n=n))>0){
    if(vocal)cat('.')
    out<-c(out,list(FUN(piece,...)))
  }
  close(handle)
  return(out)
}

readAccessionToTaxa<-function(taxaFiles,sqlFile){
  #zcat, cut off first line, cut out extra columns, read into sqlite, index 
  #db <- dbConnect(SQLite(), dbname = 'my_db.sqlite')
  #dbWriteTable(conn=db, name='my_table', value='my_file.csv', sep='\t')
  message('Reading accessions')
  tmp<-tempfile()
  writeLines('accession\ttaxa',tmp)
  for(ii in taxaFiles){
    cmd<-sprintf('zcat %s|sed 1d|cut -f2,3>>%s',ii,tmp)
    message(cmd)
    system(cmd)
  }
  db <- dbConnect(SQLite(), dbname=sqlFile)
  dbWriteTable(conn = db, name = "accessionTaxa", value =tmp, row.names = FALSE, header = TRUE,sep='\t')
  dbGetQuery(db,"CREATE INDEX index_accession ON accessionTaxa (accession)")
  dbDisconnect(db)
  #f<-file(tmp)
  #out<-sqldf("select * from f", dbname = tempfile(), file.format = list(header = T, row.names = F))
  #setkey(out,key='accession.version')
  return(sqlFile)
}
getTaxonomy<-function (ids,taxaNodes ,taxaNames, desiredTaxa=c('superkingdom','phylum','class','order','family','genus','species'),mc.cores=round(detectCores()/2)-1){
  uniqIds<-unique(ids)
  taxa<-do.call(rbind,mclapply(uniqIds,function(id){
      out<-structure(rep(NA,length(desiredTaxa)),names=desiredTaxa)
      thisId<-id    
      while(thisId!=1){
        thisNode<-taxaNodes[J(thisId),]
        if(is.na(thisNode$parent))break() #unknown taxa
        if(thisNode$rank %in% desiredTaxa)out[thisNode$rank]<-taxaNames[J(thisId),]$name
        thisId<-thisNode$parent
      }
      return(out)
  },mc.cores=mc.cores))
  rownames(taxa)<-format(uniqIds,scientific=FALSE)
  out<-taxa[format(ids,scientific=FALSE),]
  return(out)
}

accessionToTaxa<-function(accession,sqlFile){
  db <- dbConnect(SQLite(), dbname=sqlFile)
  dbWriteTable(db,'query',data.frame(accession,stringsAsFactors=FALSE),overwrite=TRUE)
  taxaDf<-dbGetQuery(db,'SELECT query.accession, taxa FROM query LEFT OUTER JOIN accessionTaxa ON query.accession=accessionTaxa.accession')
  dbGetQuery(db,'DROP TABLE query')
  dbDisconnect(db)
  if(any(taxaDf$accession!=accession))stop(simpleError('Query and SQL mismatch'))
  return(taxaDf$taxa)
}
condenseTaxa<-function(taxaTable){
  nTaxa<-apply(taxaTable,2,function(x)length(unique(x[!is.na(x)])))
  singles<-which(nTaxa==1)
  mostSpecific<-max(c(0,singles))
  out<-taxaTable[1,]
  if(mostSpecific<ncol(taxaTable))out[(mostSpecific+1):ncol(taxaTable)]<-NA
  return(out)
}

##DOWNLOAD NCBI DUMP##
######################
#if(!file.exists('dump/names.dmp.gz')){
  #dir.create('dump')
  #setwd('dump')
  #system('wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz')
  #system('tar xvfz taxdump.tar.gz')
  #system('gzip nodes.dmp names.dmp')
  #system('wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz')
  #system('wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_est.accession2taxid.gz')
  #system('wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gss.accession2taxid.gz')
  #system('wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_wgs.accession2taxid.gz')
  ##system('wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/gi_taxid_nucl.dmp.gz')
  #setwd('..')
  #accessionTaxa<-readAccessionToTaxa(list.files('dump','nucl_.*accession2taxid.gz',full.names=TRUE),'dump/accessionTaxa.sql')
#}


##READ NCBI DUMP##
##################
#if(!exists('taxaNodes')){
 taxaNodes<-readNodes('../chlorophyll/dump/nodes.dmp.gz')
 taxaNames<-readNames('../chlorophyll/dump/names.dmp.gz')
#}

