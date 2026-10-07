# Helpers for tests that render whole documents

# knitr::raw_block() warns when pandoc is unavailable
skip_if_no_pandoc <- function() {
  testthat::skip_if_not_installed("rmarkdown")
  testthat::skip_if_not(rmarkdown::pandoc_available("2.0.0"), "pandoc >= 2.0.0 is not available")
}

skip_if_no_quarto <- function() {
  testthat::skip_on_cran()
  testthat::skip_if(!nzchar(Sys.which("quarto")), "the quarto binary is not on the PATH")
  testthat::skip_if_not_installed("quarto")
}

# The line that loads ggtibble in the separate R process Quarto renders with:
# this source tree when the tests run from it (devtools::test()), so that the
# render tests exercise the code under test, and the installed package
# otherwise (R CMD check)
quarto_load_ggtibble_line <- function() {
  ns_path <- getNamespaceInfo("ggtibble", "path")
  if (file.exists(file.path(ns_path, "R", "figure_emit.R"))) {
    sprintf("pkgload::load_all(%s, quiet = TRUE)", deparse(normalizePath(ns_path, winslash = "/")))
  } else {
    "library(ggtibble)"
  }
}
