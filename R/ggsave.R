#' Save a plot or list of plots
#'
#' @inheritParams ggplot2::ggsave
#' @export
ggsave <- function(filename,
                   plot = ggplot2::last_plot(),
                   device = NULL,
                   path = NULL,
                   scale = 1,
                   width = NA,
                   height = NA,
                   units = c("in", "cm", "mm", "px"),
                   dpi = 300,
                   limitsize = TRUE,
                   bg = NULL,
                   create.dir = FALSE,
                   ...) {
  UseMethod("ggsave", plot)
}

#' @describeIn ggsave Save the figures in a `gglist` object
#' @param filename A vector of unique file names for each `plot`
#' @export
ggsave.gglist <- function(filename,
                          plot,
                          device = NULL,
                          path = NULL,
                          scale = 1,
                          width = NA,
                          height = NA,
                          units = c("in", "cm", "mm", "px"),
                          dpi = 300,
                          limitsize = TRUE,
                          bg = NULL,
                          create.dir = FALSE,
                          ...) {
  if (length(filename) != length(plot)) {
    stop("There must be one `filename` per `plot`")
  } else if (any(duplicated(filename))) {
    stop("Each `filename` must be unique")
  }
  ret <-
    vapply(
      X = seq_along(plot),
      FUN = \(idx) {
        ggplot2::ggsave(
          filename = filename[[idx]],
          plot = plot[[idx]],
          device = device,
          path = path,
          scale = scale,
          width = width,
          height = height,
          units = units,
          dpi = dpi,
          limitsize = limitsize,
          bg = bg,
          create.dir = create.dir,
          ...
        )
      },
      FUN.VALUE = ""
    )
  invisible(ret)
}

#' @describeIn ggsave Save the figures in a `ggtibble` object
#' @param filename A character string passed to `glue::glue_data()` to generate
#'   file names for each row in `plot`.
#' @export
ggsave.ggtibble <- function(filename,
                            plot,
                            device = NULL,
                            path = NULL,
                            scale = 1,
                            width = NA,
                            height = NA,
                            units = c("in", "cm", "mm", "px"),
                            dpi = 300,
                            limitsize = TRUE,
                            bg = NULL,
                            create.dir = FALSE,
                            ...) {
  checkmate::assert_character(filename, min.len = 1, max.len = nrow(plot), any.missing = FALSE, null.ok = FALSE)
  checkmate::assert_choice(length(filename), choices = c(1, nrow(plot)), null.ok = FALSE)
  if (length(filename) == nrow(plot)) {
    filenames <- filename
  } else {
    filenames <- glue::glue_data(plot, filename)
  }
  ggsave(
    filename = filenames,
    plot = plot$figure,
    device = device,
    path = path,
    scale = scale,
    width = width,
    height = height,
    units = units,
    dpi = dpi,
    limitsize = limitsize,
    bg = bg,
    create.dir = create.dir,
    ...
  )
}

#' @export
ggsave.default <- function(filename,
                           plot = ggplot2::last_plot(),
                           device = NULL,
                           path = NULL,
                           scale = 1,
                           width = NA,
                           height = NA,
                           units = c("in", "cm", "mm", "px"),
                           dpi = 300,
                           limitsize = TRUE,
                           bg = NULL,
                           create.dir = FALSE,
                           ...) {
  ggplot2::ggsave(
    filename = filename,
    plot = plot,
    device = device,
    path = path,
    scale = scale,
    width = width,
    height = height,
    units = units,
    dpi = dpi,
    limitsize = limitsize,
    bg = bg,
    create.dir = create.dir,
    ...
  )
}
