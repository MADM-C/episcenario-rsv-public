# styles.R

app_styles <- tags$head(
  # 1. Bootstrap Select Fix
  tags$style(HTML(".bootstrap-select .dropdown-menu li.selected a span.check-mark { color: #337ab7 !important;}")),

  # 2. Main Custom CSS
  tags$style(HTML("
    /* Sidebar */
    .well {
      background-color: #fcfcfc;
      border: none;
      border-top: 5px solid #003865;
      box-shadow: 0 4px 8px 0 rgba(0,0,0,0.1);
    }

    /* Input Label */
    .control-label {
      color: #003865;
      font-weight: 700;
    }

    .nav-tabs > li > a {
      color: #003865;
    }

    /* Help Icons */
    .fa-question-circle {
      color: #008CA8 !important;
    }

    /* FAQs & Panels */
    .panel-info {
      border-color: #008CA8;
    }

    .panel-info > .panel-heading {
      color: #003865;
      background-color: #E0F2F5;
      border-color: #008CA8;
    }

    .panel-info > .panel-heading + .panel-collapse > .panel-body {
      border-top-color: #008CA8;
    }

    .panel-info > .panel-heading a:hover {
      color: #008CA8;
      text-decoration: none;
    }

    /* h3 headers */
    h3 {
      color: #003865;
      font-weight: bold;
      margin-bottom: 20px;
    }

    /* h4 headers */
    h4 {
      color: #003865;
      background-color: #E0F2F5;
      padding: 10px 15px;
      border-left: 5px solid #008CA8;
      border-radius: 0 4px 4px 0;
      margin-top: 30px;
      margin-bottom: 15px;
      font-weight: bold;
    }

    hr {
      border-top: 1px solid #008CA8;
      opacity: 0.5;
    }

    /* Title Bar */
    .navbar-default {
      background-color: #E0F2F5;
      border-color: #003865;
    }
    .navbar-default .navbar-brand {
      color: #2C3E50;
    }
    .navbar-default .navbar-brand:hover {
      color: #2C3E50;
    }

    .navbar-default .navbar-nav > li > a {
      color: #2C3E50;
    }

    .navbar-default .navbar-nav > li > a:hover,
    .navbar-default .navbar-nav > li > a:focus {
      background-color: #008CA8;
      color: white;
    }

    .navbar-default .navbar-nav > .active > a,
    .navbar-default .navbar-nav > .active > a:hover,
    .navbar-default .navbar-nav > .active > a:focus {
      background-color: #008CA8;
      color: white;
      font-weight: bold;
    }
  "))
)
