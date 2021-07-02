library(utils)
library(stats)
library(lubridate)

setwd('C:/Users/Administrateur/Desktop/typology')

rodbc<-RODBC::odbcDriverConnect(
  "DRIVER={ODBC Driver 13 for SQL Server};
  SERVER=10.129.16.51;
  Database=d2epicentre_formation;
  uid=FWA_ro;
  pwd=LWs5gt#9jU7d")


catf<-function(...){
  cat(sprintf(...))
  flush.console()
}

normalizeText<-function(x){
  x <- iconv(x, to='ASCII//TRANSLIT')
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
  df<-RODBC::sqlQuery(rodbc, sprintf("SELECT * FROM %s", tablename), stringsAsFactors = FALSE)
  df<-dplyr::mutate_if(df, is.character, normalizeText)
  df<-dplyr::mutate_if(df, is.POSIXct, normalizeDate)
  if(nrow(df)>0) {
    df<-dplyr::mutate(df, rownames = 1:dplyr::n())
  } else {
    df<-dplyr::mutate(df, rownames = as.integer())
  }
  df<-dplyr::select(df, rownames, dplyr::everything())
  readr::write_csv(df,path=sprintf('C:/Users/Administrateur/MSF/GRP-EPI-PROJ-TypoEpicentre - Dump/Epicentre (Formation)/%s.csv',tolower(tablename)), na = '')
  catf('...Ok\n')
}

tables <- RODBC::sqlTables(rodbc)
tables <- subset(tables, TABLE_TYPE == "TABLE")
tables <- subset(tables, TABLE_TYPE != "ArcoleItemsImporting")

for(i in 1:nrow(tables))
  dumpTable(tables[i,'TABLE_NAME'])
