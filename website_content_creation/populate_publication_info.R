### Pull publication info from Erik's Google Scholar to make pages ###

## Occassionally, there will be some strangeness from google scholar, so just check the pages. E.g. scrambled initials and order for one pub. Fixed it manually in Yaml.

library(rvest)
library(stringr)
library(scholar)

### Way that works ####

schol_id = "ghYLsSAAAAAJ"
Erik_pubs <- get_publications(id = schol_id)

Erik_pubs <- Erik_pubs[Erik_pubs$year >=2018,] ## group pubs only 2018 +


for(pub in 1:nrow(Erik_pubs)){
        curr_pub<- Erik_pubs[pub, ]
        pubs4scrape <-  paste0("http://scholar.google.com/citations?view_op=view_citation&hl=fr&user=",
                               schol_id, "&citation_for_view=", schol_id,":", curr_pub$pubid)
        
        pub_html <- read_html(pubs4scrape) 
        
        pubhtml <- pub_html %>%
                html_elements("a") %>%
                html_attr("href")
        
        pubhtml_linkto <- ifelse(!is.na(pubhtml[1]), pubhtml[1], "")
        pubhtml_linktopdf <- ifelse(!is.na(pubhtml[2]), pubhtml[2], "")
        pubhtml_linktofull <- ifelse(!is.na(pubhtml[3]), pubhtml[3], "")
        
        pubabstract <- pub_html %>% html_elements(".gsh_csp") %>% html_text()
        pubabstract <- gsub("\\?\\?", ". . . ", pubabstract)
        
        pubdet_extract <- pub_html %>% html_elements(".gsc_vcd_value") %>% html_text()
        
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
                          "\npublishDate: '", pubdate, "'", 
                          "\ntitle: '", curr_pub$title, "'",
                          "\nurl_pdf: ", '"', pubhtml_linktopdf, '"',  
                          "\nurl_source: ", '"',pubhtml_linktofull,'"',
                          "\n--- \n\n",
                          sep="")
        
        fold_name <- paste(gsub(", ", "_", curr_pub$author), curr_pub$year, sep="_")
        if(!dir.exists(paste("content/publication", fold_name, sep="/"))){dir.create(paste("content/publication", fold_name, sep="/"))}
        
        write(YMl_head, file(paste("content/publication", fold_name, "index.md", sep="/"), encoding = "UTF-8"))

        Sys.sleep(10 + sample(1:5, 1)) # so we don't get 429 Error
        }


