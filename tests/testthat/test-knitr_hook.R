# Helper to build a small ggtibble for tests ####
make_test_ggtibble <- function(caption = "Cap {A}") {
  d_plot <- data.frame(A = 1:2, B = 3:4)
  ggtibble(
    d_plot,
    ggplot2::aes(x = B, y = B),
    outercols = "A",
    caption = caption,
    labs = list(x = "{A}")
  ) +
    ggplot2::geom_point()
}

# extract_ggtibble_name ####

test_that("extract_ggtibble_name returns the symbol itself", {
  expect_equal(extract_ggtibble_name(quote(my_obj)), "my_obj")
})

test_that("extract_ggtibble_name strips function names (tar_read)", {
  expect_equal(extract_ggtibble_name(quote(tar_read(my_obj))), "my_obj")
  # Use parse() rather than a quoted namespace reference so R CMD check does
  # not see this as a static dependency on 'targets'.
  expect_equal(
    extract_ggtibble_name(parse(text = "targets::tar_read(my_obj)")[[1]]),
    "my_obj"
  )
})

test_that("extract_ggtibble_name walks down $ to the field name", {
  expect_equal(extract_ggtibble_name(quote(my_list$obj)), "obj")
  expect_equal(extract_ggtibble_name(quote(outer$middle$leaf)), "leaf")
})

test_that("extract_ggtibble_name walks down [[ to the index name", {
  expect_equal(extract_ggtibble_name(quote(my_list[["obj"]])), "obj")
})

test_that("extract_ggtibble_name falls through for numeric [[]] indices", {
  # When [[i]] is numeric, we cannot use it as a label so fall through to
  # all.vars(), which returns the container name.
  expect_equal(extract_ggtibble_name(quote(my_list[[1L]])), "my_list")
})

test_that("extract_ggtibble_name uses a hashed fallback when no vars exist", {
  result <- extract_ggtibble_name(quote(get("my_obj")))
  expect_match(result, "^ggtibble.[a-f0-9]{8}$")
})

test_that("extract_ggtibble_name picks first var from pipe expressions", {
  expect_equal(
    extract_ggtibble_name(quote(my_obj |> dplyr::filter(x > 1))),
    "my_obj"
  )
})

test_that("extract_ggtibble_name sanitises via make.names()", {
  # `make.names` converts dashes and spaces to dots; this is what we want
  # because chunk labels accept dots and we just need a syntactically valid name.
  expect_equal(extract_ggtibble_name(quote(`bad-name`)), make.names("bad-name"))
})

# helpers ####

test_that("is_unnamed_label", {
  expect_true(is_unnamed_label(NULL))
  expect_true(is_unnamed_label("unnamed-chunk-1"))
  expect_true(is_unnamed_label("unnamed-chunk-42"))
  expect_false(is_unnamed_label("my_chunk"))
  expect_false(is_unnamed_label("fig-my_obj"))
})

test_that("is_empty_code", {
  expect_true(is_empty_code(character(0)))
  expect_true(is_empty_code(""))
  expect_true(is_empty_code(c("", "  ", "\t")))
  expect_false(is_empty_code("knit_print(x)"))
  expect_false(is_empty_code(c("# comment", "knit_print(x)")))
})

test_that("is_quarto_render reads QUARTO_VERSION", {
  withr::with_envvar(c(QUARTO_VERSION = ""), {
    expect_false(is_quarto_render())
  })
  withr::with_envvar(c(QUARTO_VERSION = "1.5.0"), {
    expect_true(is_quarto_render())
  })
})

test_that("deduplicate_label suffixes repeats", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  expect_equal(deduplicate_label("foo"), "foo")
  expect_equal(deduplicate_label("foo"), "foo-2")
  expect_equal(deduplicate_label("foo"), "foo-3")
  expect_equal(deduplicate_label("bar"), "bar")
})

