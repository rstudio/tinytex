# run tests on CI servers (these tests depend on TeX Live)
if (!is.na(Sys.getenv('CI', NA)) && tinytex:::tlmgr_available()) testit::test_pkg('tinytex', 'test-ci')
