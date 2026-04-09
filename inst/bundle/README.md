# workr Demo App Deployment

To deploy the demo app to shinyapps.io from this repository, use the bundle entrypoint at `inst/bundle/app.R`. It loads the local package source with `pkgload`, so the deployed app runs the current checkout instead of requiring a separate installed copy of {workr}. Keep `appDir = "."` so `rsconnect` uploads the full package source, and point `appPrimaryDoc` at the bundled app file.

```r
install.packages(c("pkgload", "rsconnect", "shiny", "yaml"))

rsconnect::setAccountInfo(
  name = "<account>",
  token = "<token>",
  secret = "<secret>"
)

source("inst/bundle/deploy.R")
deploy_demo_app(app_name = "workr-demoapp")
```

If you prefer not to source the helper, the equivalent direct call is:

```r
rsconnect::deployApp(
  appDir = ".",
  appPrimaryDoc = "inst/bundle/app.R",
  appName = "workr-demoapp"
)
```

After deployment, shinyapps.io will start the app by executing `inst/bundle/app.R` from the source bundle.