test_that("reset_ggtibble_caches clears both caches", {
  reset_ggtibble_caches()
  assign("a", 1, envir = .ggtibble_chunk_cache)
  assign("b", 1L, envir = .ggtibble_label_cache)
  reset_ggtibble_caches()
  expect_length(ls(.ggtibble_chunk_cache), 0)
  expect_length(ls(.ggtibble_label_cache), 0)
})

# process_ggtibble_chunk_options ####

test_that("NULL / FALSE / empty option returns options unchanged", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  expect_identical(
    process_ggtibble_chunk_options(list(), envir = emptyenv()),
    list()
  )
  expect_identical(
    process_ggtibble_chunk_options(list(ggtibble = FALSE), envir = emptyenv()),
    list(ggtibble = FALSE)
  )
  expect_identical(
    process_ggtibble_chunk_options(list(ggtibble = ""), envir = emptyenv()),
    list(ggtibble = "")
  )
  expect_identical(
    process_ggtibble_chunk_options(list(ggtibble = c("a", "b")), envir = emptyenv()),
    list(ggtibble = c("a", "b"))
  )
})

test_that("string form: sets label, fig.cap, and code", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()
  envir <- new.env()
  envir$my_obj <- my_obj

  result <- process_ggtibble_chunk_options(
    list(ggtibble = "my_obj", label = "unnamed-chunk-1"),
    envir = envir
  )

  expect_equal(result$label, "my_obj")
  expect_equal(result$fig.cap, c("Cap 1", "Cap 2"))
  expect_match(result$code, "knitr::knit_print")
  expect_match(result$code, '\\.ggtibble_chunk_cache')
  expect_match(result$code, '"my_obj"')
  # And the cache actually contains the object under the key
  expect_true(exists("my_obj", envir = .ggtibble_chunk_cache, inherits = FALSE))
  expect_s3_class(get("my_obj", envir = .ggtibble_chunk_cache), "ggtibble")
})

test_that("string form with tar_read style: label is the inner symbol and the call is evaluated only once", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()
  envir <- new.env()
  envir$my_obj <- my_obj
  # Counting stub for tar_read so we can assert single evaluation
  envir$tar_read_calls <- 0L
  envir$tar_read <- function(x) {
    envir$tar_read_calls <- envir$tar_read_calls + 1L
    x
  }

  result <- process_ggtibble_chunk_options(
    list(ggtibble = "tar_read(my_obj)", label = "unnamed-chunk-1"),
    envir = envir
  )

  expect_equal(result$label, "my_obj")
  # The injected code reads from the cache rather than re-calling tar_read
  expect_false(grepl("tar_read", result$code, fixed = TRUE))
  expect_match(result$code, "ggtibble_chunk_cache", fixed = TRUE)
  expect_true(exists("my_obj", envir = .ggtibble_chunk_cache, inherits = FALSE))
  # tar_read was called exactly once (during caption extraction)
  expect_equal(envir$tar_read_calls, 1L)
})

test_that("string form: user-set label is preserved", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()
  envir <- new.env()
  envir$my_obj <- my_obj

  result <- process_ggtibble_chunk_options(
    list(ggtibble = "my_obj", label = "explicit_label"),
    envir = envir
  )
  expect_equal(result$label, "explicit_label")
})

test_that("string form: user-set fig.cap is preserved", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()
  envir <- new.env()
  envir$my_obj <- my_obj

  result <- process_ggtibble_chunk_options(
    list(ggtibble = "my_obj", label = "unnamed-chunk-1", fig.cap = "Custom"),
    envir = envir
  )
  expect_equal(result$fig.cap, "Custom")
})

test_that("string form: non-empty chunk body is preserved", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()
  envir <- new.env()
  envir$my_obj <- my_obj

  result <- process_ggtibble_chunk_options(
    list(
      ggtibble = "my_obj",
      label = "unnamed-chunk-1",
      code = c("cat('hello')")
    ),
    envir = envir
  )
  expect_equal(result$code, c("cat('hello')"))
})

