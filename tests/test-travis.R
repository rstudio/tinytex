# run tests on Travis (these tests depend on TeX Live)
if (!is.na(Sys.getenv('CI', NA))) testit::test_pkg('tinytex', 'test-travis')
