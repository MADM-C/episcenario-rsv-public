# R Packages
if (!require('pacman')) install.packages('pacman'); library(pacman)
p_load("shiny", "bslib", "data.table", "dplyr", "ggplot2", "plotly",
       "shinyWidgets", "shinyBS", "fst", "gtools")

# Define paths
rds_inc <- "data/dashboard_results_inc.rds"
rds_cum <- "data/dashboard_results_cum.rds"
fst_inc <- "data/dashboard_results_inc.fst"
fst_cum <- "data/dashboard_results_cum.fst"

# Incidence Data
inc_data <- readRDS(rds_inc)
setDT(inc_data)
write_fst(inc_data, fst_inc, compress = 50)

# Cumulative Data
cum_data <- readRDS(rds_cum)
setDT(cum_data)
write_fst(cum_data, fst_cum, compress = 50)

# # USE THIS CODE CHUNK ONCE DATA HAS BEEN FINALIZED FOR FASTER DASHBOARD LOAD TIMES
# # Incidence Data
# if (file.exists(fst_inc)) {
#   inc_data <- fst::read_fst(fst_inc, as.data.table = TRUE)
# } else {
#   inc_data <- readRDS(rds_inc)
#   setDT(inc_data)
#   fst::write_fst(inc_data, fst_inc, compress = 50)
# }
#
# # Cumulative Data
# if (file.exists(fst_cum)) {
#   cum_data <- fst::read_fst(fst_cum, as.data.table = TRUE)
# } else {
#   cum_data <- readRDS(rds_cum)
#   setDT(cum_data)
#   fst::write_fst(cum_data, fst_cum, compress = 50)
# }

# Converting columns to correct type
cols_to_numeric <- c("rsv_hosp", "rsv_icu", "rsv_death")

inc_data[, (cols_to_numeric) := lapply(.SD, as.numeric), .SDcols = cols_to_numeric]
inc_data[, date_scale := as.Date(date_scale)]
inc_data[, policy_name := as.factor(policy_name)]

cum_data[, (cols_to_numeric) := lapply(.SD, as.numeric), .SDcols = cols_to_numeric]
cum_data[, date_scale := as.Date(date_scale)]
cum_data[, policy_name := as.factor(policy_name)]

# Adding Dummy Sensitivity Intervals
for(col in cols_to_numeric) {
  # Incidence dummy intervals
  inc_data[, (paste0(col, "_lower")) := get(col) * 0.75]
  inc_data[, (paste0(col, "_upper")) := get(col) * 1.25]

  # Cumulative dummy intervals
  cum_data[, (paste0(col, "_lower")) := get(col) * 0.75]
  cum_data[, (paste0(col, "_upper")) := get(col) * 1.25]
}

# Data filters
season_sev <- unique(inc_data$season_sev)
age_strat <- unique(inc_data$age_strat)
par_region <- unique(inc_data$par_region)
strategy_name <- mixedsort(as.character(unique(inc_data$policy_name)))
region_choices <- c("Statewide (All Regions)", sort(par_region))

# Outcome filters
outcome_choices <- c(
  "RSV Hospitalizations" = "rsv_hosp",
  "RSV ICU Admissions" = "rsv_icu",
  "RSV Deaths" = "rsv_death")