test_that("object form: sets fig.cap and code but does not override label", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()

  result <- process_ggtibble_chunk_options(
    list(ggtibble = my_obj, label = "unnamed-chunk-1"),
    envir = emptyenv()
  )

  # No name extraction from objects, so the unnamed-chunk-1 label is retained
  # for cache_key purposes.
  expect_equal(result$label, "unnamed-chunk-1")
  expect_equal(result$fig.cap, c("Cap 1", "Cap 2"))
  expect_match(result$code, "knitr::knit_print")
  expect_true(exists("unnamed-chunk-1", envir = .ggtibble_chunk_cache, inherits = FALSE))
})

test_that("invalid R code in string raises informative error", {
  expect_error(
    process_ggtibble_chunk_options(
      list(ggtibble = "this is not valid R ("),
      envir = emptyenv()
    ),
    regexp = "Chunk option `ggtibble` is not valid R code",
    fixed = TRUE
  )
})

test_that("non-ggtibble eval result raises informative error", {
  envir <- new.env()
  envir$not_a_ggtibble <- 42L
  expect_error(
    process_ggtibble_chunk_options(
      list(ggtibble = "not_a_ggtibble"),
      envir = envir
    ),
    regexp = "did not evaluate to a `ggtibble` object",
    fixed = TRUE
  )
})

test_that("wrong type raises informative error", {
  expect_error(
    process_ggtibble_chunk_options(list(ggtibble = 42L), envir = emptyenv()),
    regexp = "must be a character string or a `ggtibble` object",
    fixed = TRUE
  )
})

# Quarto-mode behaviour ####

test_that("Quarto: label is prefixed with fig-", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()
  envir <- new.env()
  envir$my_obj <- my_obj

  withr::with_envvar(c(QUARTO_VERSION = "1.5.0"), {
    result <- process_ggtibble_chunk_options(
      list(ggtibble = "my_obj", label = "unnamed-chunk-1"),
      envir = envir
    )
  })
  expect_equal(result$label, "fig-my_obj")
})

test_that("Quarto: multi-caption uses fig.subcap, single uses fig.cap", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()  # two captions
  envir <- new.env()
  envir$my_obj <- my_obj

  withr::with_envvar(c(QUARTO_VERSION = "1.5.0"), {
    result <- process_ggtibble_chunk_options(
      list(ggtibble = "my_obj", label = "unnamed-chunk-1"),
      envir = envir
    )
  })
  expect_equal(result$fig.subcap, c("Cap 1", "Cap 2"))
  expect_equal(result$fig.cap, "")
})

test_that("Quarto: single-caption ggtibble still uses fig.cap (no fig.subcap)", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  single_data <- data.frame(A = 1, B = 2)
  single_obj <- ggtibble(single_data, caption = "Only one")
  envir <- new.env()
  envir$single_obj <- single_obj

  withr::with_envvar(c(QUARTO_VERSION = "1.5.0"), {
    result <- process_ggtibble_chunk_options(
      list(ggtibble = "single_obj", label = "unnamed-chunk-1"),
      envir = envir
    )
  })
  expect_null(result$fig.subcap)
  expect_equal(result$fig.cap, "Only one")
})

# Duplicate-label handling ####

test_that("two chunks with the same string form get distinct labels", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  my_obj <- make_test_ggtibble()
  envir <- new.env()
  envir$my_obj <- my_obj

  r1 <- process_ggtibble_chunk_options(
    list(ggtibble = "my_obj", label = "unnamed-chunk-1"),
    envir = envir
  )
  r2 <- process_ggtibble_chunk_options(
    list(ggtibble = "my_obj", label = "unnamed-chunk-2"),
    envir = envir
  )
  expect_equal(r1$label, "my_obj")
  expect_equal(r2$label, "my_obj-2")
  # And each is cached under its final label
  expect_true(exists("my_obj", envir = .ggtibble_chunk_cache, inherits = FALSE))
  expect_true(exists("my_obj-2", envir = .ggtibble_chunk_cache, inherits = FALSE))
})

# Hook registration ####

test_that("opts_hook is registered on package load", {
  expect_true("ggtibble" %in% names(knitr::opts_hooks$get()))
  expect_identical(knitr::opts_hooks$get("ggtibble"), ggtibble_opts_hook)
})

