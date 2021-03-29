## Create profiles from submissions ## 
library(readxl)
library(stringr)

## get all directories in first level
directories <- list.dirs("website_content_creation/authors", recursive = F)

## Iterate through directories
for(cur_dir in directories){
        filesin <- list.files(cur_dir, full.names = TRUE)
        pic <- filesin[grepl(".jpg|.png|.jpeg", filesin)]
        
        if(length(pic) ==0){
                pic <- "static/media/meeple.jpg"
        }
        
        info <- read_excel(filesin[grepl(".xlsx", filesin)])
        colnames(info) <- c("index", "data1", "data2")
        info <- info[!is.na(info$index), ]
        
        #### Get basic info into named vector ####
        basicinf <- info$data1[2:(grep("Add new rows to the tables below, as required.", info$index)-1)]
        names(basicinf) <- info$index[2:(grep("Add new rows to the tables below, as required.", info$index)-1)]
        
        #### Get Educational info into table ####
        Educational_inf <- info[(grep("Educational Background", info$index)+2):(grep("Organizations", info$index)-1),]
        educ_yaml <- paste("education:\n  courses:")
        for(ed in 1:nrow(Educational_inf)){
                educ_yaml <- paste(educ_yaml, "\n  - course: ", 
                      Educational_inf$index[ed], 
                      "\n    institution: ",
                      Educational_inf$data1[ed], 
                      "\n    year: ",
                      Educational_inf$data2[ed],
                      sep="")
        }
        
        #### Get interests ####
        Interests_inf <- info[(grep("Interests", info$index)+1):nrow(info),]
        interests_yaml <- paste("interests:")
        for(ed in 1:nrow(Interests_inf)){
                interests_yaml <- paste(interests_yaml, "\n- ", 
                                   Interests_inf$index[ed], sep="")
        }
        
        #### Get organization ####
        org_inf <- info[(grep("Organizations", info$index)+2):(grep("Interests", info$index)-1),]
        org_yaml <- paste("organizations:")
        for(ed in 1:nrow(org_inf)){
                org_yaml <- paste(org_yaml, "\n- name: ", 
                                        org_inf$index[ed],
                                  "\n  url: ", org_inf$data1[ed], sep="")
        }
        
        #### Create social section ####
        social_yaml <- paste("social:")
        if(!is.na(basicinf["e-mail"])){social_yaml <- paste(social_yaml, "\n- icon: envelope\n  icon_pack: fas\n  link: ", 
                                                            basicinf["e-mail"], sep="")}else{
                                                                    paste(social_yaml, "\n- icon: envelope\n  icon_pack: fas\n  link: /#contact", sep="") 
                                                            }
        if(!is.na(basicinf["Twitter"])){social_yaml <- paste(social_yaml, "\n- icon: twitter\n  icon_pack: fab\n  link: ", 
                                                             basicinf["Twitter"], sep="") }
        
        if(!is.na(basicinf["github"])){social_yaml <- paste(social_yaml, "\n- icon: github\n  icon_pack: fab\n  link: ", 
                                                             basicinf["github"], sep="") }    
        if(!is.na(basicinf["LinkedIN"])){social_yaml <- paste(social_yaml, "\n- icon: linkedin\n  icon_pack: fab\n  link: ", 
                                                            basicinf["LinkedIN"], sep="") } 
 
        auth_code <- str_c(str_extract(str_split(trimws(basicinf['name']), " ")[[1]][1], "^."), str_split(trimws(basicinf['name']), " ")[[1]][length(str_split(trimws(basicinf['name']), " ")[[1]])], sep="_")
        
        usergroups <- ifelse("Groups" %in% names(basicinf), paste("[",basicinf['Groups'], "]", sep=""), "[NEEDS UPDATING]")
        
        Supervisor_statement <- ifelse
        
        ## Compile Yaml header

        YHead <- paste("--- \nbio: ", basicinf["Bio"], 
               "\n", educ_yaml, 
               "\nemail: \"", basicinf["e-mail"], "\"", 
               "\n", interests_yaml, 
               "\nhighlight_name: false",
               "\n", org_yaml, 
               "\nrole: ", basicinf["role"], 
               "\n", social_yaml,
               "\nsuperuser: false", 
               "\ntitle: ", basicinf["name"],
               "\nuser_groups: ", usergroups,
               "\nauthors:\n- ", auth_code,
               "\n---\n\n",
               paste(ifelse(!is.na(basicinf["Bio"]), basicinf["Bio"], ""), ifelse(!is.na(basicinf["Detail_Blurb"]), basicinf["Detail_Blurb"], ""), sep="\n"),
               sep="")
        

        if(!dir.exists(paste("content/authors", auth_code, sep="/"))){dir.create(paste("content/authors", auth_code, sep="/"))}
        
        write(YHead, paste("content/authors", auth_code, "_index.md", sep="/"))
        file.copy(pic, paste("content/authors", auth_code, "avatar.jpg", sep="/"))
           
}