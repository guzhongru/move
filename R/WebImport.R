setOldClass("request")
setClass(Class = "MovebankLogin",
	 contains="request",
	 validity = function(object){
		 if(nchar(object$headers['user'])==0 || nchar(object$headers['password']==0))
			 return(TRUE)
	 }
	 )
## Browsing Movebank data base
setGeneric("movebankLogin", function(username, password,...) standardGeneric("movebankLogin"))
setMethod(f="movebankLogin", 
	  signature=c(username="character", password="character"), 
	  definition = function(username, password){
		  return(new("MovebankLogin", add_headers(user=username, password=password)))
	  })

setMethod(f="movebankLogin", 
	  signature=c(username="character", password="missing"),
	  definition = function(username, password){
		  pwd<-readline("password:")
		  return(movebankLogin(username=username, password=pwd))
	  })

setMethod(f="movebankLogin", 
	  signature=c(username="missing", password="missing"),
	  definition = function(username, password){
		  user<-readline("username:")
		  return(movebankLogin(username=user))
	  })


##construct URLs and download from Movebank
setGeneric("getMovebank", function(entity_type, login,...) standardGeneric("getMovebank"))
setMethod(f="getMovebank", 
	  signature=c(entity_type="character", login="MovebankLogin"), 
	  definition = function(entity_type, login, ...){
		  tmp <- list(...)
	  if("timestamp_start" %in% names(tmp)){
			  if(inherits(tmp[['timestamp_start']], "POSIXt")){
				  tmp[['timestamp_start']]<- sub('\\.','',strftime(format="%Y%m%d%H%M%OS3", tmp[['timestamp_start']] , tz="UTC"))
		  }
		  }
		  if("timestamp_end" %in% names(tmp)){
			  if(inherits(tmp[['timestamp_end']], "POSIXt")){
				  tmp[['timestamp_end']]<- sub('\\.','',strftime(format="%Y%m%d%H%M%OS3", tmp[['timestamp_end']] , tz="UTC"))
		  }
		  }
		  url <- paste("https://www.movebank.org/movebank/service/direct-read?entity_type=",entity_type  ,sep="")
		  if(length(tmp)!=0){
			  tmp <- lapply(tmp, paste, collapse='%2C')
			  url <- paste(url, sep="&",paste(names(tmp),tmp, collapse="&", sep="="))
		  }
		  f<-GET(url, config = login)
		  if(grepl("location_long", url)){cols<-c(location_long='numeric', location_lat='numeric')}else{cols<-NA}
		  cont<-content(f, as='text', encoding = "UTF-8")
		  if(grepl(pattern="The requested download may contain copyrighted material. You may only download it if you agree with the terms listed below. If study-specific terms have not been specified, read the \"General Movebank Terms of Use\".",
		        cont[1]))  stop("You need a permission to access this data set. Go to www.movebank.org and accept the license terms when downloading the data set (you only have to do this once per data set).")
		  data <- read.csv(textConnection(cont), colClasses=cols)
		  
		  if(any(grepl(pattern="You.may.only.download.it.if.you.agree.with.the.terms", x=colnames(data)))) stop("You need a permission to access this data set. Go to www.movebank.org and accept the license terms when downloading the data set (you only have to do this once per data set).")
		  if (any(grepl(pattern="X.html..head..title.Apache.Tomcat", colnames(data)))) stop("It looks like you are not allowed to download this data set, either by permission but maybe also an invalid password. Or there is a sensor for which no attributes are available.")
		  if (any(grepl(pattern="are.not.available.for.download", colnames(data)))) stop("You have no permission to download this data set.")
		  if (any(grepl(pattern="503 Service Temporarily Unavailable", unlist(head(data))))) stop("Movebank is (temporarily) unavailable")
		  if (any(grepl(pattern="No.data.are.available.for.download", colnames(data)))) stop("Api reports: No data are available for download")
		  return(data)
	  })

setMethod(f="getMovebank", 
	  signature=c(entity_type="character", login="missing"), 
	  definition = function(entity_type, login, ...){
		  d<-movebankLogin()
		  getMovebank(entity_type=entity_type, login=d,...)
	  })


