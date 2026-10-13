# R Packages
if (!require('pacman')) install.packages('pacman'); library(pacman)
p_load("shiny", "bslib", "data.table", "dplyr", "ggplot2", "plotly",
       "shinyWidgets", "shinyBS", "fst", "gtools", "viridis",
       "htmlwidgets", "glue", "colorspace")

# Load data files
inc_nostrat_data      <- fst::read_fst("data/dashboard_results_nostrat_inc.fst",      as.data.table = TRUE)
inc_nostrat_diff_data <- fst::read_fst("data/dashboard_results_nostrat_inc_diff.fst", as.data.table = TRUE)
inc_age_data          <- fst::read_fst("data/dashboard_results_age_inc.fst",          as.data.table = TRUE)
inc_age_diff_data     <- fst::read_fst("data/dashboard_results_age_inc_diff.fst",     as.data.table = TRUE)
inc_reg_data          <- fst::read_fst("data/dashboard_results_reg_inc.fst",          as.data.table = TRUE)
inc_reg_diff_data     <- fst::read_fst("data/dashboard_results_reg_inc_diff.fst",     as.data.table = TRUE)
inc_all_data          <- fst::read_fst("data/dashboard_results_all_inc.fst",          as.data.table = TRUE)
inc_all_diff_data     <- fst::read_fst("data/dashboard_results_all_inc_diff.fst",     as.data.table = TRUE)
cum_nostrat_data      <- fst::read_fst("data/dashboard_results_nostrat_cum.fst",      as.data.table = TRUE)
cum_nostrat_diff_data <- fst::read_fst("data/dashboard_results_nostrat_cum_diff.fst", as.data.table = TRUE)
cum_age_data          <- fst::read_fst("data/dashboard_results_age_cum.fst",          as.data.table = TRUE)
cum_age_diff_data     <- fst::read_fst("data/dashboard_results_age_cum_diff.fst",     as.data.table = TRUE)
cum_reg_data          <- fst::read_fst("data/dashboard_results_reg_cum.fst",          as.data.table = TRUE)
cum_reg_diff_data     <- fst::read_fst("data/dashboard_results_reg_cum_diff.fst",     as.data.table = TRUE)
cum_all_data          <- fst::read_fst("data/dashboard_results_all_cum.fst",          as.data.table = TRUE)
cum_all_diff_data     <- fst::read_fst("data/dashboard_results_all_cum_diff.fst",     as.data.table = TRUE)

# Converting columns to correct type
cols_to_numeric <- c("rsv_hosp", "rsv_icu", "rsv_death")

v_data_files <- list(inc_nostrat_data, inc_nostrat_diff_data,
                     inc_age_data, inc_age_diff_data,
                     inc_reg_data, inc_reg_diff_data,
                     inc_all_data, inc_all_diff_data,
                     cum_nostrat_data, cum_nostrat_diff_data,
                     cum_age_data, cum_age_diff_data,
                     cum_reg_data, cum_reg_diff_data,
                     cum_all_data, cum_all_diff_data)

for (data in v_data_files) {
  data[, (cols_to_numeric) := lapply(.SD, as.numeric), .SDcols = cols_to_numeric]
  data[, date_scale := as.Date(date_scale)]
  data[, policy_name := factor(policy_name,
                               levels = c("Status Quo", "No Immunizations",
                                          "Maternal Vaccination +10%", "Maternal Vaccination +20%", "Maternal Vaccination +30%",
                                          "Monoclonal Antibodies +10%", "Monoclonal Antibodies +20%", "Monoclonal Antibodies +30%",
                                          "Older Adult Vaccination +5%", "Older Adult Vaccination +15%", "Older Adult Vaccination +25%"))]
}

# Data filters
season_sev <- unique(inc_all_data$season_sev)
age_strat <- unique(inc_all_data$age_strat)
par_region <- unique(inc_all_data$par_region)
strategy_name <- c("Maternal Vaccination +10%", "Maternal Vaccination +20%", "Maternal Vaccination +30%",
                   "Monoclonal Antibodies +10%", "Monoclonal Antibodies +20%", "Monoclonal Antibodies +30%",
                   "Older Adult Vaccination +5%", "Older Adult Vaccination +15%", "Older Adult Vaccination +25%",
                   "No Immunizations", "Status Quo")
region_choices <- c("Statewide (All Regions)", sort(par_region))

