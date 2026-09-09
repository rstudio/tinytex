library(testit)
test_pkg('tinytex', 'test-cran')
if (!is.na(Sys.getenv('CI', NA)) && tinytex:::tlmgr_available())
  test_pkg('tinytex', 'test-ci')