#names of the studies
setGeneric("searchMovebankStudies", function(x,login) standardGeneric("searchMovebankStudies"))
setMethod(f="searchMovebankStudies", 
	  signature=c(x="character",login="MovebankLogin"), 
	  definition = function(x,login){  
		  data <- getMovebank("study", login, sort="name", attributes="id%2Cname%2Ci_am_owner%2Ci_can_see_data%2Cthere_are_data_which_i_cannot_see")
		  res <- as.character(data$name)[grepl(x,data$name,useBytes=TRUE)]
		  #    names(res) <- paste("##### Results for ",x,"#####")
		  if(length(res)>0){return(res)}else{"No study matches your search criteria"}
	  })

setMethod(f="searchMovebankStudies", 
	  signature=c(x="character",login="missing"), 
	  definition = function(x,login){  
		  login=movebankLogin()
		  searchMovebankStudies(x=x,login=login)
	  })



#get all study names
setGeneric("getMovebankStudies", function(login) standardGeneric("getMovebankStudies"))
setMethod(f="getMovebankStudies", 
	  signature=c(login="missing"), 
	  definition = function(login){
		  login <- movebankLogin()
		  getMovebankStudies(login=login)
	  })

setMethod(f="getMovebankStudies", 
	  signature=c(login="MovebankLogin"), 
	  definition = function(login){
		  data <- getMovebank("study", login, sort="name", attributes="id%2Cname%2Ci_am_owner%2Ci_can_see_data%2Cthere_are_data_which_i_cannot_see")
		  return(data$name)
	  })


#names of the sensors
setGeneric("getMovebankSensors", function(study, login) standardGeneric("getMovebankSensors"))
setMethod(f="getMovebankSensors", 
	  signature=c(study="ANY",login="missing"), 
	  definition = function(study,login){
		  login <- movebankLogin()
		  getMovebankSensors(study=study, login=login)
	  })
setMethod(f="getMovebankSensors", 
	  signature=c(study="missing",login="missing"), 
	  definition = function(study,login){
		  login <- movebankLogin()
		  getMovebankSensors(login=login)        
	  })

setMethod(f="getMovebankSensors", 
	  signature=c(study="missing",login="MovebankLogin"), 
	  definition = function(study,login){
		  data <- getMovebank("tag_type", login)
		  return(data)
	  })

setMethod(f="getMovebankSensors", 
	  signature=c(study="character",login="MovebankLogin"), 
	  definition = function(study,login){      
		  study <- getMovebankID(study, login)
		  callGeneric()
	  })
setMethod(f="getMovebankSensors", 
	  signature=c(study="numeric",login="MovebankLogin"), 
	  definition = function(study,login){      
		  data <- getMovebank("sensor", login, tag_study_id=study)
		  return(data)
	  })



setGeneric("getMovebankSensorsAttributes", function(study, login, ...) standardGeneric("getMovebankSensorsAttributes"))
setMethod(f="getMovebankSensorsAttributes", 
	  signature=c(study="character",login="MovebankLogin"), 
	  definition = function(study,login,...){
		  study<-getMovebankID(study, login,... )
		  callGeneric()
	  })
setMethod(f="getMovebankSensorsAttributes", 
	  signature=c(study="numeric",login="MovebankLogin"), 
	  definition = function(study,login,...){
		  data <- getMovebank("sensor", login, tag_study_id=study,...)
		  studySensors <- unique(data$sensor_type_id)
		  data2 <- lapply(studySensors, function(y, login, study) {try(getMovebank("study_attribute", login, study_id=study, sensor_type_id=y), silent=T)} ,login=login, study=study)
		  data2<-data2[(lapply(data2, class))!='try-error']
		  return(as.data.frame(do.call(rbind, data2)))
	  })

###all or a certain ID
setGeneric("getMovebankID", function(study, login) standardGeneric("getMovebankID"))
setMethod(f="getMovebankID", 
	  signature=c(study="character", login="missing"), 
	  definition = function(study, login){
		  login <- movebankLogin()
		  getMovebankID(study=study, login=login)
	  })

