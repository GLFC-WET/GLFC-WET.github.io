### Pull publication info from Erik's Google Scholar to make pages ###

## Occassionally, there will be some strangeness from google scholar, so just check the pages. E.g. scrambled initials and order for one pub. Fixed it manually in Yaml.
library(tidyverse)
library(rvest)
library(stringr)
library(scholar)

### Way that works ####

schol_id = "ghYLsSAAAAAJ"
Erik_pubs <- get_publications(id = schol_id)

#Emily_pubs <- get_publications(id = "ZRWn6UwAAAAJ")

Erik_pubs <- Erik_pubs[Erik_pubs$year >=2021,] %>% 
        mutate(schol_id = schol_id) #%>% 
        #rbind(Emily_pubs[Emily_pubs$year >= 2025,] %>% 
                     # mutate(schol_id = "ZRWn6UwAAAAJ")) ## group pubs only 2021 + ## Update for new pubs

#rm(Emily_pubs)
## Apply additional custom filtering to just most recent
## Find the titles that are already in the dataset and filter out
db.pubs <- list.files("content/publication", pattern = "index.md", full.names = T, recursive = T)

db.pubs <- db.pubs[!grepl("_index", db.pubs)]

db.pub.titles <- sapply(db.pubs, function(x){
        temp <- readLines(x)
        title <- grep("title:", temp, value = T)
        title <- gsub("'|title: ", "", title)
        return(title)
        }) %>% unlist()

Erik_pubs <- Erik_pubs[!Erik_pubs$title %in% db.pub.titles, ]
rm(db.pub.titles)

## Also find the scholar tags that are in db already and filter out
db.pubs <- list.dirs("content/publication")

gIDs.notin <- Erik_pubs$pubid[!Erik_pubs$pubid %in% unique(str_extract(db.pubs, str_c(Erik_pubs$pubid, collapse = "|")))]

Erik_pubs <- Erik_pubs[Erik_pubs$pubid %in% gIDs.notin, ]


for(pub in 1:nrow(Erik_pubs)){
        curr_pub<- Erik_pubs[pub, ]
        pubs4scrape <-  paste0("http://scholar.google.com/citations?view_op=view_citation&hl=fr&user=",
                               curr_pub$schol_id, "&citation_for_view=", curr_pub$schol_id,":", curr_pub$pubid)
        
        pub_html <- read_html(pubs4scrape) 
        
        pubhtml <- pub_html %>%
                html_elements("a") %>%
                html_attr("href")
        
        pubhtml_linkto <- pubs4scrape
        pubhtml_linktopdf <- pub_html %>% html_elements(".gsc_oci_title_ggi") %>%
                html_elements("a") %>% 
                html_attr("href")
        pubhtml_linktofull <- pub_html %>% html_elements(".gsc_oci_title_link") %>% html_attr("href")
        
        pubabstract <- pub_html %>% html_elements(".gsh_csp") %>% html_text()
        pubabstract <- gsub("\\?\\?", ". . . ", pubabstract)
        
        pubdet_extract <- pub_html %>% html_elements(".gsc_oci_value") %>% html_text()
        
        pubauths <- pubdet_extract[1]
        
        pubauths <- str_split(pubauths, ", ")[[1]]
        
        pubauths <- gsub("Szkokan-", "", pubauths) #Replace any known name changes
        
        ## compare listed authors to team names
        auth_profiles <- list.dirs("content/authors", recursive = FALSE, full.names = FALSE)
        
        pub_auths_repl<- sapply(pubauths, function(x){
                authsrch <- paste(str_extract(x, "^."), 
                                  gsub(".* ", "", str_extract(x, " .+$")), 
                                  sep="_")
                if(sum(authsrch == auth_profiles) > 0){auth_profiles[authsrch == auth_profiles]
                        }else{x}
                
                                                   })
        
        pubauths <- str_c(paste("\n- ", pub_auths_repl), collapse ="")
        
        pubdate <- pubdet_extract[2]
        pubdate <- str_split(pubdate, "\\/")[[1]]
        if(length(pubdate)==2){
                pubdate <- c(pubdate, 01)
        }
        if(length(pubdate)==1){
                pubdate <- c(pubdate, 12, 01) #If google does not have the full date just apply as if it was published last month of year
        }
        pubdate <- as.Date(str_c(pubdate, collapse = "-"))
        pubdate <- paste(pubdate, "T00:00:00Z", sep="")
        
        curr_date <- paste(Sys.Date(), "T00:00:00Z", sep="")
        ## write out to the page headers##
        
        YMl_head <- paste("--- ",
                          "\nabstract: ",'"', pubabstract, '"', 
                          "\nauthors: ", pubauths, 
                          "\nfeatured: false", 
                          "\nprojects: []",
                          "\npublication: ", paste("'*", curr_pub$journal, "*'", sep=""),
                          "\npublication_short: ''",
                          '\npublication_types:\n- "2"', 
                          "\ndate: '", pubdate, "'",
                          "\npublishDate: '", Sys.Date(), "'",
                          "\ntitle: '", curr_pub$title, "'",
                          "\nurl_pdf: ", '"', ifelse(grepl("pdf", pubhtml_linktopdf), 
                                                     grep("pdf", pubhtml_linktopdf, value = T),
                                                     pubhtml_linktopdf[1]), '"',  
                          "\nurl_source: ", '"',pubhtml_linktofull,'"',
                          "\n--- \n\n",
                          sep="")
        
        fold_name <- paste(gsub(" ", "-", str_extract(curr_pub$author, "[[:alpha:] ]+")), curr_pub$year, curr_pub$pubid, sep="_")
        if(!dir.exists(paste("content/publication", fold_name, sep="/"))){dir.create(paste("content/publication", fold_name, sep="/"))}
        
        write(YMl_head, file(paste("content/publication", fold_name, "index.md", sep="/"), encoding = "UTF-8"))

        Sys.sleep(10 + sample(1:25, 1)) # so we don't get 429 Error
        }


