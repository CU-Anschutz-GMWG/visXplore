#' @import shiny
#' @import dplyr
#' @import ggplot2
#' @importFrom janitor clean_names
#' @importFrom fastDummies dummy_cols
#' @importFrom kableExtra kable
#' @importFrom kableExtra kable_styling
#' @importFrom kableExtra pack_rows
#' @importFrom kableExtra add_header_above
#' @importFrom kableExtra scroll_box
#' @importFrom car vif
#' @import knitr
#' @import readr
#' @import stringr
#' @import tibble
#' @importFrom tidyr pivot_longer
#' @importFrom utils write.csv

server_VisX <- function(data) {
  server <- function(input, output, session){

    # upload data
    bl_df <- reactive(data)

    # list of all reactive datasets
    df_lst <- reactiveValues(df_all=data, var_type=sapply(data, class),
                             df_new_num=NULL, new_type_num=NULL,
                             df_new_cat=NULL, new_type_cat=NULL)

    # data tab
    output$data <- DT::renderDT({bl_df() %>% clean_names(case = "none")},
                                   options = list(pageLength=10,
                                                  scrollX = T))
    output$datacheck <- renderText({data_check(bl_df())})


    ## transformations: univariate
    observeEvent(input$newtrans,
                 {new_vars <- df_lst$df_all %>%
                   mutate(across(all_of(input$vars_dist),
                                 .fns = as.formula(paste("~",input$typetrans, "(.x)")),
                                 .names = paste("{col}_", input$typetrans, sep = '')),
                          .keep = "none")
                 df_lst$df_new_num <- bind_cols(df_lst$df_new_num, new_vars)
                 df_lst$new_type_num <- c(df_lst$new_type_num, rep("numeric", ncol(new_vars)))
                 df_lst$df_all <- bind_cols(df_lst$df_all, new_vars)
                 df_lst$var_type <- c(df_lst$var_type, rep("numeric", ncol(new_vars)))
                 })
    ## transformation: multivariate
    observeEvent(input$newop,
                 {if(input$typeop == "Mean"){
                   new_vars = apply(df_lst$df_all[, input$vars_dist], 1, mean)
                   new_vars = data.frame(new_vars)
                 }
                   if(input$typeop == "Ratio (alphabetical)"){
                     new_vars = df_lst$df_all[input$vars_dist[1]]/df_lst$df_all[input$vars_dist[2]]
                   }
                   if(input$typeop == "Ratio (reverse alphabetical)"){
                     new_vars = df_lst$df_all[input$vars_dist[2]]/df_lst$df_all[input$vars_dist[1]]
                   }
                   colnames(new_vars) <- input$newvarname
                   df_lst$df_new_num <- bind_cols(df_lst$df_new_num, new_vars)
                   df_lst$new_type_num <- c(df_lst$new_type_num, "numeric")
                   df_lst$df_all <- bind_cols(df_lst$df_all, new_vars)
                   df_lst$var_type <- c(df_lst$var_type, "numeric")

                 })

    output$num_vars <- renderPlot({
      df_plot <- df_lst$df_all[, df_lst$var_type=="numeric"]

      if(nrow(df_plot)>0){
        df_plot <- mutate_all(df_plot, as.numeric)
        make_hist(df_plot)
      }
      else{
        ggplot()+theme_void()+labs(title = "No numeric variables")+
          theme(title = element_text(size = 20))
      }
    },  height = 600, width = 1000)

    # categorical variable tab
    output$vars_bin <- renderUI({
      selectInput("vars_bin", "Variable to collapse",
                  choices = colnames(df_lst$df_all)[df_lst$var_type!="numeric"])
    })
    output$levels <- renderUI({
      checkboxGroupInput("lev", "Levels to collapse",
                         choices = levels(as.factor(df_lst$df_all[, input$vars_bin])))
    })

    observeEvent(input$cattrans,{
      new_var <- ifelse(df_lst$df_all[ , input$vars_bin] %in% input$lev,
                        input$newcat, df_lst$df_all[ , input$vars_bin])
      new_var <- data.frame(new_var)
      colnames(new_var) <- paste(input$vars_bin, "_bin", sep = "")
      df_lst$df_new_cat <- bind_cols(df_lst$df_new_cat, new_var)
      df_lst$new_type_cat <- c(df_lst$new_type_cat, input$binned_type)
      df_lst$df_all <- bind_cols(df_lst$df_all, new_var)
      df_lst$var_type <- c(df_lst$var_type, input$binned_type)
    })

    ## disaplay original variables
    output$cat_vars <- renderPlot({
      if(any(df_lst$var_type != "numeric")){
        df_plot <- df_lst$df_all[, df_lst$var_type!="numeric",drop = FALSE]
        df_plot <- mutate_all(df_plot, as.character)
        make_bar(df_plot)
      }
      else{
        ggplot()+theme_void()+labs(title = "No nominal variables")+
          theme(title = element_text(size = 20))
      }

    }, height = 600, width = 1000)

    # correlation diagram panel
    output$vars_cor <- renderUI({
      checkboxGroupInput("vars_cor", "Variables to visualise",
                         choices =  colnames(df_lst$df_all))
    })

    # network plot
    output$npc <- renderPlot({
      cor_mats <- pairwise_cor(df_lst$df_all, df_lst$var_type)

      npc_mixed_cor(cor_mats, show_signif=input$signif!="none",
                    sig.level = input$signif,
                    min_cor = input$min_cor)
    }, height = 800, width = 800)

    output$cormat <-  renderText({
      cor_mats <- pairwise_cor(df_lst$df_all, df_lst$var_type)


      # association matrix for display
      format_cor <- corstars(cor_mats$cor_value, cor_mats$cor_p, df_lst$var_type)
      cor_mat_star <- format_cor$Rnew
      cor_mat_star <- rownames_to_column(cor_mat_star, var = " ")
      row_id <- factor(format_cor$row_id,
                       levels = c("numeric", "factor", "ordinal"),
                       labels = c("numeric", "nominal", "ordinal"))
      row_id <- droplevels(row_id)
      col_id <- as.character(format_cor$col_id)
      col_id <- c(" ", as.character(col_id))
      col_id <- factor(col_id,
                       levels = c(" ", "numeric", "factor", "ordinal"),
                       labels = c(" ", "numeric", "nominal", "ordinal"))
      col_id <- droplevels(col_id)

      cor_mat_star %>%
        t() %>%
        kable(escape = F) %>%
        kable_styling("condensed", full_width = F) %>%
        pack_rows(index = table(row_id)) %>%
        add_header_above(table(col_id)) %>%
        scroll_box(width = "100%", height = "1000px")
    })


    output$stat <- renderText({
      # inter-correlation statistics
      df_vif <- mutate(df_lst$df_all, y=rnorm(nrow(df_lst$df_all)))
      df_vif <- mutate_at(df_vif, which(df_lst$var_type!="numeric"), as.factor)
      vifs <- round(vif(lm(y ~ ., data = df_vif)), 2)
      r2 <- get_r2(df_lst$df_all, df_lst$var_type)
      r2 <- round(r2, 2)
      var_labs <- factor(df_lst$var_type, levels = c("numeric", "factor", "ordinal"),
                         labels = c("numeric", "nominal", "ordinal"))
      var_labs <- droplevels(var_labs)

      tb <- data.frame(vifs, r2)
      colnames(tb)<- c("GVIF", "DF", "Adjusted GVIF", "R-squared")
      tb[order(var_labs), ] %>%
        kable(escape = F) %>%
        kable_styling(full_width = F) %>%
        pack_rows(index = table(var_labs)) %>%
        scroll_box(width = "100%", height = "1000px")
    })

    # session info
    output$rinfo <- renderPrint({sessionInfo()})

  }
}