setMethod(f="getMovebankID", 
	  signature=c(study="character", login="MovebankLogin"), 
	  definition = function(study=NA, login){
		  data <- getMovebank("study", login, sort="name", attributes="id%2Cname%2Ci_am_owner%2Ci_can_see_data%2Cthere_are_data_which_i_cannot_see")
		  if (is.na(study)) {
			  return(data[ ,c("id","name")])
		  } else {
			  studyNUM <- data[gsub(" ","", data$name)==gsub(" ","", study),c("id")] #get rid of all spaces to avoid miss matching between different spaced words
			  if (length(studyNUM)>1) stop(paste("There was more than one study with the name:",study))
			  return(studyNUM)
		  }
	  })



###retrieving information of a certain study
setGeneric("getMovebankStudy", function(study, login) standardGeneric("getMovebankStudy"))
setMethod(f="getMovebankStudy", 
	  signature=c(study="numeric", login="MovebankLogin"),
	  definition = function(study, login){
		  data <- getMovebank("study", login, id=study)
		  return(data)
	  })
setMethod(f="getMovebankStudy", 
	  signature=c(study="character", login="MovebankLogin"),
	  definition = function(study, login){
		  study<- getMovebankID(study, login)
		  callGeneric()
	  })

setMethod(f="getMovebankStudy", 
	  signature=c(study="ANY", login="missing"),
	  definition = function(study, login){
		  login <- movebankLogin()
		  getMovebankStudy(study=study,login=login)
	  })


##get all animals with their IDs
setGeneric("getMovebankAnimals", function(study, login) standardGeneric("getMovebankAnimals"))
setMethod(f="getMovebankAnimals",
	  c(study="character", login="MovebankLogin"),
	  definition = function(study, login){  
		  study  <- getMovebankID(study,login)
		  callGeneric()
	  })
setMethod(f="getMovebankAnimals",
	  c(study="numeric", login="MovebankLogin"),
	  definition = function(study, login){  
		  tags <- getMovebank(entity_type="sensor", login, tag_study_id=study)
		  tagNames <- getMovebank(entity_type="tag", login, study_id=study)[,c("id", "local_identifier")]
		  colnames(tagNames) <- c("tag_id","tag_local_identifier")
		  tags <- merge.data.frame(x=tags, y=tagNames, by="tag_id")
		  animalID <- getMovebank("individual", login, study_id=study)
		  #animalID <- getMovebank("individual", login, study_id=study, attributes="id%2Clocal_identifier")
		  deploymentID <- getMovebank("deployment", login=login, study_id=study, attributes="individual_id%2Ctag_id%2Cid")
		  #  if (nrow(deploymentID)==0) warning("There are no deployment IDs available!")
		  names(deploymentID)  <- c("individual_id", "tag_id", "deployment_id") 
		  if (nrow(tags)!=0){ 
			  tagdep <- merge.data.frame(x=tags, y=deploymentID, by.x="tag_id", by.y="tag_id", all=TRUE) #skipping tags that have no deployment
			  tagdepid <- merge.data.frame(x=tagdep, y=animalID, by.x="individual_id", by.y="id", all.y=TRUE)[,-3]#skipping the column of the movebank internal tag id
			  tagdepid$animalName<-tagdepid$local_identifier
		#	  colnames(tagdepid) <- c("individual_id", "tag_id", "sensor_type_id", "deployment_id", "animalName")
			  if (any(duplicated(tagdepid$individual_id)|duplicated(tagdepid$tag_id))){
				  tagdepid$animalName <- paste(tagdepid$animalName, tagdepid$deployment_id, sep="_")
#				  names(tagdepid)  <- c("individual_id", "tag_id", "sensor_type_id", "deployment_id", "animalName_deployment")}
			  }
			  return(tagdepid) 
		  } else {
			  return(merge.data.frame(x=deploymentID, y=animalID, by.x="individual_id", by.y="id", all.y=TRUE))
		  }
	  })

