library(utils)
library(stats)
library(lubridate)
library("git2r")

setwd('C:/Users/Administrateur/Desktop/typology')

RODBC::odbcCloseAll()

rodbc<-NULL
rodbc<-RODBC::odbcDriverConnect(
  "DRIVER={ODBC Driver 13 for SQL Server};
  SERVER=10.129.16.51;
  Database=d2epicentre;
  uid=FWA_ro;
  pwd=LWs5gt#9jU7d")


catf<-function(...){
  cat(sprintf(...))
  flush.console()
}

normalizeText<-function(x){
  # x <- iconv(x, to='ASCII//TRANSLIT')
  x <- gsub('[[:cntrl:]]+', ' ', x)
  x <- gsub('\n', ' ', x)
  x <- gsub(',', ' ', x)
  return(x)
}

normalizeDate<-function(x){
  x <- as.character(x)
  x <- gsub('[0-9]{2}:[0-9]{2}:[0-9]{2}', '', x)
  return(x)
}

dumpTable<-function(tablename){
  catf('Process table "%s"',tablename)
  rodbc <- RODBC::odbcReConnect(rodbc)
  df<-RODBC::sqlQuery(rodbc, sprintf("SELECT * FROM %s", tablename), stringsAsFactors = FALSE)
  df<-dplyr::mutate_if(df, is.character, normalizeText)
  df<-dplyr::mutate_if(df, is.POSIXct, normalizeDate)
  if(nrow(df)>0) {
    df<-dplyr::mutate(df, rownames = 1:dplyr::n())
  } else {
    df<-dplyr::mutate(df, rownames = as.integer())
  }
  df<-dplyr::select(df, rownames, dplyr::everything())
  readr::write_csv(df,path=sprintf('C:/Users/Administrateur/Desktop/typology/data/%s.csv',tolower(tablename)), na = '')
  
}

tables <- RODBC::sqlTables(rodbc)
tables <- subset(tables, TABLE_TYPE == "TABLE")
tables <- subset(tables, TABLE_NAME != "ArcoleItemsImporting")

for(i in 1:nrow(tables)) {
  tryCatch({
    dumpTable(tables[i,'TABLE_NAME'])
    catf('...Ok\n')
  }, error = function(e) {
    catf('...Ko\n')
    message(e)
  })
}

Sys.setenv(GITHUB_PAT="97cc6bf86c31a42fca2de32884cd1f1c4b1102ba")

system2('git', 'commit -ma "."')
system2('git', 'push')
