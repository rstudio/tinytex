library(testit)

assert("Bib inference", {
  current_wd = getwd()
  on.exit(setwd(current_wd), add = TRUE)
  setwd("bib-inference")
	first_res = is.null(pdflatex("backend-bibtex.tex")) &&
	if (nzchar(Sys.which('pdftotext'))) {
	  system('pdftotext -layout backend-bibtex.pdf')
	  backend_bibtex_text = readLines('backend-bibtex.txt', n = 8L, warn = FALSE)
	  backend_bibtex_expected = readLines('backend-bibtex-expected.txt', n = 8L, warn = FALSE)
	  setwd(current_wd)
	  identical(backend_bibtex_text,
	            backend_bibtex_expected)
	} else {
	  TRUE  # skip test
	}
})