setMethod(f="getMovebankAnimals",
	  c(study="ANY", login="missing"),
	  definition = function(study, login){
		  login <- movebankLogin()
		  getMovebankAnimals(study=study,login=login)
	  })

setGeneric("getMovebankData", function(study,animalName,login, ...) standardGeneric("getMovebankData"))

setMethod(f="getMovebankData", 
	  signature=c(study="ANY",animalName="ANY", login="missing"),
	  definition = function(study, animalName, login=login, ...){ 
		  login <- movebankLogin()
		  callGeneric()
	  })

setMethod(f="getMovebankData", 
	  signature=c(study="character",animalName="ANY", login="MovebankLogin"),
	  definition = function(study, animalName, login, ...){ 
		  study <- getMovebankID(study, login) 
		  callGeneric()
	  })

setMethod(f="getMovebankData", 
	  signature=c(study="numeric",animalName="missing", login="MovebankLogin"),
	  definition = function(study, animalName, login, ...){ 
		  d<- getMovebank("individual", login=login, study_id=study, attributes=c('id'))$id
		  getMovebankData(study=study, login=login, ..., animalName=d)
	  })
setMethod(f="getMovebankData", 
	  signature=c(study="numeric",animalName="character", login="MovebankLogin"),
	  definition = function(study, animalName, login, ...){ 
		  d<- getMovebank("individual", login=login, study_id=study, attributes=c('id','local_identifier'))
		  animalName<-d[as.character(d$local_identifier)%in%animalName,'id']
		  callGeneric()
	  })