# Outcome filters
outcome_choices <- c(
  "RSV Hospital Admissions" = "rsv_hosp",
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
    "Last updated: September 14th, 2026",
    style = "font-size: 12.5px; color: gray; margin-top: 10px; font-style: italic;"
  )
)
# FAQs
faq_data <- data.frame(
  question = c(
    "What is the difference between Scenario Modeling and Forecasting?",

    "How does this tool work?",

    "When should I use this tool?",

    "What data was used in this model?",

    "What are the main assumptions used in the model?",

    "What does the model not take into consideration?"
  ),

  answer = c(
    "Scenario modeling is meant to estimate outcomes under 'what if' scenarios, such as which public health interventions
    are made available and population uptake of available interventions. Scenarios might also explore uncertainty in the
    features of the disease (e.g., severe versus mild strains) and/or population (e.g., prevalence of risk factors).
    Scenario modeling often estimates outcomes over relatively long time periods, such as an entire respiratory season or
    even multiple years. In contrast, forecasting aims to predict what outcomes will occur in the near-term, generally based
    on the outcomes observed in the recent past and experiences in past seasons or outbreaks.",

    "This scenario planning tool uses a compartmental Susceptible-Exposed-Infected-Recovered (SEIR) model to simulate
    the spread of an infectious disease (in this case, RSV) in the population over time. Infected individuals face some
    risk of requiring hospital admission, ICU admission, and/or dying, which depends on age and immunization status.
    See the Technical Details tab for more information.",

    "This tool should be used for RSV scenario planning purposes. Use this tool to compare the impact of different
    immunization uptake scenarios on hospital admissions, ICU admissions, and deaths due to RSV to help inform policies
    and/or prioritize interventions. This tool cannot be used for real-time forecasting or predicting outcomes for a specific RSV season.",

    "The model used data from the MADMC Social Contact Survey, Minnesota Electronic Health Record Consortium (MNEHRC), and the MDH Minnesota Immunization Information Connection.
    Additionally, model parameters were derrived from published literature. The data from MNEHRC and MDH is not available for public access.",

    paste(
      "Population interactions that spread RSV vary by age and are estimated from the MADMC Social Contact Survey, which estimated age-stratified contact patterns for Minnesota and neighboring states.",
      "Populations also interact differently within and between IDEPC regions. The patterns of these interactions were estimated via model calibration.",
      "Regions were assumed to differ in demographics and uptake of immunizations, but not in the risk of hospitalization or death.",
      "The risk of hospital admission and ICU admission depend only on age group and immunization status.",
      "Deaths only occurred in cases who required hospital care and that the risk of dying was greater for requiring ICU care and increased with age.",
      "Immunizations impact the risk of becoming infected and the risk of being hospitalized. However, we assume that once an individual is hospitalized, their immunization status does not impact their length of stay or probability of death.",
      "The timing of immunization uptake was assumed to follow historical patterns.",
      "Immunity from immunization wanes over time, as observed in clinical trials. Immunity following infection is also assumed to wane.",
      "There was no RSV-infection-associated mortality outside of cases with healthcare utilization.",
      sep = "||"
    ),

    "The model does not take into consideration the following: outpatient visits, asymptomatic vs. symptomatic cases, different
    strains of RSV (A vs. B), or sociodemographic characteristics other than age and region."
  ),
  format = c("paragraph", "paragraph", "paragraph", "paragraph", "bullets", "paragraph"),
  stringsAsFactors = FALSE
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

  # Google Analytics Tag
  tags$head(
    tags$script(async = NA, src="https://www.googletagmanager.com/gtag/js?id=G-PFBN9X4SSW"),
    tags$script(HTML("
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-PFBN9X4SSW');
    "))
  ),

  # Title + Logo
  title = div(
    tags$img(src = "insignia.png", height = "30px", style = "margin-top: -5px; margin-right: 10px"),
    "Midwest EpiScenario: RSV"),

  header = app_styles,

  # About Tab
  tabPanel("About",
           fluidPage(
             h3("Midwest EpiScenario: RSV"),
             hr(),
             h4("Project Description"),
             p("The Midwest Analytics and Disease Modeling Center's (MADMC) Midwest EpiScenario Model for RSV is designed to support decision making around respiratory disease response by estimating statewide hospital admissions,
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
             # p("The", tags$strong("Chile Policy"), "is a strategy based on increasing monoclonal antibody uptake while holding maternal vaccination at the status quo levels to achieve a combined coverage of 94%. This is based off a policy Chile implemented to introduce universal monoclonal antibody administration."),
             hr(),

             h4("Instructions for Use - Results Tab"),
             p(tags$strong("1."), "Select the outcome you would like to see plotted. Options are RSV-associated Hospital Admissions, ICU Admissions, and Deaths in Minnesota."),
             p(tags$strong("2."), "Choose whether you would like to plot total values, incremental differences from status quo, or outcomes averted compared to the status quo."),
             p(tags$strong("3."), "Select the season severity: Typical or Severe. A typical season is based on the 2024-2025 RSV season, while a severe season represents an additional 20% increase in baseline transmission and age-specific probabilities of hospitalization."),
             p(tags$strong("4."), "Choose whether you would like figures depicting all age groups or specific age group results."),
             p(tags$strong("5."), "Select a region of interest or view results statewide."),
             p(tags$strong("6."), "Select different strategies to compare. As a note, Status Quo will be always selected as a baseline."),
             hr(),

             h4("Limitations"),
             p("The model does not follow individuals, but instead follows the population of Minnesota. The only characteristics that impact health outcomes are age and geographic region (Infectious Disease Epidemiology,
               Prevention and Control (IDEPC) regions). Incorporating additional stratifications and/or building an individual-level simulation model requires more data and likely would not substantially impact the validity of the model results."),
             p("The model does not consider contact reducing strategies (i.e., masking, social distancing, etc.) because in the context of RSV, universal masking or distancing policies would not be recommended. Masking
               policies may be implemented in healthcare facilities, but this model does not consider setting-specific scenarios."),
             p("The model does not estimate the number of outpatient visits nor does it validate overall case burden. There is substantial undertesting for RSV, especially in the outpatient setting and for cases that do
               not interact with the healthcare system. Therefore, it is difficult to estimate the true number of cases. Instead, the model is calibrated to hospital admissions (including ICU admissions), where testing occurs more commonly and input
               values can be adjusted based on RSV estimates reported in the literature."),
             hr(),
             footer_block

           )
  ), # end of About tab

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
                     "3. Select Strategies to compare against the Status Quo."
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


                 section_header("Scenarios"),
                 # Select Season
                 selectInput("selected_season_sev",
                             label = HTML("Select Season Severity <i id='season_help' class='fas fa-question-circle' style='color: #337ab7; cursor: help; margin-left: 5px;'></i>"),
                             choices = season_sev, selected = season_sev),
                 bsTooltip(id = "season_help", title = "Select the RSV season you would like to see results for. Typical is based on the 2024-2025 RSV season, while Severe represents an additional 20% increase in baseline transmission and age-specific probabilities of hospitalization.", placement = "right", trigger = "hover", options = list(container = "body")),

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
                             options = pickerOptions(maxOptions = 11, maxOptionsText = "Maximum of 11 strategies")),
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

  # Technical Details tab
  tabPanel("Technical Details",
           fluidPage(
             h3("Technical Details of Midwest EpiScenario"),
             hr(),
             h4("Model Description"),
             p("Midwest EpiScenario is a modeling platform designed to be easily adapted to emerging infectious disease threats, particularly respiratory illnesses. The model is a Susceptible-Exposed-Infected-Recovered model with additional health states for hospitalizations, ICU stays, and deaths."),
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
               tags$li("The healthcare module is responsible for hospital and ICU admissions.")
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

  tabPanel("FAQs",
           fluidPage(
             h3("Frequently Asked Questions"),
             hr(),
             uiOutput("faq_ui")
           )
  )
) # end navbar

# Server
wrap_title_text <- function(text, width = 45) {
  segments <- trimws(strsplit(text, "<br>")[[1]])
  wrapped_segments <- sapply(segments, function(seg) {
    paste(strwrap(seg, width = width), collapse = "<br>")
  })
  paste(wrapped_segments, collapse = "<br>")
}

server <- function(input, output, session) {

  # Color palette for figures
  base_colors <- c("#1B9E77", "#D95F02", "#7570B3")  # ColorBrewer "Dark2" — colorblind-friendly

  palette <- unlist(lapply(base_colors, function(col) {
    c(lighten(col, 0.4), col, darken(col, 0.3))
  }))

  palette <- c(palette, "#66A61E", "#E7298A")

  access_col_palette <- setNames(
    palette,
    c("Maternal Vaccination +10%", "Maternal Vaccination +20%", "Maternal Vaccination +30%",
      "Monoclonal Antibodies +10%", "Monoclonal Antibodies +20%", "Monoclonal Antibodies +30%",
      "Older Adult Vaccination +5%", "Older Adult Vaccination +15%", "Older Adult Vaccination +25%",
      "No Immunizations", "Status Quo")
    )

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
    if (input$display_opt %in% c("versus_sq", "incremental")) {
      if (selected_reg == "Statewide (All Regions)") {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- inc_age_diff_data[age_strat %in% input$selected_age_groups &
                                    season_sev == selected_sev &
                                    policy_name %in% selected_pol]
        } else {
          dt <- inc_nostrat_diff_data[season_sev == selected_sev &
                                        policy_name %in% selected_pol]
        }
      } else {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- inc_all_diff_data[age_strat %in% input$selected_age_groups &
                                    season_sev == selected_sev &
                                    policy_name %in% selected_pol &
                                    par_region == selected_reg]
        } else {
          dt <- inc_reg_diff_data[season_sev == selected_sev &
                                    policy_name %in% selected_pol &
                                    par_region == selected_reg]
        }
      }
    } else {
      if (selected_reg == "Statewide (All Regions)") {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- inc_age_data[age_strat %in% input$selected_age_groups &
                               season_sev == selected_sev &
                               policy_name %in% selected_pol]
        } else {
          dt <- inc_nostrat_data[season_sev == selected_sev &
                                   policy_name %in% selected_pol]
        }
      } else {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- inc_all_data[age_strat %in% input$selected_age_groups &
                               season_sev == selected_sev &
                               policy_name %in% selected_pol &
                               par_region == selected_reg]
        } else {
          dt <- inc_reg_data[season_sev == selected_sev &
                               policy_name %in% selected_pol &
                               par_region == selected_reg]
        }
      }
    }


    # Select proper intervals
    out_col <- input$selected_outcome
    lower_col <- paste0(out_col, "_lower")
    upper_col <- paste0(out_col, "_upper")

    agg_dt <- setnames(dt, c(out_col, lower_col, upper_col),
                       c("daily_val", "daily_lower", "daily_upper"))

    # Relevel
    agg_dt[, policy_name := factor(policy_name, levels = c("Status Quo", "No Immunizations",
                                                           "Maternal Vaccination +10%", "Maternal Vaccination +20%", "Maternal Vaccination +30%",
                                                           "Monoclonal Antibodies +10%", "Monoclonal Antibodies +20%", "Monoclonal Antibodies +30%",
                                                           "Older Adult Vaccination +5%", "Older Adult Vaccination +15%", "Older Adult Vaccination +25%"))]

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

    if (input$display_opt %in% c("versus_sq", "incremental")) {
      if (selected_reg == "Statewide (All Regions)") {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- cum_age_diff_data[age_strat %in% input$selected_age_groups &
                                    season_sev == selected_sev &
                                    policy_name %in% selected_pol]
        } else {
          dt <- cum_nostrat_diff_data[season_sev == selected_sev &
                                        policy_name %in% selected_pol]
        }
      } else {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- cum_all_diff_data[age_strat %in% input$selected_age_groups &
                                    season_sev == selected_sev &
                                    policy_name %in% selected_pol &
                                    par_region == selected_reg]
        } else {
          dt <- cum_reg_diff_data[season_sev == selected_sev &
                                    policy_name %in% selected_pol &
                                    par_region == selected_reg]
        }
      }
    } else {
      if (selected_reg == "Statewide (All Regions)") {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- cum_age_data[age_strat %in% input$selected_age_groups &
                               season_sev == selected_sev &
                               policy_name %in% selected_pol]
        } else {
          dt <- cum_nostrat_data[season_sev == selected_sev &
                                   policy_name %in% selected_pol]
        }
      } else {
        if (input$age_view_mode == "individual") {
          req(input$selected_age_groups)
          dt <- cum_all_data[age_strat %in% input$selected_age_groups &
                               season_sev == selected_sev &
                               policy_name %in% selected_pol &
                               par_region == selected_reg]
        } else {
          dt <- cum_reg_data[season_sev == selected_sev &
                               policy_name %in% selected_pol &
                               par_region == selected_reg]
        }
      }
    }

    # Select proper intervals
    out_col <- input$selected_outcome
    lower_col <- paste0(out_col, "_lower")
    upper_col <- paste0(out_col, "_upper")

    agg_dt <- setnames(dt, c(out_col, lower_col, upper_col),
                       c("cum_val", "cum_lower", "cum_upper"))

    agg_dt[, policy_name := factor(policy_name, levels = c("Status Quo", "No Immunizations",
                                                           "Maternal Vaccination +10%", "Maternal Vaccination +20%", "Maternal Vaccination +30%",
                                                           "Monoclonal Antibodies +10%", "Monoclonal Antibodies +20%", "Monoclonal Antibodies +30%",
                                                           "Older Adult Vaccination +5%", "Older Adult Vaccination +15%", "Older Adult Vaccination +25%"))]

    return(agg_dt)
  })

  # Plotting Incidence
  plot_data_incidence <- reactive({
    req(nrow(base_inc_data()) > 0)
    dt <- copy(base_inc_data())
    if (input$display_opt %in% c("versus_sq", "incremental")) {
      if (input$display_opt == "versus_sq") {
        dt[, c("daily_val", "daily_lower", "daily_upper") :=
             lapply(.SD, function(x) x * -1),
           .SDcols = c("daily_val", "daily_lower", "daily_upper")]
      }
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
      if (input$display_opt == "versus_sq") {
        dt[, c("cum_val", "cum_lower", "cum_upper") :=
             lapply(.SD, function(x) x * -1),
           .SDcols = c("cum_val", "cum_lower", "cum_upper")]
      }
      dt <- dt[!is.na(cum_val)]
    }
    return(dt)
  })

  # Plot Totals
  total_events_data <- reactive({
    group_cols <- "policy_name"
    if(input$age_view_mode == "individual") group_cols <- c("policy_name", "age_strat")

    dt <- plot_data_cumulative()[date_scale == max(date_scale)]
    dt <- setnames(dt, c("cum_val", "cum_lower", "cum_upper"),
                   c("total_val", "total_lower", "total_upper"))
    return(dt)
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
      sel_lab
    }

    region_text <- ifelse(input$selected_region == "Statewide (All Regions)",
                          "", paste0(" - ", input$selected_region))

    title_text <-if (input$age_view_mode == "individual") {
      if (input$display_opt == "versus_sq" | input$display_opt == "incremental") {
        paste("Incidence:", y_label_text, "Compared to Status Quo", "<br>", "By Age", region_text)
      } else {
        paste("Incidence:", y_label_text, "<br>", "By Age", region_text)
      }
    } else {
      if (input$display_opt == "versus_sq" | input$display_opt == "incremental") {
        paste("Incidence:", y_label_text, "Compared to Status Quo", region_text)
      } else {
        paste("Incidence:", y_label_text, region_text)
      }
    }

    plot_df <- copy(plot_data_incidence())
    plot_df[, txt := paste0("<b>Date:</b> ", format(date_scale, "%b %d, %Y"), "<br>",
                            "<b>Strategy:</b> ", policy_name, "<br>",
                            "<b>Outcome:</b> ", format(round(daily_val,0), big.mark=","))]

    if(input$show_intervals) {
      plot_df[, txt := paste0(txt, "<br><b>Interval:</b> [", format(round(daily_lower,0), big.mark=","), " - ", format(round(daily_upper,0), big.mark=","), "]")]
    }

    wrapped_title <- wrap_title_text(title_text, width = 45)

    p <- ggplot(plot_df, aes(x = date_scale, y = daily_val, color = policy_name,
                             group = policy_name, fill = policy_name, text = txt)) +
      geom_line(size = 1.2) +
      scale_color_manual(values = access_col_palette, name = "Strategy",
                         labels = function(x) sapply(x, function(l) paste(strwrap(l, width = 80), collapse = "\n"))) +
      {if(input$show_intervals) geom_ribbon(aes(ymin = daily_lower, ymax = daily_upper, fill = policy_name), alpha = 0.5, color = NA, show.legend = FALSE)} +
      {if(input$show_intervals) scale_fill_manual(values = access_col_palette, guide = "none")} +
      scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
      {if(input$age_view_mode == "individual") facet_wrap(~age_strat, ncol = 2, scales = "free_y")} +
      scale_y_continuous(
        breaks = function(x) { b <- pretty(x); b[b %% 1 == 0] },
        limits = function(x) c(min(0, x, na.rm = TRUE), max(1, x, na.rm = TRUE))) +
      labs(title = wrapped_title, y = y_label_text, x = NULL) +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(color = "#003865", face = "bold",
                                      size = 18, hjust = 0.5),
            axis.text.x = element_text(angle = 45, hjust = 1),
            axis.text.y = element_text(face = "bold", size = 12, color = "black"))

    return(p)
  })

  # Creating incidence plot
  output$incidencePlot <- renderPlotly({
    p <- incidence_plot_obj()
    n_title_lines <- lengths(regmatches(p$labels$title, gregexpr("<br>", p$labels$title))) + 1
    top_margin <- 60 + (n_title_lines * 30)
    gp <- ggplotly(p, tooltip = "text") %>%
      layout(
        title = list(y = 1, yanchor = "top", yref = "container", pad = list(t = 30)),
        margin = list(t = top_margin)) %>%
      config(displayModeBar = FALSE)

    for (i in seq_along(gp$x$data)) {
      trace <- gp$x$data[[i]]
      # Ribbon traces usually show up with mode "none" or fill "toself"/"tonexty"
      if (!is.null(trace$fill) && trace$fill %in% c("toself", "tonexty")) {
        gp$x$data[[i]]$showlegend <- FALSE
      }
    }
    gp
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
      paste("Cumulative Weekly", sel_lab)
    } else {
      paste("Weekly", sel_lab)
    }

    region_text <- ifelse(input$selected_region == "Statewide (All Regions)",
                          "", paste0(" - ", input$selected_region))

    title_text <-if (input$age_view_mode == "individual") {
      if (input$display_opt == "versus_sq" | input$display_opt == "incremental") {
        paste("Cumulative:", y_label_text, "Compared to Status Quo", "<br>", "By Age", region_text)
      } else {
        paste("Cumulative:", y_label_text, "<br>", "By Age", region_text)
      }
    } else {
      if (input$display_opt == "versus_sq" | input$display_opt == "incremental") {
        paste("Cumulative:", y_label_text, "Compared to Status Quo", region_text)
      } else {
        paste("Cumulative:", y_label_text, region_text)
      }
    }

    plot_df <- copy(plot_data_cumulative())
    plot_df[, txt := paste0("<b>Date:</b> ", format(date_scale, "%b %d, %Y"), "<br>",
                            "<b>Strategy:</b> ", policy_name, "<br>",
                            "<b>Outcome:</b> ", format(round(cum_val,0), big.mark=","))]

    if(input$show_intervals) {
      plot_df[, txt := paste0(txt, "<br><b>Interval:</b> [", format(round(cum_lower,0), big.mark=","), " - ", format(round(cum_upper,0), big.mark=","), "]")]
    }

    wrapped_title <- wrap_title_text(title_text, width = 45)

    p <- ggplot(plot_df, aes(x = date_scale, y = cum_val, color = policy_name,
                             group = policy_name, fill = policy_name, text = txt)) +
      geom_line(size = 1.2) +
      {if(input$show_intervals) geom_ribbon(aes(ymin = cum_lower, ymax = cum_upper, fill = policy_name), alpha = 0.5, color = NA, show.legend = FALSE)} +
      scale_color_manual(values = access_col_palette, name = "Strategy",
                         labels = function(x) sapply(x, function(l) paste(strwrap(l, width = 80), collapse = "\n"))) +
      {if(input$show_intervals) scale_fill_manual(values = access_col_palette, guide = "none")} +
      scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
      {if(input$age_view_mode == "individual") facet_wrap(~age_strat, ncol = 2, scales = "free_y")} +
      scale_y_continuous(
        breaks = function(x) { b <- pretty(x); b[b %% 1 == 0] },
        limits = function(x) c(min(0, x, na.rm = TRUE), max(1, x, na.rm = TRUE))) +
      labs(title = wrapped_title, y = y_label_text, x = NULL) +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(color = "#003865", face = "bold",
                                      size = 18, hjust = 0.5),
            axis.text.x = element_text(angle = 45, hjust = 1),
            axis.text.y = element_text(face = "bold", size = 12, color = "black"))

    return(p)
  })

  # Creating cumulative plot
  output$cumulativePlot <- renderPlotly({
    p <- cumulative_plot_obj()
    n_title_lines <- lengths(regmatches(p$labels$title, gregexpr("<br>", p$labels$title))) + 1
    top_margin <- 60 + (n_title_lines * 30)
    gp <- ggplotly(p, tooltip = "text") %>%
      layout(
        title = list(y = 1, yanchor = "top", yref = "container", pad = list(t = 30)),
        margin = list(t = top_margin)) %>%
      config(displayModeBar = FALSE)
    for (i in seq_along(gp$x$data)) {
      trace <- gp$x$data[[i]]
      # Ribbon traces usually show up with mode "none" or fill "toself"/"tonexty"
      if (!is.null(trace$fill) && trace$fill %in% c("toself", "tonexty")) {
        gp$x$data[[i]]$showlegend <- FALSE
      }
    }
    gp
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
      sel_lab
    }

    region_text <- ifelse(input$selected_region == "Statewide (All Regions)",
                          "", paste0(" - ", input$selected_region))

    title_text <-if (input$age_view_mode == "individual") {
      if (input$display_opt == "versus_sq" | input$display_opt == "incremental") {
        paste("Season Totals:", y_label_text, "Compared to Status Quo", "<br>", "By Age", region_text)
      } else {
        paste("Season Totals:", y_label_text, "<br>", "By Age", region_text)
      }
    } else {
      if (input$display_opt == "versus_sq" | input$display_opt == "incremental") {
        paste("Season Totals:", y_label_text, "Compared to Status Quo", region_text)
      } else {
        paste("Season Totals:", y_label_text, region_text)
      }
    }

    wrapped_title <- wrap_title_text(title_text, width = 45)

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
        plot_df[, label_y  := ifelse(total_val >= 0, total_upper + y_offset, total_lower - y_offset)]
      } else {
        plot_df[, y_offset := ifelse(total_val >= 0, max(abs(total_val), na.rm = TRUE) * 0.05, max(abs(total_val), na.rm = TRUE) * 0.15)]
        plot_df[, label_y  := ifelse(total_val >= 0, total_val + y_offset, total_val - y_offset)]
      }
    }

    p <- ggplot(plot_df, aes(x = policy_name, y = total_val, fill = policy_name, text = txt)) +
      geom_col(width = 0.7)
    # Add text labels only when NOT showing sensitivity intervals
    if(input$age_view_mode != "individual") {
      label_size <- ifelse(length(input$selected_policies) <= 6, 5, 4)
    } else {
      label_size <- ifelse(length(input$selected_policies) <= 3, 5,
                           ifelse(length(input$selected_policies) <= 5, 4,
                                  ifelse(length(input$selected_policies) <= 7, 3, 2)))

    }

    if(!input$show_intervals) {
      p <- p + geom_text(
        aes(
          y = label_y,
          label = format(round(total_val, 0), big.mark=",")
        ),
        size = label_size,
        color = "black"
      )
    }

    p <- p +
      scale_fill_manual(values = access_col_palette,
                        labels = function(x) sapply(x, function(l) paste(strwrap(l, width = 80), collapse = "\n"))) +
      {if(input$age_view_mode == "individual") facet_wrap(~age_strat, ncol = 2, scales = "free_y")} +
      scale_y_continuous(
        expand = expansion(mult = 0.15),
        breaks = function(x) { b <- pretty(x); b[b %% 1 == 0] },
        limits = function(x) c(min(0, x, na.rm = TRUE), max(1, x, na.rm = TRUE))) +
      labs(title = wrapped_title, y = y_label_text, x = NULL, fill = "Strategy") +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(color = "#003865", face = "bold",
                                      size = 18, hjust = 0.5),
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
    p <- bar_plot_obj()
    n_title_lines <- lengths(regmatches(p$labels$title, gregexpr("<br>", p$labels$title))) + 1
    top_margin <- 60 + (n_title_lines * 30)
    ggplotly(p, tooltip = "text") %>%
      layout(
        title = list(y = 1, yanchor = "top", yref = "container", pad = list(t = 30)),
        margin = list(t = top_margin)) %>%
      config(displayModeBar = FALSE)
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
      list(w = "100%", h = "750px")
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
  faq_panels <- lapply(seq_len(nrow(faq_data)), function(i) {
    q <- faq_data$question[i]
    a <- faq_data$answer[i]
    fmt <- faq_data$format[i]

    answer_html <- if (fmt == "bullets") {
      items <- strsplit(a, "\\|\\|")[[1]]
      tags$ul(lapply(items, tags$li))
    } else {
      tags$p(a)
    }

    bsCollapsePanel(
      title = q,
      style = "info",
      answer_html
    )
  })

  do.call(bsCollapse, c(list(id = "faq_collapse", multiple = FALSE), faq_panels))
})

}

shinyApp(ui = ui, server = server)

