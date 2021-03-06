library(lubridate)
library(cgmanalysis)
setwd("/Users/timvigers/Dropbox/Work/Sarit Polsky/Triple C/Tim/")
dateparseorder <- c("mdy","mdy HM","mdy HMS","mdY HM","mdY HMS","dmy HM","dmy HMS",
                    "dmY HM","dmY HMS","Ymd HM","Ymd HMS","ymd HM","ymd HMS",
                    "Ydm HM","Ydm HMS","ydm HM","ydm HMS")
# Output location
outdir = paste0(getwd(),"/","Cleaned/")
# Import dates - remove spaces and characters from names
dates = read.csv("./Trimester Dates -Janet.csv",na.strings = "")
dates$Last.name = tolower(gsub(" ","",dates$Last.name))
dates$Last.name = tolower(gsub("[[:punct:]]","",dates$Last.name))
dates$First.name = tolower(gsub(" ","",dates$First.name))
dates$First.name = tolower(gsub("[[:punct:]]","",dates$First.name))
# List all the directories
dirs = list.dirs("RAW DATA- CGM downloads")
# Loop through directories
for (d in dirs[2:length(dirs)]) {
  # Get name - lowercase and remove special characters
  name = tolower(sub("_.*","",basename(d)))
  name = gsub(" ","",name)
  last_name = gsub("[[:punct:]]","",strsplit(name,",")[[1]][1])
  first_name = gsub("[[:punct:]]","",strsplit(name,",")[[1]][2])
  # Get dates
  r = which(dates$Last.name == last_name & dates$First.name ==  first_name)
  t0 = parse_date_time(dates$t.0[r],dateparseorder,tz = "UTC")
  wk14 = parse_date_time(dates$X14.wks[r],dateparseorder,tz = "UTC")
  wk28 = parse_date_time(dates$X28.wks[r],dateparseorder,tz = "UTC")
  dd = parse_date_time(dates$Delivery.Date[r],dateparseorder,tz = "UTC")
  # List files
  files = list.files(d,full.names = T)
  # Loop through files, combine into 1
  l = lapply(files, function(f) {
    df = read.csv(f,na.strings = "",header = F)
    # Check file type by number of columns
    if (ncol(df) == 14) {
      colnames(df) = df[1,]
      df = df[-1,]
      df = df[,grep("timestamp|glucose value",tolower(colnames(df)))]
      colnames(df) = c("timestamp","sensorglucose")
      df$timestamp = sub("T"," ",df$timestamp)
      df$timestamp = parse_date_time(df$timestamp,dateparseorder,tz = "UTC")
    } else if (ncol(df) >= 48) {
      sensor = which(df$V3 == "Sensor")
      colnames(df) = df[sensor[1]+1,]
      df = df[(sensor[1]+2):nrow(df),]
      df$timestamp = parse_date_time(paste(df$Date,df$Time),dateparseorder,tz = "UTC")
      df = df[,grep("timestamp|sensor glucose",tolower(colnames(df)))]
      colnames(df)[1] = "sensorglucose"
    } else if (ncol(df) == 19) {
      colnames(df) = df[3,]
      df = df[4:nrow(df),]
      df = df[,grep("timestamp|historic glucose",tolower(colnames(df)))]
      colnames(df) = c("timestamp","sensorglucose")
      df$timestamp = parse_date_time(df$timestamp,dateparseorder,tz = "UTC")
    }
    return(df)
  })
  # Bind
  df = do.call(rbind,l)
  # remove duplicates
  df = df[!duplicated(df),]
  df = df[!is.na(df$timestamp),]
  # ID
  df$subjectid = NA
  id = paste0(last_name,", ",first_name)
  df = df[,c("subjectid","timestamp","sensorglucose")]
  # Sort by date
  df = df[order(df$timestamp),]
  # Split and write CSVs
  t0_wk14 = df[df$timestamp >= t0 & df$timestamp < wk14,]
  if (nrow(t0_wk14)>0 & sum(is.na(t0_wk14$sensorglucose))<nrow(t0_wk14)){
    t0_wk14$subjectid[1] = id
    write.csv(t0_wk14,file = paste0(outdir,last_name,"_",first_name,"_t0_wk14.csv"),
              row.names = F,na = "")
  }
  
  wk14_wk28 = df[df$timestamp >= wk14 & df$timestamp < wk28,]
  if (nrow(wk14_wk28)>0 & sum(is.na(wk14_wk28$sensorglucose))<nrow(wk14_wk28)) {
    wk14_wk28$subjectid[1] = id
    write.csv(wk14_wk28,file = paste0(outdir,last_name,"_",first_name,"_wk14_wk28.csv"),
              row.names = F,na = "")
  }
  
  wk28_dd = df[df$timestamp >= wk28 & df$timestamp < dd,]
  if(nrow(wk28_dd)>0 & sum(is.na(wk28_dd$sensorglucose))<nrow(wk28_dd)) {
    wk28_dd$subjectid[1] = id
    write.csv(wk28_dd,file = paste0(outdir,last_name,"_",first_name,"_wk28_dd.csv"),
              row.names = F,na = "")
  }
}
# Variables
cgmvariables("./Cleaned","./Reports",id_filename = T,
             outputname = paste("polsky_triple_c_cgm",Sys.Date()))