setMethod(
  f = "getMovebankData",
  signature = c(
    study = "numeric",
    animalName = "numeric",
    login = "MovebankLogin"
  ),
  definition = function(study,
                        animalName,
                        login,
                        removeDuplicatedTimestamps = FALSE,
                        includeExtraSensors = FALSE,
                        deploymentAsIndividuals = FALSE,
                        ...) {
    # get id data
    idData <-
      getMovebank(
        "individual",
        login = login,
        study_id = study,
        id = animalName,
        ...
      )
    colnames(idData)[which(names(idData) == "id")] <-
      "individual_id"
    if (deploymentAsIndividuals) {
      dep <-
        getMovebank(
          "deployment",
          login = login,
          study_id = study,
          individual_id = animalName,
          ...
        )
      
      dep <-
        getMovebank(
          "deployment",
          login = login,
          study_id = study,
          individual_id = animalName,
          attributes = c("individual_id",
                         names(which(
                           !unlist(lapply(lapply(dep, is.na), all))
                         ))),
          ...
        )
      colnames(dep)[which(names(dep) == "id")] <- "deployment_id"
      colnames(dep)[which(names(dep) == "local_identifier")] <-
        "deployment_local_identifier"
      idData <- merge.data.frame(idData, dep, by = "individual_id")
    }
    # get sensor data
    sensorTypes <- getMovebank("tag_type", login = login)
    rownames(sensorTypes) <- sensorTypes$id
    locSen <-
      sensorTypes[as.logical(sensorTypes$is_location_sensor), "id"] #reduce track to location only sensors & only the correct animals
    # get all attributes used in study
    attribs <-
      unique(
        c(
          as.character(getMovebankSensorsAttributes(study, login, ...)$short_name),
          "sensor_type_id",
          "deployment_id",
          'event_id',
          'individual_id',
          'tag_id'
        )
      )
    # get all event data
    trackDF <-
      getMovebank(
        "event",
        login = login,
        study_id = study,
        attributes = attribs ,
        individual_id = animalName,
        sensor_type_id = locSen,
        ...
      )
    if (includeExtraSensors) {
      otherSen <-
        sensorTypes[!as.logical(sensorTypes$is_location_sensor), "id"]
      otherDF <-
        getMovebank(
          "event",
          login = login,
          study_id = study,
          attributes = attribs ,
          individual_id = animalName,
          sensor_type_id = otherSen,
          ...
        )
      trackDF <- rbind(trackDF, otherDF)
    }
    
    if (nrow(trackDF) == 0) {
      stop('No records found for this individual/study combination')
    }
    
    trackDF <-
      merge.data.frame(trackDF, sensorTypes[, c("id", "name")], by.x = "sensor_type_id", by.y =
                         "id")
    colnames(trackDF)[which(names(trackDF) == "name")] <-
      "sensor_type"

    
    trackDF$sensor_type <- droplevels(trackDF$sensor_type)
    trackDF <-
      merge.data.frame(trackDF, unique(idData[, c("individual_id", "local_identifier")]), by =
                         "individual_id")
    trackDF$individual_id <-
      NULL # this is in idData and not needed here

    if (deploymentAsIndividuals) {
      trackDF <-
        merge.data.frame(trackDF, idData[, c("deployment_id", "deployment_local_identifier")], by =
                           "deployment_id")
      trackDF$deployment_id <-
        NULL # this is in idData and not needed here
    }
    trackDF$timestamp <-
      as.POSIXct(strptime(
        as.character(trackDF$timestamp),
        format = "%Y-%m-%d %H:%M:%OS",
        tz = "UTC"
      ),
      tz = "UTC")
    if (!deploymentAsIndividuals) {
      if (any(tapply(trackDF$sensor_type_id, trackDF$local_identifier, length) !=
              1)) {
        # data comes in ordered by sensor but needs to be ordered by timestamp
        trackDF <-
          trackDF[with(trackDF, order(trackDF$local_identifier, timestamp)) ,]
      }
      trackDF$local_identifier <- as.factor(trackDF$local_identifier)
      levels(trackDF$local_identifier) <-
        validNames(levels((trackDF$local_identifier))) #changing names to 'goodNames' skipping spaces
      rownames(idData) <- validNames(idData$local_identifier)
    } else{
      if (any(
        tapply(
          trackDF$sensor_type_id,
          trackDF$deployment_local_identifier,
          length
        ) != 1
      )) {
        # data comes in ordered by sensor but needs to be ordered by timestamp
        trackDF <-
          trackDF[with(trackDF,
                       order(trackDF$deployment_local_identifier, timestamp)) ,]
      }
      trackDF$deployment_local_identifier <-
        as.factor(trackDF$deployment_local_identifier)
      levels(trackDF$deployment_local_identifier) <-
        validNames(levels((
          trackDF$deployment_local_identifier
        ))) #changing names to 'goodNames' skipping spaces
      rownames(idData) <-
        validNames(idData$deployment_local_identifier)
    }
    
    outliers <- is.na(trackDF$location_long)
    if ('algorithm_marked_outlier' %in% names(trackDF))
      outliers[trackDF$algorithm_marked_outlier == "true"] <- T
    if ('manually_marked_outlier' %in% names(trackDF)) {
      outliers[trackDF$manually_marked_outlier == "true"] <- T
      outliers[trackDF$manually_marked_outlier == "false"] <- F
    }
    if (all(outliers))
      stop("There not observed records for this study/individual")
    
    spdf <-
      SpatialPointsDataFrame(
        trackDF[!outliers, c('location_long', 'location_lat')],
        data = trackDF[!outliers, ],
        proj4string = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"),
        match.ID = T
      )
    
    if (!deploymentAsIndividuals) {
      idCol <- "local_identifier"
    } else{
      idCol <- "deployment_local_identifier"
    }
    id <-
      paste(format(trackDF$timestamp, "%Y %m %d %H %M %OS4"),
            trackDF[[idCol]],
            trackDF$sensor_type_id)
    trackId <- droplevels(spdf[[idCol]])
    spdf[[idCol]] <- NULL
    if (anyDuplicated(id)) {
      if (any(s <- id[outliers] %in% id[!outliers]))
      {
        warning(
          "There are timestamps ",
          sum(s),
          " in the unused data that are also in the real data, those records are omitted"
        )
        outliers[outliers][s] <- F
      }
      if (any(s <- duplicated(id[outliers])))
      {
        warning(
          "There are ",
          sum(s),
          " duplicated timestamps in the unused that those will be removed"
        )
        outliers[outliers][s] <- F
      }
    }
    
    unUsed <-
      new(
        '.unUsedRecordsStack',
        dataUnUsedRecords = trackDF[outliers, ],
        timestampsUnUsedRecords = trackDF$timestamp[outliers],
        sensorUnUsedRecords = trackDF[outliers, 'sensor_type'],
        trackIdUnUsedRecords = trackDF[outliers, idCol]
      )
    
    if (any(!(s <-
              (
                as.character(unUsed@trackIdUnUsedRecords) %in% levels(trackId)
              ))))
    {
      warning('Omiting individual(s) (n=',
              length(unique(unUsed@trackIdUnUsedRecords[!s])),
              ') that have only unUsedRecords')
      unUsed <- unUsed[s, ]
    }
    unUsed@trackIdUnUsedRecords <-
      factor(unUsed@trackIdUnUsedRecords, levels = levels(trackId))
    if (removeDuplicatedTimestamps) {
      message(
        "removeDupilcatedTimestamps was set to true we strongly suggest against it and that the problem is solved before because there is no systematic to which locations are removed. This can for example be done by marking them outlier in movebank."
      )
      dupsDf <-
        (data.frame(
          format(spdf$timestamp, "%Y %m %d %H %M %OS4"),
          spdf$sensor_type_id,
          trackId
        ))
      dups <- duplicated(dupsDf)
      spdf <- spdf[!dups, ]
      trackId <- trackId[!dups]
      warning(sum(dups),
              " location(s) is/are removed by removeDuplicatedTimestamps")
    }
    s <- getMovebankStudy(study, login)
    res <- new(
      "MoveStack",
      spdf,
      timestamps = spdf$timestamp,
      sensor = spdf$sensor_type,
      unUsed,
      trackId = trackId,
      idData = idData[as.character(unique(trackId)), ],
      study = ifelse(is.na(s$name), character(), as.character(s$name)),
      citation = ifelse(is.na(s$citation), character(), as.character(s$citation)),
      license = ifelse(
        is.na(s$license_terms),
        character(),
        as.character(s$license_terms)
      )
    )
    if (length(n.locs(res)) == 1)
      res <- as(res, 'Move')
    return(res)
  }
)



