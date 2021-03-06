summary.meltt = function(object, ...){

  # Summary of Input-Output
  orig_N = nrow(object$processed$complete_index)
  unique_N = nrow(object$processed$deduplicated_index)
  overlap_N = orig_N - unique_N
  match_N_event_to_event = nrow(object$processed$event_matched)
  match_N_episode_to_episode = nrow(object$processed$episode_matched)
  match_N = match_N_event_to_event + match_N_episode_to_episode
  flagged_episodes_to_events = sum(object$processed$deduplicated_index$episodal_match != "")
  data_names = object$inputDataNames
  swindow = object$parameters$spatwindow
  twindow = object$parameters$twindow
  N_data_entries = length(data_names)
  N_taxonomies = object$taxonomy$N_taxonomies
  taxonomy_names = object$taxonomy$taxonomy_names
  taxonomy_depths = object$taxonomy$taxonomy_depths
  rep2 = function(txt,n) paste0(rep(txt,n),collapse="")
  summary_message = paste0("\nMELTT output\n",
                           paste(rep("===",20),collapse=""),"\n",
                           "No. of Input Datasets: ", N_data_entries,"\n",
                           "Data Object Names: ", paste(data_names,collapse=", "),"\n",
                           "Spatial Window: ", swindow,"km\n",
                           "Temporal Window: ", twindow," Day(s)\n\n",
                           "No. of Taxonomies: ",N_taxonomies,"\n",
                           "Taxonomy Names: ",paste(taxonomy_names,collapse=", "),"\n",
                           "Taxonomy Depths: ",paste(taxonomy_depths,collapse=", "),"\n\n",
                           "Total No. of Input Observations:",rep2(" ",18),orig_N,"\n",
                           "No. of Unique Matches:",rep2(" ",28),match_N,"\n",
                           "  - No. of Event-to-Event Matches:",rep2(" ",16),match_N_event_to_event,"\n",
                           "  - No. of Episode-to-Episode Matches:",rep2(" ",12),match_N_episode_to_episode,"\n",
                           "No. of Duplicates Removed:",rep2(" ",24),overlap_N,"\n",
                           "No. of Unique Obs (after deduplication):",rep2(" ",10),unique_N,"\n",
                           paste(rep("---",20),collapse=""),"\n",
                           "Summary of Overlap\n")

  # Generate summary of overlap table
  # Unique Events (removing entries where duplicates are present)
  Uevent_set = object$processed$deduplicated_index[,c(1,2)]
  Uevent_key = paste(Uevent_set[,1],Uevent_set[,2],sep="-")
  Uevent_set$ID = Uevent_key

  # Duplicate Events
  Mevent_key = rbind(object$processed$event_matched,object$processed$episode_matched)
  Mevent_key3 = c()
  for(p in 1:(length(Mevent_key)/2)){
    Mevent_key2 = paste(Mevent_key[,grep("data",colnames(Mevent_key))[p]],
                        Mevent_key[,grep("event",colnames(Mevent_key))[p]],sep="-")
    Mevent_key3 = c(Mevent_key3,Mevent_key2[Mevent_key2!="0-0"])
  }

  # Summary of Unique
  uni = as.data.frame(table(Uevent_set[!(Uevent_set$ID %in% Mevent_key3),][1]))
  uni$Var1 = object$inputDataNames[uni$Var1]
  val = as.data.frame(matrix(t(uni$Var1),nrow=length(uni$Var1),ncol=length(uni$Var1)),stringsAsFactors = F)
  if( nrow(val) == 0 ){ # If all elements match, create placeholder
    unique_obs = matrix(0,ncol=length(object$inputDataNames) + 1)
    colnames(unique_obs) = c(object$inputDataNames,"Freq")
  }else{
    colnames(val) = object$inputDataNames
    for(c in seq_along(val)){val[val[,c] != colnames(val)[c],c] = "";val[val[,c] == colnames(val)[c],c] = "X"}
    unique_obs = cbind(val,Freq=uni$Freq)
  }


  # Summary of Overlap
  matched = rbind(object$processed$event_matched,object$processed$episode_matched)
  matched[is.na(matched)] = 0
  matched2 = matched[,1:ncol(matched) %% 2 != 0]
  Lets = letters[1:ncol(matched2)]
  for(l in seq_along(Lets)){
    matched2[,l][matched2[,l] == l] = Lets[l]
    matched2[,l][matched2[,l] == 0] = ""
  }
  matched2$ID = apply(matched2,1,function(x) paste(x,collapse=""))
  matched3 = merge(unique(matched2),as.data.frame(table(matched2$ID)),by.x = "ID",by.y="Var1")
  matched3 = matched3[order(matched3$ID),-1]
  colnames(matched3)[colnames(matched3) != "Freq"] = object$inputDataNames
  matched3[matched3 != "" & matched3!=matched3$Freq] = "X"
  ord = data.frame(pos= 1:nrow(matched3),ord=rowSums(matched3[,colnames(matched3)!="Freq"]=="X"))
  matched3 = matched3[ord[order(ord$ord),"pos"],] # order arrangement

  # collate
  out_summary = rbind(unique_obs,matched3)
  row.names(out_summary) <- NULL

  # return
  cat(summary_message)
  print(out_summary,row.names = F)
  cat(paste0(paste(rep("===",20),collapse=""),"\n"))
  if(flagged_episodes_to_events>0){
    cat(paste0("*Note: ",flagged_episodes_to_events," episode(s) flagged as potentially matching to an event.\nReview flagged match with meltt.inspect()"))
  }
  invisible(out_summary)
}
