#' @import shiny
#' @import dplyr
#' @import ggplot2
#' @importFrom DT DTOutput renderDT
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

server_VisXplore <- function(data) {
  force(data)
  server <- function(input, output, session){

    # upload data
    bl_df <- reactive(data)

    # list of all reactive datasets
    df_lst <- reactiveValues(df_all=data, var_type=sapply(data, class),
                             df_new_num=NULL, new_type_num=NULL,
                             df_new_cat=NULL, new_type_cat=NULL)

    # numeric variable selector
    output$vars_dist <- renderUI({
      num_names <- colnames(df_lst$df_all)[df_lst$var_type == "numeric"]
      checkboxGroupInput("vars_dist", "Numeric variables",
                         choices = num_names, selected = num_names)
    })

    # data tab
    output$data <- DT::renderDT({bl_df() %>% clean_names(case = "none")},
                                   options = list(pageLength=10,
                                                  scrollX = T))
    output$datacheck <- renderText({
      check <- data_check(bl_df())
      format_check_html(check)
    })


    ## transformations: univariate
    observeEvent(input$newtrans,
                 {new_vars <- visx_transform(df_lst$df_all, input$vars_dist,
                                             fun = input$typetrans)
                 df_lst$df_new_num <- bind_cols(df_lst$df_new_num, new_vars)
                 df_lst$new_type_num <- c(df_lst$new_type_num, rep("numeric", ncol(new_vars)))
                 df_lst$df_all <- bind_cols(df_lst$df_all, new_vars)
                 df_lst$var_type <- c(df_lst$var_type, rep("numeric", ncol(new_vars)))
                 })
    ## transformation: multivariate
    observeEvent(input$newop,
                 {if(input$typeop == "Mean"){
                   new_vars <- visx_mean_vars(df_lst$df_all, input$vars_dist,
                                              name = input$newvarname)
                 }
                   if(input$typeop == "Ratio (alphabetical)"){
                     new_vars <- visx_ratio(df_lst$df_all, input$vars_dist[1],
                                            input$vars_dist[2], name = input$newvarname)
                   }
                   if(input$typeop == "Ratio (reverse alphabetical)"){
                     new_vars <- visx_ratio(df_lst$df_all, input$vars_dist[2],
                                            input$vars_dist[1], name = input$newvarname)
                   }
                   df_lst$df_new_num <- bind_cols(df_lst$df_new_num, new_vars)
                   df_lst$new_type_num <- c(df_lst$new_type_num, "numeric")
                   df_lst$df_all <- bind_cols(df_lst$df_all, new_vars)
                   df_lst$var_type <- c(df_lst$var_type, "numeric")

                 })

    output$num_vars <- renderPlot({
      df_plot <- df_lst$df_all[, df_lst$var_type=="numeric"]

      if(nrow(df_plot)>0){
        df_plot <- mutate(df_plot, across(everything(), as.numeric))
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
      req(input$vars_bin)
      checkboxGroupInput("lev", "Levels to collapse",
                         choices = levels(as.factor(df_lst$df_all[[input$vars_bin]])))
    })

    observeEvent(input$cattrans,{
      new_var <- ifelse(df_lst$df_all[[input$vars_bin]] %in% input$lev,
                        input$newcat, df_lst$df_all[[input$vars_bin]])
      new_var <- data.frame(new_var)
      colnames(new_var) <- paste(input$vars_bin, "_bin", sep = "")
      df_lst$df_new_cat <- bind_cols(df_lst$df_new_cat, new_var)
      df_lst$new_type_cat <- c(df_lst$new_type_cat, input$binned_type)
      df_lst$df_all <- bind_cols(df_lst$df_all, new_var)
      df_lst$var_type <- c(df_lst$var_type, input$binned_type)
    })

    ## display original variables
    output$cat_vars <- renderPlot({
      if(any(df_lst$var_type != "numeric")){
        df_plot <- df_lst$df_all[, df_lst$var_type!="numeric",drop = FALSE]
        df_plot <- mutate(df_plot, across(everything(), as.character))
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
                         choices =  colnames(df_lst$df_all),
                         selected = colnames(df_lst$df_all))
    })

    # network plot
    output$npc <- renderPlot({
      req(input$vars_cor)
      sel <- input$vars_cor
      idx <- which(colnames(df_lst$df_all) %in% sel)
      df_sub <- df_lst$df_all[, idx, drop = FALSE]
      type_sub <- df_lst$var_type[idx]

      cor_mats <- pairwise_cor(df_sub, type_sub)

      show_sig <- input$signif != "none"
      sig_val <- if (show_sig) as.numeric(input$signif) else 0.05

      npc_mixed_cor(cor_mats, show_signif = show_sig,
                    sig.level = sig_val,
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


    output$vars_stat <- renderUI({
      checkboxGroupInput("vars_stat", "Variables to include",
                         choices = colnames(df_lst$df_all),
                         selected = colnames(df_lst$df_all))
    })

    output$stat <- renderText({
      req(input$vars_stat)
      sel <- input$vars_stat
      idx <- which(colnames(df_lst$df_all) %in% sel)
      df_sub <- df_lst$df_all[, idx, drop = FALSE]
      type_sub <- df_lst$var_type[idx]

      # inter-correlation statistics
      df_vif <- mutate(df_sub, y=rnorm(nrow(df_sub)))
      non_num_idx <- which(type_sub != "numeric")
      df_vif <- mutate(df_vif, across(all_of(non_num_idx), as.factor))
      vifs <- vif(lm(y ~ ., data = df_vif))
      r2 <- get_r2(df_sub, type_sub)
      r2 <- round(r2, 2)
      var_labs <- factor(type_sub, levels = c("numeric", "factor", "ordinal"),
                         labels = c("numeric", "nominal", "ordinal"))
      var_labs <- droplevels(var_labs)

      if (is.matrix(vifs)) {
        tb <- data.frame(round(vifs, 2), "R-squared" = r2, check.names = FALSE)
        colnames(tb) <- c("GVIF", "DF", "Adjusted GVIF", "R-squared")
      } else {
        tb <- data.frame(VIF = round(vifs, 2), "R-squared" = r2, check.names = FALSE)
        colnames(tb) <- c("VIF", "R-squared")
      }
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