setGeneric("getMovebankNonLocationData", function(study,sensorID,animalName,login, ...) standardGeneric("getMovebankNonLocationData"))
setMethod(f="getMovebankNonLocationData", 
          signature=c(study="ANY",sensorID="ANY",animalName="ANY", login="missing"),
          definition = function(study, sensorID, animalName, login=login, ...){ 
            login <- movebankLogin()
            callGeneric()
          })

setMethod(f="getMovebankNonLocationData", 
          signature=c(study="character", sensorID="ANY",animalName="ANY",login="MovebankLogin"),
          definition = function(study, sensorID, animalName, login, ...){ 
            study <- getMovebankID(study, login) 
            callGeneric()
          })

setMethod(f="getMovebankNonLocationData", 
          signature=c(study="numeric", sensorID="missing",animalName="ANY",login="MovebankLogin"),
          definition = function(study, sensorID, animalName, login, ...){ 
            allsens <- getMovebank("tag_type", login=login)[(c("id","is_location_sensor"))]
            allNL <- allsens$id[allsens$is_location_sensor=="false"]
            sensStudy <- unique(getMovebankSensors(study=study, login=login)$sensor_type_id)
            sensorID <- sensStudy[sensStudy%in%allNL]
            if(missing(animalName)){
              getMovebankNonLocationData(study=study, sensorID=sensorID, login=login, ...)
            }else{
              getMovebankNonLocationData(study=study, sensorID=sensorID, login=login, animalName=animalName, ...)}
          })

setMethod(f="getMovebankNonLocationData", 
          signature=c(study="numeric", sensorID="character",animalName="ANY",login="MovebankLogin"),
          definition = function(study, sensorID, animalName, login, ...){ 
            ss <- getMovebank("tag_type", login=login)[c("name","id")]
            sensorID<-ss[as.character(ss$name)%in%sensorID,'id']
            callGeneric()
          })