# Integration: knitr::knit on text (Rmarkdown path) ####

test_that("knitr::knit honors the ggtibble chunk option (string form)", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  # Make sure we're NOT pretending to be Quarto for this test
  withr::local_envvar(c(QUARTO_VERSION = ""))

  knit_env <- new.env(parent = globalenv())
  knit_env$my_plots <- make_test_ggtibble()

  rmd <- paste(
    "```{r ggtibble=\"my_plots\"}",
    "```",
    "",
    sep = "\n"
  )

  out <- knitr::knit(text = rmd, envir = knit_env, quiet = TRUE)
  # Two figures should be produced, using the auto-derived "my_plots" label.
  expect_match(out, "my_plots-1", fixed = TRUE)
  expect_match(out, "my_plots-2", fixed = TRUE)
  # The cache-injected knit_print code is the only chunk source rendered.
  expect_match(out, "ggtibble_chunk_cache", fixed = TRUE)
})

test_that("knitr::knit honors the ggtibble chunk option (object form)", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))

  knit_env <- new.env(parent = globalenv())
  knit_env$my_plots <- make_test_ggtibble()

  rmd <- paste(
    "```{r my_label, ggtibble=my_plots}",
    "```",
    "",
    sep = "\n"
  )

  out <- knitr::knit(text = rmd, envir = knit_env, quiet = TRUE)
  # Object form retains the user-provided label "my_label" rather than
  # auto-deriving from the symbol name.
  expect_match(out, "my_label-1", fixed = TRUE)
  expect_match(out, "my_label-2", fixed = TRUE)
})

test_that("knitr::knit preserves explicit chunk body alongside ggtibble option", {
  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())
  withr::local_envvar(c(QUARTO_VERSION = ""))

  knit_env <- new.env(parent = globalenv())
  knit_env$my_plots <- make_test_ggtibble()

  rmd <- paste(
    "```{r ggtibble=\"my_plots\"}",
    "cat('USER-CODE-MARKER')",
    "```",
    "",
    sep = "\n"
  )

  out <- knitr::knit(text = rmd, envir = knit_env, quiet = TRUE)
  # User's code ran, and the auto fig.cap / label setup did not clobber it.
  expect_match(out, "USER-CODE-MARKER", fixed = TRUE)
  expect_false(grepl("ggtibble_chunk_cache", out, fixed = TRUE))
})

# Integration: Quarto rendering ####

test_that("Quarto renders a ggtibble chunk with a cross-referenceable figure", {
  testthat::skip_on_cran()
  testthat::skip_if(Sys.which("quarto") == "")
  testthat::skip_if_not_installed("quarto")

  reset_ggtibble_caches()
  withr::defer(reset_ggtibble_caches())

  qmd <- paste(
    "---",
    "title: Quarto ggtibble hook test",
    "format: html",
    "---",
    "",
    "```{r}",
    "#| include: false",
    "library(ggtibble)",
    "library(ggplot2)",
    "my_plots <- ggtibble(",
    "  data.frame(A = 1:2, B = 3:4),",
    "  aes(x = B, y = B),",
    "  outercols = 'A',",
    "  caption = 'Cap {A}'",
    ") + geom_point()",
    "```",
    "",
    "See @fig-my_plots.",
    "",
    "```{r}",
    "#| ggtibble: \"my_plots\"",
    "```",
    "",
    sep = "\n"
  )

  td <- withr::local_tempdir()
  qmd_path <- file.path(td, "test.qmd")
  writeLines(qmd, qmd_path)

  # Render — quarto::quarto_render writes alongside the input
  quarto::quarto_render(qmd_path, output_format = "html", quiet = TRUE)
  html_path <- sub("\\.qmd$", ".html", qmd_path)
  expect_true(file.exists(html_path))

  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  # The cross-reference should resolve (no error message about unresolved refs)
  expect_false(grepl("Unable to resolve crossref", html, fixed = TRUE))
  # The figure id should be set on the figure container
  expect_match(html, "fig-my_plots")
})