# Footer Block
footer_block <- tags$div(
  style = "margin-top: 20px; text-align: center; max-width: 900px; margin-left: auto; margin-right: auto;",

  tags$div(
    HTML("
      <div style='font-size: 12.5px; color: #555; line-height: 1.55; text-align: left;'>

        <strong>Funding</strong><br>
        This work was supported by cooperative agreement CDC-RFA-FT-23-0069 from the Center for Forecasting and Outbreak Analytics of the U.S. Centers for Disease Control and Prevention (CDC). Its contents are solely the responsibility of the authors and do not necessarily represent the official views of the CDC.<br><br>

        <strong>Contact</strong><br>
  This dashboard was created by the
  <a href='https://www.sph.umn.edu/research/centers/midwest-analytics-and-disease-modeling/about/' target='_blank' style='color:#0066cc;'>
    Midwest Analytics and Disease Modeling Center (MADMC)</a>.
  For questions or more information, please contact
  <a href='mailto:madmc@umn.edu' style='color:#0066cc;'>madmc@umn.edu</a>.
</div>
")
  ),

  tags$div(
    style = "display: flex; justify-content: center; align-items: center; gap: 40px; margin-top: 25px;",
    tags$img(src = 'umn_logo.png', style = 'height: 50px;')
  ),

  tags$p(
    "Last updated: May 12th, 2026",
    style = "font-size: 12.5px; color: gray; margin-top: 10px; font-style: italic;"
  )
)
# FAQs
faq_data <- data.frame(
  question = c(
    "What is the difference between Scenario Modeling and Forecasting?",

    "How does this tool work?",

    "When should I use this tool?",

    "What can this tool be used for? What can it not be used for?",

    "What data was used in this model?",

    "What are the main assumptions used in the model?",

    "What does the model not take into consideration?",

    "Does the model account for the different strains of RSV (A or B)?"
  ),

  answer = c(
    "Scenario modeling like this tool is meant to quantify 'what if' scenarios about public health interventions.
    They are meant to explore long term changes in the population based on those what if questions. For example
    'What would happen to RSV cases in the United States if we increased RSV vaccinations among pregnant individuals?'
    This allows us to compare and contrast between the scenario where we increased vaccination and the scenario we didn't.
    We can then see the differences in cases, hospitalizations, deaths or other outcomes of interest. Forecasting is
    focused on short term predictions, instead of contrasting between different scenarios we are focused on 'predicting'
    the future as best we can by minimizing and quantifying uncertainty.",

    "This scenario planning tool uses an infectious disease model to simulate potential health outcomes.
    The infectious disease model uses a compartmental SEIR (Susceptible-Exposed-Infected-Recovered) model structure, which is very common
    when simulating disease transmission. See technical details for more information.",

    "This tool should be used for scenario planning purposes in relation to RSV. Use this tool to see the effects of different immunization scenarios
    on hospitalizations, ICU admissions, and deaths due to RSV to help inform policies or interventions.",

    "This tool can be used to support scenario planning. It should be used as one of many factors in scenario planning. This tool should
    not be used for real-time disease forecasting or for predicting real-world outcomes.",

    "This model used RSV-NET, RESP-NET, and RSV immunization data collected by MDH. The majority of the data used
    was from the CDC or MDH and is not available for public access.",

    "We assume the only model inputs that vary by IDEPC region are births and the uptake of immunizations. Inputs such as the probability of hospitalization and probability of an ICU admission vary only by age.
    We assume that transmission between IDEPC regions does not vary by age. Instead, the transmission between IDEPC regions scales the transmission within and between age groups.
    INSERT ASSUMPTIONS ABOUT SCHOOL DAYS MISSED, PRODUCTIVITY LOSSES, ETC.
    We assume that immunizations impact the probability of becoming infected and the probability of becoming hospitalized. However, we assume that once an individual is hospitalized, their immunization status does not impact their length of stay or probability of death.",

    "The model does not take into consideration the following: outpatient visits, asympotomatic vs symptomatic cases, and sociodemographic charactertistics (except age and geographic area).",

    "The model does not account for different strains, but does account for very limited time of immunity. "
  )
)

# Styles script
source("styles.R")

# Reusable section header
section_header <- function(text) {
  div(
    style = "background-color: #E0F2F5; color: #003865; padding: 8px 10px; border-left: 5px solid #008CA8; font-weight: bold; font-size: 1.2em; margin-bottom: 15px; margin-top: 10px;",
    text
  )
}

# UI
ui <- navbarPage(

  # Title + Logo
  title = div(
    tags$img(src = "insignia.png", height = "30px", style = "margin-top: -5px; margin-right: 10px"),
    "Midwest EpiScenario: RSV"),

  header = app_styles,

  # Making the max 6 popup more visible
  tags$head(
    tags$style(HTML(".bootstrap-select .notify {
      background-color: #008CA8 !important;
      color: white !important;
      font-weight: bold !important;
      font-size: 14px !important;
      opacity: 1 !important;
      transition: none !important;}"))),

  # About Tab
  tabPanel("About",
           fluidPage(
             h3("Midwest EpiScenario: RSV"),
             hr(),
             h4("Project Description"),
             p("The Midwest Analytics and Disease Modeling Center's (MADMC) Midwest EpiScenario Model for RSV is designed to support decision making around respiratory disease response by estimating hospitalizations,
               ICU admissions, and deaths under different disease scenarios and policy interventions. The model reflects Minnesota's population demographics and main geographic regions."),
             p("The model is composed of several modules, where each makes up a crucial component of the natural history of the pathogen or interactions with the healthcare system."),
             hr(),

             h4("Immunizations & Strategies"),
             p("The model runs scenario projections for multiple different immunization related strategies."),
             p("Our primary comparators for results are the Status Quo and No Immunization Strategies."),
             p(tags$strong("Status Quo"), "assumes the same uptake in the current season as was seen in the 2024-2025 RSV Season.
               The immunization coverage seen during the 2024-2025 season is as follows: 35% monoclonal antibody uptake, 23% maternal vaccine uptake, 3% older adult vaccine uptake in the 50-74 year age group
               and 15% older adult vaccine uptake in the 75+ year age group."),
             p(tags$strong("No Immunization"), "assumes no immunization uptake whatsoever in the current RSV season, but that there was regular uptake in previous seasons."),
             p("There are", tags$strong("3 monoclonal antibody strategies:"), "10%, 20%, and 30% increases which equate to 45%, 55%, and 65% uptake in the season."),
             p("There are", tags$strong("3 maternal vaccination strategies:"), "10%, 20%, and 30% increases which equate to 33%, 43%, and 53% uptake in the season."),
             p("There are", tags$strong("3 older adult vaccination strategies:"), "5%, 15%, and 25% increases."),
             p("The", tags$strong("Chile Policy"), "is a strategy based on increasing monoclonal antibody uptake while holding maternal vaccination at the status quo levels to achieve a combined coverage of 94%. This is based off a policy Chile implemented to introduce universal monoclonal antibody administration."),
             hr(),

             h4("Instructions for Use - Results Tab"),
             p(tags$strong("1."), "Select the Outcome you would like to see plotted. Current options are RSV-related Hospitalizations, RSV-related ICU Admissions, and RSV-related Deaths."),
             p(tags$strong("2."), "Choose whether you would like to plot total values, incremental differences from status quo, or outcomes averted compared to the status quo."),
             p(tags$strong("3."), "Select the season severity: Typical or Severe. A typical season is based on the 2024-2025 RSV season, while a severe season is based on the 2023-2024 RSV season."),
             p(tags$strong("4."), "Choose whether you would like figures depicting all age groups or specific age group results."),
             p(tags$strong("5."), "Select the region of interest."),
             p(tags$strong("6."), "Select up to 5 different strategies to compare. As a note, Status Quo will be always selected as a baseline."),
             hr(),

             h4("Limitations"),
             p("The model does not follow individuals, but instead follows the population of Minnesota. The only characteristics that impact health outcomes are age and geographic region (Infectious Disease Epidemiology,
               Prevention and Control (IDEPC) regions). Incorporating additional stratifications and/or building an individual-level simulation model requires more data and likely would not substantially impact the validity of the model results."),
             p("The model does not consider contact reducing strategies (i.e., masking, social distancing, etc.) because in the context of RSV, universal masking or distancing policies would not be recommended. Masking
               policies may be implemented in healthcare facilities, but this model does not consider setting-specific scenarios."),
             p("The model does not estimate the number of outpatient visits nor does it validate overall case burden. There is substantial undertesting for RSV, especially in the outpatient setting and for cases that do
               not interact with the healthcare system. Therefore, it is difficult to estimate the true number of cases. Instead, the model is calibrated to hospitalizations, where testing occurs more commonly and input
               values can be adjusted based on RSV estimates reported in the literature."),
             hr(),
             footer_block

           )
  ), # end of About tab


  # Technical Details tab
  tabPanel("Technical Details",
           fluidPage(
             h3("Technical Details of Midwest EpiScenario"),
             hr(),
             h4("Model Description"),
             p("Midwest EpiScenario is a modeling platform designed to be easily adapted to emerging infectious disease threats, particularly respiratory illnesses. The model is a Susceptible-Exposed-Infected-Recovered model with additional health states for hospitalizations, ICU admissions, and deaths."),
             div(
               tags$img(src = "SEIR.png", height = "300px",
                        style = "border: none; border-style: none; display: block; margin-left: auto; margin-right: auto;"),
               style = "text-align: center;"
             ),
             hr(),
             h4("Modules"),
             p("The modeling platform’s flexibility comes from its modular design. The core functionality is contained in 6 modules:"),
             p("1)    Demography"),
             tags$ul(
               tags$li("The demography module contains the functions that handle aging, all-cause mortality, and births.")
             ),
             p("2)    Transmission"),
             tags$ul(
               tags$li("The transmission module is responsible for estimating new cases."),
               tags$li("This module also contains the functions for seasonality and spatial dynamics.")
             ),
             p("3)    Disease Progression"),
             tags$ul(
               tags$li("The disease progression module moves the population through the exposed and infected health states.")
             ),
             p("4)    Healthcare"),
             tags$ul(
               tags$li("The healthcare module is responsible for hospitalizations and ICU admissions.")
             ),
             p("5)    Post-Infection"),
             tags$ul(
               tags$li("The post-infection module contains the functions for disease-specific mortality and recovery.")
             ),
             p("6)    Immunity"),
             tags$ul(
               tags$li("The immunity module moves populations into vaccination/immunization stratifications and estimates waning immunity.")
             ),
             p("The modular design allows for functionality to be turned on or off depending on the disease characteristics. For example, during early outbreaks of a novel disease, we may not have immunizations available and would not use that functionality."),
             hr(),
             h4("RSV Stratifications"),
             p("The RSV model has the following stratifications:"),
             p("1)    Age Group (years)"),
             tags$ul(
               tags$li("<1"),
               tags$li("1-4"),
               tags$li("5-17"),
               tags$li("18-49"),
               tags$li("50-74"),
               tags$li("75+")
             ),
             p(HTML("2)    Infectious Disease Epidemiology, Prevention and Control (<a href='https://www.health.state.mn.us/about/org/idepc/epis.html' target='_blank'>IDEPC Regions</a>) Regions")),
             tags$ul(
               tags$li("Central"),
               tags$li("Metropolitan"),
               tags$li("Northeast"),
               tags$li("Northwest"),
               tags$li("Southeast"),
               tags$li("Southwest"),
               tags$li("West Central")
             ),
             p("3)    Immunization Status"),
             tags$ul(
               tags$li("No Immunization"),
               tags$li("Vaccinated"),
               tags$li("Monoclonal antibodies"),
               tags$li("Maternal antibodies")
             ),
             p("Age and immunization status are dynamic while IDEPC regions are fixed (i.e. there are still interactions between the regions, but there is no permanent movement)."),
             hr(),
             h4("Additional Details"),
             p("Additional information on the modeling platform can be found in our technical appendix."),
             hr(),
             footer_block
           )
  ), # end of Technical Details tab

  # Results Tab
  tabPanel("Results",
           fluidPage(
             tags$details(
               style = "background-color: #E0F2F5; border-left: 5px solid #003865; padding: 12px 15px; margin-bottom: 20px; border-radius: 5px;",
               tags$summary(
                 style = "color: #003865; font-size: 16px; font-weight: bold; cursor: pointer; outline: none;",
                 HTML("<i class='fas fa-info-circle' style='margin-right: 5px;'></i> Quick Start <span style='font-size: 12px; font-weight: normal; color: #555;'>(Click to expand)</span>")
               ),
               div(style = "margin-top: 12px; font-size: 14px; color: #333; padding-left: 5px;",
                   p(style = "margin-bottom: 8px;",
                     "1. Select your desired Outcome and Display Option (Totals vs. Incremental vs. Averted)."
                   ),
                   p(style = "margin-bottom: 8px;",
                     "2. Filter by Season Severity, Age Group, and Region."
                   ),
                   p(style = "margin-bottom: 0;",
                     "3. Select up to 5 Strategies to compare against the Status Quo."
                   )
               )
             ),

             sidebarLayout(
               sidebarPanel(
                 width = 3,

                 section_header("Display Options"),

                 # Select Outcome
                 selectInput("selected_outcome",
                             label = HTML("Select Outcome to Plot <i id='outcome_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                             choices = outcome_choices, selected = "rsv_hosp"),
                 bsTooltip(id = "outcome_help", title = "Select the outcome you would like to plot.", placement = "right", trigger = "hover", options = list(container = "body")),


                 # Display options for plots
                 radioButtons(inputId = "display_opt",
                              label = HTML("Display Options <i id='display_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                              choices = c("Total Values" = "total", "Incremental Differences" = "incremental", "Outcomes Averted" = "versus_sq"),
                              selected = "total"),
                 bsTooltip(id = "display_help", title = "Select whether you would like to view total values, incremental differences from status quo, or number of outcomes averted compared to status quo.", placement = "right", trigger = "hover", options = list(container = "body")),

                 # Select Sensitivity Intervals
                 checkboxInput("show_intervals",
                               label = HTML("View Uncertainty Intervals <i id='interval_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"), value = FALSE),
                 bsTooltip(id = "interval_help", title = "Select whether you would like to see 50% uncertainty intervals on the figures", placement = "right", trigger = "hover", options = list(container = "body")),


                 # Select Color Palette
                 radioButtons(inputId = "color_mode",
                              label = HTML("Color Palette <i id='color_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                              choices = c("Accessible" = "accessible",
                                          "MADMC Colors" = "default"),
                              selected = "accessible"),
                 bsTooltip(id = "color_help", title = "Switch between the standard MADMC colors and a colorblind-friendly palette", placement = "right", trigger = "hover", options = list(container = "body")),
                 tags$hr(),

                 section_header("Scenarios"),
                 # Select Season
                 selectInput("selected_season_sev",
                             label = HTML("Select Season Severity <i id='season_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                             choices = season_sev, selected = season_sev),
                 bsTooltip(id = "season_help", title = "Select the RSV season you would like to see results for. Typical is based on the 2024-2025 RSV season, while Severe is based on the 2023-2024 season.", placement = "right", trigger = "hover", options = list(container = "body")),

                 tags$hr(),
                 section_header("Stratifications"),
                 # Select Ages
                 radioButtons("age_view_mode",
                              label = HTML("Age Group Display: <i id='age_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                              choices = c("All Ages" = "aggregated", "Individual Age Groups" = "individual"),
                              selected = "aggregated"),
                 bsTooltip(id = "age_view_mode", title = "Choose aggregated or individual age groups.", placement = "right", trigger = "hover", options = list(container = "body")),

                 conditionalPanel(
                   condition = "input.age_view_mode == 'individual'",
                   pickerInput("selected_age_groups",
                               label = "Select Age Groups to Display:",
                               choices = c("<1", "1-4", "5-17", "18-49", "50-74", "75+"),
                               selected = c("<1", "1-4", "5-17", "18-49", "50-74", "75+"),
                               multiple = TRUE,
                               options = pickerOptions(actionsBox = TRUE,
                                                       selectedTextFormat = "count > 3"))
                 ),

                 # Select Region
                 selectInput("selected_region",
                             label = HTML("Select Region <a href='https://www.health.state.mn.us/about/org/idepc/epis.html' target='_blank'>IDEPC Regions</a> <i id='region_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                             choices = region_choices, selected = "Statewide (All Regions)"),
                 bsTooltip(id = "region_help", title = "Select 'Statewide' or a specific region.", placement = "right", trigger = "hover", options = list(container = "body")),

                 tags$hr(),
                 section_header("Strategies"),
                 # Select Policies
                 pickerInput("selected_policies",
                             label = HTML("Select Strategies: <i id='policy_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                             choices = strategy_name, selected = c("Status Quo", "No Immunizations"), multiple = TRUE,
                             options = pickerOptions(maxOptions = 6, maxOptionsText = "Maximum of 6 strategies")),
                 bsTooltip(id = "policy_help", title = "Select the policies you would like to compare.", placement = "right", trigger = "hover", options = list(container = "body")),

                 bsCollapse(id = "strategy_desc_collapse", open = NULL,
                            bsCollapsePanel(
                              title = HTML("<i class='fas fa-info-circle' style='margin-right: 5px;'></i> Strategy Details <span style='font-size: 12px; font-weight: normal; color: #555;'>(Click to expand)</span>"),

                              value = "strategy_details_panel",
                              style = "info",
                              tags$div(
                                style = "font-size: 0.85em; color: #555;",
                                tags$ul(style = "padding-left: 20px;",

                                        tags$li(tags$strong("Status Quo:"), "Assumed same uptake as 2024-2025 season. 3% Older Adult Vaccination (ages 50-74).
                                                15% Older Adult Vaccination (ages 75+). 23% Maternal Vaccination. 35% Monoclonal Antibody Coverage."),
                                        br(),
                                        tags$li(tags$strong("Maternal Vaccination:"), "Increasing current maternal vaccination uptake by 10, 20, or 30%."),
                                        br(),
                                        tags$li(tags$strong("Monoclonal Antibodies:"), "Increasing current monoclonal antibody uptake by 10, 20, or 30%."),
                                        br(),
                                        tags$li(tags$strong("Older Adult Vaccination:"), "Increasing current older adult vaccination uptake by 5, 15, or 25%."),
                                        br(),
                                        tags$li(tags$strong("No Immunization:"), "No uptake of immunizations during current season (assuming regular uptake in previous seasons)."),
                                        br(),
                                        tags$li(tags$strong("Chile Policy:"), "Implementing 94% coverage of monoclonal antibodies at birth.")


                                ))))

               ),

               # Main panel with plots
               mainPanel(
                 tabsetPanel(
                   type = "tabs",
                   tabPanel("Season Totals",
                            br(),
                            uiOutput("barPlotUI"),
                            div(style = "text-align: center; margin-top: 20px; margin-bottom: 20px;",
                                downloadButton("download_bar_plot", "Download Figure", class = "btn-primary", style = "margin-right: 15px;"),
                                downloadButton("download_bar_data", "Download Data", class = "btn-secondary")
                            ),
                            uiOutput("caption_totals")
                   ),
                   tabPanel("Cumulative",
                            br(),
                            uiOutput("cumulativePlotUI"),
                            div(style = "text-align: center; margin-top: 20px; margin-bottom: 20px;",
                                downloadButton("download_cum_plot", "Download Figure", class = "btn-primary", style = "margin-right: 15px;"),
                                downloadButton("download_cum_data", "Download Data", class = "btn-secondary")
                            ),
                            uiOutput("caption_cumulative")
                   ),
                   tabPanel("Incidence",
                            br(),
                            uiOutput("incidencePlotUI"),
                            div(style = "text-align: center; margin-top: 20px; margin-bottom: 20px;",
                                downloadButton("download_inc_plot", "Download Figure", class = "btn-primary", style = "margin-right: 15px;"),
                                downloadButton("download_inc_data", "Download Data", class = "btn-secondary")
                            ),
                            uiOutput("caption_incidence")
                   )
                 )
               )
             )
           )
  ), # end of Results tab

  tabPanel("FAQ's",
           fluidPage(
             h3("Frequently Asked Questions"),
             hr(),
             uiOutput("faq_ui")
           )
  )
) # end navbar

# Server
server <- function(input, output, session) {

  # Color palette for figures
  madmc_colors <- c("#003865", "#008CA8", "#FDC648", "#56748D", "#88C5D3", "#E0F2F5")
  access_colors <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00")

  # Reactive colors
  policy_colors <- reactive({
    req(input$selected_policies)
    current_palette <- if(input$color_mode == "accessible") access_colors else madmc_colors
    ordered_policies <- c("Status Quo", sort(setdiff(input$selected_policies, "Status Quo")))
    final_policies <- ordered_policies[ordered_policies %in% input$selected_policies]
    setNames(current_palette[1:length(final_policies)], final_policies)
  })
  observeEvent(input$selected_policies, {
    if (!"Status Quo" %in% input$selected_policies) {
      updatePickerInput(session, "selected_policies", selected = unique(c("Status Quo", input$selected_policies)))
      showNotification("Status Quo is required as a baseline", type = "warning", duration = 5)
    }
  }, ignoreNULL = FALSE)

  # Reactive Captions
  output$caption_totals <- renderUI({
    req(input$display_opt, input$selected_outcome)

    sel_lab <- names(outcome_choices)[outcome_choices == input$selected_outcome]

    if(input$display_opt == "versus_sq") {
      caption_text <- HTML(paste0("This figure displays ", sel_lab, " averted compared to the status quo over the entire season for each chosen strategy.<br> Please pay attention to Y-axes when comparing individual age groups, they may have drastically different scales."))
    } else if(input$display_opt == "incremental") {
      caption_text <- HTML(paste0("This figure displays the incremental difference in ", sel_lab, " compared to the status quo over the entire season.<br> Please pay attention to Y-axes when comparing individual age groups, they may have drastically different scales."))
    } else {
      caption_text <- HTML(paste0("This figure displays total ", sel_lab, " over the entire season for each chosen strategy.<br> Please pay attention to Y-axes when comparing individual age groups, they may have drastically different scales."))
    }

    p(caption_text, style = "margin-top: 15px; font-style: italic; color: #555; text-align: center;")
  })

  output$caption_cumulative <- renderUI({
    req(input$display_opt, input$selected_outcome)

    sel_lab <- names(outcome_choices)[outcome_choices == input$selected_outcome]

    if(input$display_opt == "versus_sq") {
      caption_text <- paste0("This figure displays ", sel_lab, " averted compared to the status quo over the entire season for each chosen strategy.")
    } else if(input$display_opt == "incremental") {
      caption_text <- paste0("This figure displays the incremental difference in ", sel_lab, " compared to the status quo over the entire season.")
    } else {
      caption_text <- paste0("This figure displays total ", sel_lab, " over the entire season for each chosen strategy.")
    }

    p(caption_text, style = "margin-top: 15px; font-style: italic; color: #555; text-align: center;")
  })

  output$caption_incidence <- renderUI({
    req(input$display_opt, input$selected_outcome)

    sel_lab <- names(outcome_choices)[outcome_choices == input$selected_outcome]

    if(input$display_opt == "versus_sq") {
      caption_text <- paste0("This figure displays ", sel_lab, " averted compared to the status quo over the entire season for each chosen strategy.")
    } else if(input$display_opt == "incremental") {
      caption_text <- paste0("This figure displays the incremental difference in ", sel_lab, " compared to the status quo over the entire season.")
    } else {
      caption_text <- paste0("This figure displays total ", sel_lab, " over the entire season for each chosen strategy.")
    }

    p(caption_text, style = "margin-top: 15px; font-style: italic; color: #555; text-align: center;")
  })

  # Incidence Data
  base_inc_data <- reactive({
    req(input$selected_season_sev, input$selected_policies)

    group_cols <- c("date_scale", "policy_name")
    if(input$age_view_mode == "individual") group_cols <- c(group_cols, "age_strat")

    selected_sev <- input$selected_season_sev
    selected_pol <- input$selected_policies
    selected_reg <- input$selected_region

    # Filter
    if (selected_reg == "Statewide (All Regions)") {
      dt <- inc_data[season_sev == selected_sev & policy_name %in% selected_pol]
    } else {
      dt <- inc_data[season_sev == selected_sev & policy_name %in% selected_pol & par_region == selected_reg]
    }

    # Filter for Specific Selection on Age Groups
    if (input$age_view_mode == "individual") {
      req(input$selected_age_groups)
      dt <- dt[age_strat %in% input$selected_age_groups]
    }

    # Select proper intervals
    out_col <- input$selected_outcome
    lower_col <- paste0(out_col, "_lower")
    upper_col <- paste0(out_col, "_upper")

    agg_dt <- dt[, .(
      daily_val = sum(get(out_col), na.rm = TRUE),
      daily_lower = sum(get(lower_col), na.rm = TRUE),
      daily_upper = sum(get(upper_col), na.rm = TRUE)
    ), by = group_cols]

    # Relevel
    other_policies <- sort(setdiff(unique(agg_dt$policy_name), "Status Quo"))
    agg_dt[, policy_name := factor(policy_name, levels = c("Status Quo", other_policies))]

    return(agg_dt)
  })

  # Cumulative Data
  base_cum_data <- reactive({
    req(input$selected_season_sev, input$selected_policies)

    group_cols <- c("date_scale", "policy_name")
    if(input$age_view_mode == "individual") group_cols <- c(group_cols, "age_strat")

    selected_sev <- input$selected_season_sev
    selected_pol <- input$selected_policies
    selected_reg <- input$selected_region

    if (selected_reg == "Statewide (All Regions)") {
      dt <- cum_data[season_sev == selected_sev & policy_name %in% selected_pol]
    } else {
      dt <- cum_data[season_sev == selected_sev & policy_name %in% selected_pol & par_region == selected_reg]
    }

    # Filter for Specific Selection
    if (input$age_view_mode == "individual") {
      req(input$selected_age_groups)
      dt <- dt[age_strat %in% input$selected_age_groups]
    }

    # Select proper intervals
    out_col <- input$selected_outcome
    lower_col <- paste0(out_col, "_lower")
    upper_col <- paste0(out_col, "_upper")

    agg_dt <- dt[, .(
      cum_val = sum(get(out_col), na.rm = TRUE),
      cum_lower = sum(get(lower_col), na.rm = TRUE),
      cum_upper = sum(get(upper_col), na.rm = TRUE)
    ), by = group_cols]

    other_policies <- sort(setdiff(unique(agg_dt$policy_name), "Status Quo"))
    agg_dt[, policy_name := factor(policy_name, levels = c("Status Quo", other_policies))]

    return(agg_dt)
  })

  # Plotting Incidence
  plot_data_incidence <- reactive({
    req(nrow(base_inc_data()) > 0)
    dt <- copy(base_inc_data())
    if (input$display_opt %in% c("versus_sq", "incremental")) {
      join_cols <- if(input$age_view_mode == "individual") c("date_scale", "age_strat") else "date_scale"
      ref_dt <- dt[policy_name == "Status Quo", ..join_cols]
      ref_dt[, ref_val := dt[policy_name == "Status Quo"]$daily_val]
      dt <- merge(dt, ref_dt, by = join_cols, all.x = TRUE)
      if (input$display_opt == "versus_sq") {
        dt[, daily_val := ref_val - daily_val]
      } else {
        dt[, daily_val := daily_val - ref_val]
      }

      dt[, daily_lower := ifelse(daily_val >= 0, daily_val * 0.75, daily_val * 1.25)]
      dt[, daily_upper := ifelse(daily_val >= 0, daily_val * 1.25, daily_val * 0.75)]

      dt <- dt[!is.na(daily_val)]
    }
    return(dt)
  })

  # Plot Cumulative
  plot_data_cumulative <- reactive({
    req(nrow(base_cum_data()) > 0)
    dt <- copy(base_cum_data())
    setorder(dt, policy_name, date_scale)
    if (input$display_opt %in% c("versus_sq", "incremental")) {
      join_cols <- if(input$age_view_mode == "individual") c("date_scale", "age_strat") else "date_scale"
      ref_dt <- dt[policy_name == "Status Quo", ..join_cols]
      ref_dt[, ref_val := dt[policy_name == "Status Quo"]$cum_val]

      dt <- merge(dt, ref_dt, by = join_cols, all.x = TRUE)
      if (input$display_opt == "versus_sq") {
        dt[, cum_val := ref_val - cum_val]
      } else {
        dt[, cum_val := cum_val - ref_val]
      }

      dt[, cum_lower := ifelse(cum_val >= 0, cum_val * 0.75, cum_val * 1.25)]
      dt[, cum_upper := ifelse(cum_val >= 0, cum_val * 1.25, cum_val * 0.75)]

      dt <- dt[!is.na(cum_val)]
    }
    return(dt)
  })

  # Plot Totals
  total_events_data <- reactive({
    group_cols <- "policy_name"
    if(input$age_view_mode == "individual") group_cols <- c("policy_name", "age_strat")

    plot_data_incidence()[, .(
      total_val = sum(daily_val, na.rm = TRUE),
      total_lower = sum(daily_lower, na.rm = TRUE),
      total_upper = sum(daily_upper, na.rm = TRUE)
    ), by = group_cols]
  })

  # Incidence plot object
  incidence_plot_obj <- reactive({
    req(nrow(plot_data_incidence()) > 0)

    sel_lab <- names(outcome_choices)[outcome_choices == input$selected_outcome]
    y_label_text <- if(input$display_opt == "versus_sq") {
      paste(sel_lab, "Averted")
    } else if(input$display_opt == "incremental") {
      paste("Incremental", sel_lab)
    } else {
      paste("Daily", sel_lab)
    }

    plot_df <- copy(plot_data_incidence())
    plot_df[, txt := paste0("<b>Date:</b> ", format(date_scale, "%b %d, %Y"), "<br>",
                            "<b>Strategy:</b> ", policy_name, "<br>",
                            "<b>Outcome:</b> ", format(round(daily_val,0), big.mark=","))]

    if(input$show_intervals) {
      plot_df[, txt := paste0(txt, "<br><b>Interval:</b> [", format(round(daily_lower,0), big.mark=","), " - ", format(round(daily_upper,0, big.mark=","), "]")]
    }

    p <- ggplot(plot_df, aes(x = date_scale, y = daily_val, color = policy_name,
                             group = policy_name, text = txt)) +
      geom_line(size = 1.2) +
      scale_color_manual(values = policy_colors(), name = "Strategy",
                         labels = function(x) sapply(x, function(l) paste(strwrap(l, width = 80), collapse = "\n"))) +
      {if(input$show_intervals) scale_fill_manual(values = policy_colors(), guide = "none")} +
      scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
      {if(input$age_view_mode == "individual") facet_wrap(~age_strat, ncol = 2, scales = "free_y")} +
      scale_y_continuous(
        breaks = function(x) { b <- pretty(x); b[b %% 1 == 0] },
        limits = function(x) c(min(0, x, na.rm = TRUE), max(1, x, na.rm = TRUE))) +
      labs(title = paste("Incidence:", y_label_text, "Compared to Status Quo"), y = y_label_text, x = NULL) +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(color = "#003865", face = "bold", size = 18),
            axis.text.x = element_text(angle = 45, hjust = 1),
            axis.text.y = element_text(face = "bold", size = 12, color = "black"))

    if(input$show_intervals) {
      p <- p + geom_ribbon(aes(ymin = daily_lower, ymax = daily_upper, fill = policy_name), alpha = 0.5, color = NA, show.legend = FALSE)
    }

    return(p)
  })

  # Creating incidence plot
  output$incidencePlot <- renderPlotly({
    ggplotly(incidence_plot_obj(), tooltip = "text") %>% config(displayModeBar = FALSE)
  })

  # Incidence downloads
  # Plot download
  output$download_inc_plot <- downloadHandler(
    filename = function() {
      paste0("incidence_plot_", Sys.Date(), ".png")
    },
    content = function(file) {
      plot_height <- if(input$age_view_mode == "individual") 12 else 8
      ggsave(file, plot = incidence_plot_obj(), device = "png",
             width = 14, height = plot_height, dpi = 300, bg = "white")
    }
  )

  # Table download
  output$download_inc_data <- downloadHandler(
    filename = function() {
      paste0("incidence_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      export_data <- copy(plot_data_incidence())
      if("txt" %in% names(export_data)) export_data[, txt := NULL]
      write.csv(export_data, file, row.names = FALSE)
    }
  )

  # Cumulative plot object
  cumulative_plot_obj <- reactive({
    req(nrow(plot_data_cumulative()) > 0)

    sel_lab <- names(outcome_choices)[outcome_choices == input$selected_outcome]
    y_label_text <- if(input$display_opt == "versus_sq") {
      paste(sel_lab, "Averted")
    } else if(input$display_opt == "incremental") {
      paste("Incremental", sel_lab)
    } else {
      paste("Daily", sel_lab)
    }

    plot_df <- copy(plot_data_cumulative())
    plot_df[, txt := paste0("<b>Date:</b> ", format(date_scale, "%b %d, %Y"), "<br>",
                            "<b>Strategy:</b> ", policy_name, "<br>",
                            "<b>Outcome:</b> ", format(round(cum_val,0), big.mark=","))]

    if(input$show_intervals) {
      plot_df[, txt := paste0(txt, "<br><b>Interval:</b> [", format(round(cum_lower,0), big.mark=","), " - ", format(round(cum_upper,0), big.mark=","), "]")]
    }

    p <- ggplot(plot_df, aes(x = date_scale, y = cum_val, color = policy_name,
                             group = policy_name, text = txt)) +
      geom_line(size = 1.2) +
      scale_color_manual(values = policy_colors(), name = "Strategy",
                         labels = function(x) sapply(x, function(l) paste(strwrap(l, width = 80), collapse = "\n"))) +
      {if(input$show_intervals) scale_fill_manual(values = policy_colors(), guide = "none")} +
      scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
      {if(input$age_view_mode == "individual") facet_wrap(~age_strat, ncol = 2, scales = "free_y")} +
      scale_y_continuous(
        breaks = function(x) { b <- pretty(x); b[b %% 1 == 0] },
        limits = function(x) c(min(0, x, na.rm = TRUE), max(1, x, na.rm = TRUE))) +
      labs(title = paste("Cumulative:", y_label_text, "Compared to Status Quo"), y = y_label_text, x = NULL) +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(color = "#003865", face = "bold", size = 18),
            axis.text.x = element_text(angle = 45, hjust = 1),
            axis.text.y = element_text(face = "bold", size = 12, color = "black"))

    if(input$show_intervals) {
      p <- p + geom_ribbon(aes(ymin = cum_lower, ymax = cum_upper, fill = policy_name), alpha = 0.5, color = NA, show.legend = FALSE)
    }

    return(p)
  })

  # Creating cumulative plot
  output$cumulativePlot <- renderPlotly({
    ggplotly(cumulative_plot_obj(), tooltip = "text") %>% config(displayModeBar = FALSE)
  })

  # Cumulative downloads
  # Plot download
  output$download_cum_plot <- downloadHandler(
    filename = function() {
      paste0("cumulative_plot_", Sys.Date(), ".png")
    },
    content = function(file) {
      plot_height <- if(input$age_view_mode == "individual") 12 else 8
      ggsave(file, plot = cumulative_plot_obj(), device = "png",
             width = 14, height = plot_height, dpi = 300, bg = "white")
    }
  )

  # Table download
  output$download_cum_data <- downloadHandler(
    filename = function() {
      paste0("cumulative_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      export_data <- copy(plot_data_cumulative())
      if("txt" %in% names(export_data)) export_data[, txt := NULL]
      write.csv(export_data, file, row.names = FALSE)
    }
  )

  # Totals plot object
  bar_plot_obj <- reactive({
    req(nrow(total_events_data()) > 0)

    sel_lab <- names(outcome_choices)[outcome_choices == input$selected_outcome]
    y_label_text <- if(input$display_opt == "versus_sq") {
      paste(sel_lab, "Averted")
    } else if(input$display_opt == "incremental") {
      paste("Incremental", sel_lab)
    } else {
      paste("Daily", sel_lab)
    }

    plot_df <- copy(total_events_data())
    plot_df[, txt := paste0("<b>Strategy:</b> ", policy_name, "<br>",
                            "<b>Outcome:</b> ", format(round(total_val,0), big.mark=","))]

    if(input$show_intervals) {
      plot_df[, txt := paste0(txt, "<br><b>Interval:</b> [", format(round(total_lower,0), big.mark=","), " - ", format(round(total_upper,0), big.mark=","), "]")]
    }

    if(input$display_opt %in% c("versus_sq", "incremental")) plot_df <- plot_df[policy_name != "Status Quo"]

    # Floating Data Labels
    if(input$age_view_mode == "individual") {
      if(input$show_intervals) {
        plot_df[, y_offset := max(abs(total_upper), na.rm = TRUE) * 0.05, by = age_strat]
        plot_df[, label_y := ifelse(total_val >= 0, total_upper + y_offset, total_lower - y_offset)]
      } else {
        plot_df[, y_offset := max(abs(total_val), na.rm = TRUE) * 0.05, by = age_strat]
        plot_df[, label_y := ifelse(total_val >= 0, total_val + y_offset, total_val - y_offset)]
      }
    } else {
      if(input$show_intervals) {
        plot_df[, y_offset := max(abs(total_upper), na.rm = TRUE) * 0.05]
        plot_df[, label_y := ifelse(total_val >= 0, total_upper + y_offset, total_lower - y_offset)]
      } else {
        plot_df[, y_offset := max(abs(total_val), na.rm = TRUE) * 0.05]
        plot_df[, label_y := ifelse(total_val >= 0, total_val + y_offset, total_val - y_offset)]
      }
    }

    p <- ggplot(plot_df, aes(x = policy_name, y = total_val, fill = policy_name, text = txt)) +
      geom_col(width = 0.7)
    # Add text labels only when NOT showing sensitivity intervals
    if(!input$show_intervals) {
      p <- p + geom_text(
        aes(
          y = label_y,
          label = format(round(total_val, 0), big.mark=",")
        ),
        size = 5,
        color = "black"
      )
    }

    p <- p +
      scale_fill_manual(values = policy_colors(),
                        labels = function(x) sapply(x, function(l) paste(strwrap(l, width = 80), collapse = "\n"))) +
      {if(input$age_view_mode == "individual") facet_wrap(~age_strat, ncol = 2, scales = "free_y")} +
      scale_y_continuous(
        breaks = function(x) { b <- pretty(x); b[b %% 1 == 0] },
        limits = function(x) c(min(0, x, na.rm = TRUE), max(1, x, na.rm = TRUE))) +
      labs(title = paste("Season Totals:", y_label_text, "Compared to Status Quo"), y = y_label_text, x = NULL, fill = "Strategy") +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(color = "#003865", face = "bold", size = 18),
            axis.text.x = element_blank(),
            axis.text.y = element_text(face = "bold", size = 12, color = "black")) +
      guides(color = "none")

    if(input$show_intervals) {
      p <- p + geom_errorbar(aes(ymin = total_lower, ymax = total_upper), width = 0.2, color = "#555555", size = 0.8)
    }

    return(p)
  })

  # Creating totals plot
  output$barPlot <- renderPlotly({
    ggplotly(bar_plot_obj(), tooltip = "text") %>% config(displayModeBar = FALSE)
  })

  # Totals downloads
  # Plot download
  output$download_bar_plot <- downloadHandler(
    filename = function() {
      paste0("season_totals_plot_", Sys.Date(), ".png")
    },
    content = function(file) {
      plot_height <- if(input$age_view_mode == "individual") 12 else 8
      ggsave(file, plot = bar_plot_obj(), device = "png",
             width = 14, height = plot_height, dpi = 300, bg = "white")
    }
  )

  # Table download
  output$download_bar_data <- downloadHandler(
    filename = function() {
      paste0("season_totals_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      export_data <- copy(total_events_data())
      if("txt" %in% names(export_data)) export_data[, txt := NULL]
      write.csv(export_data, file, row.names = FALSE)
    }
  )

  # Plot dimensions
  calc_dims <- function(mode, df) {
    if(mode == "individual") {
      n_groups <- length(unique(df$age_strat))
      if (n_groups == 0) n_groups <- 1
      n_rows <- ceiling(n_groups / 2)
      list(w = "1400px", h = paste0((500 * n_rows) + 100, "px"))
    } else {
      list(w = "100%", h = "750px")
    }
  }

  # Rendering dynamic UI for figures
  output$incidencePlotUI <- renderUI({
    req(plot_data_incidence())
    dims <- calc_dims(input$age_view_mode, plot_data_incidence())
    plotlyOutput("incidencePlot", width = dims$w, height = dims$h)
  })

  output$cumulativePlotUI <- renderUI({
    req(plot_data_cumulative())
    dims <- calc_dims(input$age_view_mode, plot_data_cumulative())
    plotlyOutput("cumulativePlot", width = dims$w, height = dims$h)
  })

  output$barPlotUI <- renderUI({
    req(total_events_data())
    dims <- calc_dims(input$age_view_mode, total_events_data())
    plotlyOutput("barPlot", width = dims$w, height = dims$h)
  })

  # Render FAQ accordion
  output$faq_ui <- renderUI({
    lapply(1:nrow(faq_data), function(i) {
      bsCollapse(
        id = paste0("faq_col_", i),
        bsCollapsePanel(
          title = faq_data$question[i],
          style = "info",
          p(faq_data$answer[i])
        ))})})
}

shinyApp(ui = ui, server = server)