setMethod(f="getMovebankNonLocationData", 
          signature=c(study="numeric",sensorID="numeric",animalName="missing", login="MovebankLogin"),
          definition = function(study, sensorID, animalName, login, ...){ 
            d<- getMovebank("individual", login=login, study_id=study, attributes=c('id'))$id
            getMovebankNonLocationData(study=study, sensorID=sensorID, login=login, ..., animalName=d)
          })

setMethod(f="getMovebankNonLocationData", 
          signature=c(study="numeric",sensorID="numeric",animalName="character",login="MovebankLogin"),
          definition = function(study, sensorID, animalName, login, ...){ 
            d<- getMovebank("individual", login=login, study_id=study, attributes=c('id','local_identifier'))
            animalName<-d[as.character(d$local_identifier)%in%animalName,'id']
            callGeneric()
          })

setMethod(f="getMovebankNonLocationData", 
          signature=c(study="numeric",sensorID="numeric", animalName="numeric", login="MovebankLogin"),
          definition = function(study, sensorID, animalName, login,...){ 
            idData <- getMovebank("individual", login=login, study_id=study, id=animalName,...)         
            colnames(idData)[which(names(idData) == "id")] <- "individual_id"
            
            if(length(study)>1){stop("Download only possible for a single study")}
            
            sensorTypes <- getMovebank("tag_type", login=login)
            if(length(sensorID)==0 | length(sensorID[!sensorID%in%sensorTypes$id])>0){stop("Sensor name(s) not valid. See 'getMovebankSensors(login)' for valid sensor names")}
            
            if(any(as.logical(sensorTypes$is_location_sensor[sensorTypes$id%in%sensorID]))){
              stop("The selected sensor(s): '",paste0(sensorTypes$name[sensorTypes$id%in%sensorID & sensorTypes$is_location_sensor=="true"],collapse = ", "),"' is a/are location sensor(s). Only non location data can be downloaded with this function. Use 'getMovebankData' to download location data.")}
            
            sensorAnim <- getMovebankAnimals(study, login)[c("individual_id","sensor_type_id")]
            if(length(sensorID[!sensorID%in%unique(sensorAnim$sensor_type_id)])>0){
              NoSens <- as.character(sensorTypes$name[sensorTypes$id%in%sensorID[!sensorID%in%unique(sensorAnim$sensor_type_id)]])
              stop("Sensor(s): '",paste0(NoSens,collapse = ", "), "' is/are not available for this study" )}
            
            NoDat <- idData$local_identifier[!unlist(lapply(1:nrow(idData),function(x){is.element(sensorID,sensorAnim$sensor_type_id[sensorAnim$individual_id==idData$individual_id[x]])}))]
            if(length(NoDat)>0){
              animalName <- animalName[!animalName%in%idData$individual_id[as.character(idData$local_identifier)%in%as.character(NoDat)]]
              warning("Individual(s): '",paste0(as.character(NoDat),collapse = ", "),"' do(es) not have data for the one or more of the selected sensor(s). Data for this/these individual(s) are not downloaded.")}
            
            attribs <- unique(c(as.character(getMovebankSensorsAttributes(study, login,...)$short_name[getMovebankSensorsAttributes(study, login,...)$sensor_type_id%in%sensorID]),'sensor_type_id', 'deployment_id', 'event_id', 'individual_id', 'tag_id'))
            NonLocData <- getMovebank("event", login=login, study_id=study, sensor_type_id=sensorID, individual_id=animalName, attributes=attribs,...) 
            tagID <- getMovebank("tag", login, study_id=study)[,c("id", "local_identifier")]
            colnames(tagID) <- c("tag_id","tag_local_identifier")
            NonLocData <- merge.data.frame(NonLocData,tagID,by="tag_id")
            NonLocData <- merge.data.frame(NonLocData,idData[,c("individual_id","local_identifier")],by="individual_id")
            return(NonLocData)
          })


