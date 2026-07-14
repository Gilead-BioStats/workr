strFilterPath <- test_path("_fixtures", "workflow", "normal", "02_Filter")

lWFToFilter <- MakeWorkflowList(
  strPath = test_path("_fixtures", "workflow", "normal", "02_Filter")
)

lWFToFilterAll <- MakeWorkflowList(
  strPath = test_path("_fixtures", "workflow", "normal", "02_Filter"),
  bActiveOnly = FALSE
)
